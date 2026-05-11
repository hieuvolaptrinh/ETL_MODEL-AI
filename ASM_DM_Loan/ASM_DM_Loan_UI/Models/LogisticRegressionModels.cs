using System.Collections.Generic;

namespace ASM_DM_Loan_UI.Models
{
    /// <summary>
    /// Kết quả dự đoán Logistic Regression cho nợ xấu
    /// </summary>
    public class LogisticRegressionPredictionResult
    {
        public double CreditScore { get; set; }
        public double Income { get; set; }
        public double LoanAmount { get; set; }
        public double PropertyValue { get; set; }
        public double LTV { get; set; }
        public double DTI { get; set; }

        public double BadDebtProbability { get; set; }
        public double GoodDebtProbability { get; set; }
        public string PredictionResult { get; set; }
        public string RiskLevel { get; set; }
        public string ConfidenceLevel { get; set; }
        public string Recommendation { get; set; }
        
        // Feature Importance - Giải thích kết quả
        public List<FeatureImpact> FeatureImportance { get; set; }
    }

    /// <summary>
    /// Tác động của từng feature đến kết quả
    /// </summary>
    public class FeatureImpact
    {
        public string FeatureName { get; set; }
        public string FeatureNameVi { get; set; }
        public double Value { get; set; }
        public double ImpactScore { get; set; } // 0-100
        public string ImpactLevel { get; set; } // High, Medium, Low
        public string Description { get; set; }
        public string Status { get; set; } // Good, Warning, Bad
    }

    /// <summary>
    /// Tổng quan model Logistic Regression
    /// </summary>
    public class LogisticRegressionModelSummary
    {
        public string ModelName { get; set; }
        public string Description { get; set; }
        public string Target { get; set; }
        public string Purpose { get; set; }
        public string[] Strengths { get; set; }
        public string[] KeyInputs { get; set; }
    }
}
