-- Перед выполнением замените:
--   ЗАМЕНИТЕ_ПАРОЛЬ — на свой пароль,
--   ИМЯ_БАЗЫ_HCM    — на имя вашей базы.
-- Выполнять под учётной записью с правами администратора сервера.

USE [master];
GO

CREATE LOGIN [ws_hcm_ai_assistant] WITH
    PASSWORD = N'ЗАМЕНИТЕ_ПАРОЛЬ',
    CHECK_POLICY = ON,
    DEFAULT_DATABASE = [ИМЯ_БАЗЫ_HCM];
GO

USE [ИМЯ_БАЗЫ_HCM];
GO

CREATE USER [ws_hcm_ai_assistant] FOR LOGIN [ws_hcm_ai_assistant];
GO

ALTER ROLE [db_datareader] ADD MEMBER [ws_hcm_ai_assistant];
GO

-- Проверка (выполните под новой учётной записью):
--   SELECT TOP 1 id FROM dbo.collaborators;
--   SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo';
--   SELECT GETUTCDATE();
--   SELECT CONVERT(varchar(36), service_broker_guid) FROM sys.databases WHERE database_id = DB_ID();
