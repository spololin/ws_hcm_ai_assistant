# Правила работы с MCP `websoft-hcm` (Claude Code)

> Положи этот файл как `CLAUDE.md` в корень проекта `sm_training_backend` рядом с существующим, или объедини с ним — Claude Code прочитает их все.

К проекту backend Websoft HCM подключён MCP-сервер `websoft-hcm` с 22 инструментами. Без него ты будешь галлюцинировать имена объектов, полей и SP-XML функций.

## Что доступно

- `find_object_by_name(query, limit?)` — поиск объекта (`collaborator`, `cu_curriculum`...) по русскому/английскому со стеммингом.
- `get_object_schema(object_name, include_custom?, refresh?)` — indexed-колонки + XML-поля + FOREIGN-ARRAY + custom_elems.
- `find_field(query, object_name?, limit?, include_custom?)` — глобальный поиск поля по русск./англ.
- `get_object_relations(object_name, direction?)` — FOREIGN-ARRAY граф (`outgoing`/`incoming`/`both`).
- `get_lists(list_name?, query?, limit?, offset?)` — справочники id/name: настраиваемые из `wtv_lists.xml` и перечисления платформы по имени `common.<name>` (расшифровка кодов вроде `state_id`).
- `get_system_events(code?, query?, only_active?, include_code?, limit?, offset?, refresh?)` — системные события: без параметров индекс, `query` поиск, `code` карточка с переменными окружения, обработчиками и примером `ms_tools.raise_system_event_env`. `include_code=true` добавляет код обработчиков.
- `get_workflows(code?, query?, object?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — документооборот (ДО): без параметров индекс, `query` поиск, `object=request_type` фильтр по привязке, `code` карточка (этапы, поля, действия с операциями и кодом, эскалации, где используется). `reference=true` — путеводитель по ДО целиком, `topic=model|lifecycle|authoring|operations|conditions|context|checklist|pitfalls|skeletons` — один раздел.
- `get_remote_actions(code?, query?, catalog_name?, only_custom?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — удалённые действия (`remote_action`): без параметров компактный индекс, `query` поиск, `catalog_name=acquaint` действия объекта, `code` карточка (параметры wvars, источник кода, готовый код вызова). `include_code=true` добавляет код действия. Неизвестный `code` возвращает похожие. `topic=model|context|result|dialogs|calling|page|checklist|pitfalls|skeletons` — раздел путеводителя по написанию действий.
- `get_remote_collections(code?, query?, catalog_name?, only_custom?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — выборки (`remote_collection`): без параметров индекс, `query` поиск, `code` карточка (параметры wvars, поля результата, фильтры API, код, готовый код вызова). `topic=model|context|result|paging_sort|api|tree|analytics|calling|checklist|pitfalls|skeletons` — раздел путеводителя по коду выборок.
- `get_server_agents(code?, query?, only_scheduled?, only_custom?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — агенты сервера (`server_agent`): без параметров индекс с расписанием, `query` поиск (код, название, параметры, имя файла), `only_scheduled=true` только с расписанием, `code` карточка (код или id: расписание словами, параметры, код, готовый `tools.start_agent` и чтение `Param`). `topic=model|schedule|context|calling|authoring|checklist|pitfalls|skeletons` — раздел путеводителя.
- `get_discharges(code?, query?, type?, direction?, object_name?, stage?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — выгрузки из базы (`discharge`): экспорт в ODBC/XML и импорт из ODBC, Excel, CSV, XML. Без параметров индекс, `query` поиск (код, название, объекты, поля, файл, SQL), `direction=import|export`, `object_name` — фильтры, `code` карточка (код или id: источник с замаскированным паролем, агенты, запуски, этапы с предупреждениями), `stage=N` — поля, связи и код одного этапа. `topic=model|types|stages|fields|binds|code|running|authoring|checklist|pitfalls|skeletons` — раздел путеводителя.
- `get_statistic_recs(code?, query?, calc_mode?, catalog_name?, only_custom?, include_code?, reference?, topic?, limit?, offset?, refresh?)` — показатели (`statistic_rec`): без параметров индекс, `query` поиск (код, название, параметры, поля результата, типы страниц), `calc_mode=context|accumulating` и `catalog_name` фильтры, `code` карточка (код или id: режим, периоды, поля JSON, параметры, код, где подключён, готовые `{{curContext.…}}` и вызовы). `topic=model|modes|context|result|periods|usage|authoring|checklist|pitfalls|skeletons` — раздел путеводителя.
- `get_code_libraries(code?, method?, query?, include_code?, include_internal?, only_custom?, limit?, offset?, refresh?)` — библиотеки программного кода (`code_library`): без параметров — индекс; `query` — поиск функций; `code` — карточка библиотеки (настройки, функции); `code` + `method` — карточка функции с параметрами, полями результата и готовым `tools.call_code_library_method`; `include_code=true` — исходный код. `code` принимает и пространство tools (`tools_web`, `ms_tools`) — исходный код метода.
- `find_sp_xml_entities(query, kind?, category?, limit?)` — функции SP-XML, объекты, переменные, методы tools-библиотек, функции библиотек программного кода (`kind="lib"`).
- `compose_sql(object_name, fields?, include_custom?, description?)` — готовые SQL-выражения и SELECT-скелет.
- `query_object(object_name, fields?, where?, order_by?, limit?, …)` — **читает сами данные** без написания SQL: условия `{field, op, value}`, значения идут параметрами.
- `execute_sql(sql, max_rows?)` — выполняет готовый `SELECT` в диалекте активной СУБД. Только чтение.
- `list_objects(is_hier?, custom_fields?, limit?, offset?)` — все объекты. Только по явной просьбе; исключение — `custom_fields=defined` (где заведены настраиваемые поля) и `custom_fields=supported` (где их можно завести).
- `record_feedback(task_summary, useful_tools, useless_tools, missing_capability?, comment?, llm_model?, outcome?)` — фидбек в конце задачи.

## Когда обязательно дёргать MCP до написания кода (MUST)

- Перед тем как **писать SQL руками** для `execute_sql` → `compose_sql`: имена таблиц, экранирование и выражения по полям он отдаёт под активную СУБД. Не угадывай имена колонок связанного объекта — для них `find_field` или `get_object_schema`.
- Простое чтение по одному объекту SQL не требует: `query_object` собирает запрос сам, вызывать перед ним `compose_sql` не нужно.
- Перед использованием поля HCM, не упомянутого пользователем дословно → `find_field` или `get_object_schema`.
- Перед SP-XML функцией / объектом / `tools.*`-методом, чью сигнатуру ты не подтверждал в этой сессии → `find_sp_xml_entities`.
- Перед вызовом функции библиотеки программного кода (`tools.call_code_library_method`) → `get_code_libraries(code=…, method=…)`: параметры и поля результата бывают только в карточке. Если в карточке метода tools написано «Карточка собрана по коду инсталляции» (описания в банке нет) или «Описание составлено для другой версии HCM» — прочитай исходник: `get_code_libraries(code=<пространство>, method=<метод>, include_code=true)`.
- Перед JOIN между двумя объектами → `get_object_relations` или `compose_sql`.
- Перед написанием обработчика системного события или вызовом `ms_tools.raise_system_event*` → `get_system_events` с `code=…`. Имена переменных события бери только из карточки.
- Пользователь просит создать или изменить документооборот, спроектировать этапы и действия, объяснить как работает ДО → `get_workflows(topic="authoring")` и `get_workflows(topic="checklist")` (что уточнить у заказчика), затем карточка похожего стандартного ДО как образец.
- Перед написанием кода для операции `eval_str`, условия `if_eval_str` или эскалации ДО → `get_workflows(code=…, topic="context")`. Коды этапов и полей бери из карточки, переменные окружения (`curObject`, `workflowDoc`, `WORKFLOW_ACTION_BREAK`) — из раздела `context`. Контекст ДО НЕ совпадает с обработчиками системных событий.
- Перед вызовом удалённого действия (`tools_web.evaluate_remote_action`, `teAction.evaluate`, `ms_tools.eval_remote_action_step`, LP API `eval_action`) или написанием нового → `get_remote_actions` с `code=…`. Имена и типы параметров (wvars) бери только из карточки. Код действия неизвестен → `get_remote_actions(query=…)` или `get_remote_actions(catalog_name=<объект>)`.
- Перед написанием или правкой кода удалённого действия → `get_remote_actions(topic="context")` и `get_remote_actions(topic="skeletons")`; если действие показывает форму, спрашивает подтверждение или выбирает объект — ещё `topic="dialogs"`. Команды `RESULT` админка и портал понимают разные — `topic="result"`.
- Перед написанием или правкой кода выборки (`remote_collection`) → `get_remote_collections(topic="context")` и `get_remote_collections(topic="skeletons")`, для API v1 ещё `topic="api"`; образец — карточка похожей выборки с `include_code=true`. Окружение выборки (`RESULT` — массив, `PAGING`, `SORT`, `_FILTERS`) НЕ совпадает с удалённым действием.
- Перед вызовом выборки (`teColl.evaluate`, `ms_tools.evaluate_remote_collection_obj`, вид или виджет с выборкой) → `get_remote_collections(code=…)`: имена и типы параметров и поля результата — только из карточки.
- Перед написанием или правкой агента сервера → `get_server_agents(topic="context")` и `get_server_agents(topic="skeletons")`, расписание — `topic="schedule"`; образец — карточка похожего агента с `include_code=true`. Перед `tools.start_agent` → `get_server_agents(code=…)`.
- Перед созданием или правкой выгрузки из базы → `get_discharges(topic="stages")`, `topic="fields"`, `topic="skeletons"`; образец — карточка похожей выгрузки со `stage=N, include_code=true`. Перед запуском выгрузки → `get_discharges(code=…)`.
- Перед написанием или правкой показателя → `get_statistic_recs(topic="modes")`, `topic="result"`, `topic="skeletons"`; результат — только `VALUE`/`VALUE_STR`, параметры — строки. Сначала ищи готовый (`query=…`). Пользователю — код, таблица полей карточки (`topic="authoring"`) и подключение к типу страницы.

## Сессионный кеш

Одно подтверждение в сессии достаточно. Уже вызывал `compose_sql("collaborator")` — переиспользуй результат, не зови второй раз.

## Decision-table (быстрый маршрут)

| Запрос пользователя | Инструмент |
|---|---|
| «найди объект "сотрудник"» | `find_object_by_name` |
| «какие поля у `collaborator`» | `get_object_schema` |
| «где лежит поле "телефон"» | `find_field` |
| «что ссылается на `org`» | `get_object_relations` direction=incoming |
| «значения справочника `currency_types`» | `get_lists` list_name=… |
| в схеме увидел `→ common.X` (например `state_id → common.learning_states`) | `get_lists` list_name="common.X" |
| «напиши SQL по сотрудникам с подразделением» | `find_object_by_name` → `compose_sql` |
| «что делает функция `Top()`» | `find_sp_xml_entities` |
| «как вызвать `tools.open_doc`» | `find_sp_xml_entities` kind=tool |
| «есть ли функция в библиотеках для …» | `find_sp_xml_entities` kind=lib или `get_code_libraries` query=… |
| «как вызвать функцию `libMain.X`», «что возвращает функция библиотеки» | `get_code_libraries` code=libMain, method=X |
| «обновить кеш custom-полей» | `get_object_schema` refresh=true |
| «перечисли все объекты» | `list_objects` (только по явной просьбе) |
| «напиши обработчик события завершения теста» | `get_system_events` query=… → `get_system_events` code=… |
| «создай документооборот согласования отпуска», «добавь этап/действие в ДО» | `get_workflows` topic=authoring + topic=checklist |
| «как устроен документооборот», «что такое этапы и действия» | `get_workflows` topic=model |
| «напиши код действия ДО», «условие перехода между этапами» | `get_workflows` code=… topic=context |
| «какой ДО у типа заявки X», «почему кнопка не видна» | `get_workflows` object=request_type / code=… |
| «какие удалённые действия есть у объекта X» | `get_remote_actions` catalog_name=X |
| «вызови удалённое действие …», «передай параметры в действие» | `get_remote_actions` query=… → `get_remote_actions` code=… |
| «что делает удалённое действие X», «где его код» | `get_remote_actions` code=X include_code=true |
| «напиши выборку», «сделай выборку для виджета/вида» | `get_remote_collections` topic=context + topic=skeletons |
| «вызови выборку X», «какие поля возвращает выборка X» | `get_remote_collections` code=X |
| «какие выборки есть у объекта X» | `get_remote_collections` catalog_name=X |
| «есть ли агент, который …», «какие агенты работают по расписанию» | `get_server_agents` query=… / only_scheduled=true |
| «когда запускается агент X», «какие параметры у агента X» | `get_server_agents` code=X |
| «напиши агент», «сделай регламентное задание» | `get_server_agents` topic=context + topic=skeletons |
| «откуда загружаются сотрудники», «есть ли импорт из Excel / внешней базы», «что выгружается во внешнюю систему» | `get_discharges` direction=import / object_name=… / query=… |
| «что делает выгрузка X», «какие поля и ключи у импорта X», «когда запускалась» | `get_discharges` code=X (stage=N) |
| «сделай импорт из Excel», «настрой выгрузку в базу» | `get_discharges` topic=stages + topic=fields + topic=skeletons |
| «что выводит `{{curContext.X}}`», «какие показатели есть у сотрудника» | `get_statistic_recs` code=X / calc_mode=context + catalog_name=… |
| «напиши показатель», «выведи число на странице портала» | `get_statistic_recs` topic=modes + topic=result + topic=skeletons |
| «какие переменные доступны в обработчике события X» | `get_system_events` code=X |
| «какие обработчики висят на событии X», «почему не срабатывает» | `get_system_events` code=X (смотри `is_active`), код — `include_code=true` |
| «какой логин у Иванова», «сколько сотрудников» | `query_object` |
| «посчитай по группам», «сложный JOIN с агрегатом» | `execute_sql` |

## Чего не делать

- Не зови `list_objects` без явной просьбы (там сотни объектов).
- Не зови `get_lists` без `list_name`/`query` (вернёт всё).
- Не угадывай имя поля или сигнатуру функции «по аналогии».
- Не угадывай имена переменных системного события: у каждого события свой набор.
- Не переноси переменные системных событий (`curSystemEventObject…`) в код документооборота: там своё окружение.
- Не угадывай коды этапов ДО и не правь `condition_eval_str` руками — его генерирует платформа.
- Не угадывай имена параметров удалённого действия. Имя с точкой (`type_send.tutors`) код действия видит как `type_send_tutors`, а в `ObtainChildByKey` и `CallServerMethod` передаётся исходное. В портале повторный вызов после `confirm` приходит с `command = "eval_action"`, а не `"eval"`: ветвитесь по `command == "submit_form"` и скрытым полям `form_fields`. В админке `curObjectID` пуст — объект в `OBJECT_ID`.
- Не переноси в код выборки переменные удалённого действия (`command`, `RESULT` как объект-команда): выборка возвращает массив в `RESULT`. Не обращайся к `curObject`, `_FILTERS` и параметрам без проверки — у разных вызывающих их может не быть.
- Не переноси в код агента сервера окружение удалённого действия: параметры агента — строки в `Param` под исходным именем (точка не меняется на «_»), `SCOPE_WVARS`, `Request` и `curObject` нет, объекты — в `OBJECT_ID` и `OBJECTS_ID_STR`.
- Не пиши `async/await`/`Promise`/`class` на верхнем уровне модулей backend — runtime платформы это запретит.

## После задачи — `record_feedback`

В самом конце задачи (один раз!) вызови `record_feedback` с кратким `task_summary` и списком `useful_tools` / `useless_tools`. Укажи `llm_model` — свою модель (протокол MCP её не передаёт) и `outcome`: `done`, `partial` или `failed`. Задачу описывай обобщённо: без ФИО, телефонов, e-mail и других данных сотрудников. Если задача была тривиальная и MCP не понадобился — пропусти. Это даёт команде MCP сигнал, что улучшать.

Полная версия промпта (для Continue.dev/JetBrains AI) — [`system-prompt.md`](system-prompt.md) рядом с этим файлом.
