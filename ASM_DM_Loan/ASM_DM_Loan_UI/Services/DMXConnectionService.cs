using System;
using System.Configuration;
using System.Data;
using System.Data.OleDb;

namespace ASM_DM_Loan_UI.Services
{
    /// <summary>
    /// Service chung để kết nối và thực thi DMX queries
    /// </summary>
    public class DMXConnectionService
    {
        private readonly string _connectionString;

        public DMXConnectionService()
        {
            // Connection string cho SSAS
            _connectionString = ConfigurationManager.ConnectionStrings["SSASConnection"]?.ConnectionString 
                ?? "Provider=MSOLAP;Data Source=localhost;Initial Catalog=ASM_DM_Loan;";
        }

        /// <summary>
        /// Thực thi DMX query và trả về DataTable
        /// </summary>
        public DataTable ExecuteDMXQuery(string dmxQuery)
        {
            DataTable result = new DataTable();
            
            try
            {
                using (OleDbConnection connection = new OleDbConnection(_connectionString))
                {
                    connection.Open();
                    using (OleDbCommand command = new OleDbCommand(dmxQuery, connection))
                    {
                        command.CommandTimeout = 300; // 5 minutes timeout
                        using (OleDbDataAdapter adapter = new OleDbDataAdapter(command))
                        {
                            adapter.Fill(result);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error executing DMX query: {ex.Message}", ex);
            }

            return result;
        }
    }
}
