# 🌐 Веб-страница удаления данных

## MESTRO — Запрос на удаление персональных данных

**URL для размещения:** `https://ваш-домен.ru/delete` или разместить на GitHub Pages

---

## 📝 HTML-код страницы

```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Удаление данных — MESTRO</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 500px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 16px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #0d1b2a; margin-top: 0; }
        .note {
            background: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        label { display: block; margin: 15px 0 5px; font-weight: 600; }
        input, textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            box-sizing: border-box;
        }
        button {
            background: #0d1b2a;
            color: white;
            border: none;
            padding: 15px 30px;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
            width: 100%;
        }
        button:hover { background: #1a2e40; }
        button:disabled { background: #ccc; cursor: not-allowed; }
        .success {
            background: #e8f5e9;
            color: #2e7d32;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
            display: none;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #666;
        }
        .footer a { color: #0d1b2a; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚫 Удаление персональных данных</h1>
        
        <p>Заполните форму для удаления всех ваших данных из приложения MESTRO.</p>
        
        <div class="note">
            <strong>📋 Какие данные будут удалены:</strong><br>
            • Заявки и замеры<br>
            • Фотографии и аннотации<br>
            • История платежей<br>
            • Настройки и прайс-листы<br>
            • Данные аккаунта
        </div>
        
        <form id="deleteForm">
            <label>Номер телефона (обязательно)</label>
            <input type="tel" name="phone" required placeholder="+7 (999) 000-00-00">
            
            <label>Email (указанный при регистрации)</label>
            <input type="email" name="email" placeholder="example@mail.ru">
            
            <label>Причина удаления (необязательно)</label>
            <textarea name="reason" rows="3" placeholder="Причина удаления аккаунта"></textarea>
            
            <button type="submit" id="submitBtn">Удалить мои данны��</button>
        </form>
        
        <div class="success" id="success">
            ✅ <strong>Запрос принят!</strong><br><br>
            Ваш запрос будет обработан в течение 30 дней.<br>
            На указанный email придёт подтверждение.
        </div>
        
        <div class="footer">
            <p>По вопросам: <a href="mailto:CHIK174@YANDEX.RU">CHIK174@YANDEX.RU</a></p>
            <p><a href="https://github.com/morozzz174/MESTRO/blob/main/assets/privacy_policy.md">Политика конфиденциальности</a></p>
        </div>
    </div>
    
    <script>
        document.getElementById('deleteForm').addEventListener('submit', function(e) {
            e.preventDefault();
            document.getElementById('submitBtn').disabled = true;
            document.getElementById('submitBtn').textContent = 'Отправка...';
            
            // Здесь должен быть код отправки на сервер
            // Для примера - показываем успех
            document.getElementById('success').style.display = 'block';
            document.getElementById('deleteForm').style.display = 'none';
        });
    </script>
</body>
</html>
```

---

## 📋 Инструкция по размещению

### Вариант 1: GitHub Pages

1. Создайте репозиторий `mestro-delete`
2. Загрузите файл `index.html`
3. Включите GitHub Pages в настройках
4. Получите URL: `https://ваш-username.github.io/mestro-delete`

### Вариант 2: Свой сервер

1. Разместите файл на вашем домене
2. Настройте отправку форм (PHP/CGI)

---

## 📧 Обработка запросов

### Метод 1: Email уведомление

Настройте отправку данных на email `CHIK174@YANDEX.RU`:

```
Тема: Запрос на удаление данных - MESTRO

Данные пользователя:
- Телефон: +7 XXX XXX-XX-XX
- Email: user@mail.ru
- Дата запроса: DD.MM.YYYY HH:MM

Действие: Удалить все данные пользователя
```

### Метод 2:База данных

Создайте таблицу `delete_requests`:

| Поле | Тип |
|------|-----|
| id | INTEGER PRIMARY KEY |
| phone | TEXT |
| email | TEXT |
| reason | TEXT |
| status | TEXT (pending/done) |
| created_at | DATETIME |

---

## 🔗 Ссылки для магазинов

После размещения добавьте ссылки:

| Магазин | Ссылка |
|---------|--------|
| Google Play | Data Safety → URL формы |
| RuStore | Информация о приложении |
| App Store | Privacy Policy |

---

**Дата:** Апрель 2026