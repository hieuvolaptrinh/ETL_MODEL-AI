-- ============================================================================
-- CÂN BẰNG DỮ LIỆU TRỰC TIẾP TRÊN BẢNG CREDIT
-- Balance cả Status (Logistic Regression) và Loan Limit (Decision Tree)
-- ============================================================================
-- VẤN ĐỀ:
-- 1. Status: 84% Approved vs 16% Rejected → Logistic Regression bias
-- 2. Loan Limit: 92% cf vs 8% ncf → Decision Tree bias
--
-- GIẢI PHÁP:
-- - Balance Status về 50:50 bằng Stratified Undersampling
-- - Balance Loan Limit về 60:40 bằng Oversample ncf + Undersample cf
-- - Chỉnh sửa trực tiếp trên bảng dbo.credit
-- ============================================================================

USE ETLModelAI
GO

SET NOCOUNT ON
GO

-- ============================================================================
-- PHẦN 1: PHÂN TÍCH DỮ LIỆU HIỆN TẠI
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 1: PHÂN TÍCH DỮ LIỆU HIỆN TẠI'
PRINT '========================================================================'
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
GROUP BY loan_limit
ORDER BY COUNT(*) DESC
GO

-- ============================================================================
-- PHẦN 2: BALANCE DỮ LIỆU TRỰC TIẾP
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 2: BALANCE DỮ LIỆU TRỰC TIẾP TRÊN BẢNG CREDIT'
PRINT '========================================================================'
PRINT ''

BEGIN TRANSACTION
BEGIN TRY
    -- Tạo bảng tạm với dữ liệu balanced
    IF OBJECT_ID('tempdb..#credit_balanced', 'U') IS NOT NULL
        DROP TABLE #credit_balanced
    
    ;WITH 
    MinorityCount AS (
        SELECT COUNT(*) as Rejected_Total
        FROM dbo.credit
        WHERE Status = 1
    ),
    RejectedDistribution AS (
        SELECT 
            CASE 
                WHEN Credit_Score < 580 THEN 'Poor'
                WHEN Credit_Score < 670 THEN 'Fair'
                WHEN Credit_Score < 740 THEN 'Good'
                WHEN Credit_Score < 800 THEN 'VeryGood'
                ELSE 'Exceptional'
            END AS Credit_Range,
            age AS Age_Group,
            CASE 
                WHEN LTV <= 70 THEN 'VeryLow'
                WHEN LTV <= 80 THEN 'Low'
                WHEN LTV <= 90 THEN 'Medium'
                ELSE 'High'
            END AS LTV_Range,
            CASE 
                WHEN dtir1 <= 30 THEN 'Low'
                WHEN dtir1 <= 40 THEN 'Medium'
                ELSE 'High'
            END AS DTI_Range,
            COUNT(*) as Rejected_Count
        FROM dbo.credit
        WHERE Status = 1
        GROUP BY 
            CASE 
                WHEN Credit_Score < 580 THEN 'Poor'
                WHEN Credit_Score < 670 THEN 'Fair'
                WHEN Credit_Score < 740 THEN 'Good'
                WHEN Credit_Score < 800 THEN 'VeryGood'
                ELSE 'Exceptional'
            END,
            age,
            CASE 
                WHEN LTV <= 70 THEN 'VeryLow'
                WHEN LTV <= 80 THEN 'Low'
                WHEN LTV <= 90 THEN 'Medium'
                ELSE 'High'
            END,
            CASE 
                WHEN dtir1 <= 30 THEN 'Low'
                WHEN dtir1 <= 40 THEN 'Medium'
                ELSE 'High'
            END
    ),
    ApprovedWithRanges AS (
        SELECT 
            c.*,
            CASE 
                WHEN c.Credit_Score < 580 THEN 'Poor'
                WHEN c.Credit_Score < 670 THEN 'Fair'
                WHEN c.Credit_Score < 740 THEN 'Good'
                WHEN c.Credit_Score < 800 THEN 'VeryGood'
                ELSE 'Exceptional'
            END AS Credit_Range,
            c.age AS Age_Group,
            CASE 
                WHEN c.LTV <= 70 THEN 'VeryLow'
                WHEN c.LTV <= 80 THEN 'Low'
                WHEN c.LTV <= 90 THEN 'Medium'
                ELSE 'High'
            END AS LTV_Range,
            CASE 
                WHEN c.dtir1 <= 30 THEN 'Low'
                WHEN c.dtir1 <= 40 THEN 'Medium'
                ELSE 'High'
            END AS DTI_Range
        FROM dbo.credit c
        WHERE c.Status = 0
    ),
    ApprovedStratified AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY Credit_Range, Age_Group, LTV_Range, DTI_Range
                ORDER BY NEWID()
            ) as RowNum
        FROM ApprovedWithRanges
    ),
    StatusBalanced AS (
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM (
            SELECT * FROM dbo.credit WHERE Status = 1
            
            UNION ALL
            
            SELECT 
                a.ID, a.year, a.loan_limit, a.Gender, a.approv_in_adv, a.loan_type, a.loan_purpose, 
                a.Credit_Worthiness, a.open_credit, a.business_or_commercial, a.loan_amount, 
                a.rate_of_interest, a.Interest_rate_spread, a.Upfront_charges, a.term, 
                a.Neg_ammortization, a.interest_only, a.lump_sum_payment, a.property_value, 
                a.construction_type, a.occupancy_type, a.Secured_by, a.total_units, a.income, 
                a.credit_type, a.Credit_Score, a.[co-applicant_credit_type], a.age, 
                a.submission_of_application, a.LTV, a.Region, a.Security_Type, a.Status, a.dtir1
            FROM ApprovedStratified a
            INNER JOIN RejectedDistribution rd ON
                a.Credit_Range = rd.Credit_Range
                AND a.Age_Group = rd.Age_Group
                AND a.LTV_Range = rd.LTV_Range
                AND a.DTI_Range = rd.DTI_Range
            WHERE a.RowNum <= rd.Rejected_Count
        ) AS BalancedData
    ),
    NCF_Oversampled AS (
        SELECT 
            c.*,
            n.n as Replica_Number
        FROM StatusBalanced c
        CROSS JOIN (
            SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n
            FROM sys.objects
        ) n
        WHERE c.loan_limit = 'ncf'
    ),
    CF_WithRanges AS (
        SELECT 
            c.*,
            CASE 
                WHEN c.Credit_Score < 580 THEN 'Poor'
                WHEN c.Credit_Score < 670 THEN 'Fair'
                WHEN c.Credit_Score < 740 THEN 'Good'
                WHEN c.Credit_Score < 800 THEN 'VeryGood'
                ELSE 'Exceptional'
            END AS Credit_Range,
            c.age AS Age_Group,
            CASE 
                WHEN c.LTV <= 70 THEN 'VeryLow'
                WHEN c.LTV <= 80 THEN 'Low'
                WHEN c.LTV <= 90 THEN 'Medium'
                ELSE 'High'
            END AS LTV_Range,
            CASE 
                WHEN c.dtir1 <= 30 THEN 'Low'
                WHEN c.dtir1 <= 40 THEN 'Medium'
                ELSE 'High'
            END AS DTI_Range
        FROM StatusBalanced c
        WHERE c.loan_limit = 'cf'
    ),
    CF_Stratified AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY Credit_Range, Age_Group, LTV_Range, DTI_Range
                ORDER BY NEWID()
            ) as RowNum
        FROM CF_WithRanges
    ),
    TargetCount AS (
        SELECT 
            CAST((SELECT COUNT(*) FROM NCF_Oversampled) * 1.5 AS INT) as CF_Target
    )
    SELECT 
        ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
        Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
        rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
        Neg_ammortization, interest_only, lump_sum_payment, property_value, 
        construction_type, occupancy_type, Secured_by, total_units, income, 
        credit_type, Credit_Score, [co-applicant_credit_type], age, 
        submission_of_application, LTV, Region, Security_Type, Status, dtir1
    INTO #credit_balanced
    FROM (
        SELECT 
            ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
            Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
            rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
            Neg_ammortization, interest_only, lump_sum_payment, property_value, 
            construction_type, occupancy_type, Secured_by, total_units, income, 
            credit_type, Credit_Score, [co-applicant_credit_type], age, 
            submission_of_application, LTV, Region, Security_Type, Status, dtir1
        FROM NCF_Oversampled
        
        UNION ALL
        
        SELECT 
            cf.ID, cf.year, cf.loan_limit, cf.Gender, cf.approv_in_adv, cf.loan_type, cf.loan_purpose, 
            cf.Credit_Worthiness, cf.open_credit, cf.business_or_commercial, cf.loan_amount, 
            cf.rate_of_interest, cf.Interest_rate_spread, cf.Upfront_charges, cf.term, 
            cf.Neg_ammortization, cf.interest_only, cf.lump_sum_payment, cf.property_value, 
            cf.construction_type, cf.occupancy_type, cf.Secured_by, cf.total_units, cf.income, 
            cf.credit_type, cf.Credit_Score, cf.[co-applicant_credit_type], cf.age, 
            cf.submission_of_application, cf.LTV, cf.Region, cf.Security_Type, cf.Status, cf.dtir1
        FROM CF_Stratified cf
        CROSS JOIN TargetCount tc
        WHERE cf.RowNum <= tc.CF_Target
    ) AS FinalBalancedData
    
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
-- PHẦN 3: TẠO INDEX
-- ============================================================================

PRINT ''
PRINT '========================================================================'
PRINT 'BƯỚC 3: TẠO INDEX'
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

CREATE NONCLUSTERED INDEX IX_credit_Status 
ON dbo.credit(Status)
INCLUDE (Credit_Score, LTV, dtir1, age)
GO
PRINT '✓ Đã tạo index IX_credit_Status'

CREATE NONCLUSTERED INDEX IX_credit_LoanLimit 
ON dbo.credit(loan_limit)
INCLUDE (Credit_Score, LTV, dtir1)
GO
PRINT '✓ Đã tạo index IX_credit_LoanLimit'

CREATE NONCLUSTERED INDEX IX_credit_CreditScore 
ON dbo.credit(Credit_Score)
GO
PRINT '✓ Đã tạo index IX_credit_CreditScore'

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
PRINT '========================================================================'
PRINT 'HOÀN TẤT!'
PRINT '========================================================================'
PRINT ''
PRINT 'KẾT QUẢ:'
PRINT '  ✓ Status balanced: ~50% Approved : ~50% Rejected'
PRINT '  ✓ Loan Limit balanced: ~60% cf : ~40% ncf'
PRINT '  ✓ Dữ liệu đã được cập nhật trực tiếp vào bảng dbo.credit'
PRINT ''
PRINT 'BƯỚC TIẾP THEO:'
PRINT '  1. Vào SSAS → Process lại TẤT CẢ Mining Models'
PRINT '  2. Kiểm tra Lift Chart của Logistic Regression'
PRINT '  3. Kiểm tra Lift Chart của Decision Tree'
PRINT '  4. So sánh Classification Matrix trước và sau'
PRINT ''
PRINT '========================================================================'
GO

SET NOCOUNT OFF
GO
