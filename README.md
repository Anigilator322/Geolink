# Geolink

Геосоциальное мобильное приложение для iOS и Android.

## Возможности

- Добавление друзей
- Обмен геолокацией в реальном времени
- Просмотр друзей на карте
- Создание мероприятий на карте

## ДЛЯ ПРОВЕРКИ
Сценарий - Просмотр друзей на карте
Только клиент, бек в разработке.
```bash
cd Geolink.Mobile
flutter pub get
```
Настроить env vars:
```bash
cp .env.example .env
```
Далее - если тестирование на эмуляторе
```bash
flutter emulators
flutter emulators --launch <Device_Id>
flutter run
```
Если на телефоне
```bash
flutter build apk
```
После чего apk с приложением будет доступно для установки. 
```
build/app/outputs/flutter-apk/app-release.apk
```
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
Настроить env vars:

```bash
cp .env.example .env
```
Далее
```bash
cd Geolink.Mobile
flutter pub get
flutter run
```

## Local Secrets Setup

```bash
# Create local env file for docker-compose
cp .env.example .env

# Configure API secrets (stored outside repo)
cd Geolink.API
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=geolink;Username=postgres;Password=<NEW_PASSWORD>"
dotnet user-secrets set "Jwt:Key" "<STRONG_RANDOM_KEY_32+>"
```

## Deployment Modes (updated)

See [DEPLOYMENT.md](DEPLOYMENT.md) for the current 3-mode workflow (`local`, `staging`, `prod`), env files, and Docker commands.
