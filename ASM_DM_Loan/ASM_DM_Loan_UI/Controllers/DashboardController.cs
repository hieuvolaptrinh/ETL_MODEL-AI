using System;
using System.Web.Http;
using ASM_DM_Loan_UI.Services;

namespace ASM_DM_Loan_UI.Controllers
{
    /// <summary>
    /// API Controller cho Dashboard
    /// </summary>
    [RoutePrefix("api/dashboard")]
    public class DashboardApiController : ApiController
    {
        private readonly DashboardService _dashboardService;

        public DashboardApiController()
        {
            _dashboardService = new DashboardService();
        }

        /// <summary>
        /// GET: api/dashboard
        /// Lấy dữ liệu dashboard tổng hợp
        /// </summary>
        [HttpGet]
        [Route("")]
        public IHttpActionResult GetDashboard()
        {
            try
            {
                var data = _dashboardService.GetDashboardData();
                return Ok(data);
            }
            catch (Exception ex)
            {
                // Log chi tiết lỗi
                System.Diagnostics.Debug.WriteLine($"Dashboard Error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack Trace: {ex.StackTrace}");
                
                // Return error as JSON (not throw exception)
                return Ok(new
                {
                    Error = true,
                    Message = ex.Message,
                    InnerException = ex.InnerException?.Message
                });
            }
        }
    }
}
