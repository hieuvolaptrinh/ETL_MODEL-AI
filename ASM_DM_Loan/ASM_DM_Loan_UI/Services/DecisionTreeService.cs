using System;
using System.Data;
using ASM_DM_Loan_UI.Models;

namespace ASM_DM_Loan_UI.Services
{
    /// <summary>
    /// Service cho Decision Tree Model
    /// </summary>
    public class DecisionTreeService
    {
        private readonly DMXConnectionService _dmxService;

        public DecisionTreeService()
        {
            _dmxService = new DMXConnectionService();
        }

        /// <summary>
        /// Dự đoán khoản vay bằng Decision Tree
        /// </summary>
        public DecisionTreePredictionResult PredictLoanApproval(LoanApplicationInput input)
        {
            string dmxQuery = $@"
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
                        {input.CreditScore} AS [Credit Score],
                        {input.Income} AS [Income],
                        {input.LTV} AS [LTV],
                        {input.DTI} AS [Dtir1],
                        {input.PropertyValue} AS [Property Value],
                        '{input.LoanPurpose}' AS [Loan Purpose]
                    ) AS t";

            try
            {
                DataTable dt = _dmxService.ExecuteDMXQuery(dmxQuery);
                
                if (dt.Rows.Count > 0)
                {
                    DataRow row = dt.Rows[0];
                    return new DecisionTreePredictionResult
                    {
                        CreditScore = input.CreditScore,
                        Income = input.Income,
                        LoanAmount = input.LoanAmount,
                        PropertyValue = input.PropertyValue,
                        LTV = input.LTV,
                        DTI = input.DTI,
                        LoanPurpose = input.LoanPurpose,
                        ApprovalProbability = Convert.ToDouble(row["Probability_High"]),
                        RejectionProbability = Convert.ToDouble(row["Probability_Low"]),
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
        private DecisionTreePredictionResult PredictLoanApprovalRuleBased(LoanApplicationInput input)
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
            
            return new DecisionTreePredictionResult
            {
                CreditScore = input.CreditScore,
                Income = input.Income,
                LoanAmount = input.LoanAmount,
                PropertyValue = input.PropertyValue,
                LTV = input.LTV,
                DTI = input.DTI,
                LoanPurpose = input.LoanPurpose,
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
