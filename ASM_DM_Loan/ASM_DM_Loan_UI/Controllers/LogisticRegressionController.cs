using System;
using System.Web.Http;
using ASM_DM_Loan_UI.Models;
using ASM_DM_Loan_UI.Services;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller cho Logistic Regression Model
    /// </summary>
    [RoutePrefix("api/logistic-regression")]
    public class LogisticRegressionController : ApiController
    {
        private readonly LogisticRegressionService _service;

        public LogisticRegressionController()
        {
            _service = new LogisticRegressionService();
        }

        /// <summary>
        /// POST: api/logistic-regression/predict
        /// Dự đoán nợ xấu bằng Logistic Regression
        /// </summary>
        [HttpPost]
        [Route("predict")]
        public IHttpActionResult Predict([FromBody] LoanApplicationInput input)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = _service.PredictBadDebtRisk(input);
                if (result == null)
                {
                    return InternalServerError(new Exception("Không thể dự đoán. Vui lòng kiểm tra kết nối SSAS."));
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        /// <summary>
        /// GET: api/logistic-regression/summary
        /// Lấy thông tin tổng quan model
        /// </summary>
        [HttpGet]
        [Route("summary")]
        public IHttpActionResult Summary()
        {
            try
            {
                return Ok(_service.GetModelSummary());
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }
}
