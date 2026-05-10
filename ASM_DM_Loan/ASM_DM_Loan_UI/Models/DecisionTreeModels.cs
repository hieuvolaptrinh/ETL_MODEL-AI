using System;

namespace ASM_DM_Loan_UI.Models
{
    /// <summary>
    /// Model cho kết quả dự đoán từ Decision Tree
    /// </summary>
    public class DecisionTreePredictionResult
    {
        public int ID { get; set; }
        public double CreditScore { get; set; }
        public double Income { get; set; }
        public double LoanAmount { get; set; }
        public double PropertyValue { get; set; }
        public double LTV { get; set; }
        public double DTI { get; set; }
        public string LoanPurpose { get; set; }
        
        // Kết quả dự đoán
        public double ApprovalProbability { get; set; }
        public double RejectionProbability { get; set; }
        public string PredictionResult { get; set; }
        public string ConfidenceLevel { get; set; }
        public string RiskCategory { get; set; }
    }
}
