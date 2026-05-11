-- ============================================================================
-- DMX QUERIES - CREDIT LOAN ANALYSIS SYSTEM
-- Các truy vấn DMX THỰC SỰ được sử dụng trong ASM_DM_Loan_UI
-- ============================================================================

USE [ETLModelAI]
GO

-- ============================================================================
-- 1. DECISION TREE MODEL - DỰ ĐOÁN KHOẢN VAY (PREDICTION PAGE)
-- Model: [Credit_Decision_Tree]
-- Service: DecisionTreeService.cs
-- API: /api/decision-tree/predict
-- ============================================================================

-- Query thực tế trong DecisionTreeService.cs
SELECT 
    [Loan Limit],
    PredictProbability([Loan Limit], 'cf75') AS [Probability_High],
    PredictProbability([Loan Limit], 'ncf75') AS [Probability_Low],
    CASE 
        WHEN [Loan Limit] = 'cf75' THEN 'APPROVED'
        ELSE 'REJECTED'
    END AS [Prediction_Result],
    CASE 
        WHEN PredictProbability([Loan Limit], 'cf75') >= 0.7 THEN 'HIGH CONFIDENCE'
        WHEN PredictProbability([Loan Limit], 'cf75') >= 0.5 THEN 'MODERATE CONFIDENCE'
        ELSE 'LOW CONFIDENCE'
    END AS [Confidence_Level],
    CASE 
        WHEN [Loan Limit] = 'ncf75' THEN 'HIGH RISK'
        WHEN PredictProbability([Loan Limit], 'ncf75') >= 0.4 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS [Risk_Category]
FROM 
    [Credit_Decision_Tree]
NATURAL PREDICTION JOIN
    (SELECT 
        750 AS [Credit Score],
        5000 AS [Income],
        80 AS [LTV],
        35 AS [Dtir1],
        250000 AS [Property Value],
        'Home' AS [Loan Purpose]
    ) AS t
GO


-- ============================================================================
-- 2. LOGISTIC REGRESSION MODEL - DỰ ĐOÁN NỢ XẤU (LOGISTIC PAGE)
-- Model: [Logistic_Regression_Status]
-- Service: LogisticRegressionService.cs
-- API: /api/logistic-regression/predict
-- ============================================================================

-- Query thực tế trong LogisticRegressionService.cs
SELECT
    PredictProbability([Status], 1) AS [BadDebtProbability],
    PredictProbability([Status], 0) AS [GoodDebtProbability],
    CASE
        WHEN Predict([Status]) = 1 THEN 'BAD_DEBT'
        ELSE 'GOOD_DEBT'
    END AS [PredictionResult],
    CASE
        WHEN PredictProbability([Status], 1) >= 0.80 THEN 'VERY HIGH'
        WHEN PredictProbability([Status], 1) >= 0.60 THEN 'HIGH'
        WHEN PredictProbability([Status], 1) >= 0.40 THEN 'MEDIUM'
        WHEN PredictProbability([Status], 1) >= 0.20 THEN 'LOW'
        ELSE 'VERY LOW'
    END AS [RiskLevel],
    CASE
        WHEN PredictProbability([Status], 1) >= 0.80 OR PredictProbability([Status], 1) <= 0.20 THEN 'High'
        WHEN PredictProbability([Status], 1) >= 0.65 OR PredictProbability([Status], 1) <= 0.35 THEN 'Medium'
        ELSE 'Low'
    END AS [ConfidenceLevel]
FROM [Logistic_Regression_Status]
NATURAL PREDICTION JOIN
(SELECT
    38 AS [Age],
    680 AS [Credit Score],
    'Standard' AS [Credit Type],
    34 AS [Dtir1],
    6500 AS [Income],
    180000 AS [Loan Amount],
    'Home' AS [Loan Purpose],
    'Conventional' AS [Loan Type],
    72 AS [LTV],
    250000 AS [Property Value],
    5.5 AS [Rate Of Interest],
    360 AS [Term]
) AS t
GO


-- ============================================================================
-- 3. CLUSTERING MODEL - PHÂN NHÓM KHÁCH HÀNG (CLUSTERING PAGE)
-- Model: [Credit_Clustering]
-- Service: ClusteringService.cs
-- API: /api/clustering/predict
-- ============================================================================

-- 3.1. Dự đoán cluster cho khách hàng
-- Query thực tế trong ClusteringService.PredictCustomerCluster()
SELECT 
    Cluster() AS [ClusterID],
    PredictProbability(Cluster()) AS [ClusterProbability],
    ClusterDistance() AS [ClusterDistance]
FROM 
    [Credit_Clustering]
NATURAL PREDICTION JOIN
    (SELECT 
        'Male' AS [Gender],
        '35-44' AS [Age],
        750 AS [Credit Score],
        5000 AS [Income],
        200000 AS [Loan Amount],
        80 AS [LTV],
        35 AS [Dtir1]
    ) AS t
GO

-- 3.2. Lấy danh sách TẤT CẢ các clusters với thông tin chi tiết
-- Query thực tế trong ClusteringService.GetClusterProfiles()
-- NODE_TYPE = 5: Cluster nodes
SELECT 
    NODE_NAME, 
    NODE_CAPTION, 
    NODE_SUPPORT, 
    NODE_DESCRIPTION
FROM 
    [Credit_Clustering].CONTENT
WHERE 
    NODE_TYPE = 5
ORDER BY 
    NODE_CAPTION
GO


-- ============================================================================
-- LƯU Ý QUAN TRỌNG:
-- ============================================================================
-- 1. Tất cả queries trên đây là queries THỰC SỰ được sử dụng trong code C#
-- 2. Models được sử dụng:
--    - [Credit_Decision_Tree]: Decision Tree Model (prediction.js)
--    - [Logistic_Regression_Status]: Logistic Regression Model (logistic.js)
--    - [Credit_Clustering]: Clustering Model (clustering.js)
-- 3. NODE_TYPE values:
--    - NODE_TYPE = 5: Cluster nodes (các cụm trong clustering)
-- 4. Services sử dụng DMX:
--    - DecisionTreeService.cs
--    - LogisticRegressionService.cs
--    - ClusteringService.cs
-- 5. Dashboard (dashboard.js) không gọi DMX trực tiếp, chỉ tổng hợp data từ các services
-- ============================================================================
