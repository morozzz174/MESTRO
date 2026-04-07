# Mestro — Приложение для мастеров-замерщиков

Android-приложение для выездных специалистов (замерщики окон, дверей, кондиционеров, кухонь и т.д.).

## Возможности

- 📋 **Динамические чек-листы** с условной логикой (поля появляются/скрываются в зависимости от введённых данных)
- 📷 **Фотофиксация с аннотациями** — рисование стрелок, кругов, текста поверх фото
- 📍 **Геотеги** — автоматическая привязка координат к каждому фото
- 💰 **Расчёт стоимости** — автоматический подсчёт на основе размеров и выбранных опций
- 📄 **Генерация PDF** — коммерческое предложение с замерами, фото и ценой
- 📡 **Офлайн-режим** — все данные хранятся локально в SQLite
- 🔄 **4 типа работ**: Окна, Двери, Кондиционеры, Кухни

## Архитектура

```
lib/
├── main.dart                      # Точка входа, инициализация BLoC
├── models/
│   ├── order.dart                 # Модели: Order, PhotoAnnotation, QuoteItem
│   └── checklist_config.dart      # Модели: ChecklistField, ChecklistConfig
├── database/
│   └── database_helper.dart       # SQLite helper (sqflite)
├── bloc/
│   ├── order_bloc.dart            # BLoC для заявок
│   ├── order_event.dart           # Events/States для OrderBloc
│   ├── checklist_bloc.dart        # BLoC для чек-листов
│   └── checklist_event.dart       # Events/States для ChecklistBloc
├── screens/
│   ├── orders_screen.dart         # Экран списка заявок
│   ├── work_type_screen.dart      # Экран выбора типа работ
│   ├── checklist_screen.dart      # Экран динамического чек-листа
│   └── photo_annotation_screen.dart # Экран аннотаций на фото
├── utils/
│   ├── checklist_loader.dart      # Загрузка JSON чек-листов
│   ├── condition_evaluator.dart   # Проверка условий видимости
│   ├── cost_calculator.dart       # Расчёт стоимости
│   ├── pdf_generator.dart         # Генерация PDF
│   └── location_helper.dart       # Геолокация
└── widgets/                       # Переиспользуемые виджеты

assets/checklists/
├── windows.json                   # Чек-лист для окон
├── doors.json                     # Чек-лист для дверей
├── air_conditioners.json          # Чек-лист для кондиционеров
└── kitchens.json                  # Чек-лист для кухонь
```

## Технологический стек

| Технология        | Назначение                        |
|-------------------|-----------------------------------|
| Flutter 3.38      | Фреймворк                         |
| flutter_bloc      | State Management (BLoC pattern)   |
| sqflite           | Локальная база данных             |
| image_picker      | Съёмка камеры / галерея           |
| geolocator        | Геолокация                        |
| pdf + printing    | Генерация PDF                     |
| share_plus        | Отправка PDF через мессенджеры    |
| intl              | Форматирование дат                |
| uuid              | Генерация ID                      |

## Установка и запуск

```bash
# Переход в директорию проекта
cd c:\mestro_2\metro_2

# Установка зависимостей
flutter pub get

# Запуск на подключённом устройстве
flutter run

# Сборка APK
flutter build apk --release
```

## Сборка APK

Для сборки релизного APK:

```bash
cd c:\mestro_2\metro_2
flutter build apk --release
```

Готовый APK будет находиться в `build/app/outputs/flutter-apk/`.

## Структура чек-листов

Каждый JSON-файл в `assets/checklists/` имеет формат:

```json
{
  "work_type": "windows",
  "title": "Замер окон",
  "fields": [
    {
      "id": "width",
      "type": "number",
      "label": "Ширина проёма (мм)",
      "required": true,
      "hint": "мм"
    },
    {
      "id": "has_quarter",
      "type": "boolean",
      "label": "Есть четверть?"
    },
    {
      "id": "quarter_depth",
      "type": "number",
      "label": "Глубина четверти (мм)",
      "condition": {
        "field": "has_quarter",
        "operator": "equals",
        "value": true
      }
    }
  ]
}
```

### Типы полей
- `text` — текстовое поле
- `number` — числовое поле
- `select` — выпадающий список
- `boolean` — переключатель (checkbox)
- `date` — выбор даты

### Условная логика
Поле с `condition` отображается только если условие выполнено:
- `field` — ID поля-триггера
- `operator` — `equals`, `not_equals`, `greater_than`, `less_than`
- `value` — значение для сравнения

## Расчёт стоимости

Формулы расчёта находятся в `lib/utils/cost_calculator.dart`. Для каждого типа работ задаётся своя логика:

- **Окна**: площадь × цена рамы + тип стеклопакета + фурнитура + подоконник + откосы + монтаж
- **Двери**: полотно + коробка + замок + ручка + монтаж
- **Кондиционеры**: тип монтажа + кронштейны + труба + дренаж
- **Кухни**: погонный метр + столешница + установка техники + фартук

## Лицензия

Проект создан для демонстрации.
