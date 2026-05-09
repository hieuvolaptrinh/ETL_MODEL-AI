using System;
using System.Data;
using ASM_DM_Loan_UI.Models;

namespace ASM_DM_Loan_UI.Services
{
    /// <summary>
    /// Service cho Logistic Regression Model (Credit model)
    /// </summary>
    public class LogisticRegressionService
    {
        private readonly DMXConnectionService _dmxService;

        public LogisticRegressionService()
        {
            _dmxService = new DMXConnectionService();
        }

        /// <summary>
        /// Dự đoán khoản vay bằng Logistic Regression (model Credit)
        /// </summary>
        public LogisticRegressionPredictionResult PredictLoanApproval(LoanApplicationInput input)
        {
            string dmxQuery = $@"
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
                        '{input.Gender}' AS [Gender],
                        '{input.AgeGroup}' AS [Age],
                        {input.CreditScore} AS [Credit Score],
                        {input.Income} AS [Income],
                        {input.LoanAmount} AS [Loan Amount],
                        {input.LTV} AS [LTV],
                        {input.DTI} AS [Dtir1]
                    ) AS t";

            try
            {
                DataTable dt = _dmxService.ExecuteDMXQuery(dmxQuery);
                
                if (dt.Rows.Count > 0)
                {
                    DataRow row = dt.Rows[0];
                    return new LogisticRegressionPredictionResult
                    {
                        Gender = input.Gender,
                        AgeGroup = input.AgeGroup,
                        CreditScore = input.CreditScore,
                        Income = input.Income,
                        LoanAmount = input.LoanAmount,
                        LTV = input.LTV,
                        DTI = input.DTI,
                        ApprovalProbability = Convert.ToDouble(row["Probability_Approved"]),
                        RejectionProbability = Convert.ToDouble(row["Probability_Rejected"]),
                        PredictionResult = row["Prediction_Result"].ToString(),
                        ConfidenceLevel = row["Confidence_Level"].ToString(),
                        RiskCategory = row["Risk_Category"].ToString()
                    };
                }
            }
            catch (Exception ex)
            {
                // Fallback to rule-based prediction if DMX fails
                return PredictLoanApprovalRuleBased(input);
            }

            return null;
        }

        /// <summary>
        /// Dự đoán dựa trên rules (fallback khi DMX không hoạt động)
        /// </summary>
        private LogisticRegressionPredictionResult PredictLoanApprovalRuleBased(LoanApplicationInput input)
        {
            // Calculate approval probability based on rules
            double approvalProb = 0.5;
            
            // Credit Score impact (40%)
            if (input.CreditScore >= 750)
                approvalProb += 0.20;
            else if (input.CreditScore >= 650)
                approvalProb += 0.10;
            else if (input.CreditScore < 600)
                approvalProb -= 0.15;
            
            // LTV impact (30%)
            if (input.LTV <= 80)
                approvalProb += 0.15;
            else if (input.LTV <= 90)
                approvalProb += 0.05;
            else
                approvalProb -= 0.10;
            
            // DTI impact (30%)
            if (input.DTI <= 35)
                approvalProb += 0.15;
            else if (input.DTI <= 43)
                approvalProb += 0.05;
            else
                approvalProb -= 0.10;
            
            // Ensure probability is between 0 and 1
            approvalProb = Math.Max(0.05, Math.Min(0.95, approvalProb));
            double rejectionProb = 1 - approvalProb;
            
            return new LogisticRegressionPredictionResult
            {
                Gender = input.Gender,
                AgeGroup = input.AgeGroup,
                CreditScore = input.CreditScore,
                Income = input.Income,
                LoanAmount = input.LoanAmount,
                LTV = input.LTV,
                DTI = input.DTI,
                ApprovalProbability = approvalProb,
                RejectionProbability = rejectionProb,
                PredictionResult = approvalProb > 0.5 ? "APPROVED" : "REJECTED",
                ConfidenceLevel = approvalProb >= 0.7 || rejectionProb >= 0.7 ? "HIGH CONFIDENCE" : 
                                 approvalProb >= 0.5 || rejectionProb >= 0.5 ? "MODERATE CONFIDENCE" : "LOW CONFIDENCE",
                RiskCategory = rejectionProb >= 0.7 ? "HIGH RISK" : 
                              rejectionProb >= 0.4 ? "MEDIUM RISK" : "LOW RISK"
            };
        }
    }
}
