using System;

namespace ASM_DM_Loan_UI.Models
{
    /// <summary>
    /// Model cho kết quả dự đoán từ Logistic Regression
    /// </summary>
    public class LogisticRegressionPredictionResult
    {
        public int ID { get; set; }
        public string Gender { get; set; }
        public string AgeGroup { get; set; }
        public double CreditScore { get; set; }
        public double Income { get; set; }
        public double LoanAmount { get; set; }
        public double LTV { get; set; }
        public double DTI { get; set; }
        
        // Kết quả dự đoán
        public double ApprovalProbability { get; set; }
        public double RejectionProbability { get; set; }
        public string PredictionResult { get; set; }
        public string ConfidenceLevel { get; set; }
        public string RiskCategory { get; set; }
    }
}
