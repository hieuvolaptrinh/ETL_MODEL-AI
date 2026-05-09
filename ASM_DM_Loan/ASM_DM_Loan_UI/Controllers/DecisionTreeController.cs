using System;
using System.Web.Http;
using ASM_DM_Loan_UI.Models;
using ASM_DM_Loan_UI.Services;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller cho Decision Tree Model
    /// </summary>
    [RoutePrefix("api/decision-tree")]
    public class DecisionTreeController : ApiController
    {
        private readonly DecisionTreeService _decisionTreeService;

        public DecisionTreeController()
        {
            _decisionTreeService = new DecisionTreeService();
        }

        /// <summary>
        /// POST: api/decision-tree/predict
        /// Dự đoán khoản vay bằng Decision Tree
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

                var result = _decisionTreeService.PredictLoanApproval(input);
                
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
