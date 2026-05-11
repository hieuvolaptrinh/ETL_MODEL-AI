# Credit Decision Tree - Hướng Dẫn Chi Tiết

## 1. Mô Tả Model

### Mục Đích
Dự đoán **Loan Limit** (Hạn mức vay) cho khách hàng dựa trên các đặc điểm tài chính:
- **cf** (Confirmed): Hạn mức vay được xác nhận
- **ncf** (Not Confirmed): Hạn mức vay chưa được xác nhận

### Thông Tin Cơ Bản
- **Thuật toán**: Microsoft Decision Trees (SSAS)
- **Database**: `ETLModelAI`
- **Bảng dữ liệu**: `dbo.credit`
- **File model**: `ASM_DM_Loan/ASM_DM_Loan/Credit_Decision_Tree.dmm`
- **Tổng records**: ~20,000 (sau khi balance)

---

## 2. Cấu Trúc Model

### Input Features (7 cột)

| # | Feature | Kiểu | Phạm Vi | Mô Tả |
|---|---------|------|--------|-------|
| 1 | Credit Score | Continuous | 300-850 | Điểm tín dụng |
| 2 | Dtir1 | Continuous | 0-100 | Debt-to-Income Ratio (Tỷ lệ nợ/thu nhập) |
| 3 | Income | Continuous | 5000-1000000 | Thu nhập hàng năm |
| 4 | LTV | Continuous | 0-150 | Loan-to-Value Ratio (Tỷ lệ vay/giá trị tài sản) |
| 5 | Loan Purpose | Discrete | Home, Auto, Personal | Mục đích vay |
| 6 | Property Value | Continuous | 50000-5000000 | Giá trị tài sản đảm bảo |
| 7 | ID | Key | 1, 2, 3... | Định danh record |

### Target Variable
- **Cột**: `loan_limit`
- **Kiểu**: Discrete (2 giá trị)
- **Phân bố**: 55% cf, 45% ncf (sau khi balance)

---

## 3. Cách Hoạt Động

### Nguyên Lý Decision Tree

Decision Tree hoạt động bằng cách chia dữ liệu thành các nhánh dựa trên các điều kiện:

```
                    ┌─────────────────────────┐
                    │  Tất cả dữ liệu (20k)   │
                    │  cf: 11k, ncf: 9k       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Credit Score < 700?     │
                    │ (Chia điểm tín dụng)    │
                    └────┬──────────────┬─────┘
                         │              │
        ┌────────────────┘              └────────────────┐
        │                                               │
   ┌────▼──────────┐                          ┌────────▼────────┐
   │ Credit < 700  │                          │ Credit >= 700   │
   │ (Poor)        │                          │ (Good)          │
   │ cf: 2k, ncf:5k│                          │ cf: 9k, ncf: 4k │
   └────┬──────────┘                          └────────┬────────┘
        │                                              │
   ┌────▼──────────┐                          ┌────────▼────────┐
   │ LTV > 80?     │                          │ Income < 50k?   │
   │ (Rủi ro cao)  │                          │ (Thu nhập thấp) │
   └────┬──────────┘                          └────────┬────────┘
        │                                              │
   ┌────┴────┐                                  ┌──────┴──────┐
   │          │                                  │             │
┌──▼──┐  ┌───▼──┐                          ┌────▼──┐    ┌─────▼───┐
│ ncf │  │ cf   │                          │ cf    │    │ ncf     │
│ 70% │  │ 30%  │                          │ 80%   │    │ 20%     │
│ 3.5k│  │ 1.5k │                          │ 7.2k  │    │ 1.8k    │
└─────┘  └──────┘                          └───────┘    └─────────┘
```

### Quy Tắc Dự Đoán

Model tạo ra các quy tắc từ cây:

| Điều Kiện | Dự Đoán | Độ Tin Cậy |
|-----------|---------|-----------|
| Credit Score < 700 AND LTV > 80 | **ncf** | 70% |
| Credit Score < 700 AND LTV ≤ 80 | **cf** | 30% |
| Credit Score ≥ 700 AND Income < 50k | **cf** | 80% |
| Credit Score ≥ 700 AND Income ≥ 50k | **ncf** | 20% |

---

## 4. Chuẩn Bị Dữ Liệu

### Bước 1: Xóa NULL Values

```sql
DELETE FROM dbo.credit
WHERE Status IS NULL 
   OR loan_limit IS NULL
   OR Credit_Score IS NULL
   OR income IS NULL
   OR LTV IS NULL
   OR dtir1 IS NULL
   OR age IS NULL
```

**Kết quả**: Loại bỏ records không đầy đủ

### Bước 2: Xóa Outliers

```sql
DELETE FROM dbo.credit
WHERE Credit_Score < 300 OR Credit_Score > 850
   OR income <= 0 OR income > 1000000
   OR LTV < 0 OR LTV > 150
   OR dtir1 < 0 OR dtir1 > 100
```

**Kết quả**: Loại bỏ giá trị bất thường

### Bước 3: Balance Dữ Liệu

**Trước balance**:
- cf: 92% (18,400 records)
- ncf: 8% (1,600 records)
- **Vấn đề**: Model sẽ bias dự đoán "cf"

**Sau balance**:
- cf: 55% (11,000 records)
- ncf: 45% (9,000 records)
- **Lợi ích**: Model học cả 2 class tốt hơn

**Script**: `BALANCE_ALL_DATA.sql`

```sql
-- Lấy tất cả ncf (minority class)
SELECT * FROM dbo.credit WHERE loan_limit = 'ncf'

-- Lấy cf bằng stratified sampling
-- Chia cf thành các nhóm theo Credit Score, LTV, DTI
-- Lấy từng nhóm sao cho tổng = số ncf * 1.22

-- Kết hợp lại
UNION ALL
```

**Chạy**:
```bash
sqlcmd -S [SERVER] -d ETLModelAI -i BALANCE_ALL_DATA.sql
```

---

## 5. Dự Đoán

### Cách 1: Dự Đoán Đơn Lẻ

**File**: `DMX_Queries.sql` - Query 2.1

```sql
SELECT 
    PredictProbability([Loan Limit], 'cf') AS Prob_CF,
    PredictProbability([Loan Limit], 'ncf') AS Prob_NCF,
    CASE 
        WHEN PredictProbability([Loan Limit], 'cf') > 0.5 THEN 'cf'
        ELSE 'ncf'
    END AS Prediction
FROM [Credit_Decision_Tree]
NATURAL PREDICTION JOIN
    (SELECT 
        750 AS [Credit Score],
        5000 AS [Income],
        80 AS [LTV],
        35 AS [Dtir1],
        'Home' AS [Loan Purpose],
        200000 AS [Property Value]
    ) AS t
```

**Kết quả**:
```
Prob_CF: 0.75
Prob_NCF: 0.25
Prediction: cf
```

**Giải thích**: 
- Credit Score 750 >= 700 → nhánh "Good"
- Income 5000 < 50k → dự đoán "cf" với 80% tin cậy

### Cách 2: Dự Đoán Hàng Loạt

**File**: `DMX_Queries.sql` - Query 5.2

```sql
SELECT 
    t.ID,
    t.Credit_Score,
    t.LTV,
    t.loan_limit AS Actual,
    CASE 
        WHEN PredictProbability([Loan Limit], 'cf') > 0.5 THEN 'cf'
        ELSE 'ncf'
    END AS Predicted,
    PredictProbability([Loan Limit], 'cf') AS Confidence
FROM [Credit_Decision_Tree]
PREDICTION JOIN
    (SELECT TOP 100 * FROM dbo.credit) AS t
ON [Credit_Decision_Tree].[Credit Score] = t.[Credit_Score]
   AND [Credit_Decision_Tree].[LTV] = t.[LTV]
   AND [Credit_Decision_Tree].[Dtir1] = t.[dtir1]
   AND [Credit_Decision_Tree].[Income] = t.[income]
   AND [Credit_Decision_Tree].[Loan Purpose] = t.[loan_purpose]
   AND [Credit_Decision_Tree].[Property Value] = t.[property_value]
```

**Kết quả**: Bảng so sánh Actual vs Predicted

### Cách 3: Gọi từ C# Code

**File**: `DecisionTreeService.cs`

```csharp
public class DecisionTreeService
{
    public LoanLimitPrediction PredictLoanLimit(LoanApplication app)
    {
        string dmxQuery = $@"
            SELECT 
                PredictProbability([Loan Limit], 'cf') AS CF_Prob,
                PredictProbability([Loan Limit], 'ncf') AS NCF_Prob
            FROM [Credit_Decision_Tree]
            NATURAL PREDICTION JOIN
                (SELECT 
                    {app.CreditScore} AS [Credit Score],
                    {app.Income} AS [Income],
                    {app.LTV} AS [LTV],
                    {app.Dtir1} AS [Dtir1],
                    '{app.LoanPurpose}' AS [Loan Purpose],
                    {app.PropertyValue} AS [Property Value]
                ) AS t
        ";
        
        var result = ExecuteDMXQuery(dmxQuery);
        
        return new LoanLimitPrediction
        {
            PredictedLimit = result.CF_Prob > 0.5 ? "cf" : "ncf",
            Confidence = Math.Max(result.CF_Prob, result.NCF_Prob)
        };
    }
}
```

---

## 6. Đánh Giá Hiệu Suất

### Confusion Matrix

```
                    Predicted
                    cf      ncf
Actual  cf      [TP]    [FN]
        ncf     [FP]    [TN]
```

**Ví dụ**:
```
                    Predicted
                    cf      ncf
Actual  cf      8500    1500    (TP=8500, FN=1500)
        ncf     1000    8000    (FP=1000, TN=8000)
```

### Metrics

| Metric | Công Thức | Ý Nghĩa | Ví Dụ |
|--------|-----------|---------|-------|
| **Accuracy** | (TP+TN)/(TP+TN+FP+FN) | Tỷ lệ dự đoán đúng | (8500+8000)/19000 = 86.8% |
| **Precision** | TP/(TP+FP) | Trong dự đoán cf, bao nhiêu đúng | 8500/(8500+1000) = 89.5% |
| **Recall** | TP/(TP+FN) | Trong cf thực tế, bao nhiêu được phát hiện | 8500/(8500+1500) = 85% |
| **F1-Score** | 2*(P*R)/(P+R) | Cân bằng Precision & Recall | 2*(0.895*0.85)/(0.895+0.85) = 87.2% |

### Kiểm Tra Hiệu Suất

**File**: `DMX_Queries.sql` - Query 6.2

```sql
SELECT 
    'Decision Tree' AS Model,
    SUM(CASE WHEN t.loan_limit = 'cf' AND Predict([Loan Limit]) = 'cf' THEN 1 ELSE 0 END) AS TP,
    SUM(CASE WHEN t.loan_limit = 'ncf' AND Predict([Loan Limit]) = 'ncf' THEN 1 ELSE 0 END) AS TN,
    SUM(CASE WHEN t.loan_limit = 'ncf' AND Predict([Loan Limit]) = 'cf' THEN 1 ELSE 0 END) AS FP,
    SUM(CASE WHEN t.loan_limit = 'cf' AND Predict([Loan Limit]) = 'ncf' THEN 1 ELSE 0 END) AS FN,
    CAST(SUM(CASE 
        WHEN (t.loan_limit = 'cf' AND Predict([Loan Limit]) = 'cf') OR 
             (t.loan_limit = 'ncf' AND Predict([Loan Limit]) = 'ncf')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Accuracy
FROM [Credit_Decision_Tree]
PREDICTION JOIN
    (SELECT * FROM dbo.credit) AS t
ON ...
```

---

## 7. Quy Trình Hoàn Chỉnh

### Bước 1: Chuẩn Bị Dữ Liệu
```bash
sqlcmd -S [SERVER] -d ETLModelAI -i BALANCE_ALL_DATA.sql
```

### Bước 2: Reprocess Model
1. Mở `ASM_DM_Loan.sln` trong Visual Studio
2. Right-click `Credit_Decision_Tree` → `Process`
3. Chọn `Process Full`
4. Chờ hoàn tất

### Bước 3: Kiểm Tra Kết Quả
```sql
-- Chạy Query 6.2 từ DMX_Queries.sql
-- Kiểm tra Accuracy >= 70%
```

### Bước 4: Deploy
1. Build solution
2. Deploy lên SSAS production
3. Test dự đoán
4. Monitor accuracy
