"""
Генерация пакета документов для регистрации программы для ЭВМ "MESTRO" в Роспатенте
По форме Приказа Минэкономразвития России от 05.04.2016 N 211
"""

from fpdf import FPDF
from datetime import datetime


class PatentPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.add_font('Corp', '', 'c:/Windows/Fonts/segoeui.ttf')
        self.add_font('Corp', 'B', 'c:/Windows/Fonts/segoeuib.ttf')
        self.add_font('Corp', 'I', 'c:/Windows/Fonts/segoeuii.ttf')

    def header(self):
        self.set_font('Corp', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, 'Документы для регистрации программы для ЭВМ «MESTRO»', align='C')
        self.ln(3)
        self.set_draw_color(44, 62, 80)
        self.set_line_width(0.5)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(5)

    def footer(self):
        self.set_y(-15)
        self.set_draw_color(200, 200, 200)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(4)
        self.set_font('Corp', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, f'ИП Морозов М.И. | {datetime.now().strftime("%d.%m.%Y")} | Стр. {self.page_no()}', align='C')


def add_title(pdf, text, size=14):
    pdf.set_font('Corp', 'B', size)
    pdf.set_text_color(44, 62, 80)
    pdf.multi_cell(0, 8, text, align='C')
    pdf.ln(3)


def add_subtitle(pdf, text):
    pdf.set_font('Corp', 'B', 12)
    pdf.set_text_color(52, 73, 94)
    pdf.multi_cell(0, 8, text, align='C')
    pdf.ln(2)


def add_section(pdf, title):
    pdf.ln(3)
    pdf.set_font('Corp', 'B', 12)
    pdf.set_text_color(255, 255, 255)
    pdf.set_fill_color(44, 62, 80)
    pdf.cell(0, 9, f'  {title}', new_x="LMARGIN", new_y="NEXT", fill=True)
    pdf.ln(3)


def add_text(pdf, text, size=11, bold=False):
    style = 'B' if bold else ''
    pdf.set_font('Corp', style, size)
    pdf.set_text_color(44, 62, 80)
    pdf.multi_cell(0, 6.5, text)
    pdf.ln(2)


def add_bullet(pdf, text, indent=15):
    pdf.set_x(indent)
    pdf.set_font('Corp', '', 11)
    pdf.set_text_color(44, 62, 80)
    bullet = '\u2022'
    pdf.multi_cell(175, 6, f'{bullet} {text}')
    pdf.ln(1)


def add_field_row(pdf, label, value, bold_label=True):
    pdf.set_font('Corp', 'B' if bold_label else '', 11)
    pdf.set_text_color(52, 73, 94)
    label_w = 65
    pdf.cell(label_w, 7, f'{label}: ')
    pdf.set_font('Corp', '', 11)
    pdf.set_text_color(44, 62, 80)
    pdf.multi_cell(0, 7, value)
    pdf.ln(1)


def generate_application_package():
    pdf = PatentPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.set_left_margin(15)
    pdf.set_right_margin(15)

    # ===== ТИТУЛЬНАЯ СТРАНИЦА =====
    pdf.ln(20)
    pdf.set_font('Corp', '', 12)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 8, 'РОСПАТЕНТ (ФИПС)', new_x="LMARGIN", new_y="NEXT", align='C')
    pdf.ln(5)

    add_title(pdf, 'ДОКУМЕНТЫ ДЛЯ РЕГИСТРАЦИИ\nПРОГРАММЫ ДЛЯ ЭВМ', 16)
    pdf.ln(5)

    add_subtitle(pdf, '«MESTRO»')
    pdf.ln(3)

    add_subtitle(pdf, '(Мастер, Единый Стандарт Точности Расчёта Объекта)')
    pdf.ln(10)

    # Инфо-блок
    pdf.set_fill_color(236, 240, 241)
    pdf.set_draw_color(44, 62, 80)
    pdf.set_line_width(0.3)
    y_start = pdf.get_y()
    pdf.rect(40, y_start, 130, 70, 'DF')

    pdf.set_xy(50, y_start + 5)
    pdf.set_font('Corp', 'B', 11)
    pdf.set_text_color(44, 62, 80)
    pdf.cell(110, 7, 'СВЕДЕНИЯ О ЗАЯВИТЕЛЕ', new_x="LMARGIN", new_y="NEXT", align='C')

    pdf.set_x(50)
    add_field_row(pdf, 'Заявитель', 'ИП Морозов Максим Игоревич')
    pdf.set_x(50)
    add_field_row(pdf, 'ОГРНИП', '326745600046657')
    pdf.set_x(50)
    add_field_row(pdf, 'ИНН', '745013371800')
    pdf.set_x(50)
    add_field_row(pdf, 'Адрес', '454031, Челябинская обл., г. Челябинск,\nш. Металлургов, д. 20А, кв. 64')
    pdf.set_x(50)
    add_field_row(pdf, 'Email', 'CHIK174@YANDEX.RU')

    pdf.ln(20)
    add_text(pdf, 'Перечень документов:', 12, True)
    pdf.ln(3)
    add_bullet(pdf, 'Заявление о регистрации программы для ЭВМ (форма РП)')
    add_bullet(pdf, 'Реферат — описание программы')
    add_bullet(pdf, 'Описание исходного кода (депонируемые материалы)')
    add_bullet(pdf, 'Согласие на обработку персональных данных')
    add_bullet(pdf, 'Квитанция об уплате государственной пошлины (5 000 руб.)')
    pdf.ln(5)
    add_text(pdf, 'Дата составления: ' + datetime.now().strftime('%d.%m.%Y'), 11, True)

    # ===== СТРАНИЦА 2 — ЗАЯВЛЕНИЕ =====
    pdf.add_page()
    add_title(pdf, 'ЗАЯВЛЕНИЕ\nо регистрации программы для ЭВМ', 14)
    add_subtitle(pdf, '(форма РП, Приложение N 1 к Приказу Минэкономразвития России N 211)')
    pdf.ln(5)

    add_section(pdf, '1. ЗАЯВИТЕЛЬ (ПРАВООБЛАДАТЕЛЬ)')
    add_field_row(pdf, 'Полное наименование', 'Индивидуальный предприниматель\nМорозов Максим Игоревич')
    add_field_row(pdf, 'ОГРНИП', '326745600046657')
    add_field_row(pdf, 'ИНН', '745013371800')
    add_field_row(pdf, 'Местонахождение', '454031, Челябинская обл., г. Челябинск,\nш. Металлургов, д. 20А, кв. 64')
    add_field_row(pdf, 'Гражданство', 'Российская Федерация')
    add_field_row(pdf, 'Телефон', '(указать)')
    add_field_row(pdf, 'Email', 'CHIK174@YANDEX.RU')

    pdf.ln(3)
    add_section(pdf, '2. ОСНОВАНИЯ ВОЗНИКНОВЕНИЯ ПРАВ')
    add_field_row(pdf, 'Основание', 'Авторство — заявитель является автором программы\n(создана самостоятельно, не в порядке служебных обязанностей)')

    pdf.ln(3)
    add_section(pdf, '3. СВЕДЕНИЯ О ПРОГРАММЕ')
    add_field_row(pdf, 'Название', 'MESTRO')
    add_field_row(pdf, 'Полное название', 'MESTRO (Мастер, Единый Стандарт Точности Расчёта Объекта)')
    add_field_row(pdf, 'Версия', '1.0.0')
    add_field_row(pdf, 'Год создания', '2026')
    add_field_row(pdf, 'Класс МПК', '(заполняется при экспертизой — G06Q 10/06, G06Q 50/08)')

    pdf.ln(3)
    add_section(pdf, '4. АВТОРЫ ПРОГРАММЫ')
    add_field_row(pdf, 'ФИО', 'Морозов Максим Игоревич')
    add_field_row(pdf, 'Дата рождения', '(указать)')
    add_field_row(pdf, 'Место жительства', 'Челябинская обл., г. Челябинск')
    add_field_row(pdf, 'Вклад в разработку', 'Полный цикл разработки: проектирование архитектуры,\nпрограммирование, тестирование, дизайн интерфейсов')

    pdf.ln(3)
    add_section(pdf, '5. ПЕРВЫЙ ВЫПУСК В СВЕТ')
    add_field_row(pdf, 'Дата', '(указать дату первого запуска/публикации)')
    add_field_row(pdf, 'Страна', 'Российская Федерация')

    pdf.ln(5)
    add_text(pdf, 'Примечание: Поля, отмеченные «(указать)», необходимо заполнить самостоятельно при подаче.', 9, True)

    # ===== СТРАНИЦА 3 — РЕФЕРАТ =====
    pdf.add_page()
    add_title(pdf, 'РЕФЕРАТ', 16)
    add_subtitle(pdf, 'программы для ЭВМ «MESTRO»')
    pdf.ln(3)

    add_field_row(pdf, 'Наименование', 'MESTRO (Мастер, Единый Стандарт Точности Расчёта Объекта)')
    add_field_row(pdf, 'Версия', '1.0.0')
    add_field_row(pdf, 'Правообладатель', 'ИП Морозов Максим Игоревич\nОГРНИП: 326745600046657\nИНН: 745013371800')
    pdf.ln(3)

    add_section(pdf, '1. НАЗНАЧЕНИЕ ПРОГРАММЫ')
    add_text(pdf, 'MESTRO — мобильное приложение для выездных специалистов-замерщиков, '
             'работающих в сфере строительства, ремонта и отделки. Программа автоматизирует полный цикл работы мастера: '
             'от создания заявки на замер до формирования коммерческого предложения с расчётом стоимости работ.')
    add_text(pdf, 'Приложение работает в офлайн-режиме на мобильных устройствах под управлением Android и iOS.')

    add_section(pdf, '2. ОБЛАСТЬ ПРИМЕННЕНИЯ')
    add_text(pdf, 'Программа применяется в следующих отраслях:')
    add_bullet(pdf, 'Остекление и оконные системы')
    add_bullet(pdf, 'Дверные конструкции')
    add_bullet(pdf, 'Климатическое оборудование (кондиционеры, вентиляция)')
    add_bullet(pdf, 'Кухонные гарнитуры и мебель')
    add_bullet(pdf, 'Плиточные и отделочные работы')
    add_bullet(pdf, 'Инженерные коммуникации (отопление, водоснабжение, канализация)')
    add_bullet(pdf, 'Электромонтажные работы')
    add_bullet(pdf, 'Строительство и проектирование')

    add_section(pdf, '3. ФУНКЦИОНАЛЬНЫЕ ВОЗМОЖНОСТИ')
    add_text(pdf, 'Основные функции программы:', bold=True)
    add_bullet(pdf, 'Система заявок — создание, редактирование, удаление заявок с привязкой клиента и статуса')
    add_bullet(pdf, 'Динамические чек-листы — конфигурируемые формы с условной видимостью полей')
    add_bullet(pdf, 'Фотофиксация — съёмка с аннотациями (стрелки, круги, текст) и GPS-привязкой')
    add_bullet(pdf, 'Калькулятор стоимости — автоматический расчёт по формулам из прайс-листа')
    add_bullet(pdf, 'Генератор планов помещений — AI-оптимизация (TensorFlow Lite), Rule Engine по СНиП')
    add_bullet(pdf, 'Голосовой ввод — распознавание речи с извлечением данных через регулярные выражения')
    add_bullet(pdf, 'Календарь замеров — визуальное планирование с push-уведомлениями')
    add_bullet(pdf, 'Статистика и аналитика — финансовые сводки, топ клиентов, статистика по месяцам')
    add_bullet(pdf, 'Управление платежами — фиксация оплат, подсчёт задолженности')
    add_bullet(pdf, 'Экспорт данных — выгрузка заявок в Excel, резервное копирование базы данных')
    add_bullet(pdf, 'Генерация PDF — коммерческие предложения с фото, планами и расчётом стоимости')

    # ===== СТРАНИЦА 4 — ТЕХ. СТЕК И УНИКАЛЬНОСТЬ =====
    pdf.add_page()
    add_section(pdf, '4. ТЕХНОЛОГИЧЕСКИЙ СТЕК')
    add_text(pdf, 'Программа разработана на кроссплатформенном фреймворке Flutter (язык Dart):')
    add_bullet(pdf, 'Архитектура: BLoC (Business Logic Component)')
    add_bullet(pdf, 'База данных: SQLite (sqflite, версия схемы 8)')
    add_bullet(pdf, 'Голосовой ввод: speech_to_text')
    add_bullet(pdf, 'Геолокация: geolocator')
    add_bullet(pdf, 'Генерация PDF: pdf + printing')
    add_bullet(pdf, 'Экспорт Excel: excel')
    add_bullet(pdf, 'ИИ-модель: TensorFlow Lite (tflite_flutter)')
    add_bullet(pdf, 'Уведомления: flutter_local_notifications')
    add_bullet(pdf, 'Календарь: table_calendar')

    add_section(pdf, '5. УНИКАЛЬНЫЕ ОСОБЕННОСТИ')
    add_bullet(pdf, 'AI-генератор планов помещений — on-device модель TensorFlow Lite для автоматической оптимизации планировок')
    add_bullet(pdf, 'Rule Engine — автоматическая генерация плана по размерам из чек-листа с учётом СНиП')
    add_bullet(pdf, 'Голосовой ввод — распознавание речи с автоматическим извлечением структурированных данных через regex')
    add_bullet(pdf, 'Динамические чек-листы — условная видимость полей в зависимости от контекста замера')
    add_bullet(pdf, 'Формульный расчёт — каждая позиция прайс-листа имеет математическую формулу для расчёта количества')
    add_bullet(pdf, 'Полный офлайн-режим — не требует сетевого подключения после регистрации')

    add_section(pdf, '6. ЯЗЫКИ И ТРЕБОВАНИЯ К СИСТЕМЕ')
    add_field_row(pdf, 'Язык интерфейса', 'Русский')
    add_field_row(pdf, 'Операционная система', 'Android 8.0+ или iOS 12.0+')
    add_field_row(pdf, 'Место на устройстве', 'Не менее 200 МБ')
    add_field_row(pdf, 'Разрешения', 'Камера, микрофон, геолокация')

    # ===== СТРАНИЦА 5 — ОПИСАНИЕ ИСХОДНОГО КОДА =====
    pdf.add_page()
    add_title(pdf, 'ОПИСАНИЕ ИСХОДНОГО КОДА', 14)
    add_subtitle(pdf, '(депонируемые материалы)')
    pdf.ln(3)

    add_section(pdf, '1. ОБЩИЕ СВЕДЕНИЯ')
    add_field_row(pdf, 'Язык программирования', 'Dart')
    add_field_row(pdf, 'Фреймворк', 'Flutter SDK ^3.10.4')
    add_field_row(pdf, 'Объём исходного кода', '~15 000 строк кода (основные модули)')
    add_field_row(pdf, 'База данных', 'SQLite (схема версии 8)')
    add_field_row(pdf, 'Количество таблиц БД', '6 (orders, users, photo_annotations, notifications, custom_prices, payments)')
    pdf.ln(3)

    add_section(pdf, '2. СТРУКТУРА ПРОЕКТА')
    add_text(pdf, 'Архитектура приложения построена на паттерне BLoC (Business Logic Component) с использованием репозиторий-паттерна:', bold=True)
    pdf.ln(2)

    # Структура модулей
    modules = [
        ('lib/main.dart', 'Точка входа, маршрутизация, инициализация зависимостей'),
        ('lib/models/', 'Модели данных: User, Order, Checklist, PriceItem, FloorPlan'),
        ('lib/bloc/', 'Компоненты бизнес-логики: OrderBloc, ChecklistBloc, CalendarBloc'),
        ('lib/database/', 'DatabaseHelper — работа с SQLite, миграции схемы (1-8)'),
        ('lib/repositories/', 'Репозитории: OrderRepository, UserRepository (абстракции и реализации)'),
        ('lib/screens/', 'Экраны приложения: регистрация, заявки, чек-листы, профиль'),
        ('lib/services/', 'Сервисы: PriceListService, PriceListExcelService, CostCalculator, PDFGenerator'),
        ('lib/utils/', 'Утилиты: калькулятор стоимости, генератор PDF, валидаторы'),
        ('lib/features/', 'Модули: floor_plan (планировки), voice (голосовой ввод), calendar, notifications'),
        ('assets/checklists/', 'JSON-шаблоны чек-листов для 8 специализаций'),
        ('assets/prices/', 'JSON-прайслисты для 8 специализаций'),
    ]

    for path, desc in modules:
        pdf.set_font('Corp', '', 10)
        pdf.set_text_color(80, 80, 80)
        pdf.cell(5, 6, '')
        pdf.set_font('Corp', 'B', 10)
        pdf.set_text_color(52, 73, 94)
        x_path = pdf.get_x()
        pdf.cell(55, 6, path)
        pdf.set_font('Corp', '', 10)
        pdf.set_text_color(44, 62, 80)
        pdf.multi_cell(115, 6, f'— {desc}')
        pdf.ln(1)

    add_section(pdf, '3. ТАБЛИЦЫ БАЗЫ ДАННЫХ')
    tables = [
        ('orders', 'Заявки на замер: клиент, адрес, дата, статус, тип работ, данные чек-листа, стоимость, план помещения'),
        ('users', 'Пользователи: телефон, ФИО, дата/версия согласия, типы работ, аватар'),
        ('photo_annotations', 'Фото с аннотациями: путь к файлу, аннотированная версия, GPS-координаты'),
        ('notifications', 'Уведомления: ID заявки, шаблон, время, статус, текст'),
        ('custom_prices', 'Кастомные цены: тип работ, ID позиции, название, единица, цена, формула'),
        ('payments', 'Платежи: ID заявки, сумма, дата, описание'),
    ]
    for name, desc in tables:
        pdf.set_font('Corp', 'B', 10)
        pdf.set_text_color(52, 73, 94)
        pdf.cell(5, 6, '')
        pdf.cell(40, 6, name)
        pdf.set_font('Corp', '', 10)
        pdf.set_text_color(44, 62, 80)
        pdf.multi_cell(130, 6, f'— {desc}')
        pdf.ln(1)

    add_section(pdf, '4. КЛЮЧЕВЫЕ МОДУЛИ')

    key_modules = [
        ('CostCalculator', 'Расчёт стоимости для 8 специализаций. Формульный расчёт количества, применение прайс-листа, обработка скидок и коэффициентов.'),
        ('FloorPlanEngine', 'Rule Engine для генерации планов помещений. 10 типов комнат, валидация СНиП, drag & drop, undo/redo (50 состояний).'),
        ('VoiceInputParser', 'Парсер голосового ввода. Регулярные выражения для извлечения размеров, типов, количеств из речи на русском языке.'),
        ('PDFGenerator', 'Генерация коммерческих предложений: данные чек-листа, фото с аннотациями, план помещения, расчёт стоимости, кириллица.'),
        ('DatabaseHelper', 'Управление SQLite: создание, миграции (v1-v8), CRUD-операции, резервное копирование.'),
        ('OrderBloc', 'Управление заявками: загрузка, создание, обновление, удаление, optimistic updates.'),
        ('ChecklistBloc', 'Управление чек-листами: загрузка JSON, сохранение данных, валидация, фотофиксация.'),
    ]

    for name, desc in key_modules:
        pdf.set_font('Corp', 'B', 10)
        pdf.set_text_color(52, 73, 94)
        pdf.cell(5, 6, '')
        pdf.cell(40, 6, name)
        pdf.set_font('Corp', '', 10)
        pdf.set_text_color(44, 62, 80)
        pdf.multi_cell(130, 6, f'— {desc}')
        pdf.ln(1)

    add_section(pdf, '5. ФОРМАТ ДЕПОНИРОВАНИЯ')
    add_text(pdf, 'Исходный код предоставляется в виде распечатки ключевых модулей, достаточных для однозначной идентификации программы. '
             'Полный исходный код не требуется (п. 23 Приказа N 211).')
    pdf.ln(3)
    add_text(pdf, 'Депонируемые материалы включают:', bold=True)
    add_bullet(pdf, 'Распечатка основных модулей: main.dart, database_helper.dart, cost_calculator.dart, floor_plan engine')
    add_bullet(pdf, 'Распечатка BLoC компонентов: order_bloc.dart, checklist_bloc.dart')
    add_bullet(pdf, 'Распечатка моделей данных: order.dart, user.dart, price_item.dart')
    add_bullet(pdf, 'Описание архитектуры и структуры проекта (настоящий документ)')

    # ===== СТРАНИЦА 6 — ИНСТРУКЦИЯ ПО ПОДАЧЕ =====
    pdf.add_page()
    add_title(pdf, 'ИНСТРУКЦИЯ ПО ПОДАЧЕ ДОКУМЕНТОВ', 14)
    add_subtitle(pdf, 'в Роспатент (ФИПС)')
    pdf.ln(3)

    add_section(pdf, 'ШАГ 1. ПОЛУЧЕНИЕ ЭЛЕКТРОННОЙ ПОДПИСИ (УКЭП)')
    add_text(pdf, 'Для подачи документов в электронном виде необходимо получить усиленную квалифицированную электронную подпись (УКЭП). '
             'Это можно сделать в любом аккредитованном удостоверяющем центре.')

    add_section(pdf, 'ШАГ 2. ОПЛАТА ГОШЛИНЫ')
    add_text(pdf, 'Государственная пошлина за регистрацию программы для ЭВМ:', bold=True)
    add_bullet(pdf, 'Основная пошлина: 5 000 рублей')
    add_bullet(pdf, 'Реквизиты для оплаты: на сайте ФИПС (fips.ru) в разделе «Госпошлины»')
    add_bullet(pdf, 'После оплаты — сохранить квитанцию (платёжное поручение)')

    add_section(pdf, 'ШАГ 3. ПОДГОТОВКА ДОКУМЕНТОВ')
    add_text(pdf, 'Необходимые документы:')
    add_bullet(pdf, 'Заявление по форме РП (заполнено в этом пакете, проверьте поля «(указать)»)')
    add_bullet(pdf, 'Реферат (включён в этот пакет)')
    add_bullet(pdf, 'Описание исходного кода (включено в этот пакет)')
    add_bullet(pdf, 'Согласие на обработку персональных данных (отдельный PDF)')
    add_bullet(pdf, 'Квитанция об уплате пошлины (после оплаты)')

    add_section(pdf, 'ШАГ 4. ПОДАЧА ЗАЯВКИ')
    add_text(pdf, 'Способы подачи:', bold=True)
    add_bullet(pdf, 'Электронно (рекомендуется): через личный кабинет ФИПС (fips.ru), подписав УКЭП')
    add_bullet(pdf, 'Почтой: заказным письмом по адресу: 123995, г. Москва, Г-59, ГСП-5, Бережковская наб., 30, корп. 1')
    add_bullet(pdf, 'Лично: экспедиция Роспатента по тому же адресу')

    add_section(pdf, 'ШАГ 5. СРОКИ И РЕЗУЛЬТАТ')
    add_field_row(pdf, 'Срок рассмотрения', '1 месяц (формальная экспертиза)')
    add_field_row(pdf, 'Результат', 'Свидетельство о государственной регистрации программы для ЭВМ')
    add_field_row(pdf, 'Срок действия', 'Весь срок действия авторских прав (жизнь автора + 70 лет)')

    pdf.ln(5)
    add_section(pdf, 'ПОЛЕЗНЫЕ ССЫЛКИ')
    add_bullet(pdf, 'Официальный сайт ФИПС: www.fips.ru')
    add_bullet(pdf, 'Личный кабинет заявителя: lk.fips.ru')
    add_bullet(pdf, 'Приказ Минэкономразвития N 211: регистрация программ для ЭВМ')
    add_bullet(pdf, 'Госпошлины: раздел на сайте ФИПС')

    pdf.ln(5)
    pdf.set_draw_color(255, 193, 7)
    pdf.set_line_width(1)
    pdf.rect(15, pdf.get_y(), 180, 0.5)
    pdf.ln(5)
    add_text(pdf, 'Внимание: Поля, отмеченные «(указать)», необходимо заполнить самостоятельно. '
             'Дата рождения автора и точная дата первого выпуска программы — обязательные поля в заявлении.', 10, True)

    output_path = r'c:\ИП Морозов\Пакет документов Роспатент.pdf'
    pdf.output(output_path)
    print(f'Пакет документов сохранён: {output_path}')
    print(f'Всего страниц: {pdf.page_no()}')


if __name__ == '__main__':
    print('Генерация пакета документов для Роспатента...')
    generate_application_package()
    print('Готово!')
