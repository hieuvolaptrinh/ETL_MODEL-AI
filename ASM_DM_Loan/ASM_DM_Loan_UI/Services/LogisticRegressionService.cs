using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using ASM_DM_Loan_UI.Models;

namespace ASM_DM_Loan_UI.Services
{
    /// <summary>
    /// Service cho Logistic Regression Model
    /// </summary>
    public class LogisticRegressionService
    {
        private readonly DMXConnectionService _dmxService;

        public LogisticRegressionService()
        {
            _dmxService = new DMXConnectionService();
        }

        /// <summary>
        /// Dự đoán rủi ro nợ xấu bằng SSAS DMX.
        /// Fallback sang rule-based nếu DMX thất bại.
        /// </summary>
        public LogisticRegressionPredictionResult PredictBadDebtRisk(LoanApplicationInput input)
        {
            if (input == null)
            {
                return null;
            }

            try
            {
                var dmxQuery = BuildPredictionQuery(input);
                DataTable dt = _dmxService.ExecuteDMXQuery(dmxQuery);

                if (dt.Rows.Count > 0)
                {
                    DataRow row = dt.Rows[0];

                    double badProb = ReadDouble(row, "BadDebtProbability", 0.0);
                    double goodProb = ReadDouble(row, "GoodDebtProbability", 1.0 - badProb);

                    if (badProb <= 0 && goodProb > 0)
                    {
                        badProb = 1.0 - goodProb;
                    }

                    var result = new LogisticRegressionPredictionResult
                    {
                        CreditScore = input.CreditScore,
                        Income = input.Income,
                        LoanAmount = input.LoanAmount,
                        PropertyValue = input.PropertyValue,
                        LTV = input.LTV,
                        DTI = input.DTI,
                        BadDebtProbability = Clamp01(badProb),
                        GoodDebtProbability = Clamp01(goodProb),
                        PredictionResult = NormalizePrediction(ReadString(row, "PredictionResult", null), badProb),
                        RiskLevel = NormalizeRiskLevel(ReadString(row, "RiskLevel", null), badProb),
                        ConfidenceLevel = NormalizeConfidence(ReadString(row, "ConfidenceLevel", null), badProb),
                        Recommendation = GetRecommendation(input, badProb)
                    };

                    // Thêm feature importance để giải thích kết quả
                    result.FeatureImportance = GetFeatureImportance(input, badProb);

                    return result;
                }
            }
            catch
            {
                // Fallback rule-based nếu SSAS/DMX không chạy được
            }

            return PredictBadDebtRiskRuleBased(input);
        }

        /// <summary>
        /// Tổng quan model để hiển thị trên UI
        /// </summary>
        public LogisticRegressionModelSummary GetModelSummary()
        {
            return new LogisticRegressionModelSummary
            {
                ModelName = "Logistic Regression Status",
                Description = "Dự đoán xác suất nợ xấu dựa trên hồ sơ tín dụng, khoản vay, tài sản và mức rủi ro tổng hợp.",
                Target = "Status = 1 (Bad Debt Risk)",
                Purpose = "Risk Scoring",
                Strengths = new[]
                {
                    "Phù hợp bài toán phân loại nhị phân",
                    "Trả về xác suất rõ ràng",
                    "Dễ giải thích và hiển thị trên dashboard"
                },
                KeyInputs = new[]
                {
                    "Age",
                    "Credit Score",
                    "Credit Type",
                    "DTI (Dtir1)",
                    "Income",
                    "Loan Amount",
                    "Loan Purpose",
                    "Loan Type",
                    "LTV",
                    "Property Value",
                    "Rate Of Interest",
                    "Term"
                }
            };
        }

        private static string BuildPredictionQuery(LoanApplicationInput input)
        {
            // Model SSAS: Logistic_Regression_Status
            // Sử dụng đầy đủ các trường trong model
            string age = FormatNumber(input.Age ?? 35); // Default age nếu null
            string creditScore = FormatNumber(input.CreditScore);
            string income = FormatNumber(input.Income);
            string loanAmount = FormatNumber(input.LoanAmount);
            string propertyValue = FormatNumber(input.PropertyValue);
            string ltv = FormatNumber(input.LTV);
            string dti = FormatNumber(input.DTI);
            string loanPurpose = EscapeSql(input.LoanPurpose ?? "Home");
            string creditType = EscapeSql(input.CreditType ?? "Standard");
            string loanType = EscapeSql(input.LoanType ?? "Conventional");
            string rateOfInterest = FormatNumber(input.RateOfInterest ?? 5.0);
            string term = FormatNumber(input.Term ?? 360);

            return $@"
SELECT
    PredictProbability([Status], 1) AS [BadDebtProbability],
    PredictProbability([Status], 0) AS [GoodDebtProbability],
    CASE
        WHEN Predict([Status]) = 1 THEN 'BAD_DEBT'
        ELSE 'GOOD_DEBT'
    END AS [PredictionResult],
    CASE
        WHEN PredictProbability([Status], 1) >= 0.80 THEN 'VERY HIGH'
        WHEN PredictProbability([Status], 1) >= 0.60 THEN 'HIGH'
        WHEN PredictProbability([Status], 1) >= 0.40 THEN 'MEDIUM'
        WHEN PredictProbability([Status], 1) >= 0.20 THEN 'LOW'
        ELSE 'VERY LOW'
    END AS [RiskLevel],
    CASE
        WHEN PredictProbability([Status], 1) >= 0.80 OR PredictProbability([Status], 1) <= 0.20 THEN 'High'
        WHEN PredictProbability([Status], 1) >= 0.65 OR PredictProbability([Status], 1) <= 0.35 THEN 'Medium'
        ELSE 'Low'
    END AS [ConfidenceLevel]
FROM [Logistic_Regression_Status]
NATURAL PREDICTION JOIN
(SELECT
    {age} AS [Age],
    {creditScore} AS [Credit Score],
    '{creditType}' AS [Credit Type],
    {dti} AS [Dtir1],
    {income} AS [Income],
    {loanAmount} AS [Loan Amount],
    '{loanPurpose}' AS [Loan Purpose],
    '{loanType}' AS [Loan Type],
    {ltv} AS [LTV],
    {propertyValue} AS [Property Value],
    {rateOfInterest} AS [Rate Of Interest],
    {term} AS [Term]
) AS t";
        }

        private static LogisticRegressionPredictionResult PredictBadDebtRiskRuleBased(LoanApplicationInput input)
        {
            double score = 0.0;

            if (input.CreditScore < 580) score += 35;
            else if (input.CreditScore < 670) score += 20;
            else if (input.CreditScore < 740) score += 10;

            if (input.LTV > 90) score += 30;
            else if (input.LTV > 80) score += 18;
            else if (input.LTV > 70) score += 10;

            if (input.DTI > 45) score += 25;
            else if (input.DTI > 35) score += 15;
            else if (input.DTI > 30) score += 8;

            if (input.Income < 3000) score += 20;
            else if (input.Income < 7000) score += 10;

            if (input.LoanAmount > input.PropertyValue) score += 10;
            if (input.PropertyValue > 0 && input.LoanAmount / input.PropertyValue > 0.85) score += 10;

            double badDebtProbability = Clamp01(score / 100.0);
            double goodDebtProbability = Clamp01(1.0 - badDebtProbability);

            var result = new LogisticRegressionPredictionResult
            {
                CreditScore = input.CreditScore,
                Income = input.Income,
                LoanAmount = input.LoanAmount,
                PropertyValue = input.PropertyValue,
                LTV = input.LTV,
                DTI = input.DTI,
                BadDebtProbability = badDebtProbability,
                GoodDebtProbability = goodDebtProbability,
                PredictionResult = badDebtProbability >= 0.5 ? "BAD_DEBT" : "GOOD_DEBT",
                RiskLevel = GetRiskLevel(badDebtProbability),
                ConfidenceLevel = GetConfidenceLevel(badDebtProbability),
                Recommendation = GetRecommendation(input, badDebtProbability)
            };

            // Thêm feature importance cho rule-based fallback
            result.FeatureImportance = GetFeatureImportance(input, badDebtProbability);

            return result;
        }

        private static string GetRiskLevel(double badDebtProbability)
        {
            if (badDebtProbability >= 0.8) return "VERY HIGH";
            if (badDebtProbability >= 0.6) return "HIGH";
            if (badDebtProbability >= 0.4) return "MEDIUM";
            if (badDebtProbability >= 0.2) return "LOW";
            return "VERY LOW";
        }

        private static string GetConfidenceLevel(double badDebtProbability)
        {
            if (badDebtProbability >= 0.8 || badDebtProbability <= 0.2) return "High";
            if (badDebtProbability >= 0.65 || badDebtProbability <= 0.35) return "Medium";
            return "Low";
        }

        private static string GetRecommendation(LoanApplicationInput input, double badDebtProbability)
        {
            if (badDebtProbability >= 0.8)
            {
                return "Từ chối hoặc yêu cầu bổ sung tài sản đảm bảo, giảm khoản vay, hoặc thêm người đồng vay.";
            }

            if (badDebtProbability >= 0.6)
            {
                return "Rủi ro cao. Nên xem xét giảm hạn mức, tăng lãi suất hoặc yêu cầu hồ sơ bổ sung.";
            }

            if (badDebtProbability >= 0.4)
            {
                return "Có thể phê duyệt có điều kiện. Nên kiểm tra thêm thu nhập, lịch sử vay và khả năng trả nợ.";
            }

            return "Hồ sơ an toàn hơn. Có thể phê duyệt theo điều kiện chuẩn.";
        }

        private static double ReadDouble(DataRow row, string column, double fallback)
        {
            if (row == null || !row.Table.Columns.Contains(column) || row[column] == DBNull.Value)
            {
                return fallback;
            }

            if (double.TryParse(Convert.ToString(row[column], CultureInfo.InvariantCulture), NumberStyles.Any, CultureInfo.InvariantCulture, out double value))
            {
                return value;
            }

            if (double.TryParse(Convert.ToString(row[column]), out value))
            {
                return value;
            }

            return fallback;
        }

        private static string ReadString(DataRow row, string column, string fallback)
        {
            if (row == null || !row.Table.Columns.Contains(column) || row[column] == DBNull.Value)
            {
                return fallback;
            }

            var value = Convert.ToString(row[column]);
            return string.IsNullOrWhiteSpace(value) ? fallback : value;
        }

        private static double Clamp01(double value)
        {
            if (value < 0) return 0;
            if (value > 1) return 1;
            return value;
        }

        private static string NormalizePrediction(string prediction, double badProb)
        {
            if (!string.IsNullOrWhiteSpace(prediction))
            {
                prediction = prediction.Trim().ToUpperInvariant();
                if (prediction.Contains("BAD") || prediction.Contains("REJECT")) return "BAD_DEBT";
                if (prediction.Contains("GOOD") || prediction.Contains("APPROV")) return "GOOD_DEBT";
            }

            return badProb >= 0.5 ? "BAD_DEBT" : "GOOD_DEBT";
        }

        private static string NormalizeRiskLevel(string riskLevel, double badProb)
        {
            if (!string.IsNullOrWhiteSpace(riskLevel))
            {
                riskLevel = riskLevel.Trim().ToUpperInvariant();
                return riskLevel;
            }

            return GetRiskLevel(badProb);
        }

        private static string NormalizeConfidence(string confidence, double badProb)
        {
            if (!string.IsNullOrWhiteSpace(confidence))
            {
                confidence = confidence.Trim();
                if (confidence.Equals("HIGH", StringComparison.OrdinalIgnoreCase)) return "High";
                if (confidence.Equals("MEDIUM", StringComparison.OrdinalIgnoreCase)) return "Medium";
                if (confidence.Equals("LOW", StringComparison.OrdinalIgnoreCase)) return "Low";
                return confidence;
            }

            return GetConfidenceLevel(badProb);
        }

        private static string FormatNumber(double value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }

        private static string EscapeSql(string value)
        {
            return (value ?? string.Empty).Replace("'", "''");
        }

        /// <summary>
        /// Phân tích feature importance để giải thích kết quả
        /// </summary>
        private static List<FeatureImpact> GetFeatureImportance(LoanApplicationInput input, double badDebtProbability)
        {
            var features = new List<FeatureImpact>();

            // Credit Score Impact
            double creditScoreImpact = 0;
            string creditScoreStatus = "Good";
            string creditScoreDesc = "";
            
            if (input.CreditScore < 580)
            {
                creditScoreImpact = 35;
                creditScoreStatus = "Bad";
                creditScoreDesc = "Điểm tín dụng rất thấp, tăng rủi ro nợ xấu đáng kể";
            }
            else if (input.CreditScore < 670)
            {
                creditScoreImpact = 20;
                creditScoreStatus = "Warning";
                creditScoreDesc = "Điểm tín dụng dưới mức tốt, cần cải thiện";
            }
            else if (input.CreditScore < 740)
            {
                creditScoreImpact = 10;
                creditScoreStatus = "Warning";
                creditScoreDesc = "Điểm tín dụng ở mức trung bình";
            }
            else
            {
                creditScoreImpact = 5;
                creditScoreStatus = "Good";
                creditScoreDesc = "Điểm tín dụng tốt, giảm rủi ro";
            }

            features.Add(new FeatureImpact
            {
                FeatureName = "Credit Score",
                FeatureNameVi = "Điểm tín dụng",
                Value = input.CreditScore,
                ImpactScore = creditScoreImpact,
                ImpactLevel = creditScoreImpact >= 30 ? "High" : (creditScoreImpact >= 15 ? "Medium" : "Low"),
                Description = creditScoreDesc,
                Status = creditScoreStatus
            });

            // LTV Impact
            double ltvImpact = 0;
            string ltvStatus = "Good";
            string ltvDesc = "";
            
            if (input.LTV > 90)
            {
                ltvImpact = 30;
                ltvStatus = "Bad";
                ltvDesc = "Tỷ lệ cho vay quá cao so với tài sản, rủi ro rất lớn";
            }
            else if (input.LTV > 80)
            {
                ltvImpact = 18;
                ltvStatus = "Warning";
                ltvDesc = "Tỷ lệ cho vay cao, cần thận trọng";
            }
            else if (input.LTV > 70)
            {
                ltvImpact = 10;
                ltvStatus = "Warning";
                ltvDesc = "Tỷ lệ cho vay ở mức trung bình";
            }
            else
            {
                ltvImpact = 5;
                ltvStatus = "Good";
                ltvDesc = "Tỷ lệ cho vay an toàn";
            }

            features.Add(new FeatureImpact
            {
                FeatureName = "LTV",
                FeatureNameVi = "Tỷ lệ cho vay/Tài sản",
                Value = input.LTV,
                ImpactScore = ltvImpact,
                ImpactLevel = ltvImpact >= 25 ? "High" : (ltvImpact >= 15 ? "Medium" : "Low"),
                Description = ltvDesc,
                Status = ltvStatus
            });

            // DTI Impact
            double dtiImpact = 0;
            string dtiStatus = "Good";
            string dtiDesc = "";
            
            if (input.DTI > 45)
            {
                dtiImpact = 25;
                dtiStatus = "Bad";
                dtiDesc = "Tỷ lệ nợ/thu nhập quá cao, khả năng trả nợ kém";
            }
            else if (input.DTI > 35)
            {
                dtiImpact = 15;
                dtiStatus = "Warning";
                dtiDesc = "Tỷ lệ nợ/thu nhập cao, cần xem xét";
            }
            else if (input.DTI > 30)
            {
                dtiImpact = 8;
                dtiStatus = "Warning";
                dtiDesc = "Tỷ lệ nợ/thu nhập ở mức chấp nhận được";
            }
            else
            {
                dtiImpact = 3;
                dtiStatus = "Good";
                dtiDesc = "Tỷ lệ nợ/thu nhập tốt";
            }

            features.Add(new FeatureImpact
            {
                FeatureName = "DTI",
                FeatureNameVi = "Tỷ lệ nợ/Thu nhập",
                Value = input.DTI,
                ImpactScore = dtiImpact,
                ImpactLevel = dtiImpact >= 20 ? "High" : (dtiImpact >= 10 ? "Medium" : "Low"),
                Description = dtiDesc,
                Status = dtiStatus
            });

            // Income Impact
            double incomeImpact = 0;
            string incomeStatus = "Good";
            string incomeDesc = "";
            
            if (input.Income < 3000)
            {
                incomeImpact = 20;
                incomeStatus = "Bad";
                incomeDesc = "Thu nhập thấp, khả năng trả nợ hạn chế";
            }
            else if (input.Income < 7000)
            {
                incomeImpact = 10;
                incomeStatus = "Warning";
                incomeDesc = "Thu nhập trung bình";
            }
            else
            {
                incomeImpact = 5;
                incomeStatus = "Good";
                incomeDesc = "Thu nhập tốt, khả năng trả nợ cao";
            }

            features.Add(new FeatureImpact
            {
                FeatureName = "Income",
                FeatureNameVi = "Thu nhập",
                Value = input.Income,
                ImpactScore = incomeImpact,
                ImpactLevel = incomeImpact >= 15 ? "High" : (incomeImpact >= 8 ? "Medium" : "Low"),
                Description = incomeDesc,
                Status = incomeStatus
            });

            // Loan/Property Ratio Impact
            double loanPropertyRatio = input.PropertyValue > 0 ? (input.LoanAmount / input.PropertyValue) : 0;
            if (loanPropertyRatio > 0.85)
            {
                features.Add(new FeatureImpact
                {
                    FeatureName = "Loan/Property Ratio",
                    FeatureNameVi = "Tỷ lệ vay/Tài sản",
                    Value = loanPropertyRatio * 100,
                    ImpactScore = 10,
                    ImpactLevel = "Medium",
                    Description = "Khoản vay gần bằng giá trị tài sản",
                    Status = "Warning"
                });
            }

            // Sắp xếp theo impact score giảm dần
            features.Sort((a, b) => b.ImpactScore.CompareTo(a.ImpactScore));

            return features;
        }
    }
}
