using System;
using System.Web.Http;
using ASM_DM_Loan_UI.Models;
using ASM_DM_Loan_UI.Services;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller cho Logistic Regression Model (Credit)
    /// </summary>
    [RoutePrefix("api/logistic")]
    public class LogisticRegressionController : ApiController
    {
        private readonly LogisticRegressionService _logisticService;

        public LogisticRegressionController()
        {
            _logisticService = new LogisticRegressionService();
        }

        /// <summary>
        /// POST: api/logistic/predict
        /// Dự đoán khoản vay bằng Logistic Regression
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

                var result = _logisticService.PredictLoanApproval(input);
                
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
    }
}
