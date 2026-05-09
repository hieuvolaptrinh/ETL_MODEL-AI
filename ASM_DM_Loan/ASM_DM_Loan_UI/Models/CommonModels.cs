using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ASM_DM_Loan_UI.Models
{
    /// <summary>
    /// Model cho input form dự đoán - Dùng chung cho cả 3 models
    /// </summary>
    public class LoanApplicationInput
    {
        [Required(ErrorMessage = "Vui lòng chọn giới tính")]
        [Display(Name = "Giới tính")]
        public string Gender { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn nhóm tuổi")]
        [Display(Name = "Nhóm tuổi")]
        public string AgeGroup { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập Credit Score")]
        [Range(300, 900, ErrorMessage = "Credit Score phải từ 300 đến 900")]
        [Display(Name = "Credit Score")]
        public double CreditScore { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập thu nhập")]
        [Range(0, double.MaxValue, ErrorMessage = "Thu nhập phải lớn hơn 0")]
        [Display(Name = "Thu nhập hàng tháng ($)")]
        public double Income { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập số tiền vay")]
        [Range(0, double.MaxValue, ErrorMessage = "Số tiền vay phải lớn hơn 0")]
        [Display(Name = "Số tiền vay ($)")]
        public double LoanAmount { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập giá trị tài sản")]
        [Range(0, double.MaxValue, ErrorMessage = "Giá trị tài sản phải lớn hơn 0")]
        [Display(Name = "Giá trị tài sản ($)")]
        public double PropertyValue { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập LTV")]
        [Display(Name = "LTV (%)")]
        public double LTV { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập DTI")]
        [Display(Name = "Debt-to-Income Ratio (%)")]
        public double DTI { get; set; }
    }

    /// <summary>
    /// Model cho Dashboard
    /// </summary>
    public class DashboardViewModel
    {
        public int TotalApplications { get; set; }
        public int ApprovedCount { get; set; }
        public int RejectedCount { get; set; }
        public double ApprovalRate { get; set; }
        public double AvgCreditScore { get; set; }
        public double AvgLoanAmount { get; set; }
        public int HighRiskCount { get; set; }
        
        public List<object> ClusterProfiles { get; set; }
        public List<DemographicAnalysis> AgeGroupAnalysis { get; set; }
        public List<object> RecentPredictions { get; set; }
    }

    /// <summary>
    /// Model cho phân tích theo nhóm
    /// </summary>
    public class DemographicAnalysis
    {
        public string Category { get; set; }
        public int TotalApplications { get; set; }
        public int Approved { get; set; }
        public int Rejected { get; set; }
        public double ApprovalRate { get; set; }
        public double AvgCreditScore { get; set; }
        public double AvgLoanAmount { get; set; }
    }
}
