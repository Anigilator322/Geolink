# Authentication (OTP) - Mock Mode

## Overview
First iteration implements **email-based OTP (One-Time Password) authentication** with mock data.

### Architecture

#### Backend (ASP.NET Core)
- **AuthController** (`Geolink.API/Controllers/AuthController.cs`)
  - `POST /api/auth/send-code` - Request OTP code
  - `POST /api/auth/verify-code` - Verify OTP code
  - `POST /api/auth/refresh` - Refresh access token

- **AuthService** (`Geolink.Infrastructure/Services/AuthService.cs`)
  - `SendCodeAsync()` - Generate OTP and send via email
  - `VerifyCodeAsync()` - Validate OTP and issue JWT tokens
  - `RefreshTokenAsync()` - Issue new access token using refresh token

- **Supporting Services**
  - `ITokenService` - JWT token generation and validation
  - `IEmailOtpService` - OTP generation and verification (Redis cache)
  - `IUserRepository` - User data access

#### Frontend (Flutter)
- **AuthService** (`lib/services/auth_service.dart`)
  - Mock API client that works without real backend
  - Accepts any 6-digit code during testing
  - Can be switched to real API by providing ApiClient baseUrl

- **SecureStorageService** (`lib/services/secure_storage_service.dart`)
  - Secure token storage using `flutter_secure_storage`
  - Stores: accessToken, refreshToken, userId, email, username

- **AuthProvider** (`lib/providers/auth_provider.dart`)
  - State management with Provider package
  - Handles login flow and state transitions
  - States: initial, loading, authenticated, error

- **UI Screens**
  - `SendCodeScreen` - Email input
  - `VerifyCodeScreen` - 6-digit OTP input
  - `HomeScreen` - Authenticated user view

## How to Test (Mock Mode)

### Flutter Mobile App

1. **Start the app**
   ```bash
   cd Geolink.Mobile
   flutter pub get
   flutter run
   ```

2. **Test Login Flow**
   - **Send Code Screen**: Enter any email (e.g., `test@example.com`)
   - Click "Send Code"
   - **Verify Code Screen**: Enter any 6-digit code (e.g., `123456`)
   - Click "Verify"
   - **Success**: You'll see the Home Screen with user details

3. **Expected States**
   - **Loading State**: Button shows spinner during API calls
   - **Error State**: Red error box displays error messages
   - **Normal State**: Form accepts input and shows success
   - **Empty State**: App shows login form when logged out

4. **Test Logout**
   - On Home Screen, click "Logout" button
   - App returns to login screen
   - Storage is cleared

5. **Persistent Login**
   - Login successfully
   - Close and reopen the app
   - You should remain logged in (token stored securely)

## Mock Implementation Details

### Backend (if API is running)

#### Send Code API
**Request:**
```json
POST /api/auth/send-code
{
  "email": "user@example.com"
}
```

**Response (Success):**
```json
{
  "message": "Code sent to email"
}
```

#### Verify Code API
**Request:**
```json
POST /api/auth/verify-code
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response (Success):**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "username": "user",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...",
  "expiresAt": "2026-03-10T14:30:00Z"
}
```

### Frontend Mock Mode
- **AuthService** automatically detects when `apiClient` is null
- Returns mock responses immediately (with 1-second delay to simulate network)
- Accepts any 6-digit code for verification
- No real API calls made

### Switching to Real API
1. Uncomment in `lib/main.dart`:
   ```dart
   apiClient: ApiClient(baseUrl: 'http://localhost:5000'),
   ```
2. Real API calls will be made to backend
3. Backend must be running with Redis for OTP caching

## File Structure

```
Geolink.API/
├── Controllers/
│   └── AuthController.cs          # API endpoints
├── Hubs/
│   └── GeolinkHub.cs              # SignalR hub
└── Program.cs                      # Configuration

Geolink.Application/
├── DTOs/Auth/
│   └── AuthDtos.cs                # Data transfer objects
├── Interfaces/
│   ├── IAuthService.cs            # Auth service interface
│   ├── IEmailOtpService.cs
│   ├── ITokenService.cs
│   └── ...other interfaces...
└── Common/
    └── Result.cs                  # Result wrapper

Geolink.Infrastructure/
├── Services/
│   ├── AuthService.cs             # Auth business logic
│   ├── TokenService.cs
│   ├── EmailOtpService.cs
│   └── ConsoleEmailSender.cs
├── Repositories/
│   ├── UserRepository.cs
│   └── ...other repositories...
└── Data/
    └── GeolinkDbContext.cs        # Database context

Geolink.Domain/
├── Entities/
│   ├── User.cs
│   ├── RefreshToken.cs
│   └── ...other entities...
└── Enums/
    └── ...enums...

Geolink.Mobile/
└── lib/
    ├── main.dart                  # App entry point
    ├── models/
    │   ├── auth_response.dart
    │   └── user.dart
    ├── services/
    │   ├── auth_service.dart
    │   └── secure_storage_service.dart
    ├── providers/
    │   └── auth_provider.dart
    └── screens/
        ├── home_screen.dart
        └── auth/
            ├── send_code_screen.dart
            └── verify_code_screen.dart
```

## Key Features Implemented

✅ **Send OTP** - Request code via email  
✅ **Verify OTP** - Validate code and authenticate  
✅ **Token Management** - JWT access/refresh tokens  
✅ **Secure Storage** - Platform-specific secure token storage  
✅ **State Management** - Provider with loading/error/success states  
✅ **Error Handling** - User-friendly error messages  
✅ **Persistent Login** - Tokens survive app restarts  
✅ **User Logout** - Clear tokens and session  
✅ **Mock Mode** - Works without backend during development  

## Environment Configuration

### Backend (appsettings.json)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=geolink;...",
    "Redis": "localhost:6379"
  },
  "Jwt": {
    "Key": "your-secret-key-minimum-32-bytes",
    "Issuer": "geolink-api",
    "Audience": "geolink-app",
    "AccessTokenExpirationMinutes": 60,
    "RefreshTokenExpirationDays": 7
  }
}
```

### Frontend (pubspec.yaml)
Key dependencies:
- `provider: ^6.0.0` - State management
- `http: ^1.1.0` - HTTP client
- `flutter_secure_storage: ^9.0.0` - Secure token storage

## Next Steps
1. Implement location sharing feature
2. Add friend management
3. Implement events creation and participation
4. Add real-time location updates via SignalR
5. Implement event notifications
