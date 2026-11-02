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

## Для монитора СУБД (необязательно)

Монитор СУБД (`DB_MONITOR_ENABLED=true`, вкладка «СУБД» дашборда) читает
системные представления: сессии, блокировки, ожидания, статистику запросов. С
правами только на таблицы `dbo` часть разделов не собирается. Ассистент от этого
не падает: на вкладке и в ответе модели раздел помечен («нет прав», «неполные
данные», «выключено»), рядом — команда для администратора. Права проверяются раз
в 5 минут, после выдачи перезапуск не нужен.

Эти права дают видеть состояние всего сервера СУБД, в том числе тексты запросов
других баз на нём. Выдавать ли их — решение администратора базы.

### MS SQL Server

Без права `VIEW SERVER STATE` SQL Server не выдаёт ошибку, а показывает в списке
сессий только сессию самого ассистента. Поэтому без него монитор сессии и
блокировки не собирает вовсе — иначе вкладка честно, но ошибочно показала бы
«блокировок нет». Без этого права не будет и ожиданий, счётчиков и подсказок по
индексам.

SQL Server 2019 и старше:

```sql
USE [master];
GRANT VIEW SERVER STATE TO [ws_hcm_ai_assistant];
USE [ИМЯ_БАЗЫ_HCM];
GRANT VIEW DATABASE STATE TO [ws_hcm_ai_assistant];
GRANT VIEW DEFINITION TO [ws_hcm_ai_assistant];
```

SQL Server 2022 (право разделено; старое `VIEW SERVER STATE` тоже подходит):

```sql
USE [master];
GRANT VIEW SERVER PERFORMANCE STATE TO [ws_hcm_ai_assistant];
USE [ИМЯ_БАЗЫ_HCM];
GRANT VIEW DATABASE PERFORMANCE STATE TO [ws_hcm_ai_assistant];
GRANT VIEW SECURITY DEFINITION TO [ws_hcm_ai_assistant];
```

Если серверное право выдать нельзя, статистику времени выполнения монитор возьмёт из Query Store
базы — ему хватает права уровня базы (`VIEW DATABASE STATE`). В SQL Server
2016–2019 Query Store по умолчанию выключен:

```sql
ALTER DATABASE [ИМЯ_БАЗЫ_HCM] SET QUERY_STORE = ON;
```

Query Store пригодится и при серверном праве, если кеш планов большой. Запросы HCM
к XML дают планы по сотням килобайт, и кеш на несколько гигабайт SQL Server
перебирает целиком при каждом чтении статистики — десятки секунд. Монитор замеряет
это время и читает кеш реже: чтение — не больше 1 % времени, раздел помечен
«неполные данные». Если Query Store базы включён, монитор переходит на него сам.

### PostgreSQL

Без роли `pg_monitor` PostgreSQL показывает чужие сессии без текста запроса,
состояния и ожиданий, а в статистике времени выполнения у запросов приложения HCM скрывает и текст, и
идентификатор. Блокировки (кто кого ждёт) видны и без неё.

```sql
GRANT pg_monitor TO ws_hcm_ai_assistant;
```

Выдаёт суперпользователь (в PostgreSQL 16 — ещё роль с `ADMIN OPTION` на
`pg_monitor`). С 15-й версии роль ассистента должна наследовать права —
`INHERIT`, так по умолчанию.

Статистика времени выполнения берётся из расширения `pg_stat_statements`. Оно подключается в два
шага: библиотеку добавляют в `shared_preload_libraries` и перезапускают PostgreSQL,
затем создают расширение в базе HCM (суперпользователь):

```sql
-- ДОПИШИТЕ к текущему списку, а не замените его: SHOW shared_preload_libraries;
ALTER SYSTEM SET shared_preload_libraries = '<текущий список>,pg_stat_statements';
-- перезапуск PostgreSQL, затем в базе HCM:
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

- **Yandex Managed Service for PostgreSQL** — роль `mdb_monitor` и расширение
  `pg_stat_statements` включают в консоли кластера (SQL `GRANT` в управляемом
  кластере сбрасывается).
- **AWS RDS** — права выдаёт главный пользователь (`rds_superuser`), библиотеку
  добавляют в группе параметров.
- **Postgres Pro** с `pgpro_stats` — вместо `pg_stat_statements` создайте
  совместимые представления: `SELECT pgpro_stats_create_pg_stat_statements_compatible_views();`

## Какие данные читает сервер

- Объекты платформы: сами объекты, справочники, системные события,
  документообороты, действия и т.п. Это происходит при старте
  и по истечению TTL.
- Данные сотрудников, заявок и прочих документов — **только когда об этом
  просит модель** через `query_object` или `execute_sql`.
- С включённым мониторингом — список порталов из таблицы `hosts` и системные
  представления СУБД (сессии, блокировки, статистика запросов); тексты запросов
  обрезаются до 500 символов и остаются на сервере ассистента.

Любой запрос выполняется в транзакции, которая в конце безусловно
откатывается: в PostgreSQL — `BEGIN TRANSACTION READ ONLY`, в MS SQL —
`BEGIN TRAN` с `ROLLBACK`. Даже при ошибке в логике инструмента запись в базу
не пройдёт.

Строки данных не попадают в телеметрию: в логах остаются только текст запроса,
имена колонок и число строк — см. [07-feedback.md](07-feedback.md).
