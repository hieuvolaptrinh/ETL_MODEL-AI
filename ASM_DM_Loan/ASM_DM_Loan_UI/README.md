# ASM DM Loan - Credit Loan Analysis System

## 📋 Tổng quan dự án
Hệ thống phân tích và dự đoán khoản vay sử dụng 2 mô hình Machine Learning:
1. **Decision Tree** - Cây quyết định
2. **Clustering** - Phân nhóm khách hàng

## 🏗️ Kiến trúc dự án

### Backend: ASP.NET Web API
```
ASM_DM_Loan_UI/
├── Controllers/          # API Controllers - Mỗi model có controller riêng
│   ├── DecisionTreeController.cs
│   ├── ClusteringController.cs
│   ├── DashboardController.cs
│   └── ApiController.cs (legacy)
│
├── Services/            # Business Logic - Mỗi model có service riêng
│   ├── DecisionTreeService.cs
│   ├── ClusteringService.cs
│   ├── DashboardService.cs
│   └── DMXConnectionService.cs (shared)
│
├── Models/              # Data Models - Mỗi model có models riêng
│   ├── DecisionTreeModels.cs
│   ├── ClusteringModels.cs
│   └── CommonModels.cs (shared DTOs)
│
├── Pages/               # HTML Pages
│   ├── prediction.html      (Decision Tree)
│   └── clustering.html      (Clustering)
│
├── Scripts/app/         # JavaScript Modules
│   ├── prediction.js
│   ├── clustering.js
│   └── dashboard.js
│
└── index.html          # Dashboard (Home)
```

### Frontend: HTML + Tailwind CSS + Alpine.js
- **Tailwind CSS**: Styling framework
- **Alpine.js**: Lightweight JavaScript framework
- **Chart.js**: Data visualization
- **Font Awesome**: Icons

## 🎯 API Endpoints

### 1. Decision Tree API
- `POST /api/decision-tree/predict` - Dự đoán khoản vay

### 2. Logistic Regression API
- `POST /api/logistic/predict` - Dự đoán khoản vay

### 3. Clustering API
- `POST /api/clustering/predict` - Dự đoán cluster khách hàng
- `GET /api/clustering/profiles` - Lấy thông tin tất cả clusters
- `POST /api/clustering/similar-customers` - Tìm khách hàng tương tự

### 4. Dashboard API
- `GET /api/dashboard` - Lấy dữ liệu dashboard tổng hợp

## 🔧 Công nghệ sử dụng

### Backend
- **ASP.NET Web API** (.NET Framework 4.7.2)
- **SSAS (SQL Server Analysis Services)** - Data Mining Models
- **DMX (Data Mining Extensions)** - Query language
- **OleDb** - SSAS connection

### Frontend
- **HTML5**
- **Tailwind CSS** (CDN)
- **Alpine.js** (CDN)
- **Chart.js** (CDN)
- **Font Awesome** (CDN)

## 📊 3 Mô hình Machine Learning

### 1. Decision Tree (Cây quyết định)
- **Model**: `Decision_Tree_Status`
- **Mục đích**: Dự đoán trạng thái chấp thuận/từ chối khoản vay
- **Output**: Xác suất chấp thuận, kết quả dự đoán, mức độ tin cậy, mức độ rủi ro

### 2. Logistic Regression (Hồi quy Logistic)
- **Model**: `Credit`
- **Mục đích**: Dự đoán xác suất chấp thuận khoản vay
- **Output**: Xác suất chấp thuận/từ chối, kết quả dự đoán, mức độ tin cậy

### 3. Clustering (Phân nhóm)
- **Model**: `Credit_Clustering`
- **Mục đích**: Phân nhóm khách hàng theo đặc điểm tín dụng
- **Output**: Cluster ID, xác suất thuộc cluster, thông tin cluster, khuyến nghị

## 🚀 Cách chạy dự án

### Yêu cầu
1. Visual Studio 2019+
2. SQL Server 2019+ với Analysis Services
3. .NET Framework 4.7.2+

### Các bước
1. Mở solution `ASM_DM_Loan.sln` trong Visual Studio
2. Restore NuGet packages
3. Cập nhật connection string trong `Web.config`:
   ```xml
   <connectionStrings>
     <add name="SSASConnection" 
          connectionString="Provider=MSOLAP;Data Source=localhost;Initial Catalog=ASM_DM_Loan;" />
   </connectionStrings>
   ```
4. Build solution
5. Run project (F5)
6. Truy cập `https://localhost:44329/`

## 📝 Input Parameters

Tất cả 3 models đều sử dụng cùng input parameters:
- **Gender**: Male/Female
- **AgeGroup**: 25-34, 35-44, 45-54, 55-64, 65+
- **CreditScore**: 300-900
- **Income**: Thu nhập hàng tháng ($)
- **LoanAmount**: Số tiền vay ($)
- **PropertyValue**: Giá trị tài sản ($)
- **LTV**: Loan-to-Value ratio (%)
- **DTI**: Debt-to-Income ratio (%)

## 🎨 Tính năng

### Dashboard
- Tổng quan thống kê
- Biểu đồ phân tích theo nhóm tuổi
- Phân bố clusters
- Danh sách dự đoán gần đây

### Decision Tree Page
- Form nhập liệu
- Dự đoán khoản vay
- Hiển thị xác suất, kết quả, mức độ rủi ro

### Logistic Regression Page
- Form nhập liệu
- Dự đoán xác suất chấp thuận/từ chối
- Khuyến nghị cải thiện
- Biểu đồ xác suất

### Clustering Page
- Form nhập liệu
- Dự đoán cluster khách hàng
- Thông tin cluster
- Khách hàng tương tự
- Tất cả cluster profiles

## 👥 Nhóm phát triển
- Dự án môn học: Data Mining
- Công cụ: SSAS, DMX, ASP.NET Web API
- Năm: 2026
