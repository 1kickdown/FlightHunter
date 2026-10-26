# FlightHunter (рабочее название)

iOS-приложение для отслеживания дешёвых авиабилетов. Пользователь добавляет направления, приложение следит за ценами, показывает лучшие даты в приложении и в виджете, присылает пуш при падении цены. Покупка происходит на Aviasales по партнёрской ссылке, доход идёт с комиссии Travelpayouts.

Общайся со мной на русском языке.

## Целевая аудитория
Люди из Казахстана и Центральной Азии, которые летают в Европу и обратно (например, Караганда/Алматы/Астана ↔ Будапешт). Важны поиск через соседние города и стыковки.

## Функции первой версии (MVP)
1. Добавить направление: откуда, куда, месяц или диапазон дат, необязательный ценовой порог.
2. Экран направления: календарь цен по месяцу и список самых дешёвых дат.
3. Кнопка «Купить» открывает поиск на Aviasales с партнёрской меткой (marker).
4. Виджет (WidgetKit): лучшая текущая цена по сохранённым направлениям.
5. Пуш-уведомление, когда цена упала ниже порога или заметно ниже обычной.

Не делать в MVP: подписку, поиск «куда угодно», отели, авторизацию через аккаунты. Пользователь идентифицируется анонимно (ID устройства/установки).

## Архитектура
- **iOS:** Swift, SwiftUI, WidgetKit, App Group для обмена данными между приложением и виджетом, APNs для пушей. Минимальная версия iOS — согласовать со мной.
- **Бэкенд:** обязателен. Хранит API-токен Travelpayouts (токен НИКОГДА не должен попадать в iOS-приложение), сохранённые направления и push-токены, по расписанию проверяет цены и отправляет пуши. Стек бэкенда согласуй со мной перед началом (варианты: Supabase с Edge Functions и cron, Firebase, или простой сервер на Node.js/Python).
- Приложение ходит только к нашему бэкенду, не напрямую к Travelpayouts.

## Источник данных: Travelpayouts Data API
Документация: https://support.travelpayouts.com/hc/en-us/categories/200358578-API-and-data

Полезные эндпоинты:
- `GET https://api.travelpayouts.com/v2/prices/month-matrix` — календарь цен на месяц
- `GET https://api.travelpayouts.com/aviasales/v3/get_latest_prices` — последние найденные цены
- `GET https://api.travelpayouts.com/v1/prices/cheap` — самые дешёвые билеты
- `GET https://api.travelpayouts.com/v2/prices/nearest-places-matrix` — цены через соседние города
- справочники городов и аэропортов: `https://api.travelpayouts.com/data/cities.json`, `airports.json`

Важно:
- Данные берутся из кэша поисков пользователей Aviasales за последние ~48 часов и зависят от рынка (market). Для редких направлений данных может не быть — интерфейс должен это корректно показывать («нет свежих цен»), а не падать.
- Использовать `show_to_affiliates=true`, как рекомендует документация.
- Формат партнёрской ссылки на поиск Aviasales уточнить в документации Travelpayouts, не придумывать.
- Учитывать лимиты запросов API: кэшировать ответы на бэкенде, не дёргать API на каждый запрос пользователя.

## Этапы работы
1. Бэкенд: эндпоинт «цены по направлению» (проксирует и кэширует Travelpayouts), проверка на реальных направлениях (KGF, ALA, NQZ → BUD).
2. iOS: экран списка направлений, добавление направления с выбором городов, экран календаря цен.
3. Кнопка «Купить» с партнёрской ссылкой.
4. Виджет.
5. Хранение направлений и push-токенов на бэкенде, задача по расписанию, отправка пушей через APNs.
6. Подготовка к App Store: иконка, политика конфиденциальности, указание, что покупка идёт через Aviasales.

## Правила работы
- Перед каждым этапом коротко опиши план и дождись моего «ок».
- Секреты (токен Travelpayouts, ключи APNs) только в переменных окружения, не в коде и не в git. Добавь `.gitignore`.
- Пиши понятный код с комментариями: я не профессиональный разработчик и хочу понимать, что происходит.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
