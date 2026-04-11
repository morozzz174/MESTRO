"""
Скрипт для генерации PDF документов для ИП Морозов М.И.
1. Карточка предприятия (с банковскими реквизитами и QR-кодом)
2. Согласие на обработку персональных данных
"""

from fpdf import FPDF
from datetime import datetime
import qrcode
import io
import tempfile
import os


class BasePDF(FPDF):
    def __init__(self):
        super().__init__()
        # Segoe UI - красивый современный шрифт
        self.add_font('Corp', '', 'c:/Windows/Fonts/segoeui.ttf')
        self.add_font('Corp', 'B', 'c:/Windows/Fonts/segoeuib.ttf')
        self.add_font('Corp', 'I', 'c:/Windows/Fonts/segoeuii.ttf')
        self.add_font('CorpLight', '', 'c:/Windows/Fonts/segoeuil.ttf')


class CardPDF(BasePDF):
    def header(self):
        # Цветная полоса сверху
        self.set_fill_color(44, 62, 80)
        self.rect(0, 0, 210, 35, 'F')
        
        self.set_y(6)
        self.set_font('Corp', 'B', 20)
        self.set_text_color(255, 255, 255)
        self.cell(0, 10, 'КАРТОЧКА ПРЕДПРИЯТИЯ', new_x="LMARGIN", new_y="NEXT", align='C')
        
        self.set_font('CorpLight', '', 11)
        self.set_text_color(180, 200, 220)
        self.cell(0, 8, 'ИП Морозов Максим Игоревич', new_x="LMARGIN", new_y="NEXT", align='C')
        
        self.ln(12)

    def footer(self):
        self.set_y(-18)
        self.set_draw_color(200, 200, 200)
        self.set_line_width(0.3)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(4)
        self.set_font('Corp', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, f'Сформировано: {datetime.now().strftime("%d.%m.%Y")}  |  Страница {self.page_no()}/{{nb}}', align='C')


class ConsentPDF(BasePDF):
    def header(self):
        self.set_font('Corp', 'B', 14)
        self.set_text_color(33, 33, 33)
        self.cell(0, 10, 'СОГЛАСИЕ НА ОБРАБОТКУ ПЕРСОНАЛЬНЫХ ДАННЫХ', new_x="LMARGIN", new_y="NEXT", align='C')
        self.set_font('Corp', '', 11)
        self.cell(0, 8, '(в соответствии с Федеральным законом от 27.07.2006 N 152-ФЗ)', new_x="LMARGIN", new_y="NEXT", align='C')
        self.ln(3)
        self.set_draw_color(52, 73, 94)
        self.set_line_width(0.8)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(8)

    def footer(self):
        self.set_y(-20)
        self.set_draw_color(200, 200, 200)
        self.set_line_width(0.3)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(5)
        self.set_font('Corp', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, f'ИП Морозов М.И.  |  Сформировано: {datetime.now().strftime("%d.%m.%Y")}  |  Страница {self.page_no()}/{{nb}}', align='C')


def add_section_title(pdf, title):
    pdf.ln(3)
    pdf.set_font('Corp', 'B', 11)
    pdf.set_text_color(52, 73, 94)
    pdf.set_fill_color(236, 240, 241)
    pdf.cell(0, 8, f'  {title}', new_x="LMARGIN", new_y="NEXT", fill=True)
    pdf.ln(3)


def add_info_row(pdf, label, value):
    x_start = pdf.get_x()
    y_start = pdf.get_y()
    
    # Метка
    pdf.set_font('Corp', 'B', 10)
    pdf.set_text_color(52, 73, 94)
    pdf.multi_cell(65, 6, f'{label}:', border=0)
    y_after_label = pdf.get_y()
    
    # Значение
    pdf.set_xy(x_start + 65, y_start)
    pdf.set_font('Corp', '', 10)
    pdf.set_text_color(44, 62, 80)
    pdf.multi_cell(115, 6, value, border=0)
    
    pdf.set_y(max(y_after_label, pdf.get_y()))
    pdf.ln(3)


def draw_rounded_rect(pdf, x, y, w, h, r):
    """Рисуем прямоугольник со скруглёнными углами"""
    # Верхняя линия
    pdf.line(x + r, y, x + w - r, y)
    # Правая
    pdf.line(x + w, y + r, x + w, y + h - r)
    # Нижняя
    pdf.line(x + r, y + h, x + w - r, y + h)
    # Левая
    pdf.line(x, y + r, x, y + h - r)
    # Углы (дуги)
    pdf.arc(x + w - 2 * r, y, x + w, y + 2 * r, 0, 90)
    pdf.arc(x + w - 2 * r, y + h - 2 * r, x + w, y + h, 90, 180)
    pdf.arc(x, y + h - 2 * r, x + 2 * r, y + h, 180, 270)
    pdf.arc(x, y, x + 2 * r, y + 2 * r, 270, 360)


def add_section(pdf, title, content_pairs, y_start=None):
    """Добавляем секцию с заголовком и содержимым"""
    if y_start:
        pdf.set_y(y_start)
    
    # Заголовок секции с фоном
    pdf.set_font('Corp', 'B', 12)
    pdf.set_text_color(255, 255, 255)
    pdf.set_fill_color(44, 62, 80)
    pdf.cell(0, 9, f'  {title}', new_x="LMARGIN", new_y="NEXT", fill=True)
    pdf.ln(2)
    
    # Содержимое
    for label, value in content_pairs:
        pdf.set_font('Corp', 'B', 11)
        pdf.set_text_color(52, 73, 94)
        pdf.cell(0, 7, label, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font('Corp', '', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.cell(0, 7, value, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(1)
    
    pdf.ln(2)


def generate_card():
    pdf = CardPDF()
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=25)
    pdf.set_left_margin(20)
    pdf.set_right_margin(20)
    
    # ===== ОСНОВНЫЕ СВЕДЕНИЯ =====
    add_section(pdf, 'ОСНОВНЫЕ СВЕДЕНИЯ', [
        ('Полное наименование:', 'Индивидуальный предприниматель Морозов Максим Игоревич'),
        ('ИНН:', '745 013 371 800'),
        ('ОГРНИП:', '326 745 600 046 657'),
        ('Email:', 'CHIK174@YANDEX.RU'),
        ('Юридический адрес:', '454031, Челябинская обл, г. Челябинск, ш. Металлургов, д. 20А, кв. 64'),
    ])
    
    # ===== БАНКОВСКИЕ РЕКВИЗИТЫ =====
    add_section(pdf, 'БАНКОВСКИЕ РЕКВИЗИТЫ', [
        ('Банк:', 'АО «ТБанк»'),
        ('Расчётный счёт:', '4080 2810 7000 0942 8805'),
        ('БИК:', '044 525 974'),
        ('Корр. счёт:', '3010 1810 1452 5000 0974'),
    ])
    
    # ===== ОСНОВНОЙ ОКВЭД =====
    pdf.set_font('Corp', 'B', 12)
    pdf.set_text_color(255, 255, 255)
    pdf.set_fill_color(44, 62, 80)
    pdf.cell(0, 9, '  ОСНОВНОЙ ОКВЭД', new_x="LMARGIN", new_y="NEXT", fill=True)
    pdf.ln(2)
    
    pdf.set_font('Corp', 'B', 14)
    pdf.set_text_color(44, 62, 80)
    pdf.cell(0, 9, '46.74', new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_font('Corp', '', 11)
    pdf.set_text_color(80, 80, 80)
    pdf.multi_cell(0, 7, 'Торговля оптовая скобяными изделиями, водопроводным и отопительным оборудованием и принадлежностями')
    pdf.ln(5)
    
    # ===== QR-КОД =====
    qr_data = (
        "ИНН:745013371800|ОГРНИП:326745600046657|"
        "Р/с:40802810700009428805|БИК:044525974|"
        "К/с:30101810145250000974|Банк:АО ТБанк|"
        "ИНН_банка:7710140679|"
        "Адрес:454031,Челябинская обл,г.Челябинск,ш.Металлургов,д.20А,кв.64"
    )
    
    qr = qrcode.QRCode(version=4, box_size=10, border=2)
    qr.add_data(qr_data)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="#2C3E50", back_color="white")
    
    with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
        qr_img.save(tmp.name)
        tmp_path = tmp.name
    
    # QR-код в рамке справа
    qr_size = 35
    qr_x = 150
    qr_y = pdf.get_y() + 5
    
    # Рамка вокруг QR
    pdf.set_draw_color(44, 62, 80)
    pdf.set_line_width(0.5)
    pdf.rect(qr_x - 5, qr_y - 5, qr_size + 10, qr_size + 10)
    
    pdf.image(tmp_path, x=qr_x, y=qr_y, w=qr_size, h=qr_size)
    
    # Текст слева от QR
    pdf.set_xy(20, qr_y + 5)
    pdf.set_font('Corp', 'B', 16)
    pdf.set_text_color(44, 62, 80)
    pdf.cell(100, 10, 'Реквизиты для оплаты', new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_font('Corp', '', 11)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(100, 7, 'Отсканируйте QR-код для быстрого', new_x="LMARGIN", new_y="NEXT")
    pdf.cell(100, 7, 'получения банковских реквизитов', new_x="LMARGIN", new_y="NEXT")
    
    os.unlink(tmp_path)
    
    output_path = r'c:\ИП Морозов\Карточка_предприятия.pdf'
    pdf.output(output_path)
    print(f'Карточка предприятия сохранена: {output_path}')


def generate_consent():
    pdf = ConsentPDF()
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=25)
    pdf.set_left_margin(15)
    pdf.set_right_margin(15)
    
    pdf.set_font('Corp', '', 11)
    pdf.set_text_color(0, 0, 0)
    
    pdf.ln(5)
    
    # Вводный текст
    pdf.multi_cell(0, 6, 'Я, действуясь свободно, своей волей и в своем интересе, а также подтверждая свою дееспособность, даю свое согласие Индивидуальному предпринимателю Морозову Максиму Игоревичу (ОГРНИП 326745600046657, ИНН 745013371800, адрес: Челябинская область, г.о. Челябинский, г. Челябинск, email: CHIK174@YANDEX.RU), именуемому далее "Оператор", на обработку моих персональных данных на следующих условиях:')
    pdf.ln(5)
    
    # Секции согласия
    sections = [
        ('1. ОПРЕДЕЛЕНИЕ ПЕРСОНАЛЬНЫХ ДАННЫХ', [
            '1.1. Под персональными данными понимается любая информация, относящаяся к прямо или косвенно определенному или определяемому физическому лицу (субъекту персональных данных).',
        ]),
        ('2. СОСТАВ ПЕРСОНАЛЬНЫХ ДАННЫХ', [
            '2.1. Я даю согласие на обработку следующих персональных данных:',
            '\u2022 Фамилия, имя, отчество;',
            '\u2022 Контактный телефон;',
            '\u2022 Адрес электронной почты (e-mail);',
            '\u2022 Паспортные данные (серия, номер, кем и когда выдан);',
            '\u2022 Адрес регистрации/проживания;',
            '\u2022 Иная информация, предоставленная мною Оператору.',
        ]),
        ('3. ЦЕЛИ ОБРАБОТКИ ПЕРСОНАЛЬНЫХ ДАННЫХ', [
            '3.1. Обработка персональных данных осуществляется в следующих целях:',
            '\u2022 Заключение и исполнение договоров/соглашений;',
            '\u2022 Предоставление услуг и выполнение работ;',
            '\u2022 Связь с субъектом персональных данных;',
            '\u2022 Направление уведомлений и сообщений;',
            '\u2022 Обработка обращений и заявлений;',
            '\u2022 Улучшение качества обслуживания;',
            '\u2022 Иные цели, не запрещенные законодательством Российской Федерации.',
        ]),
        ('4. ПРАВОВЫЕ ОСНОВАНИЯ ОБРАБОТКИ', [
            '4.1. Оператор обрабатывает персональные данные на основании:',
            '\u2022 Федерального закона от 27.07.2006 N 152-ФЗ "О персональных данных";',
            '\u2022 Настоящего согласия, данного мною Оператору;',
            '\u2022 Договоров и соглашений, заключаемых между мною и Оператором.',
        ]),
        ('5. ДЕЙСТВИЯ С ПЕРСОНАЛЬНЫМИ ДАННЫМИ', [
            '5.1. Я даю согласие на совершение следующих действий с персональными данными:',
            '\u2022 Сбор, запись, систематизация, накопление;',
            '\u2022 Хранение, уточнение (обновление, изменение);',
            '\u2022 Извлечение, использование;',
            '\u2022 Удаление, уничтожение;',
            '\u2022 Передача третьим лицам только в случаях, предусмотренных законодательством РФ;',
            '\u2022 Обработка с использованием средств автоматизации и без их использования.',
        ]),
        ('6. СРОК ДЕЙСТВИЯ СОГЛАСИЯ', [
            '6.1. Настоящее согласие действует в течение срока, необходимого для достижения целей обработки персональных данных, или до момента отзыва согласия.',
            '6.2. Я вправе отозвать настоящее согласие, направив Оператору письменное заявление по адресу: Челябинская область, г.о. Челябинский, г. Челябинск, или на электронный адрес: CHIK174@YANDEX.RU.',
            '6.3. В случае отзыва согласия Оператор вправе продолжить обработку персональных данных без моего согласия при наличии оснований, указанных в статье 6, частях 2-11 статьи 10 и части 2 статьи 11 Федерального закона от 27.07.2006 N 152-ФЗ "О персональных данных".',
        ]),
        ('7. ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ', [
            '7.1. Настоящее согласие действует бессрочно до момента его отзыва в порядке, предусмотренном действующим законодательством.',
            '7.2. Оператор обеспечивает защиту обрабатываемых персональных данных от несанкционированного доступа и разглашения в соответствии с требованиями Федерального закона от 27.07.2006 N 152-ФЗ "О персональных данных".',
        ]),
    ]
    
    for section_title, section_items in sections:
        pdf.set_font('Corp', 'B', 11)
        pdf.set_text_color(52, 73, 94)
        pdf.cell(0, 8, section_title, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        for item in section_items:
            pdf.set_font('Corp', '', 10)
            pdf.set_text_color(0, 0, 0)
            if item.startswith('\u2022'):
                pdf.set_x(20)
                pdf.multi_cell(170, 5.5, item)
            else:
                pdf.multi_cell(0, 5.5, item)
            pdf.ln(1)
        pdf.ln(3)
    
    # Блок подписи
    pdf.ln(5)
    pdf.set_draw_color(52, 73, 94)
    pdf.set_line_width(0.5)
    pdf.line(15, pdf.get_y(), 195, pdf.get_y())
    pdf.ln(8)
    
    pdf.set_font('Corp', 'B', 11)
    pdf.set_text_color(44, 62, 80)
    pdf.cell(0, 8, 'ПОДПИСИ СТОРОН:', new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)

    # Субъект
    pdf.set_font('Corp', 'B', 10)
    pdf.set_text_color(0, 0, 0)
    pdf.cell(90, 7, 'СУБЪЕКТ ПЕРСОНАЛЬНЫХ ДАННЫХ:', new_x="END")
    pdf.cell(90, 7, 'ОПЕРАТОР:', new_x="LMARGIN", new_y="NEXT")
    pdf.ln(3)

    pdf.set_font('Corp', '', 10)
    pdf.set_text_color(0, 0, 0)
    
    # Левая колонка - Субъект
    x_left = pdf.get_x()
    y_start = pdf.get_y()
    
    pdf.set_xy(x_left, y_start)
    pdf.cell(85, 7, 'ФИО: ________________________________')
    pdf.ln(10)
    pdf.cell(85, 7, 'Подпись: _____________________________')
    pdf.ln(10)
    pdf.cell(85, 7, 'Дата: "____" _____________ 20___ г.')
    
    # Правая колонка - Оператор
    x_right = x_left + 95
    pdf.set_xy(x_right, y_start)
    pdf.cell(85, 7, 'ИП Морозов М.И.')
    pdf.ln(10)
    pdf.cell(85, 7, 'ОГРНИП 326745600046657')
    pdf.ln(7)
    pdf.cell(85, 7, 'ИНН 745013371800')
    pdf.ln(10)
    pdf.cell(85, 7, 'Подпись: ___________ / Морозов М.И.')
    pdf.ln(10)
    pdf.cell(85, 7, 'Дата: "____" _____________ 20___ г.')
    
    # Сохраняем
    output_path = r'c:\ИП Морозов\Согласие_на_обработку_персональных_данных.pdf'
    pdf.output(output_path)
    print(f'Согласие сохранено: {output_path}')


if __name__ == '__main__':
    print('Генерация документов...')
    generate_card()
    generate_consent()
    print('Готово! Оба документа сохранены в папку "c:\\ИП Морозов\\"')
