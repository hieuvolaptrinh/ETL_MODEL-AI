-- ============================================================================
-- TẠO BALANCED DATASET BẰNG STRATIFIED SAMPLING
-- Sử dụng FICO Credit Score Standard Ranges
-- ============================================================================

USE [YourDatabase]
GO

-- Xóa view/table cũ nếu có
IF OBJECT_ID('dbo.credit_balanced', 'V') IS NOT NULL
    DROP VIEW dbo.credit_balanced
GO

IF OBJECT_ID('dbo.credit_balanced', 'U') IS NOT NULL
    DROP TABLE dbo.credit_balanced
GO

-- ============================================================================
-- FICO CREDIT SCORE RANGES (Standard Industry Classification)
-- ============================================================================
-- 300-579: Poor (Very High Risk)
-- 580-669: Fair (High Risk)
-- 670-739: Good (Medium Risk)
-- 740-799: Very Good (Low Risk)
-- 800-850: Exceptional (Very Low Risk)
-- ============================================================================

-- Phân tích phân bố của Rejected records để làm chuẩn
SELECT 
    CASE 
        WHEN Credit_Score < 580 THEN '1. Poor (300-579)'
        WHEN Credit_Score < 670 THEN '2. Fair (580-669)'
        WHEN Credit_Score < 740 THEN '3. Good (670-739)'
        WHEN Credit_Score < 800 THEN '4. Very Good (740-799)'
        ELSE '5. Exceptional (800+)'
    END AS Credit_Range,
    age AS Age_Group,
    CASE 
        WHEN LTV <= 80 THEN 'Low LTV (≤80%)'
        WHEN LTV <= 90 THEN 'Medium LTV (80-90%)'
        ELSE 'High LTV (>90%)'
    END AS LTV_Range,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Percentage
FROM dbo.credit
WHERE Status = 1
GROUP BY 
    CASE 
        WHEN Credit_Score < 580 THEN '1. Poor (300-579)'
        WHEN Credit_Score < 670 THEN '2. Fair (580-669)'
        WHEN Credit_Score < 740 THEN '3. Good (670-739)'
        WHEN Credit_Score < 800 THEN '4. Very Good (740-799)'
        ELSE '5. Exceptional (800+)'
    END,
    age,
    CASE 
        WHEN LTV <= 80 THEN 'Low LTV (≤80%)'
        WHEN LTV <= 90 THEN 'Medium LTV (80-90%)'
        ELSE 'High LTV (>90%)'
    END
ORDER BY Credit_Range, Age_Group, LTV_Range
GO

-- ============================================================================
-- STRATIFIED SAMPLING THEO FICO RANGES, AGE & LTV
-- Lấy Approved records theo tỷ lệ tương tự Rejected
-- ============================================================================

;WITH RejectedDistribution AS (
    -- Tính phân bố của Rejected theo Credit Score (FICO), Age, và LTV
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
            WHEN LTV <= 80 THEN 'Low'
            WHEN LTV <= 90 THEN 'Medium'
            ELSE 'High'
        END AS LTV_Range,
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
            WHEN LTV <= 80 THEN 'Low'
            WHEN LTV <= 90 THEN 'Medium'
            ELSE 'High'
        END
),
ApprovedSampled AS (
    -- Lấy Approved records theo stratified sampling
    SELECT 
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY 
                CASE 
                    WHEN c.Credit_Score < 580 THEN 'Poor'
                    WHEN c.Credit_Score < 670 THEN 'Fair'
                    WHEN c.Credit_Score < 740 THEN 'Good'
                    WHEN c.Credit_Score < 800 THEN 'VeryGood'
                    ELSE 'Exceptional'
                END,
                c.age,
                CASE 
                    WHEN c.LTV <= 80 THEN 'Low'
                    WHEN c.LTV <= 90 THEN 'Medium'
                    ELSE 'High'
                END
            ORDER BY NEWID()
        ) as rn,
        rd.Rejected_Count
    FROM dbo.credit c
    INNER JOIN RejectedDistribution rd ON
        CASE 
            WHEN c.Credit_Score < 580 THEN 'Poor'
            WHEN c.Credit_Score < 670 THEN 'Fair'
            WHEN c.Credit_Score < 740 THEN 'Good'
            WHEN c.Credit_Score < 800 THEN 'VeryGood'
            ELSE 'Exceptional'
        END = rd.Credit_Range
        AND c.age = rd.Age_Group
        AND CASE 
            WHEN c.LTV <= 80 THEN 'Low'
            WHEN c.LTV <= 90 THEN 'Medium'
            ELSE 'High'
        END = rd.LTV_Range
    WHERE c.Status = 0
)
SELECT * 
INTO dbo.credit_balanced
FROM (
    -- Lấy TẤT CẢ Rejected records
    SELECT * FROM dbo.credit WHERE Status = 1
    
    UNION ALL
    
    -- Lấy Approved records theo stratified sampling
    SELECT 
        ID, year, loan_limit, Gender, approv_in_adv, loan_type, loan_purpose, 
        Credit_Worthiness, open_credit, business_or_commercial, loan_amount, 
        rate_of_interest, Interest_rate_spread, Upfront_charges, term, 
        Neg_ammortization, interest_only, lump_sum_payment, property_value, 
        construction_type, occupancy_type, Secured_by, total_units, income, 
        credit_type, Credit_Score, [co-applicant_credit_type], age, 
        submission_of_application, LTV, Region, Security_Type, Status, dtir1
    FROM ApprovedSampled
    WHERE rn <= Rejected_Count
) AS balanced_data
GO

-- ============================================================================
-- KIỂM TRA KẾT QUẢ
-- ============================================================================

-- 1. Kiểm tra tổng số lượng và tỷ lệ
SELECT 
    Status,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Percentage
FROM dbo.credit_balanced
GROUP BY Status
ORDER BY Status
GO

-- 2. Kiểm tra phân bố theo FICO Credit Score Ranges
SELECT 
    Status,
    CASE 
        WHEN Credit_Score < 580 THEN '1. Poor (300-579)'
        WHEN Credit_Score < 670 THEN '2. Fair (580-669)'
        WHEN Credit_Score < 740 THEN '3. Good (670-739)'
        WHEN Credit_Score < 800 THEN '4. Very Good (740-799)'
        ELSE '5. Exceptional (800+)'
    END AS Credit_Range,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Status) AS DECIMAL(5,2)) as Percentage_Within_Status
FROM dbo.credit_balanced
GROUP BY 
    Status,
    CASE 
        WHEN Credit_Score < 580 THEN '1. Poor (300-579)'
        WHEN Credit_Score < 670 THEN '2. Fair (580-669)'
        WHEN Credit_Score < 740 THEN '3. Good (670-739)'
        WHEN Credit_Score < 800 THEN '4. Very Good (740-799)'
        ELSE '5. Exceptional (800+)'
    END
ORDER BY Status, Credit_Range
GO

-- 3. Kiểm tra phân bố theo Age Group
SELECT 
    Status,
    age AS Age_Group,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Status) AS DECIMAL(5,2)) as Percentage_Within_Status
FROM dbo.credit_balanced
GROUP BY Status, age
ORDER BY Status, age
GO

-- 4. Kiểm tra phân bố theo LTV Range
SELECT 
    Status,
    CASE 
        WHEN LTV <= 80 THEN '1. Low LTV (≤80%)'
        WHEN LTV <= 90 THEN '2. Medium LTV (80-90%)'
        ELSE '3. High LTV (>90%)'
    END AS LTV_Range,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Status) AS DECIMAL(5,2)) as Percentage_Within_Status
FROM dbo.credit_balanced
GROUP BY 
    Status,
    CASE 
        WHEN LTV <= 80 THEN '1. Low LTV (≤80%)'
        WHEN LTV <= 90 THEN '2. Medium LTV (80-90%)'
        ELSE '3. High LTV (>90%)'
    END
ORDER BY Status, LTV_Range
GO

-- ============================================================================
-- KẾT QUẢ MONG ĐỢI:
-- ============================================================================
-- 1. Status 0 và Status 1 có số lượng gần bằng nhau (~50:50)
-- 2. Phân bố Credit Score của 2 classes tương tự nhau
-- 3. Phân bố Age Group của 2 classes tương tự nhau
-- 4. Phân bố LTV Range của 2 classes tương tự nhau
-- 
-- VÍ DỤ:
-- Nếu Rejected có 25% Poor Credit + 25-34 tuổi + High LTV
-- Thì Approved cũng sẽ có 25% Poor Credit + 25-34 tuổi + High LTV
-- 
-- → Model sẽ học được pattern chính xác hơn!
-- ============================================================================
