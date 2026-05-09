using System.Linq;
using System.Web.Http;

namespace ASM_DM_Loan_UI
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Web API configuration and services

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            // Return JSON by default (remove XML formatter)
            var appXmlType = config.Formatters.XmlFormatter.SupportedMediaTypes
                .FirstOrDefault(t => t.MediaType == "application/xml");
            if (appXmlType != null)
            {
                config.Formatters.XmlFormatter.SupportedMediaTypes.Remove(appXmlType);
            }

            // Enable CORS (if needed)
            // config.EnableCors();
        }
    }
}
