# Security Settings

<cite>
**Referenced Files in This Document**
- [biometric_service.dart](file://lib/core/utils/biometric_service.dart)
- [secure_storage_service.dart](file://lib/core/storage/secure_storage_service.dart)
- [auth_interceptor.dart](file://lib/core/network/auth_interceptor.dart)
- [error_interceptor.dart](file://lib/core/network/error_interceptor.dart)
- [SessionAdminController.php](file://kyApp_API/app/Http/Controllers/SessionAdminController.php)
- [SessionPolicy.php](file://kyApp_API/app/Support/SessionPolicy.php)
- [PermissionCatalog.php](file://kyApp_API/app/Support/PermissionCatalog.php)
- [EnsurePermission.php](file://kyApp_API/app/Http/Middleware/EnsurePermission.php)
- [SettingsStore.php](file://kyApp_API/app/Support/SettingsStore.php)
- [AppConfigController.php](file://kyApp_API/app/Http/Controllers/AppConfigController.php)
- [api_password_dialog.dart](file://lib/features/auth/presentation/widgets/api_password_dialog.dart)
- [app_config_repository.dart](file://lib/features/app_config/data/repositories/app_config_repository.dart)
- [api_constants.dart](file://lib/core/constants/api_constants.dart)
- [login_screen.dart](file://lib/features/auth/presentation/screens/login_screen.dart)
</cite>

## Update Summary
**Changes Made**
- Added comprehensive API password protection system with server-side verification and local fallback
- Enhanced authentication flow with secure API settings access gate from login screen
- Integrated SHA-256 local hash storage for offline authentication capability
- Updated secure storage service with API password hash management methods
- Added new API endpoints for password verification and management
- Enhanced error handling for network connectivity scenarios

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [API Password Protection System](#api-password-protection-system)
7. [Dependency Analysis](#dependency-analysis)
8. [Performance Considerations](#performance-considerations)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Conclusion](#conclusion)

## Introduction
This document explains the security settings implementation across the mobile client and backend. It covers:
- Biometric authentication configuration, registration flow, fingerprint and face ID setup, and policy controls.
- Secure storage for tokens, user data, permissions, session expiry, biometric flags, and API password hashes.
- Session management with sliding expiration, absolute lifetime, and active session termination.
- Permission controls using a canonical permission catalog and middleware enforcement.
- **Enhanced API password protection** with dual verification (server + local fallback), rate limiting, and offline authentication support.
- Practical examples for custom policies, session lifecycle handling, biometric failure strategies, and API password management.

## Project Structure
The security system spans Flutter client code and Laravel backend services:
- Client-side:
  - Biometric service wrapping device hardware capabilities.
  - Secure storage service managing encrypted tokens, credentials, permissions, session metadata, and API password hashes.
  - Network interceptors attaching authorization headers and handling unauthorized responses.
  - API password dialog providing secure access gate to API settings.
- Server-side:
  - Session controller listing and terminating active sessions.
  - Session policy enforcing idle sliding renewal and absolute expiration.
  - Permission catalog defining modules, actions, wildcards, and labels.
  - Permission middleware enforcing access control.
  - Settings store providing secure/session configuration with caching.
  - **App config controller** handling API password verification and management with rate limiting.

```mermaid
graph TB
subgraph "Flutter Client"
BS["BiometricService"]
SS["SecureStorageService"]
AI["AuthInterceptor"]
EI["ErrorInterceptor"]
APD["ApiPasswordDialog"]
ACR["AppConfigRepository"]
end
subgraph "Laravel Backend"
SA["SessionAdminController"]
SP["SessionPolicy"]
PC["PermissionCatalog"]
EP["EnsurePermission"]
ST["SettingsStore"]
ACC["AppConfigController"]
end
BS --> SS
AI --> SS
EI --> SS
APD --> ACR
ACR --> SS
ACC --> ST
SA --> SP
EP --> PC
SP --> ST
```

**Diagram sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [SessionAdminController.php:32-474](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L32-L474)
- [SessionPolicy.php:42-185](file://kyApp_API/app/Support/SessionPolicy.php#L42-L185)
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)
- [AppConfigController.php:38-423](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L38-L423)

**Section sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [SessionAdminController.php:32-474](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L32-L474)
- [SessionPolicy.php:42-185](file://kyApp_API/app/Support/SessionPolicy.php#L42-L185)
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)
- [AppConfigController.php:38-423](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L38-L423)

## Core Components
- BiometricService: Detects device capability, checks enrollment, prompts for biometric authentication, and maps capabilities to UI labels.
- SecureStorageService: Encrypts and stores tokens, user data, API base URL, permissions, admin flag, session expiry, biometric state, and **API password hashes**. Provides logout-safe clearing and full purge.
- AuthInterceptor: Automatically attaches Bearer token and JSON accept header to outgoing requests.
- ErrorInterceptor: Centralized error handling; clears session on 401 and triggers an unauthorized callback.
- ApiPasswordDialog: Secure dialog that gates access to API settings behind password verification with server-first then local fallback logic.
- AppConfigRepository: Manages API password verification against server with offline fallback, local hash storage, and SHA-256 digest generation.
- SessionAdminController: Lists active sessions with search/filter/pagination and terminates single or all sessions by pushing expiry into the past.
- SessionPolicy: Validates tokens per request, enforces idle sliding renewal, absolute lifetime, and purges expired rows.
- PermissionCatalog: Canonical source of permission codes, module definitions, wildcard support, and human-readable labels.
- EnsurePermission: Middleware that denies access without required permission, returning localized messages.
- SettingsStore: Reads/writes security and session settings with type casting, bounds checking, locking, and short-lived cache.
- **AppConfigController**: Handles public API configuration retrieval, API password verification with rate limiting, and secure password updates with bcrypt hashing.

**Section sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [SessionAdminController.php:32-474](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L32-L474)
- [SessionPolicy.php:42-185](file://kyApp_API/app/Support/SessionPolicy.php#L42-L185)
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)
- [AppConfigController.php:38-423](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L38-L423)

## Architecture Overview
The security architecture integrates device biometrics, secure local storage, network interception, server-side session policy, permission enforcement, and **enhanced API password protection with dual verification**.

```mermaid
sequenceDiagram
participant App as "App Screen"
participant BS as "BiometricService"
participant SS as "SecureStorageService"
participant APD as "ApiPasswordDialog"
participant ACR as "AppConfigRepository"
participant Dio as "Dio Client"
participant AI as "AuthInterceptor"
participant EI as "ErrorInterceptor"
participant API as "Backend API"
participant ACC as "AppConfigController"
participant SP as "SessionPolicy"
App->>BS : checkSupport()
BS-->>App : Capability (fingerprint/faceId/supported/notSupported/notEnrolled)
App->>BS : authenticate(reason)
BS-->>App : bool success/failure
App->>APD : show() for API settings access
APD->>ACR : verifyApiPassword(password)
ACR->>API : POST /app-config/verify-api-password
API->>ACC : verifyApiPassword()
ACC-->>ACR : verified result
alt Server reachable
ACR-->>APD : verification result
else Server unreachable
ACR->>ACR : verifyLocally() with stored hash
ACR-->>APD : local verification result
end
APD-->>App : allow/deny access
App->>Dio : API Request
Dio->>AI : onRequest()
AI->>SS : getToken()
SS-->>AI : Token or null
AI->>Dio : Attach Authorization header
Dio->>API : HTTP Request
API->>SP : validate(token)
SP-->>API : allow/deny
API-->>Dio : Response (200/401/...)
Dio->>EI : onError()
EI->>SS : clearAll()
EI-->>App : Unauthorized callback
```

**Diagram sources**
- [biometric_service.dart:18-71](file://lib/core/utils/biometric_service.dart#L18-L71)
- [secure_storage_service.dart:32-95](file://lib/core/storage/secure_storage_service.dart#L32-L95)
- [api_password_dialog.dart:44-70](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L44-L70)
- [app_config_repository.dart:88-114](file://lib/features/app_config/data/repositories/app_config_repository.dart#L88-L114)
- [auth_interceptor.dart:11-22](file://lib/core/network/auth_interceptor.dart#L11-L22)
- [error_interceptor.dart:12-36](file://lib/core/network/error_interceptor.dart#L12-L36)
- [AppConfigController.php:188-226](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L188-L226)
- [SessionPolicy.php:70-108](file://kyApp_API/app/Support/SessionPolicy.php#L70-L108)

## Detailed Component Analysis

### Biometric Authentication Service
Responsibilities:
- Enumerates supported biometric types and enrollment status.
- Prompts for biometric authentication with platform-specific options.
- Maps capabilities to user-facing labels.

Key behaviors:
- Capability detection returns notSupported, notEnrolled, fingerprint, faceId, or supported.
- isAvailable filters out unsupported or unenrolled states.
- authenticate uses biometricOnly and stickyAuth to enforce strict biometric-only flows.

```mermaid
flowchart TD
Start(["checkSupport"]) --> CanCheck["canCheckBiometrics + isDeviceSupported"]
CanCheck --> Supported{"Any support?"}
Supported --> |No| NotSupported["Return notSupported"]
Supported --> |Yes| Types["getAvailableBiometrics()"]
Types --> Empty{"Types empty?"}
Empty --> |Yes| NotEnrolled["Return notEnrolled"]
Empty --> |No| HasFace{"Has face?"}
HasFace --> |Yes| FaceId["Return faceId"]
HasFace --> |No| HasFinger{"Has fingerprint/strong/weak?"}
HasFinger --> |Yes| Fingerprint["Return fingerprint"]
HasFinger --> |No| SupportedGeneric["Return supported"]
```

**Diagram sources**
- [biometric_service.dart:18-47](file://lib/core/utils/biometric_service.dart#L18-L47)

Practical guidance:
- Use checkSupport to gate UI elements for biometric login.
- Use isAvailable before prompting to avoid unnecessary prompts.
- Handle PlatformException and generic exceptions gracefully; treat failures as denied.

**Section sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)

### Secure Storage Service
Responsibilities:
- Encrypted persistence for auth tokens, user data, API base URL, permissions, admin flag, session expiry, biometric state, and **API password hashes**.
- Logout-safe clearing that preserves API base URL but removes session-scoped data.
- Safe permission parsing that defaults to no permissions on corruption.

Key behaviors:
- clearAll removes token, user type, user data, permissions, admin flag, and session expiry.
- getPermissions tolerates malformed stored JSON and returns an empty list.
- saveSessionExpiresAt persists server-provided deadline text; getSessionExpiresAt reads it.
- Biometric keys persist across logout so users can re-authenticate via biometrics.
- **New API password hash methods**: saveApiPasswordHash(), getApiPasswordHash(), deleteApiPasswordHash() for offline fallback authentication.

```mermaid
classDiagram
class SecureStorageService {
+saveToken(token)
+getToken() String?
+deleteToken()
+saveUserType(type)
+getUserType() String?
+saveUserData(json)
+getUserData() String?
+saveApiBaseUrl(url)
+getApiBaseUrl() String?
+deleteApiBaseUrl()
+clearAll()
+savePermissions(codes)
+getPermissions() String[]
+saveIsAdmin(flag)
+getIsAdmin() bool
+saveSessionExpiresAt(expiresAt)
+getSessionExpiresAt() String?
+clearPermissions()
+saveBiometricEnabled(enabled)
+getBiometricEnabled() bool
+saveUserId(userId)
+getUserId() int?
+clearBiometricData()
+purgeEverything()
+saveAppConfig(json)
+getAppConfig() String?
+deleteAppConfig()
+saveAppLogoPath(path)
+getAppLogoPath() String?
+deleteAppLogoPath()
+saveApiPasswordHash(hash)
+getApiPasswordHash() String?
+deleteApiPasswordHash()
}
```

**Diagram sources**
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)

Security notes:
- Tokens and credentials are stored via flutter_secure_storage with platform keychain/keystore protection.
- Permissions are read defensively; corrupt blobs result in deny-by-default behavior.
- Biometric enablement and associated user ID survive logout to support biometric login.
- **API password hashes are stored securely for offline fallback authentication when server is unreachable.**

**Section sources**
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)

### Network Interceptors
AuthInterceptor:
- Injects Authorization header when a token exists.
- Sets Accept header to application/json.

ErrorInterceptor:
- Handles cancellation errors gracefully.
- On 401, clears all session data and invokes an unauthorized callback.

```mermaid
sequenceDiagram
participant Dio as "Dio"
participant AI as "AuthInterceptor"
participant SS as "SecureStorageService"
participant EI as "ErrorInterceptor"
Dio->>AI : onRequest(options)
AI->>SS : getToken()
SS-->>AI : token?
AI->>Dio : next(options with Authorization)
Dio-->>EI : onError(err)
alt err.type == cancel
EI-->>Dio : resolve(200 cancelled response)
else statusCode == 401
EI->>SS : clearAll()
EI-->>Dio : next(err)
end
```

**Diagram sources**
- [auth_interceptor.dart:11-22](file://lib/core/network/auth_interceptor.dart#L11-L22)
- [error_interceptor.dart:12-36](file://lib/core/network/error_interceptor.dart#L12-L36)

**Section sources**
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)

### Active Sessions Management
SessionAdminController:
- Lists sessions with pagination, filtering by status and user, and search across names/devices.
- Terminates a single session or all sessions for a user by setting EXPIRES_AT to the past.
- Avoids reading sensitive TOKEN or ABILITIES columns.

SessionPolicy:
- Validates tokens after Sanctum lookup.
- Rejects if account deactivated, idle expired, or absolute age exceeded.
- Slides expiry within a threshold window to reduce writes.
- Purges expired tokens on login and session screen open.

```mermaid
flowchart TD
VStart["validate(token)"] --> ValidSanctum{"Sanctum valid?"}
ValidSanctum --> |No| Deny["Return false"]
ValidSanctum --> |Yes| CheckUser["Check IS_ACTIVATED"]
CheckUser --> |Inactive| Deny
CheckUser --> |Active| CheckIdle["Check expires_at vs now"]
CheckIdle --> Expired{"Expired?"}
Expired --> |Yes| Discard["Delete token row"] --> Deny
Expired --> |No| CheckAbsolute["Check created_at vs absolute days"]
CheckAbsolute --> TooOld{"Too old?"}
TooOld --> |Yes| Discard --> Deny
TooOld --> |No| Slide["Slide expiry if needed"] --> Allow["Return true"]
```

**Diagram sources**
- [SessionPolicy.php:70-108](file://kyApp_API/app/Support/SessionPolicy.php#L70-L108)
- [SessionPolicy.php:147-183](file://kyApp_API/app/Support/SessionPolicy.php#L147-L183)

Operational notes:
- Termination does not delete token rows to preserve audit trail; it sets EXPIRES_AT to the past.
- The client's ErrorInterceptor will log out devices automatically upon receiving 401 from subsequent requests.

**Section sources**
- [SessionAdminController.php:93-141](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L93-L141)
- [SessionAdminController.php:147-182](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L147-L182)
- [SessionAdminController.php:193-233](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L193-L233)
- [SessionPolicy.php:70-108](file://kyApp_API/app/Support/SessionPolicy.php#L70-L108)
- [SessionPolicy.php:130-141](file://kyApp_API/app/Support/SessionPolicy.php#L130-L141)

### Permission Controls
PermissionCatalog:
- Defines modules, core actions, extra actions, wildcards, and labels.
- Provides grouped structures for UI and validation helpers.

EnsurePermission:
- Enforces require-permission middleware.
- Returns 401 if unauthenticated, 403 with Arabic label if permission missing.

```mermaid
flowchart TD
MStart["EnsurePermission.handle(code)"] --> UserExists{"User authenticated?"}
UserExists --> |No| R401["Return 401 Unauthenticated"]
UserExists --> |Yes| CanAccess["permissions.can(user, code)"]
CanAccess --> |False| R403["Return 403 with Arabic label"]
CanAccess --> |True| Next["next(request)"]
```

**Diagram sources**
- [EnsurePermission.php:32-52](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L32-L52)
- [PermissionCatalog.php:432-441](file://kyApp_API/app/Support/PermissionCatalog.php#L432-L441)

Implementation tips:
- Register routes under auth:sanctum and apply ->middleware('permission:module.action').
- System administrators bypass grant checks via PermissionResolver.

**Section sources**
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)

### Security Settings Store
SettingsStore:
- Caches hot security/session keys with TTL to reduce database load.
- Validates and normalizes values by declared type (bool/int/json/string).
- Supports locked settings and provides raw access for sensitive hashes.

Hot keys include session idle minutes, absolute days, touch threshold, single active session per device, password min length, max failed logins, lockout minutes, biometric login enabled, activity log retention, and maintenance message.

```mermaid
flowchart TD
SStart["SettingsStore.get(key)"] --> HotCache{"Hot key?"}
HotCache --> |Yes| FromCache["Read from cache"]
HotCache --> |No| FetchOne["Direct DB fetch"]
FromCache --> Cast["Cast to declared type"]
FetchOne --> Cast
Cast --> Return["Return value or default"]
```

**Diagram sources**
- [SettingsStore.php:130-153](file://kyApp_API/app/Support/SettingsStore.php#L130-L153)
- [SettingsStore.php:205-216](file://kyApp_API/app/Support/SettingsStore.php#L205-L216)

Configuration guidance:
- Use SettingsStore.int(), .bool(), .raw() for typed reads.
- Use set() with updatedBy to persist changes; locked settings throw exceptions.

**Section sources**
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)

## API Password Protection System

### Overview
The enhanced API password protection system provides secure access to API configuration settings through a dual-verification mechanism that ensures both security and availability even when the server is unreachable.

### Key Components

#### ApiPasswordDialog
A secure dialog component that gates access to API settings behind password verification. It implements a sophisticated verification strategy:
- Attempts server-side verification first via `POST /app-config/verify-api-password`
- Falls back to local hash verification if server is unreachable
- Never stores the actual password in memory after successful verification
- Provides clear user feedback for different failure scenarios

#### AppConfigRepository
Manages the complete API password workflow:
- **Server verification**: Calls the rate-limited endpoint and distinguishes between wrong passwords and server unavailability
- **Local fallback**: Uses SHA-256 hashed passwords stored locally for offline authentication
- **Password management**: Updates server-side bcrypt hashes while storing local SHA-256 fallbacks
- **Offline capability**: Generates salted SHA-256 hashes compatible with the device ID pattern

#### Secure Storage Integration
Extended SecureStorageService with new methods:
- `saveApiPasswordHash(String hash)`: Stores SHA-256 hash for offline fallback
- `getApiPasswordHash()`: Retrieves stored hash for local verification
- `deleteApiPasswordHash()`: Removes stored hash during cleanup operations

#### Backend Implementation
AppConfigController provides three critical endpoints:
- **Public verification**: Rate-limited endpoint for password verification without authentication
- **Secure password updates**: Protected endpoint requiring `app_config.api_manage` permission
- **Public configuration**: Secret-free endpoint for app branding and theming

```mermaid
flowchart TD
UserInput["User enters API password"] --> ServerCheck{"Server reachable?"}
ServerCheck --> |Yes| ServerVerify["POST /app-config/verify-api-password"]
ServerCheck --> |No| LocalVerify["verifyLocally() with stored hash"]
ServerVerify --> ServerResult{"Server response"}
ServerResult --> |Success| AccessGranted["Grant API settings access"]
ServerResult --> |Failure| AccessDenied["Deny access"]
LocalVerify --> LocalResult{"Hash match?"}
LocalResult --> |Yes| AccessGranted
LocalResult --> |No| AccessDenied
```

**Diagram sources**
- [api_password_dialog.dart:44-70](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L44-L70)
- [app_config_repository.dart:88-114](file://lib/features/app_config/data/repositories/app_config_repository.dart#L88-L114)
- [app_config_repository.dart:159-165](file://lib/features/app_config/data/repositories/app_config_repository.dart#L159-L165)
- [AppConfigController.php:188-226](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L188-L226)

### Security Features
- **Dual verification**: Server-first approach with reliable offline fallback
- **Rate limiting**: Prevents brute force attacks on the verification endpoint
- **Secure hashing**: Uses bcrypt on server, SHA-256 with salt for local fallback
- **Permission control**: Requires elevated permissions for password changes
- **Audit logging**: Tracks failed verification attempts and password changes
- **Memory safety**: Clears sensitive data from memory after verification

### Integration Points
- Login screen integration via `_openApiSettingsWithGate()` method
- Secure storage integration for persistent offline authentication capability
- Network interceptor compatibility for authenticated operations
- Error handling integration for graceful degradation when server is unavailable

**Section sources**
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [secure_storage_service.dart:249-265](file://lib/core/storage/secure_storage_service.dart#L249-L265)
- [AppConfigController.php:188-292](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L188-L292)
- [login_screen.dart:77-84](file://lib/features/auth/presentation/screens/login_screen.dart#L77-L84)

## Dependency Analysis
```mermaid
graph LR
BS["BiometricService"] --> SS["SecureStorageService"]
AI["AuthInterceptor"] --> SS
EI["ErrorInterceptor"] --> SS
APD["ApiPasswordDialog"] --> ACR["AppConfigRepository"]
ACR --> SS
ACC["AppConfigController"] --> ST["SettingsStore"]
SA["SessionAdminController"] --> SP["SessionPolicy"]
EP["EnsurePermission"] --> PC["PermissionCatalog"]
SP --> ST
```

**Diagram sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [SessionAdminController.php:32-474](file://kyApp_API/app/Http/Controllers/SessionAdminController.php#L32-L474)
- [SessionPolicy.php:42-185](file://kyApp_API/app/Support/SessionPolicy.php#L42-L185)
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)
- [AppConfigController.php:38-423](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L38-L423)

Coupling and cohesion:
- BiometricService depends only on LocalAuthentication; SecureStorageService encapsulates all persistent security state including API password hashes.
- SessionPolicy centralizes token lifecycle logic; controllers delegate to it rather than duplicating rules.
- PermissionCatalog is the single source of truth for permission semantics, reducing drift between server and UI.
- **AppConfigRepository provides cohesive API password management with clear separation between server and local verification logic.**

Potential circular dependencies:
- None observed among analyzed components; dependencies are directional and well-scoped.

External integrations:
- Device biometric APIs via local_auth.
- Encrypted storage via flutter_secure_storage.
- HTTP client Dio with interceptors.
- Oracle-backed Laravel application with Sanctum tokens.
- **Rate limiting for API password verification endpoints.**

**Section sources**
- [biometric_service.dart:14-84](file://lib/core/utils/biometric_service.dart#L14-L84)
- [secure_storage_service.dart:7-268](file://lib/core/storage/secure_storage_service.dart#L7-L268)
- [auth_interceptor.dart:6-23](file://lib/core/network/auth_interceptor.dart#L6-L23)
- [error_interceptor.dart:6-38](file://lib/core/network/error_interceptor.dart#L6-L38)
- [api_password_dialog.dart:14-129](file://lib/features/auth/presentation/widgets/api_password_dialog.dart#L14-L129)
- [app_config_repository.dart:32-227](file://lib/features/app_config/data/repositories/app_config_repository.dart#L32-L227)
- [SessionPolicy.php:42-185](file://kyApp_API/app/Support/SessionPolicy.php#L42-L185)
- [PermissionCatalog.php:22-480](file://kyApp_API/app/Support/PermissionCatalog.php#L22-L480)
- [EnsurePermission.php:25-54](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L25-L54)
- [SettingsStore.php:28-501](file://kyApp_API/app/Support/SettingsStore.php#L28-L501)
- [AppConfigController.php:38-423](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L38-L423)

## Performance Considerations
- SessionPolicy slide writes are throttled by a configurable threshold to minimize database updates while keeping sessions alive.
- SettingsStore caches hot keys with a short TTL to reduce repeated queries on the request path.
- SecureStorageService reads permissions defensively to avoid expensive exception paths; corrupted data yields deny-by-default behavior.
- SessionController avoids reading large CLOB fields and formats dates explicitly for Oracle compatibility.
- **API password verification uses rate limiting to prevent brute force attacks while maintaining responsive user experience.**
- **Local hash verification provides instant offline authentication without network overhead.**

## Troubleshooting Guide
Common issues and resolutions:
- Biometric not available:
  - Check device support and enrollment via BiometricService.checkSupport().
  - If not enrolled, guide the user to register fingerprint or face ID in device settings.
- Biometric prompt fails:
  - Catch PlatformException and generic exceptions; fall back to password or account selection.
  - Ensure reason string is provided to localize the prompt.
- Unexpected 401 responses:
  - ErrorInterceptor clears all session data; ensure your app handles the unauthorized callback to navigate to login.
  - Verify SessionPolicy settings (idle minutes, absolute days) and that tokens are being primed on login.
- Permission denied:
  - Confirm the route uses ->middleware('permission:...') and the user has the required grant.
  - Use PermissionCatalog.arabicName to display friendly messages.
- Settings not applying immediately:
  - SettingsStore caches hot keys; changes may take up to the TTL unless flushed.
  - After transaction rollback, call SettingsStore.flush() to prevent stale cache.
- **API password verification fails:**
  - Check network connectivity; the system falls back to local hash if server is unreachable.
  - Verify the stored local hash matches the current password if offline mode is used.
  - Ensure the server-side bcrypt hash is properly configured for the intended password.
- **API settings access denied:**
  - Verify the user has the `app_config.api_manage` permission for password changes.
  - Check that the rate limit hasn't been exceeded on the verification endpoint.
  - Confirm the password meets minimum length requirements (4 characters).

**Section sources**
- [biometric_service.dart:57-71](file://lib/core/utils/biometric_service.dart#L57-L71)
- [error_interceptor.dart:12-36](file://lib/core/network/error_interceptor.dart#L12-L36)
- [SessionPolicy.php:70-108](file://kyApp_API/app/Support/SessionPolicy.php#L70-L108)
- [EnsurePermission.php:32-52](file://kyApp_API/app/Http/Middleware/EnsurePermission.php#L32-L52)
- [SettingsStore.php:130-153](file://kyApp_API/app/Support/SettingsStore.php#L130-L153)
- [app_config_repository.dart:88-114](file://lib/features/app_config/data/repositories/app_config_repository.dart#L88-L114)
- [AppConfigController.php:244-258](file://kyApp_API/app/Http/Controllers/AppConfigController.php#L244-L258)

## Conclusion
The security settings system combines robust client-side biometric integration, encrypted local storage, and server-side session and permission controls with **enhanced API password protection**. BiometricService abstracts device capabilities, SecureStorageService protects sensitive data including API password hashes, and interceptors streamline authentication and error handling. The new ApiPasswordDialog and AppConfigRepository provide secure, resilient access to API configuration with dual verification capabilities. On the server, SessionPolicy enforces safe session lifetimes, SessionAdminController provides administrative control over active sessions, PermissionCatalog defines a consistent permission model, EnsurePermission enforces access control, and AppConfigController manages API password security with rate limiting and audit logging. SettingsStore centralizes configuration with caching and validation. Together, these components deliver a secure, maintainable, and user-friendly authentication and authorization experience that remains functional even in offline scenarios.