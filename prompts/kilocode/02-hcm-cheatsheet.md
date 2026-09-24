# Шпаргалка по данным Websoft HCM

Минимум фактов, которые нужно помнить даже если MCP сейчас недоступен.

## Таблицы

- На каждый объект две таблицы: `dbo.<object>` (только indexed-поля, плоско) и `dbo.<object>_xml` (XML-колонка `[data]` со всеми полями).
- LEFT JOIN: `LEFT JOIN dbo.[<object>_xml] AS s ON s.[id] = p.[id]`.
- Примеры ниже — в синтаксисе MS SQL. Если инсталляция на PostgreSQL, имена экранируются двойными кавычками (`"dbo"."<object>"`); готовый вариант отдаёт `compose_sql`.

## Поля внутри XML

- Доступ в MS SQL: `s.[data].value('(<object>/<path>)[1]', 'NVARCHAR(MAX)')`; в PostgreSQL — `xpath(...)` над `s."data"`.
- Точное выражение, типы и экранирование под активную СУБД дают `compose_sql` / `find_field` — не пиши вручную.

## custom_elems

- Динамически настраиваемые поля в HCM. Хранятся в XML по пути `/<object>/custom_elems/custom_elem[name="<field>"]/value`.
- Кеш в MCP — TTL 45 сек. При жалобе «custom-поля пропали» вызывай `get_object_schema(refresh=true)`.

## FOREIGN-ARRAY

- Массив ссылок (M:N) между объектами. Поле `<name>_id` хранит ссылку, `<name>_array` — список.
- Inbound-анализ («кто ссылается на X»): `get_object_relations(object_name=X, direction=incoming)`.

## Иерархические объекты

- Если `is_hier=true` — у объекта есть `parent_id` и `fullname`. Учитывай в WHERE/ORDER BY.

## SP-XML ≠ XQuery в MS SQL

- Серверный язык платформы (TypeScript-runtime со своими глобальными `tools.*`, `Sql()`, `XQuery`).
- Если пользователь говорит «xquery в SP-XML» — он про объект `XQuery` платформы, а не про MS SQL XQuery.

## Стемминг

- Запросы пиши как пишет пользователь («сотрудника» = «сотрудник»). Сервер сам нормализует русские окончания.

## Часто-используемые SP-XML функции

`tools.open_doc()`, `ArraySelect()`, `Sql()`, `GetOptProperty()`, `tools.read_object()`, `tools.activate_course_to_person()`. Если не помнишь сигнатуру — `find_sp_xml_entities`.
