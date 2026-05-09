using System;
using System.Web.Http;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller chung (Legacy - để tương thích ngược)
    /// Khuyến nghị sử dụng các controller chuyên biệt:
    /// - DecisionTreeController: /api/decision-tree/*
    /// - LogisticRegressionController: /api/logistic/*
    /// - ClusteringController: /api/clustering/*
    /// - DashboardApiController: /api/dashboard/*
    /// </summary>
    [RoutePrefix("api")]
    public class LoanApiController : ApiController
    {
        #region Test API

        /// <summary>
        /// GET: api/test
        /// Test endpoint để kiểm tra API hoạt động
        /// </summary>
        [HttpGet]
        [Route("test")]
        public IHttpActionResult Test()
        {
            return Ok(new
            {
                Status = "OK",
                Message = "API is working!",
                Timestamp = DateTime.Now,
                AvailableEndpoints = new
                {
                    DecisionTree = "/api/decision-tree/predict",
                    LogisticRegression = "/api/logistic/predict",
                    Clustering = "/api/clustering/predict",
                    ClusteringProfiles = "/api/clustering/profiles",
                    ClusteringSimilar = "/api/clustering/similar-customers",
                    Dashboard = "/api/dashboard"
                }
            });
        }

        #endregion
    }
}
