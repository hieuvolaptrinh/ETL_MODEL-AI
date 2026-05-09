-- ============================================================================
-- DMX QUERIES - CREDIT LOAN ANALYSIS SYSTEM
-- Các truy vấn DMX THỰC SỰ được sử dụng trong dự án ASM_DM_Loan
-- ============================================================================

USE [ETLModelAI]
GO

-- ============================================================================
-- 1. LOGISTIC REGRESSION MODEL - DỰ ĐOÁN KHOẢN VAY
-- Model: [Credit] (Logistic_Regression_Status)
-- Service: LogisticRegressionService.cs
-- ============================================================================

-- 1.1. Dự đoán khoản vay với Logistic Regression (Query thực tế trong code)
SELECT 
    PredictProbability([Status], 0) AS [Probability_Approved],
    PredictProbability([Status], 1) AS [Probability_Rejected],
    CASE 
        WHEN PredictProbability([Status], 0) > 0.5 THEN 'APPROVED'
        ELSE 'REJECTED'
    END AS [Prediction_Result],
    CASE 
        WHEN PredictProbability([Status], 0) >= 0.7 THEN 'HIGH CONFIDENCE'
        WHEN PredictProbability([Status], 0) >= 0.5 THEN 'MODERATE CONFIDENCE'
        ELSE 'LOW CONFIDENCE'
    END AS [Confidence_Level],
    CASE 
        WHEN PredictProbability([Status], 1) >= 0.7 THEN 'HIGH RISK'
        WHEN PredictProbability([Status], 1) >= 0.4 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS [Risk_Category]
FROM 
    [Credit]
NATURAL PREDICTION JOIN
    (SELECT 
        'Male' AS [Gender],
        '25-34' AS [Age],
        750 AS [Credit Score],
        5000 AS [Income],
        150000 AS [Loan Amount],
        80 AS [LTV],
        35 AS [Dtir1]
    ) AS t
GO


-- ============================================================================
-- 2. DECISION TREE MODEL - DỰ ĐOÁN KHOẢN VAY
-- Model: [Decision_Tree_Status]
-- Service: DecisionTreeService.cs
-- ============================================================================

-- 2.1. Dự đoán khoản vay với Decision Tree (Query thực tế trong code)
SELECT 
    PredictProbability([Status], 0) AS [Probability_Approved],
    PredictProbability([Status], 1) AS [Probability_Rejected],
    CASE 
        WHEN PredictProbability([Status], 0) > 0.5 THEN 'APPROVED'
        ELSE 'REJECTED'
    END AS [Prediction_Result],
    CASE 
        WHEN PredictProbability([Status], 0) >= 0.7 THEN 'HIGH CONFIDENCE'
        WHEN PredictProbability([Status], 0) >= 0.5 THEN 'MODERATE CONFIDENCE'
        ELSE 'LOW CONFIDENCE'
    END AS [Confidence_Level],
    CASE 
        WHEN PredictProbability([Status], 1) >= 0.7 THEN 'HIGH RISK'
        WHEN PredictProbability([Status], 1) >= 0.4 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS [Risk_Category]
FROM 
    [Decision_Tree_Status]
NATURAL PREDICTION JOIN
    (SELECT 
        'Male' AS [Gender],
        '25-34' AS [Age],
        750 AS [Credit Score],
        5000 AS [Income],
        150000 AS [Loan Amount],
        80 AS [LTV],
        35 AS [Dtir1]
    ) AS t
GO


-- ============================================================================
-- 3. CLUSTERING MODEL - PHÂN NHÓM KHÁCH HÀNG
-- Model: [Credit_Clustering]
-- Service: ClusteringService.cs
-- ============================================================================

-- 3.1. Dự đoán cluster cho khách hàng (Query thực tế trong code)
SELECT 
    Cluster() AS [ClusterID],
    PredictProbability(Cluster()) AS [ClusterProbability],
    ClusterDistance() AS [ClusterDistance]
FROM 
    [Credit_Clustering]
NATURAL PREDICTION JOIN
    (SELECT 
        'Male' AS [Gender],
        '25-34' AS [Age],
        750 AS [Credit Score],
        5000 AS [Income],
        150000 AS [Loan Amount],
        80 AS [LTV],
        35 AS [Dtir1],
        200000 AS [Property Value]
    ) AS t
GO

-- 3.2. Lấy danh sách TẤT CẢ các clusters (Query thực tế trong code)
-- NODE_TYPE = 5: Cluster nodes
SELECT 
    NODE_NAME, 
    NODE_CAPTION AS ClusterName, 
    NODE_SUPPORT AS CustomerCount, 
    NODE_DESCRIPTION AS ClusterCharacteristics
FROM 
    [Credit_Clustering].CONTENT
WHERE 
    NODE_TYPE = 5
ORDER BY 
    NODE_CAPTION
GO

-- 3.3. Lấy siêu dữ liệu của Clustering Model
-- NODE_TYPE = 1: Root node
SELECT 
    MODEL_CATALOG,
    MODEL_NAME, 
    NODE_CAPTION,
    NODE_SUPPORT AS TotalRecords,
    [CHILDREN_CARDINALITY] AS TotalClusters,
    NODE_DESCRIPTION
FROM 
    [Credit_Clustering].CONTENT
WHERE 
    NODE_TYPE = 1
GO

-- 3.4. Lấy thông tin schema của Clustering Model
SELECT 
    MODEL_NAME,
    DATE_CREATED,
    LAST_PROCESSED,
    MINING_PARAMETERS
FROM 
    $system.DMSCHEMA_MINING_MODELS
WHERE 
    MODEL_NAME = 'Credit_Clustering'
GO

-- 3.5. Xem phân bố Age Group trong các clusters
-- NODE_TYPE = 11: Attribute nodes
SELECT 
    c.NODE_CAPTION AS ClusterName,
    a.ATTRIBUTE_VALUE AS AgeGroup,
    CAST(a.[PROBABILITY] AS DECIMAL(5,4)) AS Probability,
    a.[SUPPORT] AS Count
FROM 
    [Credit_Clustering].CONTENT c
    INNER JOIN [Credit_Clustering].CONTENT a 
        ON a.PARENT_UNIQUE_NAME = c.NODE_UNIQUE_NAME
WHERE 
    c.NODE_TYPE = 5
    AND a.NODE_TYPE = 11
    AND a.ATTRIBUTE_NAME = 'Age'
ORDER BY 
    c.NODE_CAPTION, a.[PROBABILITY] DESC
GO

-- 3.6. Xem phân bố Gender trong các clusters
SELECT 
    c.NODE_CAPTION AS ClusterName,
    a.ATTRIBUTE_VALUE AS Gender,
    CAST(a.[PROBABILITY] AS DECIMAL(5,4)) AS Probability,
    a.[SUPPORT] AS Count
FROM 
    [Credit_Clustering].CONTENT c
    INNER JOIN [Credit_Clustering].CONTENT a 
        ON a.PARENT_UNIQUE_NAME = c.NODE_UNIQUE_NAME
WHERE 
    c.NODE_TYPE = 5
    AND a.NODE_TYPE = 11
    AND a.ATTRIBUTE_NAME = 'Gender'
ORDER BY 
    c.NODE_CAPTION, a.[PROBABILITY] DESC
GO


-- ============================================================================
-- 4. MODEL METADATA - THÔNG TIN CÁC MODELS
-- Truy vấn thông tin về tất cả các models trong hệ thống
-- ============================================================================

-- 4.1. Danh sách tất cả các mining models
SELECT 
    MODEL_CATALOG,
    MODEL_NAME,
    SERVICE_NAME AS Algorithm,
    DATE_CREATED,
    LAST_PROCESSED,
    MINING_PARAMETERS
FROM 
    $system.DMSCHEMA_MINING_MODELS
WHERE 
    MODEL_CATALOG = 'ETLModelAI'
ORDER BY 
    MODEL_NAME
GO

-- 4.2. Thông tin chi tiết Logistic Regression Model
SELECT 
    MODEL_CATALOG,
    MODEL_NAME, 
    NODE_CAPTION,
    NODE_SUPPORT AS TotalRecords,
    NODE_DESCRIPTION
FROM 
    [Credit].CONTENT
WHERE 
    NODE_TYPE = 1
GO

-- 4.3. Thông tin chi tiết Decision Tree Model
SELECT 
    MODEL_CATALOG,
    MODEL_NAME, 
    NODE_CAPTION,
    NODE_SUPPORT AS TotalRecords,
    [CHILDREN_CARDINALITY] AS TotalNodes,
    NODE_DESCRIPTION
FROM 
    [Decision_Tree_Status].CONTENT
WHERE 
    NODE_TYPE = 1
GO


-- ============================================================================
-- 5. BATCH PREDICTION - DỰ ĐOÁN HÀNG LOẠT
-- Dự đoán cho nhiều records cùng lúc (dùng cho testing/validation)
-- ============================================================================

-- 5.1. Batch prediction với Logistic Regression
SELECT 
    t.ID,
    t.Gender,
    t.age AS AgeGroup,
    t.Credit_Score,
    t.income,
    t.loan_amount,
    t.LTV,
    t.dtir1 AS DTI,
    t.Status AS ActualStatus,
    PredictProbability([Status], 0) AS ApprovalProbability,
    PredictProbability([Status], 1) AS RejectionProbability,
    CASE 
        WHEN PredictProbability([Status], 0) > 0.5 THEN 'APPROVED'
        ELSE 'REJECTED'
    END AS PredictionResult,
    CASE 
        WHEN PredictProbability([Status], 0) >= 0.7 THEN 'HIGH CONFIDENCE'
        WHEN PredictProbability([Status], 0) >= 0.5 THEN 'MODERATE CONFIDENCE'
        ELSE 'LOW CONFIDENCE'
    END AS ConfidenceLevel
FROM 
    [Credit]
PREDICTION JOIN
    OPENQUERY([ETL Model AI], 
        'SELECT TOP 100 ID, Gender, age, Credit_Score, income, loan_amount, 
                LTV, dtir1, Status
         FROM credit
         ORDER BY ID DESC') AS t
ON 
    [Credit].[Gender] = t.[Gender] AND
    [Credit].[Age] = t.[age] AND
    [Credit].[Credit Score] = t.[Credit_Score] AND
    [Credit].[Income] = t.[income] AND
    [Credit].[Loan Amount] = t.[loan_amount] AND
    [Credit].[LTV] = t.[LTV] AND
    [Credit].[Dtir1] = t.[dtir1]
GO

-- 5.2. Batch prediction với Decision Tree
SELECT 
    t.ID,
    t.Gender,
    t.age AS AgeGroup,
    t.Credit_Score,
    t.income,
    t.loan_amount,
    t.LTV,
    t.dtir1 AS DTI,
    t.Status AS ActualStatus,
    PredictProbability([Status], 0) AS ApprovalProbability,
    PredictProbability([Status], 1) AS RejectionProbability,
    CASE 
        WHEN PredictProbability([Status], 0) > 0.5 THEN 'APPROVED'
        ELSE 'REJECTED'
    END AS PredictionResult
FROM 
    [Decision_Tree_Status]
PREDICTION JOIN
    OPENQUERY([ETL Model AI], 
        'SELECT TOP 100 ID, Gender, age, Credit_Score, income, loan_amount, 
                LTV, dtir1, Status
         FROM credit
         ORDER BY ID DESC') AS t
ON 
    [Decision_Tree_Status].[Gender] = t.[Gender] AND
    [Decision_Tree_Status].[Age] = t.[age] AND
    [Decision_Tree_Status].[Credit Score] = t.[Credit_Score] AND
    [Decision_Tree_Status].[Income] = t.[income] AND
    [Decision_Tree_Status].[Loan Amount] = t.[loan_amount] AND
    [Decision_Tree_Status].[LTV] = t.[LTV] AND
    [Decision_Tree_Status].[Dtir1] = t.[dtir1]
GO

-- 5.3. Batch clustering - Phân nhóm hàng loạt
SELECT 
    t.ID,
    t.Gender,
    t.age AS AgeGroup,
    t.Credit_Score,
    t.income,
    t.loan_amount,
    Cluster() AS ClusterID,
    ClusterProbability() AS ClusterConfidence
FROM 
    [Credit_Clustering]
PREDICTION JOIN
    OPENQUERY([ETL Model AI], 
        'SELECT TOP 100 ID, Gender, age, Credit_Score, income, loan_amount, 
                LTV, dtir1, property_value
         FROM credit
         ORDER BY ID DESC') AS t
ON 
    [Credit_Clustering].[Gender] = t.[Gender] AND
    [Credit_Clustering].[Age] = t.[age] AND
    [Credit_Clustering].[Credit Score] = t.[Credit_Score] AND
    [Credit_Clustering].[Income] = t.[income] AND
    [Credit_Clustering].[Loan Amount] = t.[loan_amount] AND
    [Credit_Clustering].[LTV] = t.[LTV] AND
    [Credit_Clustering].[Dtir1] = t.[dtir1] AND
    [Credit_Clustering].[Property Value] = t.[property_value]
GO


-- ============================================================================
-- 6. MODEL ACCURACY - ĐÁNH GIÁ ĐỘ CHÍNH XÁC
-- Tính toán Confusion Matrix và Accuracy
-- ============================================================================

-- 6.1. Confusion Matrix cho Logistic Regression
SELECT 
    'Logistic Regression' AS Model,
    SUM(CASE WHEN t.Status = 0 AND PredictProbability([Status], 0) > 0.5 THEN 1 ELSE 0 END) AS TruePositive,
    SUM(CASE WHEN t.Status = 1 AND PredictProbability([Status], 0) <= 0.5 THEN 1 ELSE 0 END) AS TrueNegative,
    SUM(CASE WHEN t.Status = 1 AND PredictProbability([Status], 0) > 0.5 THEN 1 ELSE 0 END) AS FalsePositive,
    SUM(CASE WHEN t.Status = 0 AND PredictProbability([Status], 0) <= 0.5 THEN 1 ELSE 0 END) AS FalseNegative,
    CAST(SUM(CASE 
        WHEN (t.Status = 0 AND PredictProbability([Status], 0) > 0.5) OR 
             (t.Status = 1 AND PredictProbability([Status], 0) <= 0.5) 
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Accuracy
FROM 
    [Credit]
PREDICTION JOIN
    OPENQUERY([ETL Model AI], 
        'SELECT ID, Gender, age, Credit_Score, income, loan_amount, 
                LTV, dtir1, Status
         FROM credit') AS t
ON 
    [Credit].[Gender] = t.[Gender] AND
    [Credit].[Age] = t.[age] AND
    [Credit].[Credit Score] = t.[Credit_Score] AND
    [Credit].[Income] = t.[income] AND
    [Credit].[Loan Amount] = t.[loan_amount] AND
    [Credit].[LTV] = t.[LTV] AND
    [Credit].[Dtir1] = t.[dtir1]
GO

-- 6.2. Confusion Matrix cho Decision Tree
SELECT 
    'Decision Tree' AS Model,
    SUM(CASE WHEN t.Status = 0 AND PredictProbability([Status], 0) > 0.5 THEN 1 ELSE 0 END) AS TruePositive,
    SUM(CASE WHEN t.Status = 1 AND PredictProbability([Status], 0) <= 0.5 THEN 1 ELSE 0 END) AS TrueNegative,
    SUM(CASE WHEN t.Status = 1 AND PredictProbability([Status], 0) > 0.5 THEN 1 ELSE 0 END) AS FalsePositive,
    SUM(CASE WHEN t.Status = 0 AND PredictProbability([Status], 0) <= 0.5 THEN 1 ELSE 0 END) AS FalseNegative,
    CAST(SUM(CASE 
        WHEN (t.Status = 0 AND PredictProbability([Status], 0) > 0.5) OR 
             (t.Status = 1 AND PredictProbability([Status], 0) <= 0.5) 
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Accuracy
FROM 
    [Decision_Tree_Status]
PREDICTION JOIN
    OPENQUERY([ETL Model AI], 
        'SELECT ID, Gender, age, Credit_Score, income, loan_amount, 
                LTV, dtir1, Status
         FROM credit') AS t
ON 
    [Decision_Tree_Status].[Gender] = t.[Gender] AND
    [Decision_Tree_Status].[Age] = t.[age] AND
    [Decision_Tree_Status].[Credit Score] = t.[Credit_Score] AND
    [Decision_Tree_Status].[Income] = t.[income] AND
    [Decision_Tree_Status].[Loan Amount] = t.[loan_amount] AND
    [Decision_Tree_Status].[LTV] = t.[LTV] AND
    [Decision_Tree_Status].[Dtir1] = t.[dtir1]
GO


-- ============================================================================
-- LƯU Ý QUAN TRỌNG:
-- ============================================================================
-- 1. Tất cả queries trên đây là queries THỰC SỰ được sử dụng trong code C#
-- 2. Models được sử dụng:
--    - [Credit]: Logistic Regression Model (Logistic_Regression_Status.dmm)
--    - [Decision_Tree_Status]: Decision Tree Model (Credit_Decision_Tree.dmm)
--    - [Credit_Clustering]: Clustering Model (Credit_Clustering.dmm)
-- 3. NODE_TYPE values:
--    - NODE_TYPE = 1: Root node (siêu dữ liệu model)
--    - NODE_TYPE = 5: Cluster nodes (các cụm trong clustering)
--    - NODE_TYPE = 11: Attribute nodes (thuộc tính của clusters)
-- 4. Services sử dụng DMX:
--    - LogisticRegressionService.cs
--    - DecisionTreeService.cs
--    - ClusteringService.cs
--    - DashboardService.cs
-- ============================================================================
