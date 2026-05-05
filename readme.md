# 1. Logictist Regression là t để dự đoán cột Status chính là biến nhị phân (0 và 1):

0: Không nợ xấu (Non-default).

1: Nợ xấu/Vi phạm hợp đồng (Default).

## lỗi thì chạy lệnh này để fix

USE master;
GO
CREATE LOGIN [NT Service\MSSQLServerOLAPService] FROM WINDOWS;
GO
USE ETLModelAI;
GO
CREATE USER [NT Service\MSSQLServerOLAPService] FOR LOGIN [NT Service\MSSQLServerOLAPService];
GO
ALTER ROLE db_datareader ADD MEMBER [NT Service\MSSQLServerOLAPService];
GO

### nếu có user rồi thì ghi lệnh này

ALTER ROLE db_owner ADD MEMBER [NT Service\MSSQLServerOLAPService];
