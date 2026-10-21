# AGENTS.md — ky_apps

> **ملف إرشادات وكلاء الذكاء الاصطناعي للمشروع** — اقرأه كاملاً قبل تعديل أي ملف.
> Agent operating guide for this repository. Read it fully before changing any code.

This is the authoritative guide for AI coding agents (and new contributors) working on **ky_apps**.
It follows the [agents.md](https://agents.md) convention: a single predictable file describing setup,
architecture, conventions, testing, and the traps that are not visible from the code alone.

Nested guides take precedence over this file for the directories they cover:

| File | Scope |
|---|---|
| `AGENTS.md` *(this file)* | Whole repository — Flutter client, monorepo workflow, shared domain knowledge |
| [`kyApp_API/AGENTS.md`](kyApp_API/AGENTS.md) | Laravel backend only — wins over this file inside `kyApp_API/` |
| [`appsroles.md`](appsroles.md) | Flutter/Dart coding standards (aspirational in places — see [§11](#11-known-issues--traps-read-before-you-touch-anything)) |

---

## 1. What this project is

**ky_apps** is the Arabic-first, RTL client for **الكبودي للخياطة الرجالية** (Al-Kaboodi Men's
Tailoring) — a tailoring business in Yemen. It is a mobile/desktop front end for a **legacy Oracle
accounting ERP**, reached through a purpose-built Laravel REST API.

```
┌──────────────────────┐   HTTPS/HTTP + Bearer   ┌──────────────────────┐   OCI8   ┌─────────────────────┐
│  Flutter client      │ ──────────────────────> │  Laravel 12 API      │ ───────> │  Oracle 11g (legacy) │
│  (this repo, lib/)   │ <────────────────────── │  (kyApp_API submodule)│ <─────── │  schema: ACCOUNTS    │
└──────────────────────┘        JSON             └──────────────────────┘   rows   └─────────────────────┘
```

Three facts shape almost every decision in this codebase:

1. **The database is not ours to migrate.** Business data lives in a pre-existing Oracle 11g schema
   owned by another system (`ACCOUNTS`). There are no migrations for business tables, and there never
   will be. Read [§6](#6-the-oracle-database-the-single-most-important-context).
2. **Arabic text is stored as Windows-1256 bytes.** The Oracle instance has
   `NLS_CHARACTERSET = WE8MSWIN1252`, so Arabic comes back mojibake (`ÎÇáÏ` instead of `خالد`).
   Both sides carry a repair layer. Never remove it.
3. **The app is Arabic-first and RTL.** UI strings are hardcoded Arabic literals. `en_US` is
   declared but effectively vestigial.

### Current status

| Area | State |
|---|---|
| Auth (password + biometric), employee portal shell | **Working** |
| Customers, workers (employees/cutters/tailors), accounts & chart of accounts, currencies | **Working** |
| Sales, tailoring cards (كروت التفصيل), stores/inventory, home dashboard | **Placeholders** — `DataListScaffold`/`PortalSectionScaffold` empty states |
| الإدارة (admin: users, grants, sessions, security settings, activity) | **Working** — `lib/features/admin/`, gated by `permission:` on both sides |
| Customer portal (`user_type = customer`) | **Stub** — login shows "بوابة العميل قيد التطوير حالياً" |
| Permissions & sessions (**IBAC**, not RBAC) | **Implemented** — 93-code catalog, direct per-user grants, `permission:` route guard, admin UI under الإدارة |

> **There is no RBAC and none is planned.** Permissions are attached directly to a user row
> (Identity-Based Access Control, `APP_USERS_PERMISSIONS`), with an `IS_ADMIN = 1` full bypass.
> The single legacy `USER_TYPE` column (`employee` / `customer`) is *not* a permission and stays
> exactly as it was. The full design and its accepted decisions live in
> [`ibac_permissions_plan.md`](ibac_permissions_plan.md).

---

## 2. Repository layout

This is a **two-repo monorepo joined by a git submodule**. Treat the boundary with care.

```
ky_apps/                          ← Flutter client (repo: github.com/Aporaad/ky_apps)
├── lib/                          ← ALL Dart application code (122 files)
│   ├── main.dart                 ← entry point: ProviderScope → KyApp (MaterialApp.router)
│   ├── routing/app_router.dart   ← GoRouter, 5 flat routes
│   ├── core/                     ← shared infrastructure
│   │   ├── constants/api_constants.dart   ← base URL, endpoint paths, timeouts
│   │   ├── constants/permission_codes.dart ← the 93 IBAC codes + Arabic section titles
│   │   ├── network/              ← dio_client.dart, auth_interceptor.dart, error_interceptor.dart
│   │   ├── storage/secure_storage_service.dart
│   │   ├── theme/                ← app_theme.dart, app_colors.dart
│   │   ├── utils/                ← arabic_encoding_utils, biometric_service, device_id_helper,
│   │   │                         responsive, json_value_utils, permission_check
│   │   └── widgets/permission_gate.dart  ← the only shared widget: hides children the user can't use
│   └── features/                 ← feature-first modules
│       ├── auth/                 ├── accounts/     ├── customers/
│       ├── workers/              ├── employee_portal/  ├── settings/
│       └── admin/                ← IBAC administration (36 files: 7 models, 4 repos, 6 providers,
│                                   10 screens, 9 widgets) — users, grants, sessions, security, activity
├── test/                         ← flutter_test (4 files, 51 tests)
├── android/ ios/ web/ windows/   ← platform runners
├── kyApp_API/                    ← GIT SUBMODULE → github.com/Aporaad/kyApp_API (Laravel 12)
├── appsroles.md                  ← Flutter/Dart coding standards
├── ibac_permissions_plan.md      ← the IBAC design: decisions D1–D8, DDL, phases 0–9
├── DBdevloping_history.md        ← de-facto Oracle schema documentation
├── devloping_history.md          ← Flutter-side changelog
├── db_commends.md                ← log of Oracle SQL run during development
├── user_commends.md              ← log of user prompts + captured error traces
└── todo.md                       ← dated task checklists
```

Every feature folder follows the same shape:

```
features/<name>/
├── data/
│   ├── models/          ← hand-written immutable classes, fromJson/toJson/copyWith
│   └── repositories/    ← the ONLY layer allowed to touch Dio
└── presentation/
    ├── providers/       ← Riverpod notifiers + provider declarations
    ├── screens/         ← one file per screen, snake_case
    └── widgets/         ← widgets reused only inside this feature
```

### Submodule workflow (important)

`kyApp_API/` is a separate repository pinned by commit SHA. Changes there do **not** appear in
`git status` of the parent beyond a pointer bump.

```bash
git submodule update --init --recursive        # first clone / after pulling
cd kyApp_API && git status                     # the submodule has its OWN working tree & branch
```

Rules:
- **Commit inside the submodule first, then commit the pointer bump in the parent.** Otherwise the
  parent references a commit nobody else can fetch.
- Never commit work-in-progress in the parent that points at an unpushed submodule commit.
- `kyApp_API/` itself declares a nested submodule `ky_Apps/` pointing back at the Flutter repo.
  It is **empty and uninitialized** — ignore it, do not populate it.

---

## 3. Setup

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | Dart `^3.7.2` | `pubspec.yaml` constraint |
| PHP | `^8.2.12` | required by `kyApp_API/composer.json` |
| Composer | 2.x | |
| Node.js | ≥ 20 | Vite 7 in the API |
| Oracle Instant Client | 11g-compatible | PHP `oci8` / `pdo_oci` extension must load |
| Oracle DB | 11g, schema `ACCOUNTS` | legacy, external |

### Flutter client

```bash
cd ky_apps
flutter pub get          # NO build_runner — there is zero codegen in this project
flutter analyze          # quality gate: target is "No issues found!"
flutter test
flutter run              # or: flutter run -d chrome  /  -d <android-device-id>
```

The client needs the API reachable. Default base URL is
`http://192.168.0.11:8000/api` (`lib/core/constants/api_constants.dart:6`) — a LAN address.
It is **not** baked in at build time: the URL is editable at runtime from the login screen's
settings icon → `/api-settings`, persisted encrypted under the `ky_api_base_url` key.

### Laravel API

```bash
cd kyApp_API
composer install
cp .env.example .env      # then fill in the Oracle vars — see the warning below
php artisan key:generate
php artisan serve --host 0.0.0.0    # --host is REQUIRED so the phone/emulator on the LAN can reach it
composer dev              # or: server + queue + pail logs + vite concurrently
```

> ⚠️ **`.env.example` is incomplete.** It ships the stock Laravel template with
> `DB_CONNECTION=sqlite` and none of the Oracle variables that `config/database.php` and
> `config/oracle.php` actually read. You must add:
> `DB_CONNECTION=oracle`, `DB_HOST`, `DB_PORT=1521`, `DB_SERVICE_NAME`, `DB_DATABASE=orcl`,
> `DB_USERNAME`, `DB_PASSWORD`, `DB_CHARSET=AL32UTF8`, `DB_SCHEMA_PREFIX=accounts`,
> `DB_SERVER_VERSION=11g`. Ask the user for real credentials — do not invent them.

### Verify the whole chain

```bash
curl http://<lan-ip>:8000/api/hello     # API alive (the Flutter "test connection" probe)
php artisan route:list --path=api       # 55 registered API endpoints
flutter analyze && flutter test         # client healthy
```

---

## 4. Flutter architecture

### Bootstrap — `lib/main.dart`

`main()` does only `WidgetsFlutterBinding.ensureInitialized()` + `runApp(ProviderScope(child: KyApp()))`.
No provider overrides, no dotenv, no Firebase. `KyApp` is a `MaterialApp.router` with:

- `locale: Locale('ar','SA')`, `supportedLocales: [ar_SA, en_US]`
- Only the three `Global*Localizations` delegates — **no `.arb` files, no `AppLocalizations`**
- `theme: AppTheme.lightTheme` only — **no dark theme exists** despite a dark-mode toggle in settings
- A `builder` that clamps system text scale to `0.85–1.25`. This is a deliberate, app-wide guard
  against `RenderFlex` overflow. **Do not remove it.**

### Routing — `lib/routing/app_router.dart`

A plain (non-codegen) `GoRouter` with `initialLocation: '/splash'` and exactly **5 routes**:
`/splash`, `/login`, `/employee`, `/api-settings`, `/security-settings`. No route names, no
`redirect`, no declarative guards.

Auth gating is **programmatic**:
- `SplashScreen._checkNavigation()` waits 1200 ms, reads `authNotifierProvider`, then
  `context.go('/employee')` or `context.go('/login')`.
- Everything below the top level is **not** in the router. Feature screens are pushed imperatively
  with `Navigator.push(MaterialPageRoute(...))`. This is the established convention — follow it
  rather than adding 40 routes to `app_router.dart`.

### State management — Riverpod 3, no codegen

`flutter_riverpod: ^3.3.2` with **no** `riverpod_annotation` and **no** `build_runner`. Four
patterns coexist; match whatever the surrounding feature already uses.

| Pattern | Where | Use for |
|---|---|---|
| `Provider` | repositories, services | dependency injection |
| `Notifier` + `NotifierProvider` | auth, settings, customers, workers | **new code — prefer this** |
| `StateNotifier` (from `package:flutter_riverpod/legacy.dart`) | accounts, currency | legacy — do not add new ones |
| `FutureProvider` / `.family` | cascading parent-account dropdowns, currency prices | read-only async lookups |

Conventions that matter:

- **`build()` returns initial state and kicks off loading via `Future.microtask(() => loadX())`** —
  never `await` in `build()`.
- Notifiers hold a `CancelToken`; requests are cancelled on screen dispose. Keep this — it is the
  fix for a long-running class of "setState after dispose" and stale-search bugs.
- Race guards use a monotonically increasing `_searchVersion` int (see `ChartAccountsNotifier`).
- Search inputs are debounced **300 ms**.
- Nullable-field `copyWith` uses the closure trick: `String? Function()? errorMessage`.

> ⚠️ **Cross-feature import that looks wrong but is load-bearing:** the global infrastructure
> providers — `secureStorageProvider`, `dioClientProvider`, `authRepositoryProvider` — are declared
> inside `lib/features/auth/presentation/providers/auth_notifier.dart`. **Every** feature imports
> that file to get `dioClientProvider`. Don't "clean this up" without updating all call sites, and
> don't create a second `dioClientProvider`.

### Networking — Dio

`lib/core/network/dio_client.dart` builds one `Dio` with `Content-Type`/`Accept: application/json`
and three interceptors, **in this order**:

1. `AuthInterceptor` — injects `Authorization: Bearer <token>` from secure storage on every request,
   and on every response reads `X-Session-Expires-At` and reports it through `onSessionDeadline`
   (see the session watchdog below).
2. `ErrorInterceptor` — resolves `DioExceptionType.cancel` into a synthetic 200
   `{success:false, cancelled:true, data:[], meta:{}}`; on **401** calls `clearAll()` + the
   `onUnauthorized` callback, which is wired to `AuthNotifier.forceLogout()`.
3. `LogInterceptor` — request/response bodies on, headers off.

> **Session lifetime is enforced on both ends.** The server decides (`SessionPolicy` on `EXPIRES_AT`)
> and answers every authenticated response with the *current* deadline in `X-Session-Expires-At`,
> because it slides that column on each request. `AuthNotifier` stores it (`updateSessionDeadline` →
> `ky_session_expires_at`) and a **local, network-free** `Timer.periodic(30s)` evicts the user the
> moment it passes. The watchdog must never probe the network: a probe would renew the session and
> cancel the very idle expiry it is supposed to honour. `checkAuthStatus()` runs the same check at
> start, so a session that died while the app was closed never draws the portal.
>
> Navigation is **centralised in `KyApp`**: one `ref.listen` on `isAuthenticated` routes
> signed-in → signed-out to `/login`, covering all three exits (admin termination, idle timeout,
> normal logout). Do not add `context.go('/login')` to individual screens — that is how one path was
> always missed.

There is **no refresh-token flow** (a dead session ends and the user signs in again — it is never
silently renewed) and **no `RetryInterceptor`** even though `appsroles.md` prescribes one.

Base URL switching is runtime, not compile time: `updateBaseUrl()` / `initializeBaseUrl()`
(restore from secure storage, called by `AuthNotifier.checkAuthStatus()`).

Timeouts (`ApiConstants`): connect 15 s, receive 15 s, connection-test 7 s.

Repositories hardcode their own paths — there is no endpoint registry. Response handling convention:
check `body['success'] == true`, return `[]`/`null` when `CancelToken.isCancel(e)`.

### Auth & biometrics

`flutter_secure_storage` is **mandatory** for credentials — never `SharedPreferences`.
Exact keys (`lib/core/storage/secure_storage_service.dart`):

| Key | Contents |
|---|---|
| `ky_auth_token` | Sanctum bearer token |
| `ky_user_type` | `'employee'` or `'customer'` |
| `ky_user_data` | JSON-encoded `UserModel` |
| `ky_api_base_url` | user-overridden API base URL |
| `ky_biometric_enabled` | `'1'` / `'0'` |
| `ky_biometric_user_id` | user id as string |
| `ky_user_permissions` | JSON list of granted permission codes (IBAC) |
| `ky_is_admin` | `'1'` / `'0'` — the `IS_ADMIN` bypass flag |
| `ky_session_expires_at` | the server's `YYYY-MM-DD HH:MM:SS` deadline text of the current session (Oracle clock, no zone marker) |

`clearAll()` (logout) removes token + user type + user data + the three IBAC keys, but **intentionally
keeps** biometric enrollment and the API URL, so a logged-out user can still sign in with a
fingerprint. `purgeEverything()` wipes all nine.

Biometric flow:
- `device_token = sha256("$rawDeviceId:ky_apps_biometric_v1_2026")`
  (`lib/core/utils/device_id_helper.dart`). `rawDeviceId` is Android `ANDROID_ID` (fallback
  `fingerprint`) or iOS `identifierForVendor`. **The salt string is part of the contract with the
  server** — changing it silently invalidates every enrolled device.
- Enrollment: local `authenticate()` → `POST /auth/biometric/register` with
  `{device_token, device_name, platform}`. One device per user.
- Login: local `authenticate()` → `POST /auth/biometric/login` with `{user_id, device_token}`.
- Revoke: `DELETE /auth/biometric/revoke`, then local wipe **even if the request fails**.
- `BiometricCapability` enum: `notSupported | notEnrolled | fingerprint | faceId | supported`.

Android needs `USE_BIOMETRIC` + `USE_FINGERPRINT` (present in the main manifest); iOS needs
`NSFaceIDUsageDescription` (present, in Arabic).

### Permissions (IBAC) — client core

The client mirrors the server rules **for display only**; the server decides every request again.

- `lib/core/constants/permission_codes.dart` — `Perm.*` constants for all 93 catalog codes
  (`module.action`), `permModuleOrder`, and the Arabic section titles. **Codes are ASCII — never put
  Arabic through them**, and never invent a code that is not in `APP_PERMISSIONS`.
- `lib/core/utils/permission_check.dart` — `canCode` / `canAnyCode` / `canAllCode`, the pure mirror of
  `PermissionResolver::can`: `isAdmin` ⇒ true, `system.*` ⇒ true, literal code ⇒ true,
  `module.*` wildcard ⇒ true, otherwise **false (deny-by-default)**.
- `AuthState.can(code)` / `canAny` / `canAll` / `canSeeSection`
  (`lib/features/auth/presentation/providers/auth_notifier.dart`) — what screens actually watch,
  e.g. `ref.watch(authNotifierProvider.select((a) => a.can(Perm.customersCreate)))`.
- `lib/core/widgets/permission_gate.dart` — `PermissionGate(code:, child:, onDenied:, hide:)`, the only
  shared widget in `lib/core/widgets/`. Wrap any action; it must not merely disable.
- `lib/features/auth/presentation/providers/permissions_notifier.dart` +
  `lib/features/auth/data/models/permission_snapshot_model.dart` — `permissionsNotifierProvider`
  fetches `GET /auth/permissions`, persists it to secure storage, and refreshes on resume;
  `refreshNow()` is called after any grant change so a re-permissioned user sees it without relogin.
- `lib/features/employee_portal/domain/portal_sections.dart` — **the single registry of portal
  sections** (index ↔ title ↔ icon ↔ required code). The drawer, the bottom bar, and the home
  dashboard all read it; the old 4↔5 index mismatch is why it exists. A new section is added here
  first, nowhere else.

`lib/features/admin/` (36 files) is the administration UI: users CRUD, in-form permission picker,
catalog viewer, active sessions, security settings, and the per-user activity log. Screens are
pushed imperatively like every other feature — they are **not** in `app_router.dart`.

### Models

Hand-written immutable classes. **No freezed, no json_serializable, no build_runner** — `appsroles.md`
recommends them but they were never adopted. Do not add codegen without explicit approval, since it
would change the build pipeline for the whole project.

Required conventions:

- `factory X.fromJson(Map<String, dynamic>)`, plus `toJson()` and any of
  `toJsonForApi()` / `toJsonForCreate()` / `toJsonForUpdate()` as the endpoint demands.
- Manual `copyWith()`.
- **Dual-case key reads**, because the API proxies raw Oracle rows:
  ```dart
  custNo: json['CUST_NO'] ?? json['cust_no'],
  ```
  Dart fields stay camelCase (`custNo`, `accName`, `limitedBalance`).
- **Defensive parsing** — Oracle returns numbers as strings. Every model carries private
  `_parseInt` / `_parseDouble` / `_parseString` helpers. Use them; never `int.parse` raw JSON.
- **Every Arabic string field must pass through `ArabicEncodingUtils.fix()`**
  (`lib/core/utils/arabic_encoding_utils.dart`). Phone numbers and emails are parsed with
  `isArabic: false` to skip the repair. Forgetting `fix()` produces mojibake in the UI — this is the
  single most common bug in this project.

### UI

- **Theme**: `AppTheme.lightTheme`, Material 3, `ColorScheme.fromSeed(seedColor: AppColors.primary)`,
  Cairo font via `google_fonts`. Never hardcode a color in a widget — add it to `AppColors`.
- **Colors**: `AppColors.primary = 0xFF7C2D12` (a deep brown/orange). The adjacent comment says
  "أزرق كحلي ملكي" (royal navy) — **the comment is stale, the value is correct**. Fix the comment,
  don't change the color.
- **Responsive** (`lib/core/utils/responsive.dart`): mobile `< 768`, tablet `< 1100`, desktop `≥ 1100`.
  Use `Responsive.isMobile(context)` etc. Many screens also use a local `isNarrow = width < 600`.
- Use `MediaQuery.sizeOf` / `textScalerOf` (not the deprecated `of` overloads), and
  `color.withValues(alpha: …)` (not the deprecated `withOpacity`).
- Use `WidgetStateProperty`, not the deprecated `MaterialStateProperty`.
- Every data screen renders **four states**: loading / success / empty / error, and offers
  search + sort + filter + export.
- Statement screens reproduce the company's printed letterhead exactly (gold/mustard header;
  columns السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد). Do not restyle them casually —
  they are matched to a physical document.

### Employee portal shell

`lib/features/employee_portal/presentation/screens/employee_main_layout.dart` is the post-login
host: an `IndexedStack` over 9 drawer sections (الرئيسية، المبيعات، التفصيل، العملاء، الحسابات،
جاري العاملين، المخازن، الإدارة، الإعدادات). Mobile renders a `Drawer` + 5-item `NavigationBar`;
tablet/desktop render the persistent `CollapsibleSideDrawer` (250 px, 76 px collapsed).
The top bar shows the branch chip `فرع {branchNo}`, a "متصل" status dot, and logout (with a
confirmation dialog).

Which sections a user sees comes from **`portal_sections.dart`** + `canSeeSection(code)` — a section
whose code the user does not hold is not rendered at all (and its routes would 403 anyway). Never add
a section index, title, or icon anywhere else; the drawer, bottom bar, and dashboard all read that one
registry, which is also why the old 4↔5 index collision stopped being possible.

---

## 5. Laravel API — summary

Full details live in [`kyApp_API/AGENTS.md`](kyApp_API/AGENTS.md). The essentials:

- **Laravel 12** (locked 12.69.0), PHP `^8.2.12`, **`yajra/laravel-oci8` 12.0** for Oracle.
- **Sanctum 4** personal access tokens. `config/sanctum.php` keeps `expiration => null` **on purpose**
  — `Sanctum\Guard` compares it to `created_at`, so any value becomes a hard absolute age that would
  kick out an active worker. Session lifetime is driven by the `EXPIRES_AT` column instead, through
  `App\Support\SessionPolicy` (idle sliding renewal + absolute cap), registered in
  `AppServiceProvider` via `Sanctum::$accessTokenAuthenticationCallback`. Do not set `expiration`.
  A rejected token is now **deleted** (`discard()`), `purgeExpired()` sweeps dead ones on login and on
  the sessions screen, and every time computation runs on `SessionPolicy::dbNow()` — the **Oracle**
  clock, because `app.timezone` is `UTC` while `SYSDATE` is `+03:00` (see trap C13).
- One model: `app/Models/User.php` → Oracle table `APP_USERS`, `$primaryKey = 'user_id'` (resolved
  through the model's case-insensitive `getAttribute()` fallback; **`USER_NO` no longer exists** — it
  was the legacy ERP number), `$timestamps = false`, UPPERCASE `$fillable` including `IS_ADMIN`, and
  an `isAdmin()` helper.
- Eleven controllers + **two** middlewares (`EnsurePermission` as the `permission` alias, and
  `AppendSessionExpiry` appended to the `api` group in `bootstrap/app.php`) + seven support classes
  (`ArabicEncoding`, `PermissionCatalog`,
  `PermissionResolver`, `PermissionGrantSync`, `SessionPolicy`, `SettingsStore`, `ActivityLogger`).
  Still **no** Form Requests, **no** API Resources, **no** Policies. Logic is in controllers,
  validation is inline.
- Response envelope (hand-built arrays, snake_case keys):
  ```json
  { "success": true,  "message": "…", "data": …, "meta": { "total": 0, "page": 1, "limit": 100 } }
  { "success": false, "message": "…", "errors": { } }
  ```
  Messages are bilingual Arabic/English. `InvoiceController` now follows the envelope and
  `ArabicEncoding` like the rest (the old outlier, C5, is closed).
- Pagination is **manual** `page`/`limit` query params, and the `meta` shape is **inconsistent**:
  Customer/Worker/Invoice/AdminUsers emit `{total, page, limit, pages}`, Account/Currency emit
  `{total, page, limit, total_pages, has_more}`. Match the neighbouring controller.
- **Pest 3** for tests, **Pint** for formatting (`vendor/bin/pint --dirty --format agent` after
  touching PHP).
- **Laravel Boost** is configured (`boost.json`, `.agents/`, `.codex/config.toml`) and exposes MCP
  tools — prefer `search-docs`, `database-query`, `database-schema`, `record-rule` over manual
  equivalents. Skills live in `kyApp_API/.agents/skills/`.

### Endpoint surface (71 routes)

Every route carries **two** layers where relevant: `auth:sanctum` for the session, then
`permission:<code>` for the grant. Deny-by-default: no grant ⇒ **403** with the missing permission's
Arabic name. `IS_ADMIN = 1` bypasses the grant table entirely.

| Layer | Routes | Which |
|---|---|---|
| **Public (3)** | 3 | `POST /auth/login`, `POST /auth/biometric/login`, `GET /hello` (the client's connectivity probe) |
| **`auth:sanctum` only (6)** | 6 | `logout`, `me`, `user`, `auth/permissions`, `biometric/register`, `biometric/revoke` — these are the session's *own* property: gating `me` behind a grant would lock out a user who has none and could never learn why |
| **`auth:sanctum` + `permission:*`** | 62 | all business + admin routes |

Business guards: customers (6) · workers as three independent modules `employees`/`cutters`/`tailors`
(18) · accounts (12: `view` reads, `create`/`update` items, `structure_manage` for the tree,
`statement` for extracts) · currencies (8: `currencies.*` for the vocabularies,
`currencies.prices_view`/`prices_manage` for prices) · invoices (2) · `selectFromTable` behind
`system.*`.

Admin (`/users`, `/permissions`, `/sessions`, `/settings`, `/users/{id}/activity` — 16 routes) uses
`users.view` / `users.create` / `users.update` / `users.toggle` / `users.delete` /
`users.permissions_manage` / `users.activity_view` / `sessions.view` / `sessions.terminate` /
`settings.view` / `settings.update`.

`tests/Feature/BusinessRoutesSealedTest.php` is what *proves* this table (no public route outside
the three, every other route carries a guard, 401/403 samples per module) — if you change
`routes/api.php`, that test is the gate.

No API version prefix (`/v1`) and no route names anywhere.

---

## 6. The Oracle database (the single most important context)

**There are no migrations for business data.** `kyApp_API/database/migrations/` contains only the
stock Laravel skeleton (users/cache/jobs) plus `personal_access_tokens`. Those describe the *default*
(SQLite) connection, not Oracle.

The real schema is legacy Oracle 11g, owner `ACCOUNTS`, `prefix_schema => 'accounts'`. Key tables:

| Table | Purpose |
|---|---|
| `APP_USERS` | staff/customer logins. PK is **`USER_ID`** (`USER_NO` is gone — it was the legacy ERP number). Biometric columns: `DEVICE_TOKEN`, `DEVICE_NAME`, `PLATFORM`, `BIOMETRIC_ENABLED`, `BIOMETRIC_REGISTERED_AT`, `BIOMETRIC_LAST_USED`. IBAC adds **`IS_ADMIN`** (1 = full bypass, grant-free) |
| `APP_PERMISSIONS` | the catalog: 93 rows, 17 modules, ASCII `PERMISSION_CODE` (`module.action`) + Arabic `NAME_AR`/`DESCRIPTION_AR`. Seeded, not edited from the UI |
| `APP_USERS_PERMISSIONS` | **the IBAC core** — direct user→permission grants (`USER_ID`, `PERMISSION_ID`, `GRANTED_BY`, `IS_ACTIVE`, `EXPIRES_ON`) |
| `APP_SETTINGS` | 10 security/session settings with `VALUE_TYPE` (`int` / `bool` / `string`) and bounds, read through `SettingsStore` |
| `APP_USER_ACTIVITY` | audit trail (`ACTION_TYPE`, `DESCRIPTION_AR`, `STATUS`, `IP_ADDRESS`, `CREATED_ON`), written by `ActivityLogger` |
| `PERSONAL_ACCESS_TOKENS` | Sanctum tokens; **`EXPIRES_AT` is what the session policy actually enforces** (idle window, sliding) |
| `CUST` | customers (incl. `LIMITED_BALANCE` credit limit, `STOPPING_CUST` deactivation) |
| `TAILOR_EMPLOYEES`, `CUTTER`, `TAILOR` | the three worker registries, each with its own `ACC_NO` |
| `ACCOUNT` → `ACC_MAIN` → `ACC_SUB` → `ACC_SUB_GROUP` → `CHART_ACC` | the 5-level chart of accounts |
| `ENTRY_MAIN`, `ENTRY_SUB`, `ENTRY_TYPE` | journal entries → all statements |
| `CURRENCY`, `CUR_CODE`, `CUR_PRICE` | currencies and daily FX rates |
| `SALES_BILL` | invoices (read-only) |

The five IBAC tables plus their sequences and triggers are **DDL scripts, not migrations**, in
`kyApp_API/database/oracle/`: `01_ibac_schema.sql` (tables/sequences/triggers), `02_ibac_seed.php`
(catalog + settings), `03_ibac_bootstrap.php` (foundational grants), `04_ibac_rollback.sql`. They
were applied by hand through the Oracle MCP and are recorded line by line in `db_commends.md`.

`DBdevloping_history.md` (root) and `kyApp_API/DBdevloping_history.md` are the **de-facto schema
documentation** — read them before writing any SQL.

### Oracle 11g gotchas

- **No identity columns.** Auto-increment requires a Sequence + Trigger. Four exist for the
  Laravel infra tables (`PERSONAL_ACCESS_TOKENS_ID_TRG`, `MIGRATIONS_ID_TRG`, `JOBS_ID_TRG`,
  `FAILED_JOBS_ID_TRG`) — created to fix `ORA-01400` on login — and four more for the IBAC tables
  (`TRG_APP_PERMISSIONS`, `TRG_APP_USERS_PERM`, `TRG_APP_SETTINGS`, `TRG_APP_ACTIVITY`). DDL is
  recorded in `kyApp_API/db_commends.md`.
  ⚠️ Inside PL/SQL the sequence must be named **unqualified** (`SEQ_X.NEXTVAL`, not
  `ACCOUNTS.SEQ_X.NEXTVAL`): there is a **VIEW called `ACCOUNTS`** inside the `ACCOUNTS` schema, so a
  qualified reference parses as a column of that view and the trigger is created `INVALID`
  (`PLS-00302` → `ORA-04098`).
- **Business-table inserts use `MAX(pk) + 1`**, not sequences (Customer, Worker, Currency, Account
  stores). This is race-prone under concurrent writes. Don't copy the pattern into new code without
  flagging it; prefer a sequence where you can add one. New IBAC code does: `UserAdminController@store`
  takes `SEQ_APP_USERS_ID.NEXTVAL` explicitly (no trigger on `APP_USERS`, so the ERP is unaffected).
- **Column-name case is unreliable.** Oracle PDO may return lowercase keys while the catalog is
  UPPERCASE. `User::getAttribute()` is overridden with a case fallback, and Flutter models read
  dual-case. Preserve both.
- **Max identifier length 30** (`config/oracle.php`), `server_version => '11g'`.
- **`TRUNC()` here is arithmetic, not temporal.** In the controllers it derives the chart-of-accounts
  hierarchy — `TRUNC(c.ACC_NO/10000) = s.ACC_PART` walks `CHART_ACC` → `ACC_SUB`. Don't mistake it
  for a date function. (The `TRUNC(ENTRY_DATE)` idiom appears in the SQL logs in `db_commends.md`,
  not in controller code.)
- **Date binds use `TO_DATE()` with table-specific formats** that are *not* consistent:
  `AccountController` statements use `TRXN_DATE >= TO_DATE(:from_date, 'DD/MM/YYYY')`, while
  `CurrencyController` prices use `TO_DATE(:day_date, 'YYYY-MM-DD')`. Copy the neighbouring query.
- Statement queries bind `:acc_no`, `:from_date`, `:to_date`, `:id`, `:cur_no`. Always bind; never
  interpolate.
- `oci8` DLL/PATH conflicts are a known local-setup failure (moving Oracle 10g → 11g left a stale
  `oci8_19` on `PATH`). See `kyApp_API/user_commends.md`.

### The Arabic encoding problem

`NLS_CHARACTERSET = WE8MSWIN1252` means Arabic is stored as Windows-1256 bytes and arrives as
mojibake. Two repair layers exist and **both must stay in sync**:

- Server: `kyApp_API/app/Support/ArabicEncoding.php` — `fixMojibake()` / `cleanData()` on **read**,
  `toOracleSearchChars()` on **write and search**.
- Client: `lib/core/utils/arabic_encoding_utils.dart` — `ArabicEncodingUtils.fix()`, with a
  `_cp1256Map` table. The client sends plain UTF-8 JSON; conversion is the server's job.

**The write path is `toOracleSearchChars()`, and there is no alternative.** The app connects with
`charset=AL32UTF8`, so binding raw CP1256 bytes makes Oracle substitute the replacement char —
`خالد سالم` measured live with `DUMP()`: `bf,bf,bf` (3 chars instead of 9, value destroyed). Mapping
each CP1256 byte to the Latin-1 char of the same code (`0xD6` ⇒ `U+00D6`) lands the original byte,
exactly like the legacy system's rows. The old `encodeForOracle()` helper was **deleted** for this
reason; `tests/Unit/ArabicWritePathTest.php` pins the invariant.

Searching Arabic needs **both** character forms, because stored bytes and typed UTF-8 differ:

```sql
WHERE CUST_NAME LIKE '%Ç%' OR CUST_NAME LIKE '%ا%'
```

Any new Arabic text field — read or write — must be routed through the repair layer end to end, or
it will render as garbage or be stored corrupted.

### Business rule worth memorizing

Account **`12310000` — "عملاء الكبودي للخياطة"** is the customer control account. The account tree
hides individual customer accounts **except** this one (`ACC_PART` 123 / `GROUP_ID` 5 special-casing
in `AccountController@getAccountTree`). Statements and balances tie out against it.

---

## 7. Commands

### Flutter (from repo root)

```bash
flutter pub get                     # install deps (no codegen step exists)
flutter analyze                     # MUST be clean: "No issues found!"
flutter test                        # run test/
flutter test test/api_config_test.dart                       # single file
flutter test --plain-name "ApiConfigRepository normalizeUrl" # single test
flutter run                                                 # debug on default device
flutter run -d chrome                                       # web (watch for CORS preflight noise)
flutter build apk --release                                 # see §9 before shipping
```

### Laravel (from `kyApp_API/`)

```bash
composer install
composer dev                        # serve + queue + pail + vite concurrently
composer test                       # config:clear && php artisan test
php artisan serve --host 0.0.0.0    # LAN-accessible dev server (required for device testing)
php artisan route:list --path=api
php artisan config:show database.default
vendor/bin/pint --dirty --format agent   # REQUIRED after modifying any PHP file
vendor/bin/pest                     # or: php artisan test --compact --filter=AuthTest
php artisan tinker --execute 'User::count();'   # single quotes — prevents shell expansion
```

Run the **narrowest** test set that covers your change; ask the user to run the full suite afterward.

### Oracle (via the configured MCP server)

An `oracle` MCP server is available — prefer it over ad-hoc SQL clients for read-only inspection
(`list_tables`, `execute_sql`, `get_query_plan`). Never run DDL or `DELETE`/`UPDATE` against the
production Oracle schema without explicit user approval.

---

## 8. Testing

### Flutter — `test/` (4 files, 51 tests, `flutter_test`)

| File | Covers |
|---|---|
| `test/widget_test.dart` | *Despite the name*, unit tests for `UserModel.fromJson` (incl. Arabic `displayName`) and `AuthResponse.fromJson` |
| `test/api_config_test.dart` | `ApiConfigRepository.normalizeUrl` (trailing slashes/trim) and `ApiConstants` defaults |
| `test/responsive_layout_test.dart` | `Responsive` breakpoints at 360×640 and 1280×800, pumps `EmployeeMainLayout`, and renders the 9 admin screens at both sizes (18 cases) asserting `takeException()` is null — an **overflow regression test** |
| `test/ibac_test.dart` | permission-resolution rules (mirror of `PermissionResolver::can`), catalog integrity (no duplicate code, every module has a title + wildcard), raw-Oracle row reading (UPPER keys, numeric strings `'7'`/`'1'`/`'0'`), the unified section registry, and picker behaviour |

Conventions: `group()` + descriptive English names, no mocking library, no network tests (repositories
are faked), no `integration_test/`. When you add a widget, extend `responsive_layout_test.dart` rather
than inventing a new harness — overflow regressions are this project's recurring failure mode.

### Laravel — `kyApp_API/tests/` (Pest 3, 127 tests)

| File | Covers |
|---|---|
| `tests/Feature/AuthTest.php` | login validation 422, bad credentials 401, `/auth/me` + `/auth/logout` reject unauthenticated |
| `tests/Feature/TableQueryTest.php` | `/api/selectFromTable` shape, 404 unknown table, 422 on injection attempt, 422 on `limit > 1000`, plus the sealed/behaviour changes |
| `tests/Feature/IbacCoreTest.php` | catalog integrity, resolver rules (admin bypass, `system.*`, literal, module wildcard, deny-by-default), session policy, middleware 401/403, the **database clock** (`dbNow()` vs `SYSDATE`), the sweep (dead tokens deleted, live ones untouched), and `X-Session-Expires-At` with/without a session |
| `tests/Feature/UsersAdminTest.php` | user administration: auth required, named-permission 403, validation, self-protection, last-admin guard, activity trail shape |
| `tests/Feature/PermissionSyncTest.php` | `PUT /users/{id}/permissions` atomic replace, unknown codes 422, anti-escalation (cannot grant what you don't hold), session termination on change |
| `tests/Feature/ActiveSessionsTest.php` | session listing shape, idle/expiry derivation, terminate by token and by user, self-session rules |
| `tests/Feature/SecuritySettingsTest.php` | settings read/write, per-type bounds, locked settings, `settings.update` guard |
| `tests/Feature/BusinessRoutesSealedTest.php` | **the route-sealing gate**: no public route outside the three, every business route carries a `permission:` guard, 401/403 samples per module, invoice envelope |
| `tests/Unit/ArabicWritePathTest.php` | the Arabic **write contract** for Oracle — bound chars carry the exact CP1256 bytes, no raw-byte binding, read-back equality, and `encodeForOracle()` stays deleted |
| `tests/Unit/ArabicReadPathTest.php` | the Arabic **read contract** — `fixMojibake()` repairs mojibake back to proper Arabic and is **idempotent** (a second pass on good text changes nothing, incl. through `cleanData()`); runs with **no** Oracle connection |
| `tests/Feature/ExampleTest.php`, `tests/Unit/ExampleTest.php` | skeleton |

`tests/Pest.php` binds `Tests\TestCase` to Feature with **`RefreshDatabase` commented out**.
`phpunit.xml` sets `DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:` — but that only affects the
*default* connection. The IBAC tests hardcode `DB::connection('oracle')`, so **they only pass on a
machine with the live Oracle instance reachable**. Expect them to fail in a clean environment; that is
not your bug.

⚠️ **IBAC feature tests are deliberately read-only** against the live legacy schema: they never
create or delete a user. Writing routes are covered by their *refusal* branches (422/403/404/409),
which return before any `INSERT`. Do not add tests that write to `CUST`, `ENTRY_MAIN`, or any other
ERP table without explicit user approval. The one exception is `PERSONAL_ACCESS_TOKENS` itself:
the sweep test exercises a `DELETE` that is the behaviour under test, and the sliding-renewal path uses
an **in-memory** token whose deadline already sits past the renewal horizon, so `slide()` skips its write.

Nothing covers customers, workers, accounts, currencies, invoices, or biometrics. Adding Pest feature
tests for any controller you touch is welcome — use `php artisan make:test --pest {Name}` (no
directory in the name).

Never delete tests without approval.

---

## 9. Build & release

```bash
flutter build apk --release
```

> ⚠️ **Not production-ready.** Three blockers, all in `android/`:
> 1. **`INTERNET` permission is missing from `android/app/src/main/AndroidManifest.xml`.** It is
>    declared only in `src/debug/` and `src/profile/`. A release APK therefore has **no network
>    access** and will fail every API call. Add it to the main manifest before shipping.
> 2. `applicationId` is still `com.example.ky_apps` (`android/app/build.gradle.kts:24`).
> 3. Release builds sign with the **debug** key (`signingConfig = signingConfigs.getByName("debug")`,
>    same file, ~line 37).
>
> Also: the web build is only partly rebranded. `web/index.html` has `<title>ky_apps</title>` but its
> description meta still reads "A new Flutter project."; `web/manifest.json` still uses the stock
> Flutter blue `#0175C2` for `background_color` / `theme_color`. Cosmetic, but fix before a web release.

Working Android config: `compileSdk = 36`, `minSdk = 23` (raised from 21 — required by `local_auth`
and `flutter_secure_storage`; **do not lower it**), NDK `27.0.12077973`, Java/Kotlin target 11,
AGP 8.7.0, Kotlin 1.9.24.

> `android/build.gradle.kts` and `settings.gradle.kts` put **Aliyun Maven mirrors**
> (`maven.aliyun.com/repository/google|public`) ahead of `google()`/`mavenCentral()`. This is a
> deliberate network workaround for Gradle download timeouts — keep it.

Version: `pubspec.yaml` `version: 1.0.0+1`.

---

## 10. Code style

### Dart

- Files `snake_case`, classes `PascalCase`, variables/methods `camelCase`.
- Strict null safety. Avoid `!`; prefer `?.`, `??`, and explicit guards.
- Descriptive names (`isRegisteredForDiscounts`, not `discount()`).
- Comments are **paired Arabic + English** `///` doc comments. Match this style:
  ```dart
  /// خدمة التخزين الآمن لحفظ التوكن وبيانات الاعتماد المشفرة
  /// Secure storage service to manage encrypted tokens and credentials
  ```
- `analysis_options.yaml` is the stock `package:flutter_lints/flutter.yaml` include with **no custom
  rules and no excludes**. Keep it that way unless asked.

### PHP / Laravel

Follow [`kyApp_API/AGENTS.md`](kyApp_API/AGENTS.md). Headlines: Laravel 12 structure (no
`Http/Kernel.php`, no `Console/Kernel.php`), `php artisan make:*` with `--no-interaction` for new
files, `casts()` method over `$casts` property, always run Pint, curly braces on all control
structures, explicit return types and parameter type hints, constructor property promotion.

### Commits

The existing history is written in **Arabic**, imperative, no conventional-commit prefixes:

```
50df688 اكمال اصلاح واجهات الحسابات
3e8cc10 اصلاح واجهات الحسابات
5ce6620 اعداد المصادقه بالبصمه
```

Match that style. Never commit unless the user asks. Never `--no-verify`. Never force-push.

---

## 11. Known issues & traps (read before you touch anything)

### Security

| # | Issue | Detail |
|---|---|---|
| S1 | ~~All business routes were unauthenticated~~ **CLOSED (phase 7)** | Every business route now sits behind `auth:sanctum` + `permission:<code>`; only `POST /auth/login`, `POST /auth/biometric/login` and `GET /hello` are public, and 6 session-ownership routes are auth-only by design. `BusinessRoutesSealedTest` is the gate. `selectFromTable` additionally has a restricted-table deny list (11 tables) and redacts any column matching `PASSWORD`/`DEVICE_TOKEN`/`TOKEN`/`SECRET`/`KEY`. |
| S2 | **Plaintext password comparison** | `AuthController@login` tries `$userPassword === $password` *before* `Hash::check`. Deliberate legacy support, but security-relevant — don't "fix" it silently, it will lock out real users. |
| S3 | **Oracle credentials committed as config defaults** | `config/database.php:122-123` falls back to `ACCOUNTS` / `acc`. Real credentials belong in `.env` only. |
| S4 | **Sanctum `expiration => null` — and it must stay null** | `Guard.php` compares that setting to `created_at`, so any value becomes a hard absolute age that kicks active users out. Lifetime is enforced by `SessionPolicy` on `EXPIRES_AT` (idle sliding renewal + `session_absolute_days`). The old "tokens never expire" hole is closed; do not re-open it by setting `expiration`. The same hole is re-opened by **leaving dead token rows behind**: a rejected token is now deleted (`discard()`) and `purgeExpired()` sweeps the leftovers on login and on the sessions screen — including `EXPIRES_AT IS NULL` rows idle beyond the window, which otherwise sit on that screen as "active" forever. |
| S5 | **`WorkerController@store*/update*` has zero validation** | It does `$request->only([UPPERCASE Oracle columns])` and inserts directly. The Flutter client must send keys like `EMP_NAME`, `CUTTER_PHONE1`. Add validation before extending it. |
| S6 | **Release APK has no `INTERNET` permission** | See [§9](#9-build--release). |
| S7 | **Cache payload ceiling on Oracle: 3000 bytes** | The `CACHE` table writes `VALUE` through `merge … (select :value from dual)`, and Oracle refuses a bound string over 4000 bytes (`ORA-01461`). `PermissionResolver` (`MAX_CACHE_BYTES`) and `SettingsStore` cap themselves at 3000 and fall back to reading the table; Arabic never enters the cache. Raise a payload and you will 500 every authenticated request. |

### Correctness

| # | Issue | Detail |
|---|---|---|
| C1 | **Arabic encoding is a two-sided contract** | Read: `ArabicEncoding::fixMojibake()`/`cleanData()` (server) + `ArabicEncodingUtils.fix()` (client). **Write and search: `toOracleSearchChars()` only.** Binding raw CP1256 bytes corrupts them to `0xBF` over the AL32UTF8 connection (measured: `خالد سالم` → `bf,bf,bf`), which is why `encodeForOracle()` was deleted — never reintroduce it. Repair each value **exactly once** — before the 2026-10-20 idempotence guard a second `cleanData()` pass mapped the *bytes* of good Arabic through the CP1256 table (`موظف` → `ظ…ظˆط¸ظپ`), which is what the sessions and security-settings screens displayed. `tests/Unit/ArabicWritePathTest.php` + `tests/Unit/ArabicReadPathTest.php` guard this. |
| C2 | **`AccountController@getDetailedStatement` is a stub in disguise** | It reads `from_date`/`to_date`/`cur_no` but **no branch of its `switch ($type)` ever uses them** — they are only echoed back in `summary`. `$totalDebit`/`$totalCredit` are initialized to `0` and never updated, so `summary.total_debit`/`total_credit` are **always 0**; only `total_balance` is real. Pagination applies only to the `type=account`-with-no-`id` branch. |
| C3 | **`getAccountStatement` queries `ACC_TRXN`** inside a silently-swallowed `try/catch` ("جدول الحركات غير موجود") while every other statement uses `ENTRY_MAIN`/`ENTRY_SUB`. Returns empty transactions when the table is absent. |
| C4 | **`getAccountTree` does heavy N+1 querying** — one query per node per level. |
| C5 | ~~`InvoiceController` skips the envelope and `ArabicEncoding`~~ **CLOSED (phase 7)** | Unified envelope + `cleanData()` + search by bill number or customer name in both byte forms + `meta: {total, page, limit, pages}` and explicit 404. |
| C6 | **`MAX(pk)+1` primary keys** on business tables — race-prone. |
| C7 | **`UserFactory` / `DatabaseSeeder` are broken skeleton leftovers** — they target `name`/`email`, which don't exist on the Oracle `APP_USERS` model. Don't rely on them. |
| C8 | **Mixed Riverpod generations** — `StateNotifier` (legacy import) in accounts/currency alongside modern `Notifier` elsewhere. |
| C9 | **Dead code**: `lib/features/auth/data/models/biometric_status_model.dart` is never imported. |
| C10 | **Non-functional settings stubs**: the dark-mode switch and font-size slider in `settings_section.dart` do nothing (no dark theme exists). Language is a locked "عربي (RTL)" badge. |
| C11 | **Stale comment**: `AppColors.primary` is `0xFF7C2D12` (brown) but commented as royal navy. |
| C12 | **`USER_ID` ≠ `USER_NO`** | The Oracle column and our PK is `USER_ID`; `USER_NO` (the legacy ERP number) was **dropped from `APP_USERS`** and is absent from `$fillable` on purpose — re-adding it makes inserts fail with `ORA-00904`. Biometric login and every IBAC lookup key on `USER_ID`. |
| C13 | **Two clocks: PHP is UTC, `SYSDATE` is +03:00** | `config/app.php` `timezone => 'UTC'` while the Oracle instance runs at +03:00. Any session math that uses `now()` breaks in both directions at once: deadlines written by PHP look expired to the screen's `SYSDATE` comparison, and a `SYSDATE - 1` termination reads as a *future* expiry to `SessionPolicy`, so a cut session keeps working for three hours. **All session time goes through `SessionPolicy::dbNow()`** (offset measured once per request). Do not "fix" this by changing `app.timezone` — that re-dates every other module's timestamps. Any new code comparing `EXPIRES_AT`/`LAST_USED_AT` must use `dbNow()`, and the client compares the header text against device-local time. |

### Documentation drift

- `appsroles.md` and `kyApp_API/roles.md` prescribe freezed, json_serializable, `RetryInterceptor`,
  `AsyncNotifierProvider`, `--dart-define`/`.env` secrets, and dotenv. **None of these are actually
  used.** Treat those files as aspirational standards, and follow the *code* for what is real.
- `kyApp_API/roles.md` is misnamed — despite the filename it is **not** a roles/permissions model.
  It is a Flutter + API integration standards reference. There is **no RBAC** in this project; access
  control is IBAC (direct user grants) and lives in `App\Support\PermissionCatalog` /
  `PermissionResolver` + `ibac_permissions_plan.md`.
- `devloping_history.md` / `db_commends.md` describe statements over `JOURNAL_ENTRY_REC`; the code
  uses the base tables `ENTRY_MAIN`/`ENTRY_SUB`/`ENTRY_TYPE`.
- `implementation_plan.md` is referenced by `kyApp_API/todo.md` but does not exist.
- Root `README.md` is the untouched Flutter template; `kyApp_API/README.md` is the stock Laravel one.

---

## 12. Documentation index

| File | What it is | Read it when… |
|---|---|---|
| `ibac_permissions_plan.md` | **The IBAC design record** — accepted decisions D1–D8, the data model, catalog (17 modules / 93 codes), session policy, phases 0–9 with what was actually built, and the deviation tables | touching permissions, sessions, `APP_USERS`, or any admin screen |
| `appsroles.md` | Flutter/Dart coding standards (aspirational) | starting a new Flutter feature |
| `DBdevloping_history.md` | **Oracle schema documentation** — tables, columns, encoding story, the `12310000` rule | writing any SQL or touching models |
| `devloping_history.md` | Flutter-side changelog with exact file paths per task | tracing why something was built the way it was |
| `db_commends.md` | Oracle SQL actually executed during development, with sequence/trigger DDL | you need a working statement query |
| `user_commends.md` | Verbatim user prompts + captured error traces (Gradle/Java conflicts, CORS, mojibake samples, ORA-01400) | reproducing a reported bug |
| `todo.md` | Dated task checklists | checking what is considered done vs pending |
| `kyApp_API/AGENTS.md` | Backend agent guide | working in `kyApp_API/` |
| `kyApp_API/roles.md` | Flutter + API integration standards (misnamed) | — |
| `kyApp_API/.agents/rules/appsroles.md` | copy of `roles.md` with `trigger: glob` frontmatter for Boost | — |
| `kyApp_API/.agents/skills/` | Boost skills: `laravel-best-practices` (19 rule docs), `testing-best-practices` (9), `tailwindcss-development`, `infer-conventions` | working in that domain |

`kyApp_API/‏‏AGENTS - نسخة.md` is an untracked copy of the old generic Boost boilerplate. It carries
RTL mark characters in its filename — handle it with quotes, and don't mistake it for a real guide.

---

## 13. How to work in this repo

1. **Read the nearest `AGENTS.md` first** — `kyApp_API/AGENTS.md` when working in the backend.
2. **Check sibling files before writing new code.** Conventions here are local and inconsistent
   (envelope shapes, Riverpod generations, pagination `meta`). Match the neighbour, don't
   "improve" it drive-by.
3. **Verify package versions before relying on an API** — `composer show --direct` (PHP),
   `pubspec.lock` (Dart). Laravel 12 and Riverpod 3 both broke with earlier majors.
4. **Do not create documentation files** unless the user explicitly asks.
5. **Do not change dependencies, add codegen, or create new top-level folders** without approval.
6. **Do not run destructive operations** against the Oracle schema, and never `git push --force`.
7. **Do not commit `.env`**, tokens, or Oracle credentials. `.env` is gitignored; keep it that way.
8. **Gates before you report done**: `flutter analyze` clean, `flutter test` passing,
   `vendor/bin/pint --dirty --format agent` run, relevant Pest tests passing.
9. **If a change touches Arabic text, prove it end to end** — DB → `ArabicEncoding` → JSON →
   `ArabicEncodingUtils.fix()` → widget. Mojibake that appears only on real Oracle data will not
   show up in any test.
10. **Be concise.** Explain the non-obvious; don't narrate the diff.

---

## 14. Quick reference

```
Business        الكبودي للخياطة الرجالية — Al-Kaboodi Men's Tailoring (Yemen)
Client          Flutter, Dart ^3.7.2, Riverpod 3, Dio 5, go_router 17, Arabic RTL (Cairo font)
Backend         Laravel 12.69, PHP ^8.2.12, Sanctum 4, yajra/laravel-oci8 12.0, Pest 3, Pint
Database        Oracle 11g, schema ACCOUNTS, charset WE8MSWIN1252 (Arabic = CP1256 bytes)
Default API     http://192.168.0.11:8000/api   (runtime-configurable, key ky_api_base_url)
Health probe    GET /api/hello
Routes          71 in routes/api.php — 3 public, 6 auth-only, the rest auth:sanctum + permission:<code>
Access          IBAC: APP_PERMISSIONS (93 codes / 17 modules) + APP_USERS_PERMISSIONS, IS_ADMIN bypass
Sessions        SessionPolicy on PERSONAL_ACCESS_TOKENS.EXPIRES_AT (idle 240′ sliding, absolute 14d) —
                all time via SessionPolicy::dbNow() (Oracle clock), dead tokens deleted on rejection,
                purgeExpired() on login + sessions screen, X-Session-Expires-At header + 30 s client watchdog
Storage keys    ky_auth_token, ky_user_type, ky_user_data, ky_api_base_url,
                ky_biometric_enabled, ky_biometric_user_id,
                ky_user_permissions, ky_is_admin, ky_session_expires_at
Device salt     "ky_apps_biometric_v1_2026" (sha256, part of the server contract)
Arabic write    ArabicEncoding::toOracleSearchChars() — never raw CP1256 bytes (they store as 0xBF)
Special acct    12310000 — عملاء الكبودي للخياطة (customer control account)
Android         applicationId com.example.ky_apps · minSdk 23 · compileSdk 36 · debug-signed release
Quality gates   flutter analyze → flutter test → pint --dirty → pest
```
