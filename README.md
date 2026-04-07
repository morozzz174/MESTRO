# MESTRO — Мастер, Единый Стандарт Точности Расчёта Объекта

> *«Мастер, единый стандарт точности расчёта объекта»*

Мобильное приложение для выездных специалистов (замерщики, монтажники, строительные бригады). Автоматизирует запись клиентов, заполнение чек-листов, фотофиксацию с аннотациями и расчёт стоимости.

## 🎯 Возможности

- 📋 **Динамические чек-листы** — поля появляются/скрываются в зависимости от ответов
- 📷 **Фотофиксация с аннотациями** — стрелки, круги, текст поверх фото
- 📍 **Геотеги** — координаты автоматически привязываются к каждому фото
- 🎤 **Голосовой ввод** — надиктовка замеров с автозаполнением полей
- 💰 **Расчёт стоимости** — авторасчёт по редактируемым прайс-листам
- 📄 **PDF коммерческих предложений** — с кириллицей, фото и ценой
- 📅 **Календарь замеров** — визуальный календарь с оптимизацией маршрутов
- 📡 **Офлайн-режим** — все данные хранятся локально в SQLite
- 🔒 **Авторизация по телефону** — звонок от uCaller с кодом верификации

## 📊 8 типов работ

| # | Тип | Описание |
|---|-----|----------|
| 1 | 🪟 **Окна** | Ширина, высота, тип стеклопакета, откосы, подоконник |
| 2 | 🚪 **Двери** | Полотно, коробка, замок, ручка, направление открывания |
| 3 | ❄️ **Кондиционеры** | Тип монтажа, длина трубы, дренаж, кронштейны |
| 4 | 🍳 **Кухни** | Погонный метр, столешница, техника, фартук |
| 5 | 🔲 **Плиточные работы** | Площадь, способ укладки, тёплый пол |
| 6 | 🪑 **Мебельные блоки** | Материал корпуса, фасады, выдвижные ящики |
| 7 | 🔧 **Инженерные системы** | Котельная, отопление, вентиляция |
| 8 | ⚡ **Электрика** | Розетки, освещение, трассы, щиток |

## 🏗️ Архитектура

```
lib/
├── main.dart                          # Точка входа, BLoC инициализация
├── models/
│   ├── order.dart                     # Заявка (Order, PhotoAnnotation)
│   ├── user.dart                      # Пользователь
│   ├── checklist_config.dart          # Конфигурация чек-листа
│   └── price_item.dart                # Элемент прайс-листа
├── bloc/
│   ├── order_bloc.dart                # Управление заявками (CRUD)
│   ├── checklist_bloc.dart            # Управление чек-листами
├── screens/
│   ├── registration_screen.dart       # Авторизация (uCaller)
│   ├── checklist_screen.dart          # Экран замера
│   ├── photo_annotation_screen.dart   # Аннотирование фото
│   └── consent_screen.dart            # Согласие на ПДн
├── database/
│   └── database_helper.dart           # SQLite CRUD
├── features/
│   ├── home/                          # Дашборд + главная
│   ├── appointments/                  # Список замеров
│   ├── calendar/                      # Календарь замеров
│   ├── price_list/                    # Управление прайсами
│   ├── voice/                         # Голосовой ввод
│   └── profile/                       # Профиль
├── services/
│   ├── ucaller_service.dart           # API ucaller.ru
│   ├── price_list_service.dart        # Сервис прайс-листов
│   └── voice_input_service.dart       # Голос → данные
└── utils/
    ├── cost_calculator.dart           # Калькулятор стоимости
    ├── pdf_generator.dart             # Генерация PDF
    └── checklist_loader.dart          # Загрузка JSON

assets/
├── checklists/                        # 8 JSON-шаблонов
├── prices/                            # 8 JSON-прайсов
└── fonts/                             # Arial (кириллица для PDF)
```

## 🛠️ Технологический стек

| Технология | Назначение |
|------------|-----------|
| **Flutter 3.x** | Кроссплатформенный фреймворк |
| **flutter_bloc** | State Management (BLoC pattern) |
| **sqflite** | Локальная база данных SQLite |
| **image_picker** | Съёмка камеры / галерея |
| **speech_to_text** | Голосовой ввод |
| **geolocator** | Геолокация |
| **pdf + printing** | Генерация PDF |
| **share_plus** | Шеринг PDF |
| **intl** | Форматирование дат |
| **http** | API запросы (uCaller) |

## 🚀 Быстрый старт

```bash
# Переход в директорию проекта
cd metro_2

# Установка зависимостей
flutter pub get

# Запуск на подключённом устройстве
flutter run

# Сборка APK
flutter build apk --release
```

## 📱 Установка

### Android
```bash
# APK после сборки
flutter build apk --release
# Файл: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
# Требуется Mac + Xcode
flutter build ios --release
```

## 📊 База данных

### Таблица `orders`
- `id`, `client_name`, `address`, `date`, `status`, `work_type`
- `checklist_data` (JSON), `estimated_cost`
- `appointment_date`, `client_phone`, `notes`

### Таблица `photo_annotations`
- `id`, `order_id`, `file_path`, `annotated_path`
- `latitude`, `longitude`, `timestamp`

### Таблица `users`
- `id`, `phone`, `full_name`, `consent_date`

## 📋 Структура чек-листа

```json
{
  "work_type": "windows",
  "title": "Замер окон",
  "fields": [
    {
      "id": "width",
      "type": "number",
      "label": "Ширина проёма (мм)",
      "required": true
    },
    {
      "id": "quarter_depth",
      "type": "number",
      "label": "Глубина четверти (мм)",
      "condition": { "field": "has_quarter", "operator": "equals", "value": true }
    }
  ]
}
```

## 📄 Документация

Полная документация проекта: [PROJECT_DOCS.md](PROJECT_DOCS.md)

## 📈 Roadmap

- [x] v1.0 — Базовый функционал, 8 типов работ, голосовой ввод, прайс-листы
- [ ] v1.1 — Premium подписка (Google Play Billing + App Store IAP)
- [ ] v1.2 — ИИ-подсказки (Gemini Flash API)
- [ ] v2.0 — Mestro AI Server (анализ фото, Whisper, диагностика)

## 📝 Лицензия

Проект разработан для коммерческого использования. Все права защищены.

---

**MESTRO v1.0.0** — [github.com/morozzz174/MESTRO](https://github.com/morozzz174/MESTRO)
