# WebSoft HCM AI Assistant (beta)

AI-ассистент подойдет в первую очередь разработчикам, администраторам, аналитикам, тестировщикам,
разрабатывающим на платформе **Websoft HCM**. Ассистент может получать данные по любым объектам системы.
Подключается к LLM-клиенту (Cursor, VS Code, Kilo Code, Claude Code, OpenCode и т.п.)
по протоколу MCP и даёт модели точные сведения об инстансе HCM: объекты и их
поля, схемы объектов, связи полей, функции системы, tools и библиотек, контекст объектов,
код и настройки объектов, а также выполняет чтение данных из БД.
Модель перестаёт выдумывать имена объектов, полей и функций SP-XML.

Работает on-premise: подключается к базе HCM и каталогу `WebSoftServer`. 
Только чтение — запросы выполняются в транзакции с безусловным
откатом, каталог монтируется в режиме `ro`. Наружу сервер ничего не отправляет.

Ассистент — независимая разработка: это не продукт компании Websoft, он не
связан с ней и ею не поддерживается. Название Websoft HCM используется только
для обозначения платформы, с которой работает ассистент.

## Теги

- `latest` — последний выпуск;
- `<версия>` — конкретный выпуск, например `2.4.1-beta.1525`.

## Запуск

Образу нужны: доступ к базе HCM, смонтированный каталог `WebSoftServer`
и ключ доступа.

```bash
docker run -d --name ws_hcm_ai_assistant --restart unless-stopped \
  -p 3100:3000 -p 3101:3001 \
  -e LICENSE_KEY=<ключ из .env.example репозитория> \
  -e MCP_AUTH_TOKEN=<токен, например openssl rand -hex 16> \
  -e DB_TYPE=mssql -e DB_SERVER=... -e DB_DATABASE=... \
  -e DB_USER=... -e DB_PASSWORD=... \
  -e HCM_PATH=/hcm \
  -e DASHBOARD_SQLITE_PATH=/app/data/mcp-usage.sqlite \
  -v /path/to/WebSoftServer:/hcm:ro \
  -v "$PWD/logs":/app/logs \
  -v ws_hcm_ai_assistant_data:/app/data \
  spololin/ws_hcm_ai_assistant:latest
```

Проверка после запуска: `curl http://localhost:3100/readyz` → `"status":"ready"`.

Готовый `docker-compose.yml`, `.env.example`, инструкция по установке,
подключению клиентов и условия использования —
в репозитории дистрибутива: https://github.com/spololin/ws_hcm_ai_assistant

Основной реестр — `ghcr.io/spololin/ws_hcm_ai_assistant`.
