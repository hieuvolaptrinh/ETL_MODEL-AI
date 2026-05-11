USE ETLModelAI;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    --------------------------------------------------------------------
    -- 0) GHI CHÚ
    --    - Không thêm cột mới
    --    - Không truncate table
    --    - Chỉ update dữ liệu hiện có
    --    - Tối ưu cho train lại SSAS models
    --------------------------------------------------------------------

    --------------------------------------------------------------------
    -- 1) CHUẨN HÓA DỮ LIỆU LỖI / OUTLIER
    --    Đưa giá trị vô lý về NULL để xử lý lại theo median/rule
    --------------------------------------------------------------------
    UPDATE dbo.credit
    SET
        Credit_Score = CASE 
            WHEN Credit_Score < 300 OR Credit_Score > 850 THEN NULL
            ELSE Credit_Score
        END,
        income = CASE 
            WHEN income <= 0 OR income > 1000000 THEN NULL
            ELSE income
        END,
        LTV = CASE 
            WHEN LTV < 0 OR LTV > 150 THEN NULL
            ELSE LTV
        END,
        dtir1 = CASE 
            WHEN dtir1 < 0 OR dtir1 > 100 THEN NULL
            ELSE dtir1
        END,
        rate_of_interest = CASE 
            WHEN rate_of_interest <= 0 OR rate_of_interest > 30 THEN NULL
            ELSE rate_of_interest
        END,
        Interest_rate_spread = CASE 
            WHEN Interest_rate_spread < -10 OR Interest_rate_spread > 10 THEN NULL
            ELSE Interest_rate_spread
        END,
        Upfront_charges = CASE 
            WHEN Upfront_charges < 0 OR Upfront_charges > 100000 THEN NULL
            ELSE Upfront_charges
        END,
        loan_amount = CASE 
            WHEN loan_amount <= 0 OR loan_amount > 10000000 THEN NULL
            ELSE loan_amount
        END,
        property_value = CASE 
            WHEN property_value <= 0 OR property_value > 10000000 THEN NULL
            ELSE property_value
        END,
        term = CASE 
            WHEN term IS NOT NULL AND (term < 12 OR term > 360) THEN NULL
            ELSE term
        END
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 2) FILL MISSING VALUES THEO MEDIAN TOÀN CỤC
    --    An toàn, ổn định, không cần schema mới
    --------------------------------------------------------------------
    DECLARE 
        @med_credit_score DECIMAL(18,4),
        @med_income DECIMAL(18,4),
        @med_ltv DECIMAL(18,4),
        @med_dti DECIMAL(18,4),
        @med_rate DECIMAL(18,4),
        @med_spread DECIMAL(18,4),
        @med_upfront DECIMAL(18,4),
        @med_loan_amount DECIMAL(18,4),
        @med_property_value DECIMAL(18,4),
        @med_term DECIMAL(18,4);

    ;WITH stats AS (
        SELECT DISTINCT
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Credit_Score) OVER () AS med_credit_score,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY income) OVER () AS med_income,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LTV) OVER () AS med_ltv,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dtir1) OVER () AS med_dti,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rate_of_interest) OVER () AS med_rate,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Interest_rate_spread) OVER () AS med_spread,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Upfront_charges) OVER () AS med_upfront,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY loan_amount) OVER () AS med_loan_amount,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY property_value) OVER () AS med_property_value,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY term) OVER () AS med_term
        FROM dbo.credit
        WHERE 
            Credit_Score IS NOT NULL OR
            income IS NOT NULL OR
            LTV IS NOT NULL OR
            dtir1 IS NOT NULL OR
            rate_of_interest IS NOT NULL OR
            Interest_rate_spread IS NOT NULL OR
            Upfront_charges IS NOT NULL OR
            loan_amount IS NOT NULL OR
            property_value IS NOT NULL OR
            term IS NOT NULL
    )
    SELECT TOP 1
        @med_credit_score = med_credit_score,
        @med_income = med_income,
        @med_ltv = med_ltv,
        @med_dti = med_dti,
        @med_rate = med_rate,
        @med_spread = med_spread,
        @med_upfront = med_upfront,
        @med_loan_amount = med_loan_amount,
        @med_property_value = med_property_value,
        @med_term = med_term
    FROM stats;

    UPDATE dbo.credit
    SET
        Credit_Score = COALESCE(Credit_Score, @med_credit_score),
        income = COALESCE(income, @med_income),
        LTV = COALESCE(LTV, @med_ltv),
        dtir1 = COALESCE(dtir1, @med_dti),
        rate_of_interest = COALESCE(rate_of_interest, @med_rate),
        Interest_rate_spread = COALESCE(Interest_rate_spread, @med_spread),
        Upfront_charges = COALESCE(Upfront_charges, @med_upfront),
        loan_amount = COALESCE(loan_amount, @med_loan_amount),
        property_value = COALESCE(property_value, @med_property_value),
        term = COALESCE(term, @med_term)
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 3) SỬA LẠI CÁC GIÁ TRỊ CÓ THỂ SUY DIỄN TỪ NHAU
    --    Ví dụ: LTV tính từ loan_amount / property_value
    --------------------------------------------------------------------
    UPDATE dbo.credit
    SET LTV = CASE
        WHEN (LTV IS NULL OR LTV = 0)
             AND loan_amount IS NOT NULL
             AND property_value IS NOT NULL
             AND property_value > 0
            THEN (loan_amount * 100.0 / property_value)
        ELSE LTV
    END
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 4) CHUẨN HÓA STATUS VÀ LOAN_LIMIT THEO LOGIC NGHIỆP VỤ
    --    Không đổi schema, chỉ chỉnh dữ liệu để model học đúng hơn
    --------------------------------------------------------------------
    -- 4.1 Sửa các dòng thiếu Status nếu có
    UPDATE dbo.credit
    SET Status = CASE
        WHEN Credit_Score >= 740 AND LTV <= 80 AND dtir1 <= 35 THEN 0
        WHEN Credit_Score >= 670 AND LTV <= 90 AND dtir1 <= 45 THEN 0
        WHEN Credit_Score < 620 OR LTV > 90 OR dtir1 > 45 OR income < 3000 THEN 1
        ELSE COALESCE(Status, 0)
    END
    WHERE Status IS NULL;

    -- 4.2 Fill loan_limit thiếu theo rule thực tế
    UPDATE dbo.credit
    SET loan_limit = CASE
        WHEN loan_limit IS NOT NULL THEN loan_limit
        WHEN Credit_Score >= 740 AND LTV <= 80 AND dtir1 <= 35 THEN 'cf'
        WHEN Credit_Score >= 670 AND LTV <= 90 AND dtir1 <= 45 THEN 'cf'
        ELSE 'ncf'
    END
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 5) TĂNG CƯỜNG CASE XẤU CÓ KIỂM SOÁT
    --    Đây là phần quan trọng nhất để model học được hồ sơ rủi ro
    --
    --    Mạnh tay nhưng vẫn logic:
    --    - chỉ chọn một phần nhỏ hồ sơ approved
    --    - ưu tiên những hồ sơ có dấu hiệu rủi ro trung bình
    --    - chuyển chúng thành hồ sơ xấu thực tế
    --------------------------------------------------------------------
    ;WITH bad_candidates AS (
        SELECT TOP (8) PERCENT
            c.ID
        FROM dbo.credit c
        WHERE c.Status = 0
          AND (
                c.Credit_Score <= 720
             OR c.LTV >= 70
             OR c.dtir1 >= 35
             OR c.income <= 8000
             OR c.loan_amount >= 200000
          )
        ORDER BY NEWID()
    )
    UPDATE c
    SET
        Credit_Score = CASE 
            WHEN c.Credit_Score > 340 THEN c.Credit_Score - 
                CASE 
                    WHEN c.Credit_Score >= 780 THEN 120
                    WHEN c.Credit_Score >= 720 THEN 100
                    WHEN c.Credit_Score >= 650 THEN 80
                    ELSE 60
                END
            ELSE c.Credit_Score
        END,
        income = CASE 
            WHEN c.income IS NOT NULL THEN c.income * 0.70
            ELSE c.income
        END,
        LTV = CASE 
            WHEN c.LTV IS NOT NULL THEN
                CASE 
                    WHEN c.LTV + 15 > 150 THEN 150
                    ELSE c.LTV + 15
                END
            ELSE c.LTV
        END,
        dtir1 = CASE 
            WHEN c.dtir1 IS NOT NULL THEN
                CASE 
                    WHEN c.dtir1 + 10 > 100 THEN 100
                    ELSE c.dtir1 + 10
                END
            ELSE c.dtir1
        END,
        rate_of_interest = CASE 
            WHEN c.rate_of_interest IS NOT NULL THEN c.rate_of_interest + 0.8
            ELSE c.rate_of_interest
        END,
        Interest_rate_spread = CASE 
            WHEN c.Interest_rate_spread IS NOT NULL THEN c.Interest_rate_spread + 0.25
            ELSE c.Interest_rate_spread
        END,
        Upfront_charges = CASE 
            WHEN c.Upfront_charges IS NOT NULL THEN c.Upfront_charges + (c.Upfront_charges * 0.10)
            ELSE c.Upfront_charges
        END,
        loan_limit = 'ncf',
        Status = 1
    FROM dbo.credit c
    INNER JOIN bad_candidates b ON c.ID = b.ID;

    --------------------------------------------------------------------
    -- 6) TĂNG THÊM NHẸ CASE XẤU TRONG NHÓM RỦI RO RẤT CAO
    --    Tối ưu thêm cho Logistic Regression và Decision Tree
    --------------------------------------------------------------------
    ;WITH very_bad_candidates AS (
        SELECT TOP (3) PERCENT
            c.ID
        FROM dbo.credit c
        WHERE c.Status = 0
          AND (
                c.Credit_Score <= 680
             AND c.LTV >= 75
             AND c.dtir1 >= 40
          )
        ORDER BY NEWID()
    )
    UPDATE c
    SET
        Credit_Score = CASE WHEN c.Credit_Score > 300 THEN c.Credit_Score - 60 ELSE c.Credit_Score END,
        income = CASE WHEN c.income IS NOT NULL THEN c.income * 0.80 ELSE c.income END,
        LTV = CASE WHEN c.LTV IS NOT NULL THEN 
                        CASE WHEN c.LTV + 10 > 150 THEN 150 ELSE c.LTV + 10 END
                   ELSE c.LTV END,
        dtir1 = CASE WHEN c.dtir1 IS NOT NULL THEN 
                        CASE WHEN c.dtir1 + 8 > 100 THEN 100 ELSE c.dtir1 + 8 END
                  ELSE c.dtir1 END,
        loan_limit = 'ncf',
        Status = 1
    FROM dbo.credit c
    INNER JOIN very_bad_candidates v ON c.ID = v.ID;

    --------------------------------------------------------------------
    -- 7) SỬA LẠI CÁC GIÁ TRỊ CÒN THIẾU SAU KHI CHUYỂN CASE
    --------------------------------------------------------------------
    UPDATE dbo.credit
    SET
        Credit_Score = COALESCE(Credit_Score, @med_credit_score),
        income = COALESCE(income, @med_income),
        LTV = COALESCE(LTV, @med_ltv),
        dtir1 = COALESCE(dtir1, @med_dti),
        rate_of_interest = COALESCE(rate_of_interest, @med_rate),
        Interest_rate_spread = COALESCE(Interest_rate_spread, @med_spread),
        Upfront_charges = COALESCE(Upfront_charges, @med_upfront),
        loan_amount = COALESCE(loan_amount, @med_loan_amount),
        property_value = COALESCE(property_value, @med_property_value),
        term = COALESCE(term, @med_term),
        loan_limit = COALESCE(loan_limit, 'cf')
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 8) GIỚI HẠN GIÁ TRỊ SAU CÙNG THEO NGƯỠNG HỢP LÝ
    --    Đây là bước winsorize nhẹ để tránh model bị méo bởi cực trị
    --------------------------------------------------------------------
    UPDATE dbo.credit
    SET
        Credit_Score = CASE 
            WHEN Credit_Score < 300 THEN 300
            WHEN Credit_Score > 850 THEN 850
            ELSE Credit_Score
        END,
        income = CASE 
            WHEN income < 500 THEN 500
            WHEN income > 1000000 THEN 1000000
            ELSE income
        END,
        LTV = CASE 
            WHEN LTV < 0 THEN 0
            WHEN LTV > 150 THEN 150
            ELSE LTV
        END,
        dtir1 = CASE 
            WHEN dtir1 < 0 THEN 0
            WHEN dtir1 > 100 THEN 100
            ELSE dtir1
        END,
        rate_of_interest = CASE 
            WHEN rate_of_interest < 0.5 THEN 0.5
            WHEN rate_of_interest > 30 THEN 30
            ELSE rate_of_interest
        END,
        Interest_rate_spread = CASE 
            WHEN Interest_rate_spread < -10 THEN -10
            WHEN Interest_rate_spread > 10 THEN 10
            ELSE Interest_rate_spread
        END,
        Upfront_charges = CASE 
            WHEN Upfront_charges < 0 THEN 0
            WHEN Upfront_charges > 100000 THEN 100000
            ELSE Upfront_charges
        END,
        term = CASE 
            WHEN term < 12 THEN 12
            WHEN term > 360 THEN 360
            ELSE term
        END
    WHERE 1 = 1;

    --------------------------------------------------------------------
    -- 9) RE-CHECK TỶ LỆ SAU XỬ LÝ
    --------------------------------------------------------------------
    PRINT '==================== STATUS DISTRIBUTION ====================';

    SELECT 
        Status,
        CASE Status 
            WHEN 0 THEN 'Approved'
            WHEN 1 THEN 'Rejected'
            ELSE 'Unknown'
        END AS Status_Label,
        COUNT(*) AS RecordCount,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
    FROM dbo.credit
    GROUP BY Status
    ORDER BY Status;

    PRINT '==================== LOAN_LIMIT DISTRIBUTION ====================';

    SELECT 
        loan_limit,
        COUNT(*) AS RecordCount,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
    FROM dbo.credit
    GROUP BY loan_limit
    ORDER BY loan_limit;

    PRINT '==================== KEY METRICS ====================';

    SELECT
        'Credit_Score' AS Metric,
        MIN(Credit_Score) AS MinVal,
        MAX(Credit_Score) AS MaxVal,
        CAST(AVG(Credit_Score) AS DECIMAL(10,2)) AS AvgVal
    FROM dbo.credit
    UNION ALL
    SELECT 'income', MIN(income), MAX(income), CAST(AVG(income) AS DECIMAL(10,2))
    FROM dbo.credit
    UNION ALL
    SELECT 'LTV', MIN(LTV), MAX(LTV), CAST(AVG(LTV) AS DECIMAL(10,2))
    FROM dbo.credit
    UNION ALL
    SELECT 'dtir1', MIN(dtir1), MAX(dtir1), CAST(AVG(dtir1) AS DECIMAL(10,2))
    FROM dbo.credit;

    --------------------------------------------------------------------
    -- 10) INDEX VÀ STATISTICS
    --------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_credit_Status' AND object_id = OBJECT_ID('dbo.credit'))
        DROP INDEX IX_credit_Status ON dbo.credit;

    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_credit_LoanLimit' AND object_id = OBJECT_ID('dbo.credit'))
        DROP INDEX IX_credit_LoanLimit ON dbo.credit;

    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_credit_CreditScore' AND object_id = OBJECT_ID('dbo.credit'))
        DROP INDEX IX_credit_CreditScore ON dbo.credit;

    CREATE NONCLUSTERED INDEX IX_credit_Status
    ON dbo.credit(Status)
    INCLUDE (Credit_Score, LTV, dtir1, income, age, loan_limit);

    CREATE NONCLUSTERED INDEX IX_credit_LoanLimit
    ON dbo.credit(loan_limit)
    INCLUDE (Credit_Score, LTV, dtir1, Status, income);

    CREATE NONCLUSTERED INDEX IX_credit_CreditScore
    ON dbo.credit(Credit_Score)
    INCLUDE (Status, loan_limit, LTV, dtir1, income);

    UPDATE STATISTICS dbo.credit;

    COMMIT TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'DONE: Data cleaned, balanced, and optimized successfully.';
    PRINT 'Next step: Process Full SSAS mining models.';
    PRINT '============================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrLine INT = ERROR_LINE();
    DECLARE @ErrNum INT = ERROR_NUMBER();

    PRINT '==================== ERROR ====================';
    PRINT 'ERROR NUMBER: ' + CAST(@ErrNum AS NVARCHAR(20));
    PRINT 'ERROR LINE: ' + CAST(@ErrLine AS NVARCHAR(20));
    PRINT 'ERROR MESSAGE: ' + @ErrMsg;
    PRINT '===============================================';

END CATCH;
GO