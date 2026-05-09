using System;
using System.Web.Http;
using ASM_DM_Loan_UI.Models;
using ASM_DM_Loan_UI.Services;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller cho Clustering Model (Credit_Clustering)
    /// </summary>
    [RoutePrefix("api/clustering")]
    public class ClusteringController : ApiController
    {
        private readonly ClusteringService _clusteringService;

        public ClusteringController()
        {
            _clusteringService = new ClusteringService();
        }

        /// <summary>
        /// POST: api/clustering/predict
        /// Dự đoán cluster cho khách hàng
        /// </summary>
        [HttpPost]
        [Route("predict")]
        public IHttpActionResult PredictCluster([FromBody] LoanApplicationInput input)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = _clusteringService.PredictCustomerCluster(input);
                
                if (result == null)
                {
                    return InternalServerError(new Exception("Không thể dự đoán cluster. Vui lòng kiểm tra kết nối SSAS."));
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        /// <summary>
        /// GET: api/clustering/profiles
        /// Lấy thông tin tất cả các clusters
        /// </summary>
        [HttpGet]
        [Route("profiles")]
        public IHttpActionResult GetClusterProfiles()
        {
            try
            {
                var profiles = _clusteringService.GetClusterProfiles();
                return Ok(profiles);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        /// <summary>
        /// POST: api/clustering/similar-customers?top=10
        /// Tìm khách hàng tương tự
        /// </summary>
        [HttpPost]
        [Route("similar-customers")]
        public IHttpActionResult FindSimilarCustomers([FromBody] LoanApplicationInput input, int top = 10)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = _clusteringService.FindSimilarCustomers(input, top);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }
}
