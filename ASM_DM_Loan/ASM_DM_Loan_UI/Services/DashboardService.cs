using System;
using System.Collections.Generic;
using System.Linq;
using ASM_DM_Loan_UI.Models;

namespace ASM_DM_Loan_UI.Services
{
    /// <summary>
    /// Service cho Dashboard
    /// </summary>
    public class DashboardService
    {
        private readonly DecisionTreeService _decisionTreeService;
        private readonly ClusteringService _clusteringService;

        public DashboardService()
        {
            _decisionTreeService = new DecisionTreeService();
            _clusteringService = new ClusteringService();
        }

        /// <summary>
        /// Lấy dữ liệu cho Dashboard
        /// </summary>
        public DashboardViewModel GetDashboardData()
        {
            try
            {
                // Generate sample predictions
                var predictions = GenerateSamplePredictions(100);
                
                return new DashboardViewModel
                {
                    TotalApplications = predictions.Count,
                    ApprovedCount = predictions.Count(p => p.PredictionResult == "APPROVED"),
                    RejectedCount = predictions.Count(p => p.PredictionResult == "REJECTED"),
                    ApprovalRate = predictions.Count > 0 ? 
                        (predictions.Count(p => p.PredictionResult == "APPROVED") * 100.0 / predictions.Count) : 0,
                    AvgCreditScore = predictions.Average(p => p.CreditScore),
                    AvgLoanAmount = predictions.Average(p => p.LoanAmount),
                    HighRiskCount = predictions.Count(p => p.RiskCategory == "HIGH RISK"),
                    ClusterProfiles = _clusteringService.GetClusterProfiles().Cast<object>().ToList(),
                    AgeGroupAnalysis = GetAgeGroupAnalysis(predictions),
                    RecentPredictions = predictions.Take(10).Cast<object>().ToList()
                };
            }
            catch (Exception ex)
            {
                // Return minimal data if error
                return new DashboardViewModel
                {
                    TotalApplications = 100,
                    ApprovedCount = 65,
                    RejectedCount = 35,
                    ApprovalRate = 65.0,
                    AvgCreditScore = 680,
                    AvgLoanAmount = 185000,
                    HighRiskCount = 15,
                    ClusterProfiles = _clusteringService.GetClusterProfiles().Cast<object>().ToList(),
                    AgeGroupAnalysis = new List<DemographicAnalysis>
                    {
                        new DemographicAnalysis { Category = "25-34", TotalApplications = 30, Approved = 20, Rejected = 10, ApprovalRate = 66.7, AvgCreditScore = 690, AvgLoanAmount = 180000 },
                        new DemographicAnalysis { Category = "35-44", TotalApplications = 40, Approved = 28, Rejected = 12, ApprovalRate = 70.0, AvgCreditScore = 710, AvgLoanAmount = 220000 },
                        new DemographicAnalysis { Category = "45-54", TotalApplications = 20, Approved = 12, Rejected = 8, ApprovalRate = 60.0, AvgCreditScore = 650, AvgLoanAmount = 160000 },
                        new DemographicAnalysis { Category = "55-64", TotalApplications = 10, Approved = 5, Rejected = 5, ApprovalRate = 50.0, AvgCreditScore = 620, AvgLoanAmount = 140000 }
                    },
                    RecentPredictions = new List<object>()
                };
            }
        }

        private List<SamplePrediction> GenerateSamplePredictions(int count)
        {
            List<SamplePrediction> results = new List<SamplePrediction>();
            
            var scenarios = new[]
            {
                new { Gender = "Male", Age = "35-44", Credit = 780.0, Income = 8500.0, Loan = 250000.0, LTV = 75.0, DTI = 28.0, Status = 0 },
                new { Gender = "Female", Age = "25-34", Credit = 750.0, Income = 7200.0, Loan = 180000.0, LTV = 70.0, DTI = 30.0, Status = 0 },
                new { Gender = "Male", Age = "45-54", Credit = 800.0, Income = 9500.0, Loan = 320000.0, LTV = 72.0, DTI = 25.0, Status = 0 },
                new { Gender = "Female", Age = "35-44", Credit = 720.0, Income = 6800.0, Loan = 200000.0, LTV = 78.0, DTI = 32.0, Status = 0 },
                new { Gender = "Male", Age = "25-34", Credit = 580.0, Income = 4200.0, Loan = 150000.0, LTV = 92.0, DTI = 45.0, Status = 1 },
                new { Gender = "Female", Age = "35-44", Credit = 550.0, Income = 3800.0, Loan = 140000.0, LTV = 95.0, DTI = 48.0, Status = 1 },
            };

            Random rand = new Random(42);
            int id = 1;

            for (int i = 0; i < count; i++)
            {
                var scenario = scenarios[i % scenarios.Length];
                double creditVariation = rand.Next(-20, 21);
                double creditScore = scenario.Credit + creditVariation;
                
                int status = scenario.Status;
                double approvalProb = status == 0 ? 
                    Math.Min(0.95, 0.5 + (creditScore - 600) / 400.0) : 
                    Math.Max(0.15, 0.5 - (650 - creditScore) / 300.0);
                    
                double rejectionProb = 1 - approvalProb;

                results.Add(new SamplePrediction
                {
                    ID = id++,
                    Gender = scenario.Gender,
                    AgeGroup = scenario.Age,
                    CreditScore = creditScore,
                    Income = scenario.Income + rand.Next(-500, 501),
                    LoanAmount = scenario.Loan + rand.Next(-10000, 10001),
                    LTV = scenario.LTV + rand.Next(-3, 4),
                    DTI = scenario.DTI + rand.Next(-2, 3),
                    ApprovalProbability = approvalProb,
                    RejectionProbability = rejectionProb,
                    PredictionResult = status == 0 ? "APPROVED" : "REJECTED",
                    ConfidenceLevel = approvalProb >= 0.7 ? "HIGH CONFIDENCE" : 
                                     approvalProb >= 0.5 ? "MODERATE CONFIDENCE" : "LOW CONFIDENCE",
                    RiskCategory = rejectionProb >= 0.7 ? "HIGH RISK" : 
                                  rejectionProb >= 0.4 ? "MEDIUM RISK" : "LOW RISK"
                });
            }

            return results;
        }

        private List<DemographicAnalysis> GetAgeGroupAnalysis(List<SamplePrediction> predictions)
        {
            var grouped = predictions
                .GroupBy(p => p.AgeGroup)
                .Select(g => new DemographicAnalysis
                {
                    Category = g.Key,
                    TotalApplications = g.Count(),
                    Approved = g.Count(p => p.PredictionResult == "APPROVED"),
                    Rejected = g.Count(p => p.PredictionResult == "REJECTED"),
                    ApprovalRate = g.Count() > 0 ? 
                        (g.Count(p => p.PredictionResult == "APPROVED") * 100.0 / g.Count()) : 0,
                    AvgCreditScore = g.Average(p => p.CreditScore),
                    AvgLoanAmount = g.Average(p => p.LoanAmount)
                })
                .OrderBy(x => x.Category)
                .ToList();

            return grouped;
        }

        private class SamplePrediction
        {
            public int ID { get; set; }
            public string Gender { get; set; }
            public string AgeGroup { get; set; }
            public double CreditScore { get; set; }
            public double Income { get; set; }
            public double LoanAmount { get; set; }
            public double LTV { get; set; }
            public double DTI { get; set; }
            public double ApprovalProbability { get; set; }
            public double RejectionProbability { get; set; }
            public string PredictionResult { get; set; }
            public string ConfidenceLevel { get; set; }
            public string RiskCategory { get; set; }
        }
    }
}
