# ETL Model AI - Credit Loan Analysis System

Hệ thống phân tích và dự đoán tín dụng sử dụng SQL Server Analysis Services (SSAS) với 3 mô hình Data Mining chuyên biệt.

---

## Các Model AI

### 1. Logistic Regression Model
**File:** `Logistic_Regression_Status.dmm`  
**Model Name:** Credit

**Mục đích:** 
- Dự đoán **rủi ro nợ xấu** (Default Risk) của khách hàng
- Đánh giá xác suất khách hàng vi phạm hợp đồng vay
- Hỗ trợ quyết định phê duyệt/từ chối khoản vay dựa trên risk score

**Thuật toán:** Microsoft Logistic Regression (Neural Network-based)

**Target Variable (PredictOnly):**
- **Status** (Discrete): 
  - `0` = Không nợ xấu (Non-default) - Khách hàng trả nợ đúng hạn
  - `1` = Nợ xấu (Default) - Khách hàng vi phạm hợp đồng

**Input Features (34 biến):**

**Thông tin cá nhân:**
- Age (Ordered) - Nhóm tuổi
- Gender (Discrete) - Giới tính

**Thông tin tín dụng:**
- Credit Score (Continuous) - Điểm tín dụng (300-850)
- Credit Type (Discrete) - Loại tín dụng
- Credit Worthiness (Discrete) - Mức độ tín nhiệm
- Co-applicant Credit Type (Discrete) - Loại tín dụng người đồng vay

**Thông tin tài chính:**
- Income (Continuous) - Thu nhập
- Dtir1 (Continuous) - Debt-to-Income Ratio
- Loan Amount (Discretized) - Số tiền vay (đã rời rạc hóa)
- Property Value (Continuous) - Giá trị tài sản
- LTV (Continuous) - Loan-to-Value Ratio
- Upfront Charges (Continuous) - Chi phí trả trước

**Thông tin khoản vay:**
- Loan Purpose (Discrete) - Mục đích vay
- Loan Type (Discrete) - Loại khoản vay
- Loan Limit (Discrete) - Giới hạn vay
- Term (Continuous) - Kỳ hạn vay
- Rate Of Interest (Continuous) - Lãi suất
- Interest Rate Spread (Continuous) - Chênh lệch lãi suất

**Đặc điểm khoản vay:**
- Approv In Adv (Discrete) - Phê duyệt trước
- Interest Only (Discrete) - Chỉ trả lãi
- Lump Sum Payment (Discrete) - Thanh toán một lần
- Neg Ammortization (Discrete) - Khấu hao âm
- Open Credit (Discrete) - Tín dụng mở

**Thông tin tài sản:**
- Secured By (Discrete) - Được bảo đảm bởi
- Security Type (Discrete) - Loại bảo đảm
- Construction Type (Discrete) - Loại công trình
- Occupancy Type (Discrete) - Loại sử dụng
- Total Units (Discrete) - Tổng số đơn vị

**Thông tin khác:**
- Business Or Commercial (Discrete) - Kinh doanh/Thương mại
- Submission Of Application (Discrete) - Hình thức nộp đơn
- Region (Discrete) - Khu vực
- Year (Discrete) - Năm

**Output:** 
- Xác suất nợ xấu (0-1)
- Phân loại: Default (1) hoặc Non-default (0)

**Ứng dụng:**
- Screening khách hàng trước khi phê duyệt
- Tính toán risk premium cho lãi suất
- Quản lý danh mục nợ (portfolio risk management)
- Early warning system cho nợ xấu

**Đặc điểm:**
- Supervised learning với labeled data
- Holdout: 30% dữ liệu để validation
- Xử lý nhiều biến categorical và continuous

---

### 2. Decision Tree Model
**File:** `Credit_Decision_Tree.dmm`  
**Model Name:** Credit_Decision_Tree

**Mục đích:** 
- Phân loại và dự đoán **giới hạn vay** (Loan Limit) được phê duyệt
- Tạo các quy tắc business logic rõ ràng, dễ giải thích
- Hỗ trợ underwriter đưa ra quyết định nhanh chóng

**Thuật toán:** Microsoft Decision Trees

**Target Variable (PredictOnly):**
- **Loan Limit** (Discrete) - Mức giới hạn vay được phê duyệt

**Input Features (7 biến):**

**Biến Continuous (REGRESSOR):**
- Credit Score - Điểm tín dụng (ảnh hưởng mạnh nhất)
- Income - Thu nhập
- Dtir1 - Debt-to-Income Ratio
- LTV - Loan-to-Value Ratio
- Property Value - Giá trị tài sản

**Biến Discrete:**
- Loan Purpose - Mục đích vay (Home, Refinance, CashOut, Other)

**Output:** 
- Loan Limit category (VD: Low, Medium, High, Very High)
- Decision path (chuỗi quy tắc dẫn đến kết quả)

**Ứng dụng:**
- Tự động tính toán giới hạn vay phù hợp
- Tạo rule-based system cho loan officers
- Giải thích lý do phê duyệt/từ chối cho khách hàng
- Audit trail cho compliance

**Đặc điểm:**
- Cây quyết định với các node if-then rõ ràng
- Dễ visualize và giải thích cho non-technical users
- Holdout: 30% dữ liệu để validation
- Sử dụng REGRESSOR flags cho continuous variables

---

### 3. K-Means Clustering Model
**File:** `Credit_Clustering.dmm`  
**Model Name:** Credit_Clustering

**Mục đích:** 
- **Phân khúc khách hàng** (Customer Segmentation) thành các nhóm đồng nhất
- Tìm kiếm khách hàng tương đồng (Similar Customer Lookup)
- Cá nhân hóa chiến lược marketing và sản phẩm cho từng segment
- Phát hiện pattern và insight về hành vi vay

**Thuật toán:** Microsoft Clustering (K-Means)

**Input Features (9 biến):**

**Thông tin nhân khẩu:**
- Age (Discrete) - Nhóm tuổi (25-34, 35-44, 45-54, 55-64, 65+)
- Gender (Discrete) - Giới tính (Male, Female)

**Thông tin tín dụng & tài chính (Continuous):**
- Credit Score - Điểm tín dụng
- Income - Thu nhập
- Loan Amount - Số tiền vay
- Property Value - Giá trị tài sản

**Tỷ lệ rủi ro (Continuous):**
- Dtir1 - Debt-to-Income Ratio
- LTV - Loan-to-Value Ratio

**Output:** 
- **Cluster ID** (1, 2, 3, 4, ...) - Nhóm khách hàng
- **Cluster Description** - Mô tả đặc điểm nhóm
- **Probability** - Độ tin cậy phân cụm

**Các Cluster điển hình:**
1. **Premium Segment** - Rủi ro thấp, Thu nhập cao, Nhu cầu vay lớn
2. **Standard Segment** - Rủi ro trung bình, Thu nhập ổn định, Vay tiêu dùng
3. **Subprime Segment** - Rủi ro cao, Điểm tín dụng thấp
4. **Emerging Segment** - Trẻ tuổi, Thu nhập đang tăng, Vay mua nhà lần đầu

**Ứng dụng:**
- **Marketing:** Thiết kế campaign cho từng segment
- **Product Development:** Tạo sản phẩm vay phù hợp từng nhóm
- **Cross-selling:** Tìm khách hàng tương đồng để recommend sản phẩm
- **Risk Management:** Phân tích rủi ro theo cluster
- **Customer Insights:** Hiểu hành vi và nhu cầu từng nhóm

**Đặc điểm:**
- Unsupervised learning (không cần label)
- Tự động phát hiện pattern trong dữ liệu
- Holdout: 30% dữ liệu để validation
- Kết hợp cả biến categorical và continuous

---

## So sánh 3 Models

| Tiêu chí | Logistic Regression | Decision Tree | K-Means Clustering |
|----------|---------------------|---------------|-------------------|
| **Loại học** | Supervised | Supervised | Unsupervised |
| **Mục đích** | Dự đoán nợ xấu | Phân loại giới hạn vay | Phân khúc khách hàng |
| **Output** | Status (0/1) | Loan Limit | Cluster ID |
| **Số biến** | 34 features | 7 features | 9 features |
| **Giải thích** | Khó (black box) | Dễ (rule-based) | Trung bình |
| **Use case** | Risk assessment | Loan approval | Marketing & Insights |

---

## Data Source

**Database:** ETLModelAI  
**Table:** `dbo.credit`

**Cấu trúc dữ liệu chính:**
- **ID** (Key) - Mã khách hàng
- **Credit_Score** - Điểm tín dụng (300-850)
- **income** - Thu nhập
- **loan_amount** - Số tiền vay
- **property_value** - Giá trị tài sản
- **LTV** - Loan-to-Value ratio
- **dtir1** - Debt-to-Income ratio
- **loan_purpose** - Mục đích vay
- **loan_limit** - Giới hạn vay
- **Status** - Trạng thái nợ (0/1)
- **age** - Nhóm tuổi
- **Gender** - Giới tính
- *+ 20+ cột khác cho Logistic Regression*

---

## Workflow Sử Dụng

### 1. Khách hàng mới nộp đơn vay
```
Input → Logistic Regression → Risk Score
     ↓
     → Decision Tree → Loan Limit
     ↓
     → K-Means Clustering → Customer Segment
```

### 2. Kết quả tổng hợp
- **Risk Score:** 85% Non-default → **APPROVED**
- **Loan Limit:** $250,000 (High)
- **Segment:** Premium (Cluster 1)
- **Action:** Phê duyệt với lãi suất ưu đãi

---

## Troubleshooting

### Lỗi Permission khi Process Model

Nếu gặp lỗi quyền truy cập, chạy các lệnh sau:

```sql
USE master;
GO
CREATE LOGIN [NT Service\MSSQLServerOLAPService] FROM WINDOWS;
GO
USE ETLModelAI;
GO
CREATE USER [NT Service\MSSQLServerOLAPService] FOR LOGIN [NT Service\MSSQLServerOLAPService];
GO
ALTER ROLE db_datareader ADD MEMBER [NT Service\MSSQLServerOLAPService];
GO
```

### Nếu user đã tồn tại

```sql
ALTER ROLE db_owner ADD MEMBER [NT Service\MSSQLServerOLAPService];
```

---

## Tech Stack

- **SSAS (SQL Server Analysis Services)** - Data Mining Engine
- **ASP.NET MVC** - Web Application Backend
- **ECharts** - Interactive Data Visualization
- **Alpine.js** - Reactive Frontend Framework
- **Tailwind CSS** - Modern UI Styling
- **DMX (Data Mining Extensions)** - Query Language for Models
