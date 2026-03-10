## Реализованный функционал

Реализован базовый сценарий OTP-авторизации пользователя.

**Backend (ASP.NET Core):**

* `POST /api/auth/send-code` — отправка кода подтверждения на email
* `POST /api/auth/verify-code` — проверка кода и выдача JWT-токенов
* `POST /api/auth/refresh` — обновление access token

**Frontend (Flutter):**

* экран ввода email
* экран ввода кода подтверждения
* хранение токенов с использованием `flutter_secure_storage`
* поддержка mock-режима для тестирования без backend

---

# Как протестировать

## 1. Запуск backend

```bash
cd Geolink.API
dotnet build
dotnet run
```

После запуска API будет доступен по адресу:

```
http://localhost:5169
```

---

## 2. Запуск мобильного приложения

```bash
cd Geolink.Mobile
flutter pub get
flutter run
```

---

# Реализованный сценарий (End-to-End)

1. Пользователь вводит email
2. API отправляет код подтверждения
3. Пользователь вводит код
4. API возвращает JWT токен
5. Токен используется для авторизации запросов

---

# Тестирование с backend

1. Ввести любой email (например `example@mail.ru`).
2. В консоли backend будет выведен код подтверждения (используется mock-EmailSender).
3. Ввести этот код в приложении.
4. После успешной проверки происходит авторизация пользователя.

---

# API Endpoints

## Отправка кода подтверждения

```
POST /api/auth/send-code
```

```json
{
  "email": "user@example.com"
}
```

Ответ:

```json
{
  "message": "Code sent to email"
}
```

---

## Проверка кода

```
POST /api/auth/verify-code
```

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

Ответ:

```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "username": "user",
  "accessToken": "...",
  "refreshToken": "...",
  "expiresAt": "timestamp"
}
```

---

## Обновление access-токена

```
POST /api/auth/refresh
```

```json
{
  "refreshToken": "..."
}
```

Ответ содержит новый `accessToken`.

---

# Использование токена

Полученный JWT-токен используется для доступа к защищённым endpoint’ам.

```
GET /api/protected-endpoint
Authorization: Bearer <accessToken>
```

