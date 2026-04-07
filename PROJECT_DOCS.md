# MESTRO — Мобильное приложение для выездных специалистов

## 🏷️ Бренд

**Название:** МЕСТРО (Mestro)

**Расшифровка:**
| Буква | Значение |
|-------|----------|
| **М** | Мастер |
| **Е** | Единый |
| **С** | Стандарт |
| **Т** | Точности |
| **Р** | Расчёта |
| **О** | Объекта |

**Девиз:** *«Мастер, единый стандарт точности расчёта объекта»*

---

## 🎯 Цель проекта

Мобильное приложение для выездных специалистов (замерщики, монтажники, строительные бригады), которое автоматизирует:

- ✅ Запись клиентов и управление встречами
- ✅ Заполнение чек-листов на объекте
- ✅ Фотофиксацию с аннотациями
- ✅ Расчёт стоимости работ
- ✅ Генерацию коммерческих предложений (PDF)
- ✅ Голосовой ввод данных
- ✅ ИИ-помощник (Premium)

**Ключевое отличие** — интеграция ИИ-функций, превращающих приложение из простого инструмента в «умного помощника» для мастера и руководителя.

---

## 👥 Целевая аудитория

| Роль | Описание |
|------|----------|
| **Мастера-замерщики** | Окна, Двери, Кондиционеры, Кухни, Мебель, Плиточные работы, Инженерные системы, Электрика |
| **Бригадиры** | Контроль рабочего времени и материалов |
| **Руководители** | Аналитика, отчёты, управление бригадами |

---

## 📐 Архитектура приложения

### Стек технологий

| Компонент | Технология |
|-----------|-----------|
| **Фреймворк** | Flutter 3.x (Dart) |
| **State Management** | BLoC (flutter_bloc) |
| **База данных** | SQLite (sqflite) |
| **Камера** | image_picker |
| **Геолокация** | geolocator |
| **PDF** | pdf + printing |
| **Голосовой ввод** | speech_to_text |
| **Уведомления** | flutter_local_notifications |
| **API** | HTTP (http) |

### Структура проекта

```
lib/
├── main.dart                          # Точка входа
├── models/
│   ├── order.dart                     # Модель заявки (Order, PhotoAnnotation)
│   ├── user.dart                      # Модель пользователя
│   ├── checklist_config.dart          # Конфигурация чек-листа
│   └── price_item.dart                # Модель элемента прайс-листа
├── bloc/
│   ├── order_bloc.dart                # Управление заявками (CRUD)
│   ├── order_event.dart               # События Order
│   ├── checklist_bloc.dart            # Управление чек-листами
│   └── checklist_event.dart           # События Checklist
├── screens/
│   ├── registration_screen.dart       # Регистрация по телефону (uCaller)
│   ├── checklist_screen.dart          # Экран замера (чек-лист, фото, расчёт)
│   ├── consent_screen.dart            # Согласие на обработку ПДн
│   └── photo_annotation_screen.dart   # Аннотирование фото
├── database/
│   └── database_helper.dart           # SQLite CRUD
├── features/
│   ├── home/                          # Главная страница + дашборд
│   ├── appointments/                  # Список замеров
│   ├── calendar/                      # Календарь замеров
│   ├── price_list/                    # Управление прайс-листами
│   ├── voice/                         # Голосовой ввод
│   ├── checklists_list/               # Шаблоны чек-листов
│   ├── profile/                       # Профиль пользователя
│   └── notifications/                 # Уведомления
├── services/
│   ├── ucaller_service.dart           # API ucaller.ru (SMS-авторизация)
│   ├── price_list_service.dart        # Сервис прайс-листов
│   └── voice_input_service.dart       # Голосовой ввод + парсер замеров
└── utils/
    ├── cost_calculator.dart           # Калькулятор стоимости
    ├── pdf_generator.dart             # Генерация PDF КП
    ├── checklist_loader.dart          # Загрузка JSON чек-листов
    ├── condition_evaluator.dart       # Условия видимости полей
    └── location_helper.dart           # Геолокация

assets/
├── checklists/                        # JSON-шаблоны чек-листов
│   ├── windows.json, doors.json, ...
├── prices/                            # JSON-прайс-листы
│   ├── windows_price.json, doors_price.json, ...
└── fonts/                             # Шрифты для PDF
    └── arial.ttf, arial_bold.ttf
```

---

## 🧩 Модули приложения

### 1. Авторизация
- Регистрация по номеру телефона (звонок от uCaller)
- Верификация кода из звонка
- Профиль мастера (ФИО)
- Согласие на обработку ПДн

### 2. Заявки на замер (Orders)
- Создание заявки (клиент, адрес, дата, тип работ)
- Список заявок с фильтрацией по статусу
- Статусы: Новая → В работе → Завершена / Отменена

### 3. Чек-листы (Checklists)
- Динамические формы для 8 типов работ
- Условная видимость полей (зависят от ответов)
- Голосовое заполнение полей
- Валидация обязательных полей

### 4. Фотофиксация
- Съёмка с камеры / выбор из галереи
- Геолокация + временная метка
- Аннотации (стрелки, текст на фото)
- Привязка к полю чек-листа

### 5. Расчёт стоимости
- Авторасчёт по прайс-листу
- Редактируемые цены (экран "Прайс-лист")
- Диалог подтверждения → сохранение в Order

### 6. Коммерческое предложение (PDF)
- Генерация PDF с кириллическим шрифтом
- Информация о клиенте, замеры, стоимость, фото
- Русский язык для всех полей
- Шеринг PDF (Share Plus)

### 7. Календарь
- Визуальный календарь с маркерами замеров
- Список замеров за день
- Создание замера из календаря
- Синхронизация с OrderBloc

### 8. Голосовой ввод
- Распознавание речи (speech_to_text)
- Парсер замеров (ширина, высота, тип, доп. опции)
- Автозаполнение полей чек-листа

### 9. Прайс-листы
- 8 категорий с редактируемыми ценами
- JSON-файлы в assets
- UI для изменения цен
- Сброс к дефолту

---

## 📊 Типы работ (WorkType)

| ID | Название | Файл чеклиста | Прайс-лист |
|----|----------|---------------|------------|
| `windows` | Окна | windows.json | windows_price.json |
| `doors` | Двери | doors.json | doors_price.json |
| `air_conditioners` | Кондиционеры | air_conditioners.json | air_conditioners_price.json |
| `kitchens` | Кухни | kitchens.json | kitchens_price.json |
| `tiles` | Плиточные работы | tiles.json | tiles_price.json |
| `furniture` | Мебельные блоки | furniture.json | furniture_price.json |
| `engineering` | Инженерные системы | engineering.json | engineering_price.json |
| `electrical` | Электрика | electrical.json | electrical_price.json |

---

## 🗄️ База данных (SQLite)

### Таблица `orders`
```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  client_name TEXT NOT NULL,
  address TEXT NOT NULL,
  date TEXT NOT NULL,
  status TEXT NOT NULL,
  work_type TEXT NOT NULL,
  checklist_data TEXT,           -- JSON с данными чек-листа
  estimated_cost REAL,
  appointment_date TEXT,
  appointment_end TEXT,
  client_phone TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### Таблица `photo_annotations`
```sql
CREATE TABLE photo_annotations (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  file_path TEXT NOT NULL,
  annotated_path TEXT,
  checklist_field_id TEXT,
  latitude REAL,
  longitude REAL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
)
```

### Таблица `users`
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  phone TEXT NOT NULL UNIQUE,
  full_name TEXT,
  consent_date TEXT NOT NULL,
  consent_version TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

---

## 🔀 State Management (BLoC)

### OrderBloc
| Событие | Действие |
|---------|----------|
| `LoadOrders` | Загрузить все заявки |
| `CreateOrder` | Создать заявку |
| `UpdateOrder` | Обновить заявку |
| `DeleteOrder` | Удалить заявку |
| `AddPhoto` | Добавить фото |
| `UpdatePhoto` | Обновить фото |
| `DeletePhoto` | Удалить фото |

### CalendarBloc
| Событие | Действие |
|---------|----------|
| `CalendarLoadOrders` | Загрузить данные календаря |
| `CalendarSelectDay` | Выбрать день |
| `CalendarCreateOrder` | Создать замер из календаря |
| `CalendarUpdateOrder` | Обновить замер |
| `CalendarSyncFromOrderBloc` | Синхронизация с OrderBloc |

### ChecklistBloc
| Событие | Действие |
|---------|----------|
| `LoadChecklist` | Загрузить шаблон чек-листа |
| `UpdateField` | Обновить поле |
| `ResetChecklist` | Сбросить чек-лист |

---

## 🚀 Roadmap (планы развития)

### ✅ Фаза 1: Базовый функционал (сделано)
- [x] Авторизация по телефону
- [x] Создание и редактирование заявок
- [x] Динамические чек-листы
- [x] Фотофиксация с аннотациями
- [x] Расчёт стоимости
- [x] PDF коммерческих предложений
- [x] Календарь замеров
- [x] Голосовой ввод
- [x] Прайс-листы

### 🔄 Фаза 2: Premium подписка (в планах)
- [ ] Google Play Billing + App Store IAP
- [ ] Экран покупки подписки
- [ ] Серверная валидация receipt
- [ ] Умные подсказки (Gemini Flash API)
- [ ] Авторасчёт сметы с ИИ-рекомендациями
- [ ] Перекрёстные продажи

### 🔮 Фаза 3: ИИ-функции (Premium+)
- [ ] Mestro AI Server (FastAPI)
- [ ] Анализ фото (GPT-4o Vision)
- [ ] Распознавание шильдиков (PaddleOCR)
- [ ] Сравнение "Было/Стало"
- [ ] Whisper транскрибация
- [ ] Голосовой помощник "свободные руки"
- [ ] Помощник по диагностике

---

## 📱 Платформы

| Платформа | Статус |
|-----------|--------|
| **Android** | ✅ Работает (APK) |
| **iOS** | 🔄 Готов к сборке (нужен Mac + Xcode) |

---

## 🔑 API интеграции

| Сервис | Назначение | URL |
|--------|-----------|-----|
| **uCaller** | SMS/звонок авторизация | https://api.ucaller.ru |
| **Google Speech** | Голосовой ввод (локально) | speech_to_text пакет |

---

## 📝 Лицензия

Проект разработан для коммерческого использования. Все права защищены.

---

**Mestro v1.0.0** — «Мастер, единый стандарт точности расчёта объекта»
