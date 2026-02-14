# Geolink

Геосоциальное мобильное приложение для iOS и Android.

## Возможности

- Добавление друзей
- Обмен геолокацией в реальном времени
- Просмотр друзей на карте
- Создание мероприятий на карте

## Структура проекта

| Папка | Описание |
|-------|----------|
| `Geolink.API/` | Backend API на .NET 9 |
| `Geolink.Application/` | Application Layer (Use Cases, DTOs) |
| `Geolink.Domain/` | Domain Layer (Entities, Enums) |
| `Geolink.Infrastructure/` | Infrastructure (EF Core, Redis) |
| `Geolink.Mobile/` | Мобильное приложение на Flutter |

## Быстрый старт с Docker

### Запуск всего стека (API + PostgreSQL + Redis)

```bash
docker-compose up -d
```

API будет доступен на http://localhost:5000

### Только инфраструктура (для локальной разработки)

```bash
docker-compose -f docker-compose.dev.yml up -d
```

Затем запустите API локально:
```bash
cd Geolink.API
dotnet run
```

### Доступные сервисы

| Сервис | URL | Описание |
|--------|-----|----------|
| API | http://localhost:5000 | Backend API |
| PostgreSQL | localhost:5432 | База данных |
| Redis | localhost:6379 | Кеш локаций |
| pgAdmin | http://localhost:5050 | UI для PostgreSQL (dev) |

pgAdmin credentials: `admin@geolink.com` / `admin`

### Остановка

```bash
docker-compose down
```

С удалением данных:
```bash
docker-compose down -v
```

## Локальная разработка

### Требования

- .NET 9 SDK
- Flutter SDK 3.x
- Docker (для БД и Redis)

### Backend

```bash
# Запустить инфраструктуру
docker-compose -f docker-compose.dev.yml up -d

# Применить миграции
dotnet ef database update -p Geolink.Infrastructure -s Geolink.API

# Запустить API
cd Geolink.API
dotnet run
```

### Mobile

```bash
cd Geolink.Mobile
flutter pub get
flutter run
```

## API Endpoints

| Модуль | Endpoints |
|--------|-----------|
| **Auth** | `POST /api/auth/register`, `/login`, `/refresh` |
| **Users** | `GET /api/users/me`, `PUT /api/users/me`, `GET /api/users/search` |
| **Friends** | `GET /api/friends`, `POST /api/friends/request`, `PUT /api/friends/{id}` |
| **Location** | `PUT /api/location`, SignalR Hub: `/hubs/geolink` |
| **Events** | `GET /api/events`, `POST /api/events`, `GET /api/events/nearby` |
