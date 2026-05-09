using System.Web;
using System.Web.Http;

namespace ASM_DM_Loan_UI
{
    public class WebApiApplication : HttpApplication
    {
        protected void Application_Start()
        {
            GlobalConfiguration.Configure(WebApiConfig.Register);
        }
    }
}
