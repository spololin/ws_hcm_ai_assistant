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

-- Необязательно — для монитора СУБД (DB_MONITOR_ENABLED=true), см. docs/02-database-user.md.
-- SQL Server 2019 и старше:
-- USE [master];
-- GRANT VIEW SERVER STATE TO [ws_hcm_ai_assistant];
-- USE [ИМЯ_БАЗЫ_HCM];
-- GRANT VIEW DATABASE STATE TO [ws_hcm_ai_assistant];
-- GRANT VIEW DEFINITION TO [ws_hcm_ai_assistant];
-- SQL Server 2022:
-- USE [master];
-- GRANT VIEW SERVER PERFORMANCE STATE TO [ws_hcm_ai_assistant];
-- USE [ИМЯ_БАЗЫ_HCM];
-- GRANT VIEW DATABASE PERFORMANCE STATE TO [ws_hcm_ai_assistant];
-- GRANT VIEW SECURITY DEFINITION TO [ws_hcm_ai_assistant];

-- Проверка (выполните под новой учётной записью):
--   SELECT TOP 1 id FROM dbo.collaborators;
--   SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo';
--   SELECT GETUTCDATE();
--   SELECT CONVERT(varchar(36), service_broker_guid) FROM sys.databases WHERE database_id = DB_ID();
