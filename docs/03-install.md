# 3. Установка и первый запуск

Всё, что ниже, выполняется **на той машине, где работает Docker**. Это может
быть ваш компьютер или отдельный сервер в сети.

## Шаг 1. Рабочий каталог

Склонируйте репозиторий `git clone https://github.com/spololin/ws_hcm_ai_assistant.git` 
из PowerShell, bash или cmd.

## Шаг 2. Файл настроек

Файл `.env.example` либо переименуйте в `.env`, либо скопируйте содержимое.
Важно! Для запуска нужен именно `.env`.

В `.env` заполните:

| Переменная | Что писать |
| --- | --- |
| `HCM_HOST_PATH` | путь к каталогу `WebSoftServer` (см. раздел ниже) |
| `DB_TYPE` | `mssql` или `postgres` |
| `DB_SERVER`, `DB_PORT`, `DB_DATABASE` | адрес, порт и имя базы HCM |
| `DB_USER`, `DB_PASSWORD` | пользователь из [02-database-user.md](02-database-user.md) |
| `MCP_AUTH_TOKEN` | любая случайная строка — её будут указывать клиенты. Обязателен: с пустым значением сервер не запустится! |

`LICENSE_KEY` не менять.

Рекомендуется использовать БД с DEV контура.

Токен можно сгенерировать так:

```powershell
[guid]::NewGuid().ToString('N')
```

```bash
openssl rand -hex 16
```

## Шаг 3. Получить образ

Образ опубликован в двух реестрах.

### Реестр GitHub — основной

Выполнить 

```bash
docker compose up -d
```

или

```bash
docker pull ghcr.io/spololin/ws_hcm_ai_assistant:latest
```

### Docker Hub — запасной

Если `ghcr.io` не открывается, раскомментируйте в `.env` строку
`ASSISTANT_IMAGE` — Compose возьмёт образ оттуда:

```ini
ASSISTANT_IMAGE=docker.io/spololin/ws_hcm_ai_assistant
```

Выполнить

```bash
docker compose up -d
```

или

```bash
docker pull docker.io/spololin/ws_hcm_ai_assistant:latest
```

## Шаг 4. Запуск

Если на шаге 3, запускался `docker pull`, то выполнить:
```bash
docker compose up -d
```

Результат: `Container ws_hcm_ai_assistant Started`.

## Шаг 5. Дождаться готовности

Первый старт занимает 1-5 минут: сервер читает схемы и данные из базы. Порт при этом уже отвечает.

```bash
curl http://localhost:3100/readyz
```

- `{"status":"starting", ...}` — идёт загрузка, подождите;
- `{"status":"ready", ...}` — сервер готов;
- ничего не отвечает — смотрите `docker compose logs -f` и дальше
  [09-troubleshooting.md](09-troubleshooting.md).

В ответе `ready` полезны поля: `hcm_version` — версия вашей HCM; 
`objects` и `schemas` — сколько объектов платформы
разобрано (обычно 400+).

Как идёт загрузка, видно в логе:

```bash
docker compose logs -f
```

Строки вида `step load-objects ok`, `step build-schemas ok` — это этапы
загрузки, последняя должна быть `bootstrap ready`.

## Шаг 6. Подключить клиент

[04-clients.md](04-clients.md) — Cursor, VS Code, Kilo Code, Claude Code. 
Адрес сервера: `http://<хост>:3100/mcp`, заголовок
`Authorization: Bearer <MCP_AUTH_TOKEN>`.

---

## Расположение каталога WebSoftServer

Серверу нужен доступ на чтение к корню `WebSoftServer`. При старте он читает
`wtv/wtv_common.xml` и файлы `*.xmd` (схема объектов). Дальше, когда модель
просит показать код, он читает файлы по ссылкам `x-local://…` и от
веб-корня — обработчики событий, удалённые действия, выборки, агентов,
показатели, шаблоны страниц, библиотеки. Отдельно, один раз после старта,
сервер обходит каталоги `wtv`, `wt/web`, `components`, `custom` и ищет, откуда
отправляются уведомления.

Поэтому **монтируйте корень `WebSoftServer` целиком**, а не отдельные папки.

### Вариант 1. Папка на машине с Docker

Самый простой: укажите путь в `HCM_HOST_PATH`.

```ini
# Windows, Docker Desktop
HCM_HOST_PATH=C:/Program Files/WebSoft/WebSoftServer
# Linux
HCM_HOST_PATH=/opt/websoft/WebSoftServer
# macOS
HCM_HOST_PATH=/Users/me/WebSoftServer
# Docker Engine внутри WSL (диски Windows видны как /mnt/c)
HCM_HOST_PATH=/mnt/c/Program Files/WebSoft/WebSoftServer
```

В Windows-пути пишите прямые слеши и не берите путь в кавычки.

На Linux каталог должен читаться пользователем с uid 1000 — под ним работает
процесс внутри контейнера. Проверить: `sudo -u '#1000' ls <путь>`.

### Вариант 2. Сетевая шара

Смонтируйте её как том Docker: в конце `docker-compose.yml` есть готовый
закомментированный блок `hcm-share` для cifs и nfs. Раскомментируйте нужный,
замените в сервисе строку тома `"${HCM_HOST_PATH:?...}:/hcm:ro"` на
`hcm-share:/hcm:ro` и заполните `HCM_SHARE_*` в `.env`.

Запасной путь — смонтировать шару средствами операционной системы и указать
получившийся путь в `HCM_HOST_PATH`. На Windows с Docker Desktop подключённый
сетевой диск (`Z:\`) контейнеру **не виден**: монтируйте шару внутри WSL
(`sudo mount -t cifs …`) и указывайте путь `/mnt/…`.

### Вариант 3. Каталог внутри другого контейнера

Если HCM работает в Docker и каталог лежит на томе — подключите тот же том
к нашему сервису. Если каталог лежит в слоях образа HCM, скопируйте его
наружу:

```bash
docker cp <контейнер-hcm>:/path/to/WebSoftServer ./WebSoftServer
```

и укажите путь к копии.

### Вариант 4. Каталога рядом нет

Скопируйте его один раз на машину с Docker. Минимально нужны `wtv/` и
`wt/web/`, для поиска мест отправки уведомлений — ещё `components/` и
`custom/`. После обновления платформы копию нужно обновить:

```powershell
robocopy \\сервер\WebSoftServer C:\ws_hcm_ai_assistant\WebSoftServer /MIR
```

```bash
rsync -a --delete сервер:/opt/websoft/WebSoftServer/ ./WebSoftServer/
```

Сервер читает каталог при старте, поэтому после обновления копии
перезапустите контейнер: `docker compose up -d`.
