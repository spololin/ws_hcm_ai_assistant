# 9. Если что-то пошло не так

Откройте Issue по шаблону «Ошибка» и приложите:

- вывод `curl http://localhost:3100/healthz`;
- `docker compose ps`;
- `logs/startup-<дата>.log` и `logs/errors-<дата>.log`;
- выгрузку телеметрии
- что делали и что ожидали увидеть.

**Пароли базы и `MCP_AUTH_TOKEN` в Issue не вставляйте.**
