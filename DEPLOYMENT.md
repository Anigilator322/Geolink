# Deployment Modes

## Environment files

Create three files from `.env.example`:

- `.env.local`
- `.env.staging`
- `.env.prod`

All secrets must be different for `staging` and `prod`.

## 1) Local (active API development)

Only infrastructure runs in Docker (`postgres`, `redis`, optional `pgadmin`), API runs locally with `dotnet run`.

```bash
docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.dev.yml up -d
dotnet run --project Geolink.API
```

Stop:

```bash
docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.dev.yml down
```

## 2) Staging (mobile client development)

Full backend runs in Docker (`postgres`, `redis`, `api`).

```bash
docker compose --env-file .env.staging -f docker-compose.yml -f docker-compose.staging.yml up -d --build
```

Stop:

```bash
docker compose --env-file .env.staging -f docker-compose.yml -f docker-compose.staging.yml down
```

## 3) Production

Full backend runs in Docker with production keys/config values.

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

Stop:

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml down
```

## Notes

- API reads secrets from environment variables in `staging` and `prod`.
- `appsettings.Development.json` is only for local API launch.
- `postgres` and `redis` ports are published in `local`/`staging`, but not in `prod`.
