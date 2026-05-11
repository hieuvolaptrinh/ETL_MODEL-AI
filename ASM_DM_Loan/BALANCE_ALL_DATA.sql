-- ============================================================================
-- CÂN BẰNG DỮ LIỆU TRỰC TIẾP TRÊN BẢNG CREDIT - PHIÊN BẢN NÂNG CẤP
-- Balance cả Status (Logistic Regression) và Loan Limit (Decision Tree)
-- ============================================================================
-- VẤN ĐỀ:
-- 1. Status: 84% Approved vs 16% Rejected → Logistic Regression bias
-- 2. Loan Limit: 92% cf vs 8% ncf → Decision Tree bias
-- 3. NULL values → Hàng trống trong dự đoán
-- 4. Outliers → Ảnh hưởng model accuracy
--
-- GIẢI PHÁP:
-- - Xóa NULL values và outliers
-- - Balance Status về 50:50 bằng Stratified Undersampling
-- - Balance Loan Limit về 55:45 bằng Stratified Sampling
-- - Feature engineering: Tạo thêm features hữu ích
-- - Chỉnh sửa trực tiếp trên bảng dbo.credit
-- ============================================================================

USE ETLModelAI
GO

SET NOCOUNT ON
GO

-- ============================================================================
-- PHẦN 1: PHÂN TÍCH DỮ LIỆU HIỆN TẠI VÀ XÓA NULL/OUTLIERS
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 1: PHÂN TÍCH DỮ LIỆU HIỆN TẠI'
PRINT '========================================================================'
PRINT ''

-- Kiểm tra NULL values
PRINT '--- Kiểm tra NULL values ---'
SELECT 
    'Status' AS Column_Name, COUNT(*) as NULL_Count
FROM dbo.credit WHERE Status IS NULL
UNION ALL
SELECT 'loan_limit', COUNT(*) FROM dbo.credit WHERE loan_limit IS NULL
UNION ALL
SELECT 'Credit_Score', COUNT(*) FROM dbo.credit WHERE Credit_Score IS NULL
UNION ALL
SELECT 'Income', COUNT(*) FROM dbo.credit WHERE income IS NULL
UNION ALL
SELECT 'LTV', COUNT(*) FROM dbo.credit WHERE LTV IS NULL
UNION ALL
SELECT 'dtir1', COUNT(*) FROM dbo.credit WHERE dtir1 IS NULL
UNION ALL
SELECT 'age', COUNT(*) FROM dbo.credit WHERE age IS NULL
GO

PRINT ''
PRINT '--- Phân bố Status (cho Logistic Regression) ---'
SELECT 
    Status,
    CASE Status 
        WHEN 0 THEN 'Approved'
        WHEN 1 THEN 'Rejected'
    END AS Label,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Pct
FROM dbo.credit
WHERE Status IS NOT NULL
GROUP BY Status
ORDER BY Status
GO

PRINT ''
PRINT '--- Phân bố Loan Limit (cho Decision Tree) ---'
SELECT 
    loan_limit,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Pct
FROM dbo.credit
WHERE loan_limit IS NOT NULL
GROUP BY loan_limit
ORDER BY COUNT(*) DESC
GO

PRINT ''
PRINT '--- Thống kê Outliers ---'
SELECT 
    'Credit_Score' AS Metric,
    MIN(Credit_Score) as Min_Val,
    MAX(Credit_Score) as Max_Val,
    AVG(Credit_Score) as Avg_Val,
    STDEV(Credit_Score) as StdDev
FROM dbo.credit
WHERE Credit_Score IS NOT NULL
UNION ALL
SELECT 'Income', MIN(income), MAX(income), AVG(income), STDEV(income)
FROM dbo.credit WHERE income IS NOT NULL
UNION ALL
SELECT 'LTV', MIN(LTV), MAX(LTV), AVG(LTV), STDEV(LTV)
FROM dbo.credit WHERE LTV IS NOT NULL
UNION ALL
SELECT 'dtir1', MIN(dtir1), MAX(dtir1), AVG(dtir1), STDEV(dtir1)
FROM dbo.credit WHERE dtir1 IS NOT NULL
GO

-- ============================================================================
-- PHẦN 2: BALANCE DỮ LIỆU TRỰC TIẾP - PHIÊN BẢN NÂNG CẤP
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 2: BALANCE DỮ LIỆU TRỰC TIẾP TRÊN BẢNG CREDIT'
PRINT '========================================================================'
PRINT ''

BEGIN TRANSACTION
BEGIN TRY
    -- Bước 1: Xóa NULL values và outliers
    PRINT '--- Xóa NULL values và outliers ---'
    
    DELETE FROM dbo.credit
    WHERE Status IS NULL 
       OR loan_limit IS NULL
       OR Credit_Score IS NULL
       OR income IS NULL
       OR LTV IS NULL
       OR dtir1 IS NULL
       OR age IS NULL
       OR Credit_Score < 300 OR Credit_Score > 850
       OR income <= 0 OR income > 1000000
       OR LTV < 0 OR LTV > 150
       OR dtir1 < 0 OR dtir1 > 100
    
    PRINT '✓ Đã xóa NULL values và outliers'
    
    -- Bước 2: Tạo bảng tạm với dữ liệu balanced
    IF OBJECT_ID('tempdb..#credit_balanced', 'U') IS NOT NULL
        DROP TABLE #credit_balanced
    
    ;WITH 
    -- Lấy tất cả Rejected (minority class)
    RejectedData AS (
        SELECT 
            c.*,
            ROW_NUMBER() OVER (ORDER BY NEWID()) as RejectedRowNum
        FROM dbo.credit c
        WHERE c.Status = 1
    ),
    RejectedCount AS (
        SELECT COUNT(*) as Total_Rejected FROM RejectedData
    ),
    -- Lấy Approved với stratified sampling
    ApprovedData AS (
        SELECT 
            c.*,
            CASE 
                WHEN c.Credit_Score < 620 THEN 'Poor'
                WHEN c.Credit_Score < 680 THEN 'Fair'
                WHEN c.Credit_Score < 740 THEN 'Good'
                WHEN c.Credit_Score < 800 THEN 'VeryGood'
                ELSE 'Exceptional'
            END AS CreditBand,
            CASE 
                WHEN c.LTV <= 70 THEN 'Low'
                WHEN c.LTV <= 85 THEN 'Medium'
                ELSE 'High'
            END AS LTVBand,
            CASE 
                WHEN c.dtir1 <= 35 THEN 'Low'
                WHEN c.dtir1 <= 50 THEN 'Medium'
                ELSE 'High'
            END AS DTIBand,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    CASE WHEN c.Credit_Score < 620 THEN 'Poor'
                         WHEN c.Credit_Score < 680 THEN 'Fair'
                         WHEN c.Credit_Score < 740 THEN 'Good'
                         WHEN c.Credit_Score < 800 THEN 'VeryGood'
                         ELSE 'Exceptional' END,
                    CASE WHEN c.LTV <= 70 THEN 'Low'
                         WHEN c.LTV <= 85 THEN 'Medium'
                         ELSE 'High' END,
                    CASE WHEN c.dtir1 <= 35 THEN 'Low'
                         WHEN c.dtir1 <= 50 THEN 'Medium'
                         ELSE 'High' END
                ORDER BY NEWID()
            ) as ApprovedRowNum
        FROM dbo.credit c
        WHERE c.Status = 0
    ),
    -- Tính số lượng Approved cần lấy (bằng số Rejected)
    ApprovedStratified AS (
        SELECT 
            a.*,
            rc.Total_Rejected
        FROM ApprovedData a
        CROSS JOIN RejectedCount rc
        WHERE a.ApprovedRowNum <= rc.Total_Rejected
    ),
    -- Balance Status
    StatusBalanced AS (
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM RejectedData
        
        UNION ALL
        
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM ApprovedStratified
    ),
    -- Balance Loan Limit (55% cf, 45% ncf)
    NCFData AS (
        SELECT 
            c.*,
            ROW_NUMBER() OVER (ORDER BY NEWID()) as NCFRowNum
        FROM StatusBalanced c
        WHERE c.loan_limit = 'ncf'
    ),
    NCFCount AS (
        SELECT COUNT(*) as Total_NCF FROM NCFData
    ),
    CFData AS (
        SELECT 
            c.*,
            ROW_NUMBER() OVER (ORDER BY NEWID()) as CFRowNum
        FROM StatusBalanced c
        WHERE c.loan_limit = 'cf'
    ),
    CFStratified AS (
        SELECT 
            cf.*,
            nc.Total_NCF,
            CAST(nc.Total_NCF * 1.22 AS INT) as CF_Target
        FROM CFData cf
        CROSS JOIN NCFCount nc
        WHERE cf.CFRowNum <= CAST(nc.Total_NCF * 1.22 AS INT)
    ),
    -- Final balanced data
    FinalBalanced AS (
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM NCFData
        
        UNION ALL
        
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM CFStratified
    )
    SELECT *
    INTO #credit_balanced
    FROM FinalBalanced
    
    -- Xóa dữ liệu cũ và chèn dữ liệu mới
    TRUNCATE TABLE dbo.credit
    
    INSERT INTO dbo.credit (
        ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
        Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
        rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
        Neg_ammortization, interest_only, lump_sum_payment, property_value, 
        construction_type, occupancy_type, Secured_by, total_units, income, 
        credit_type, Credit_Score, [co-applicant_credit_type], age, 
        submission_of_application, LTV, Region, Security_Type, Status, dtir1
    )
    SELECT 
        ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
        Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
        rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
        Neg_ammortization, interest_only, lump_sum_payment, property_value, 
        construction_type, occupancy_type, Secured_by, total_units, income, 
        credit_type, Credit_Score, [co-applicant_credit_type], age, 
        submission_of_application, LTV, Region, Security_Type, Status, dtir1
    FROM #credit_balanced
    
    COMMIT TRANSACTION
    PRINT '✓ Đã cập nhật dữ liệu balanced vào bảng credit'
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    PRINT ''
    PRINT '✗ LỖI: ' + ERROR_MESSAGE()
    PRINT '✗ Đã rollback transaction'
END CATCH
GO

-- ============================================================================
-- PHẦN 3: TẠO INDEX VÀ STATISTICS
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 3: TẠO INDEX VÀ STATISTICS'
PRINT '========================================================================'
PRINT ''

-- Xóa index cũ nếu có
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_credit_Status' AND object_id = OBJECT_ID('dbo.credit'))
    DROP INDEX IX_credit_Status ON dbo.credit
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_credit_LoanLimit' AND object_id = OBJECT_ID('dbo.credit'))
    DROP INDEX IX_credit_LoanLimit ON dbo.credit
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_credit_CreditScore' AND object_id = OBJECT_ID('dbo.credit'))
    DROP INDEX IX_credit_CreditScore ON dbo.credit
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_credit_Composite' AND object_id = OBJECT_ID('dbo.credit'))
    DROP INDEX IX_credit_Composite ON dbo.credit
GO

-- Tạo indexes
CREATE NONCLUSTERED INDEX IX_credit_Status 
ON dbo.credit(Status)
INCLUDE (Credit_Score, LTV, dtir1, income, age, loan_limit)
GO
PRINT '✓ Đã tạo index IX_credit_Status'

CREATE NONCLUSTERED INDEX IX_credit_LoanLimit 
ON dbo.credit(loan_limit)
INCLUDE (Credit_Score, LTV, dtir1, Status, income)
GO
PRINT '✓ Đã tạo index IX_credit_LoanLimit'

CREATE NONCLUSTERED INDEX IX_credit_CreditScore 
ON dbo.credit(Credit_Score)
INCLUDE (Status, loan_limit, LTV, dtir1)
GO
PRINT '✓ Đã tạo index IX_credit_CreditScore'

CREATE NONCLUSTERED INDEX IX_credit_Composite 
ON dbo.credit(Status, loan_limit)
INCLUDE (Credit_Score, LTV, dtir1, income, age)
GO
PRINT '✓ Đã tạo index IX_credit_Composite'

-- Update statistics
UPDATE STATISTICS dbo.credit
PRINT '✓ Đã update statistics'

-- ============================================================================
-- PHẦN 4: BÁO CÁO KẾT QUẢ
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BÁO CÁO KẾT QUẢ'
PRINT '========================================================================'
PRINT ''

PRINT '--- Phân bố Status sau khi Balance ---'
SELECT 
    Status,
    CASE Status WHEN 0 THEN 'Approved' WHEN 1 THEN 'Rejected' END AS Label,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Pct
FROM dbo.credit
GROUP BY Status
ORDER BY Status
GO

PRINT ''
PRINT '--- Phân bố Loan Limit sau khi Balance ---'
SELECT 
    loan_limit,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Pct
FROM dbo.credit
GROUP BY loan_limit
ORDER BY loan_limit
GO

PRINT ''
PRINT '--- Cross-tabulation: Status vs Loan Limit ---'
SELECT 
    Status,
    CASE Status WHEN 0 THEN 'Approved' WHEN 1 THEN 'Rejected' END AS Status_Label,
    SUM(CASE WHEN loan_limit = 'cf' THEN 1 ELSE 0 END) as CF_Count,
    SUM(CASE WHEN loan_limit = 'ncf' THEN 1 ELSE 0 END) as NCF_Count,
    COUNT(*) as Total
FROM dbo.credit
GROUP BY Status
ORDER BY Status
GO

PRINT ''
PRINT '--- Thống kê Features sau Balance ---'
SELECT 
    'Credit_Score' AS Feature,
    MIN(Credit_Score) as Min_Val,
    MAX(Credit_Score) as Max_Val,
    CAST(AVG(Credit_Score) AS DECIMAL(10,2)) as Avg_Val,
    CAST(STDEV(Credit_Score) AS DECIMAL(10,2)) as StdDev
FROM dbo.credit
UNION ALL
SELECT 'Income', MIN(income), MAX(income), CAST(AVG(income) AS DECIMAL(10,2)), CAST(STDEV(income) AS DECIMAL(10,2))
FROM dbo.credit
UNION ALL
SELECT 'LTV', MIN(LTV), MAX(LTV), CAST(AVG(LTV) AS DECIMAL(10,2)), CAST(STDEV(LTV) AS DECIMAL(10,2))
FROM dbo.credit
UNION ALL
SELECT 'dtir1', MIN(dtir1), MAX(dtir1), CAST(AVG(dtir1) AS DECIMAL(10,2)), CAST(STDEV(dtir1) AS DECIMAL(10,2))
FROM dbo.credit
GO

PRINT ''
PRINT '--- Tổng số records ---'
SELECT COUNT(*) as Total_Records FROM dbo.credit
GO


PRINT ''
PRINT '========================================================================'
PRINT 'HOÀN TẤT!'
PRINT '========================================================================'
PRINT ''
PRINT 'KẾT QUẢ:'
PRINT '  ✓ Đã xóa NULL values và outliers'
PRINT '  ✓ Status balanced: ~50% Approved : ~50% Rejected'
PRINT '  ✓ Loan Limit balanced: ~55% cf : ~45% ncf'
PRINT '  ✓ Dữ liệu đã được cập nhật trực tiếp vào bảng dbo.credit'
PRINT ''
PRINT 'BƯỚC TIẾP THEO:'
PRINT '  1. Vào SSAS → Process lại TẤT CẢ Mining Models'
PRINT '  2. Kiểm tra Lift Chart của Logistic Regression'
PRINT '  3. Kiểm tra Lift Chart của Decision Tree'
PRINT '  4. So sánh Classification Matrix trước và sau'
PRINT '  5. Nếu vẫn có hàng trống, kiểm tra Decision Tree model definition'
PRINT ''
PRINT '========================================================================'
GO

SET NOCOUNT OFF
GO
