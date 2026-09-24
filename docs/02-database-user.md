# 2. Пользователь базы данных

Серверу нужен доступ к базе HCM **только на чтение**. Заведите отдельного
пользователя: так видно, чьи запросы идут в базу, и его легко отключить.
Также можно взять кредлы и из spxml_unibridge_config.xml.

Готовые скрипты: [../sql/create-readonly-user.mssql.sql](../sql/create-readonly-user.mssql.sql)
и [../sql/create-readonly-user.postgres.sql](../sql/create-readonly-user.postgres.sql).
Перед выполнением замените в них пароль и имя базы.

## MS SQL Server

```sql
USE [master];
CREATE LOGIN [ws_hcm_ai_assistant] WITH PASSWORD = N'задать_пароль';
USE [ИМЯ_БАЗЫ_HCM];
CREATE USER [ws_hcm_ai_assistant] FOR LOGIN [ws_hcm_ai_assistant];
ALTER ROLE [db_datareader] ADD MEMBER [ws_hcm_ai_assistant];
```

`db_datareader` разрешает `SELECT` на все таблицы базы, включая созданные позже, и
не даёт ничего на запись.

Проверка — подключитесь новым пользователем и выполните:

```sql
SELECT TOP 1 id FROM dbo.collaborators;
SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo';
SELECT GETUTCDATE();
SELECT CONVERT(varchar(36), service_broker_guid) FROM sys.databases WHERE database_id = DB_ID();
```

Ошибок в результатах запросов не должно быть.

## PostgreSQL

```sql
CREATE ROLE ws_hcm_ai_assistant LOGIN PASSWORD 'задать_пароль';
GRANT CONNECT ON DATABASE "ИМЯ_БАЗЫ_HCM" TO ws_hcm_ai_assistant;
\c ИМЯ_БАЗЫ_HCM
GRANT USAGE ON SCHEMA dbo TO ws_hcm_ai_assistant;
GRANT SELECT ON ALL TABLES IN SCHEMA dbo TO ws_hcm_ai_assistant;
```

Чтобы новые таблицы платформы тоже читались, добавьте `ALTER DEFAULT
PRIVILEGES` (см. скрипт) — от имени владельца таблиц HCM.

Проверка:

```sql
SELECT id FROM dbo.collaborators LIMIT 1;
SELECT count(*) FROM information_schema.columns WHERE table_schema = 'dbo';
SELECT EXTRACT(EPOCH FROM now())::bigint;
SELECT system_identifier FROM pg_control_system();
```

Ошибок в результатах запросов не должно быть.

## Сеть и порты

Контейнер обращается к базе с машины, где запущен Docker. Убедитесь, что:
- сервер базы принимает подключения по TCP/IP (для MS SQL это отдельная
  настройка в SQL Server Configuration Manager);
- порт открыт в брандмауэре;
- для **именованного экземпляра** MS SQL (`SERVER\INSTANCE`) укажите в `.env`
  хост в `DB_SERVER` и порт в `DB_PORT` **числом**: запись через обратный слеш
  из контейнера не разрешается, а служба SQL Browser обычно недоступна.

Если база стоит на той же машине, что и Docker, в `DB_SERVER` пишите
`host.docker.internal` — из контейнера `localhost` указывает на сам контейнер.

## Шифрование соединения (`DB_ENCRYPT`)

Относится к MS SQL. По умолчанию `DB_ENCRYPT=true`, и **самоподписанный
сертификат сервера принимается** — отдельно ничего настраивать не нужно.

`DB_ENCRYPT=false` ставьте, только если сервер вообще не поддерживает TLS и
подключение иначе не устанавливается.

## Какие данные читает сервер

- Объекты платформы: сами объекты, справочники, системные события,
  документообороты, действия и т.п. Это происходит при старте
  и по истечению TTL.
- Данные сотрудников, заявок и прочих документов — **только когда об этом
  просит модель** через `query_object` или `execute_sql`.

Любой запрос выполняется в транзакции, которая в конце безусловно
откатывается: в PostgreSQL — `BEGIN TRANSACTION READ ONLY`, в MS SQL —
`BEGIN TRAN` с `ROLLBACK`. Даже при ошибке в логике инструмента запись в базу
не пройдёт.

Строки данных не попадают в телеметрию: в логах остаются только текст запроса,
имена колонок и число строк — см. [07-feedback.md](07-feedback.md).
