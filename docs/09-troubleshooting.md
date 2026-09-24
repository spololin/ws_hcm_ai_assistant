# 9. Если что-то пошло не так

Откройте Issue по шаблону «Ошибка» и приложите:

- вывод `curl http://localhost:3100/healthz`;
- `docker compose ps`;
- `logs/startup-<дата>.log` и `logs/errors-<дата>.log`;
- выгрузку телеметрии
- что делали и что ожидали увидеть.

**Пароли базы и `MCP_AUTH_TOKEN` в Issue не вставляйте.**

## Кажется, что консоль зависла

Так и должно быть. Последняя строка старта — `server ready` с адресами MCP и
дашборда. После неё сервер в консоль не логирует: запросы и вызовы инструментов
уходят в файлы `logs/access-<дата>.log` и `logs/mcp-usage-<дата>.log`, а на
дашборде видна статистика вызовов.

Проверить, что сервер отвечает: `curl http://localhost:3100/readyz` — должно
быть `"status":"ready"`.

## Гибридный поиск не работает

На дашборде — красное уведомление «Гибридный поиск не работает», в `/readyz` —
`"search_mode":"bm25"` и поля `search_error`, `search_hint`. Сервер при этом
работает: поиск по функциям платформы идёт по словам. Чаще всего модель поиска
не скачалась. Что именно случилось, написано в `search_hint`.

### Антивирус или прокси перехватывает HTTPS

Причина в `search_error` — `SELF_SIGNED_CERT_IN_CHAIN` или
`UNABLE_TO_GET_ISSUER_CERT_LOCALLY`. Так бывает, когда антивирус проверяет
защищённые соединения (Kaspersky, ESET, Avast, Dr.Web) или прокси
подставляет свой сертификат. Система ему доверяет, поэтому браузер работает, а
контейнер — нет: у него свой набор корневых сертификатов.

Модель поиска — единственное, что сервер скачивает из интернета, поэтому
проще всего [скачать её вручную](#скачать-модель-вручную). Если хотите, чтобы
сервер качал сам, подключите сертификат:

1. Выгрузите корневой сертификат перехватчика в файл `certs/ca.pem` рядом с
   `docker-compose.yml` — как это сделать в вашей ОС, написано
   [ниже](#как-выгрузить-сертификат).
2. Добавьте в `.env` строку:

   ```ini
   NODE_EXTRA_CA_CERTS=/app/certs/ca.pem
   ```

   Если `.env` создан из `.env.example` версии 2.3.1 или новее, строка там
   уже есть закомментированной — достаточно убрать `#`. При обновлении `.env`
   не меняется, поэтому у тех, кто ставил раньше, её нет.
3. Выполните `docker compose up -d`. Именно эту команду: `docker compose
   restart` и перезапуск в Docker Desktop оставляют прежние настройки и `.env`
   не перечитывают. Через несколько минут `/readyz` покажет
   `"search_mode":"hybrid_building"`, а после расчёта векторов — `"hybrid"`.

Отключать проверку сертификатов (`NODE_TLS_REJECT_UNAUTHORIZED=0`) не нужно:
это выключит её для всех соединений сервера.

#### Как выгрузить сертификат

Файл должен быть в формате PEM (текст, начинается с `-----BEGIN
CERTIFICATE-----`). Сертификатов в нём может быть несколько — лишние не мешают.

**Кто перехватывает соединение.** На macOS и Linux:

```bash
openssl s_client -connect huggingface.co:443 -servername huggingface.co </dev/null 2>/dev/null | openssl x509 -noout -issuer
```

Если в `issuer` антивирус, прокси или ваша компания — это он. Если Amazon или
другой публичный центр сертификации — перехвата нет, причина в другом. Если
там что-то незнакомое, разберитесь, кто это, прежде чем доверять.

**Windows** — в PowerShell из папки ассистента:

```powershell
$req = [Net.HttpWebRequest]::Create('https://huggingface.co/')
try { $req.GetResponse().Dispose() } catch {}
$leaf = [Security.Cryptography.X509Certificates.X509Certificate2]$req.ServicePoint.Certificate
$chain = New-Object Security.Cryptography.X509Certificates.X509Chain
[void]$chain.Build($leaf)
$chain.ChainElements | ForEach-Object { $_.Certificate.Subject }
New-Item -ItemType Directory -Force certs | Out-Null
$chain.ChainElements | Select-Object -Skip 1 | ForEach-Object {
  "-----BEGIN CERTIFICATE-----"
  [Convert]::ToBase64String($_.Certificate.RawData, 'InsertLineBreaks')
  "-----END CERTIFICATE-----"
} | Out-File -Encoding ascii certs\ca.pem
```

Скрипт печатает цепочку: первым — сертификат сайта, дальше — того, кто
перехватывает соединение (например, `Kaspersky Anti-Virus Personal Root
Certificate`), — и сохраняет всё, кроме сертификата сайта.

**macOS** — сертификат перехватчика лежит в Связке ключей. В терминале из
папки ассистента, подставив часть имени из `issuer`:

```bash
mkdir -p certs && security find-certificate -a -p -c "Kaspersky" > certs/ca.pem
```

Без терминала: «Связка ключей» → найдите сертификат → «Файл» →
«Экспортировать объекты» → формат «Privacy Enhanced Mail (.pem)» → сохраните
как `certs/ca.pem`.

**Linux** — обычно HTTPS перехватывает прокси, и его сертификат администратор
уже установил в систему. Проще всего взять системный набор корневых
сертификатов целиком — в нём есть и этот. Debian, Ubuntu:

```bash
mkdir -p certs && cp /etc/ssl/certs/ca-certificates.crt certs/ca.pem
```

RHEL, Fedora, Astra и другие с `ca-trust`:

```bash
mkdir -p certs && cp /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem certs/ca.pem
```

Только добавленный вручную сертификат лежит в `/usr/local/share/ca-certificates/`
(Debian, Ubuntu) или `/etc/pki/ca-trust/source/anchors/` (RHEL): его `.crt` уже в
формате PEM, достаточно скопировать как `certs/ca.pem`.

**Проверить**, что с этим файлом модель скачивается, можно до перезапуска
сервера (`200` — всё в порядке):

```bash
docker run --rm -v ./certs:/certs:ro -e NODE_EXTRA_CA_CERTS=/certs/ca.pem -e U=https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/config.json --entrypoint node ghcr.io/spololin/ws_hcm_ai_assistant:latest -e "fetch(process.env.U).then(r=>console.log(r.status)).catch(e=>console.log(e.message,e.cause))"
```

### Скачать модель вручную

Если у контейнера нет доступа в интернет или вы не хотите возиться с
сертификатом, скачайте модель сами и положите в папку `models` рядом с
`docker-compose.yml`. Сервер берёт модель оттуда и в интернет не обращается,
векторы он посчитает сам.

Нужны четыре файла (самый большой — `model_quantized.onnx`, ~113 МБ):

```text
models/
  Xenova/multilingual-e5-small/
    config.json
    tokenizer.json
    tokenizer_config.json
    onnx/model_quantized.onnx
```

**Windows** — в PowerShell из папки ассистента:

```powershell
$base = 'https://huggingface.co/Xenova/multilingual-e5-small/resolve/main'
$dir = 'models\Xenova\multilingual-e5-small'
New-Item -ItemType Directory -Force "$dir\onnx" | Out-Null
foreach ($f in 'config.json','tokenizer.json','tokenizer_config.json','onnx/model_quantized.onnx') {
  curl.exe -L --fail -o "$dir\$($f -replace '/','\')" "$base/$f"
}
```

Именно `curl.exe` из PowerShell: он доверяет тем же сертификатам, что и
Windows, поэтому скачивает и при антивирусе, перехватывающем HTTPS. `curl` из
Git Bash или Cmder может оказаться другим — со своим набором сертификатов.

**macOS и Linux** — в терминале из папки ассистента:

```bash
base=https://huggingface.co/Xenova/multilingual-e5-small/resolve/main
dir=models/Xenova/multilingual-e5-small
mkdir -p "$dir/onnx"
for f in config.json tokenizer.json tokenizer_config.json onnx/model_quantized.onnx; do curl -L --fail -o "$dir/$f" "$base/$f"; done
```

**Через браузер** — откройте четыре ссылки и разложите скачанные файлы по
папкам, как на схеме выше:

- https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/config.json
- https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/tokenizer.json
- https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/tokenizer_config.json
- https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/onnx/model_quantized.onnx

Если на сервере с ассистентом интернета нет вовсе, скачайте файлы на любом
другом компьютере и перенесите папку `models` целиком.

Затем в `.env` — `SEARCH_HYBRID_ENABLED=true` и `docker compose up -d`. Через
несколько минут `/readyz` покажет `"search_mode":"hybrid_building"`, а после
расчёта векторов — `"hybrid"`.
