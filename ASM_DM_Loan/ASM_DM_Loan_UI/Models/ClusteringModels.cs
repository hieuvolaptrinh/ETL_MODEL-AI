using System;
using System.Collections.Generic;

namespace ASM_DM_Loan_UI.Models
{
    /// <summary>
    /// Model cho kết quả phân nhóm khách hàng
    /// </summary>
    public class CustomerClusterPrediction
    {
        public int ClusterID { get; set; }
        public string ClusterName { get; set; }
        public double ClusterProbability { get; set; }
        public string ClusterDescription { get; set; }
        public int CustomerCount { get; set; }
        public double AvgCreditScore { get; set; }
        public double AvgIncome { get; set; }
        public double AvgLoanAmount { get; set; }
        public string Recommendation { get; set; }
    }

    /// <summary>
    /// Model cho cluster profile
    /// </summary>
    public class ClusterProfile
    {
        public int ClusterID { get; set; }
        public int CustomerCount { get; set; }
        public double AvgCreditScore { get; set; }
        public double AvgIncome { get; set; }
        public double AvgLoanAmount { get; set; }
        public double AvgLTV { get; set; }
        public double AvgDTI { get; set; }
        public string ClusterDescription { get; set; }
    }

    /// <summary>
    /// Model cho khách hàng tương tự
    /// </summary>
    public class SimilarCustomer
    {
        public int CustomerID { get; set; }
        public string Gender { get; set; }
        public string AgeGroup { get; set; }
        public double CreditScore { get; set; }
        public double Income { get; set; }
        public double LoanAmount { get; set; }
        public int ClusterID { get; set; }
        public double SimilarityScore { get; set; }
    }

    /// <summary>
    /// Model cho customer segment
    /// </summary>
    public class CustomerSegment
    {
        public int ID { get; set; }
        public string Gender { get; set; }
        public string AgeGroup { get; set; }
        public double CreditScore { get; set; }
        public double Income { get; set; }
        public double LoanAmount { get; set; }
        
        // Thông tin cluster
        public int ClusterID { get; set; }
        public double ClusterProbability { get; set; }
        public string ClusterProfile { get; set; }
    }
}
