-- Перед выполнением замените:
--   ЗАМЕНИТЕ_ПАРОЛЬ — на свой пароль,
--   ИМЯ_БАЗЫ_HCM    — на имя вашей базы.
-- Выполнять под суперпользователем (обычно postgres).

CREATE ROLE ws_hcm_ai_assistant LOGIN PASSWORD 'ЗАМЕНИТЕ_ПАРОЛЬ';

GRANT CONNECT ON DATABASE "ИМЯ_БАЗЫ_HCM" TO ws_hcm_ai_assistant;

GRANT USAGE ON SCHEMA dbo TO ws_hcm_ai_assistant;
GRANT SELECT ON ALL TABLES IN SCHEMA dbo TO ws_hcm_ai_assistant;

ALTER DEFAULT PRIVILEGES FOR ROLE ВЛАДЕЛЕЦ_ТАБЛИЦ IN SCHEMA dbo
    GRANT SELECT ON TABLES TO ws_hcm_ai_assistant;

-- Проверка (выполните под новой учётной записью):
--   SELECT id FROM dbo.collaborators LIMIT 1;
--   SELECT count(*) FROM information_schema.columns WHERE table_schema = 'dbo';
--   SELECT EXTRACT(EPOCH FROM now())::bigint;
--   SELECT system_identifier FROM pg_control_system();
