# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore
COPY ["Geolink.API/Geolink.API.csproj", "Geolink.API/"]
COPY ["Geolink.Application/Geolink.Application.csproj", "Geolink.Application/"]
COPY ["Geolink.Domain/Geolink.Domain.csproj", "Geolink.Domain/"]
COPY ["Geolink.Infrastructure/Geolink.Infrastructure.csproj", "Geolink.Infrastructure/"]
RUN dotnet restore "Geolink.API/Geolink.API.csproj"

# Copy everything and build
COPY . .
WORKDIR "/src/Geolink.API"
RUN dotnet build "Geolink.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Geolink.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Geolink.API.dll"]
