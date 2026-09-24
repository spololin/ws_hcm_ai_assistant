# Правила использования MCP `websoft-hcm`

К проекту подключён MCP-сервер с 22 инструментами по платформе Websoft HCM. Без них ты будешь галлюцинировать имена объектов, полей и SP-XML функций.

## КОГДА ОБЯЗАТЕЛЬНО ИСПОЛЬЗОВАТЬ MCP

- Перед тем как писать SQL руками для `execute_sql` — вызови `compose_sql`. Имена колонок связанного объекта уточняй через `find_field`, а не по догадке.
- Для простого чтения по одному объекту используй `query_object` — он собирает запрос сам, `compose_sql` перед ним не нужен.
- Перед использованием поля HCM, не упомянутого пользователем — вызови `find_field` или `get_object_schema`.
- Перед SP-XML функцией / объектом / методом `tools.*` с неподтверждённой сигнатурой — вызови `find_sp_xml_entities`.
- Перед вызовом функции библиотеки программного кода (`tools.call_code_library_method`) — вызови `get_code_libraries(code=…, method=…)`. Карточка метода tools «собрана по коду инсталляции» (описания в банке нет) или «составлено для другой версии HCM» — прочитай исходник: `get_code_libraries(code=<пространство>, method=<метод>, include_code=true)`.
- Перед связкой двух объектов — вызови `get_object_relations` или `compose_sql`.
- Перед написанием обработчика системного события или вызовом `ms_tools.raise_system_event*` — вызови `get_system_events` с `code=…`: имена переменных события берутся только оттуда.
- Когда пользователь просит создать или изменить документооборот (ДО), спроектировать этапы и действия или объяснить, как ДО работает — вызови `get_workflows(topic="authoring")` и `get_workflows(topic="checklist")`, затем карточку похожего ДО как образец.
- Перед написанием кода операции `eval_str`, условия `if_eval_str` или эскалации ДО — вызови `get_workflows(code=…, topic="context")`. Окружение ДО не совпадает с обработчиками системных событий.
- Перед вызовом удалённого действия (`tools_web.evaluate_remote_action`, `ms_tools.eval_remote_action_step`, LP API) — вызови `get_remote_actions` с `code=…`: имена и типы параметров берутся только оттуда. Перед написанием нового действия — `get_remote_actions(topic="context")`, `topic="dialogs"` и `topic="skeletons"`.
- Перед написанием или правкой кода выборки (`remote_collection`) — вызови `get_remote_collections(topic="context")` и `get_remote_collections(topic="skeletons")`; перед вызовом выборки — `get_remote_collections(code=…)`. Окружение выборки не совпадает с удалённым действием.
- Перед написанием или правкой агента сервера (`server_agent`) — вызови `get_server_agents(topic="context")` и `get_server_agents(topic="skeletons")`; перед `tools.start_agent` — `get_server_agents(code=…)`. Параметры агента — строки в `Param` под исходным именем.
- Перед созданием или правкой выгрузки из базы (`discharge`: импорт из Excel/ODBC/CSV/XML, экспорт в ODBC/XML) — вызови `get_discharges(topic="stages")`, `topic="fields"`, `topic="skeletons"`; перед запуском — `get_discharges(code=…)`. Пароль из строки подключения не выводи.
- Перед написанием или правкой показателя (`statistic_rec`) — вызови `get_statistic_recs(topic="modes")`, `topic="result"` и `topic="skeletons"`; перед `{{curContext.…}}` или `tools.obtain_statistic_data` — `get_statistic_recs(code=…)`. Результат показателя — только `VALUE`/`VALUE_STR`, параметры — строки.

## СЕССИОННЫЙ КЕШ

В текущей сессии не повторяй уже сделанные подтверждения. Уже вызывал `compose_sql("collaborator")` — переиспользуй результат.

## DECISION-TABLE

| Запрос пользователя | Инструмент |
|---|---|
| «найди объект "сотрудник"» | `find_object_by_name` |
| «какие поля у `collaborator`» | `get_object_schema` |
| «где лежит поле "телефон"» | `find_field` |
| «что ссылается на `org`» | `get_object_relations` direction=incoming |
| «справочник статусов» | `get_lists` query=… |
| «напиши SQL по X» | `compose_sql` (после `find_object_by_name` если объект ещё не определён) |
| в схеме `→ common.X`, надо расшифровать код | `get_lists` list_name="common.X" |
| «что делает функция Y» | `find_sp_xml_entities` |
| «метод `tools.open_doc`» | `find_sp_xml_entities` kind=tool |
| «функция библиотеки `libMain.X`» | `get_code_libraries` code=libMain, method=X |
| «есть ли в библиотеках функция для …» | `find_sp_xml_entities` kind=lib |
| «обновить custom-поля» | `get_object_schema` refresh=true |
| «напиши обработчик события завершения теста» | `get_system_events` query=… → `get_system_events` code=… |
| «какие переменные / обработчики у события X» | `get_system_events` code=X |
| «создай ДО согласования», «добавь этап/действие» | `get_workflows` topic=authoring + topic=checklist |
| «как устроен документооборот» | `get_workflows` topic=model |
| «напиши код действия ДО», «условие перехода» | `get_workflows` code=… topic=context |
| «какой ДО у типа заявки X» | `get_workflows` object=request_type |
| «какие удалённые действия у объекта X» | `get_remote_actions` catalog_name=X |
| «вызови удалённое действие …» | `get_remote_actions` query=… → `get_remote_actions` code=… |
| «напиши выборку» | `get_remote_collections` topic=context + topic=skeletons |
| «вызови выборку X», «какие поля у выборки X» | `get_remote_collections` code=X |
| «есть ли агент, который …», «какие агенты по расписанию» | `get_server_agents` query=… / only_scheduled=true |
| «когда запускается агент X», «какие у него параметры» | `get_server_agents` code=X |
| «напиши агент» | `get_server_agents` topic=context + topic=skeletons |
| «откуда загружаются сотрудники», «есть ли импорт из Excel» | `get_discharges` direction=import / object_name=… |
| «что делает выгрузка X», «какие у неё поля» | `get_discharges` code=X (stage=N) |
| «сделай импорт из Excel» | `get_discharges` topic=stages + topic=fields + topic=skeletons |
| «что выводит `{{curContext.X}}`», «какие показатели у сотрудника» | `get_statistic_recs` code=X / calc_mode=context |
| «напиши показатель» | `get_statistic_recs` topic=modes + topic=result + topic=skeletons |

## АНТИ-ПАТТЕРНЫ

- Не вызывай `list_objects` без явной просьбы перечислить все объекты.
- Не вызывай `get_lists` без `list_name`/`query`.
- Не угадывай имя поля — XML-выражения бери из `compose_sql`.
- Не угадывай сигнатуру SP-XML функции «по аналогии» с JS.
- Не угадывай имена переменных системного события.
- Не угадывай имена параметров удалённого действия. Не жди ответа от `confirm` и не проверяй повторный вызов по `command == "eval"` (в портале это `eval_action`) — topic=dialogs.
- Не угадывай параметры и поля результата выборки и не переноси в выборку переменные удалённого действия.
- Не переноси в код агента `SCOPE_WVARS`, `Request`, `curObject`: у агента `Param`, `OBJECT_ID`, `OBJECTS_ID_STR`.
- Не переноси переменные системных событий в код документооборота и не угадывай коды этапов ДО.
- Не пиши `async/await`/`Promise`/`class` на верхнем уровне backend.

## ОБРАТНАЯ СВЯЗЬ

В конце задачи (один раз!) — `record_feedback` со списком полезных/бесполезных инструментов. Пропускай для тривиальных задач без MCP-вызовов. Используй поле `missing_capability`, если чего-то не хватило в MCP. Укажи `llm_model` (свою модель) и `outcome` (`done` / `partial` / `failed`). Без ФИО, телефонов и других данных сотрудников в текстах.
