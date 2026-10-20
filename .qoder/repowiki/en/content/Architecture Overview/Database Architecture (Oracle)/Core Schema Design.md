# Core Schema Design

<cite>
**Referenced Files in This Document**
- [01_ibac_schema.sql](file://kyApp_API/database/oracle/01_ibac_schema.sql)
- [02_ibac_seed.php](file://kyApp_API/database/oracle/02_ibac_seed.php)
- [03_ibac_bootstrap.php](file://kyApp_API/database/oracle/03_ibac_bootstrap.php)
- [04_ibac_rollback.sql](file://kyApp_API/database/oracle/04_ibac_rollback.sql)
- [PermissionCatalog.php](file://kyApp_API/app/Support/PermissionCatalog.php)
- [ArabicEncoding.php](file://kyApp_API/app/Support/ArabicEncoding.php)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)

## Introduction
This document explains the core Oracle database schema design for the IBAC (Identity-Based Access Control) foundation. It focuses on:
- Foundational tables: `APP_USERS`, `APP_PERMISSIONS`, `APP_SETTINGS`, plus supporting tables for direct user permissions and activity logging.
- Data types, constraints, indexes, sequences, and triggers used for automatic ID generation.
- Bilingual support for Arabic and English through separate columns.
- The legacy-safe modification strategy for `APP_USERS` to preserve compatibility with existing ERP systems while adding admin flags and password capacity.
- The seed and bootstrap process that populates permission catalogs, security settings, comments, and initial administrator access.

The schema targets an Oracle 11g environment under the `ACCOUNTS` schema, using a Windows-1256-compatible approach for Arabic text storage and retrieval.

## Project Structure
The Oracle-related schema and initialization logic live under the API layer:
- SQL DDL and rollback scripts define tables, sequences, triggers, indexes, and verification queries.
- PHP scripts seed reference data and perform final bootstrap steps such as applying bilingual comments and promoting the first administrator.
- Application support classes provide the canonical permission catalog and safe Arabic encoding helpers.

```mermaid
graph TB
subgraph "Oracle ACCOUNTS Schema"
APP_USERS["APP_USERS<br/>Legacy users table"]
APP_PERMISSIONS["APP_PERMISSIONS<br/>Permission catalog"]
APP_USERS_PERMISSIONS["APP_USERS_PERMISSIONS<br/>Direct grants"]
APP_SETTINGS["APP_SETTINGS<br/>Security & session settings"]
APP_USER_ACTIVITY["APP_USER_ACTIVITY<br/>Audit log"]
end
subgraph "Initialization Scripts"
SCHEMA_SQL["01_ibac_schema.sql"]
SEED_PHP["02_ibac_seed.php"]
BOOTSTRAP_PHP["03_ibac_bootstrap.php"]
ROLLBACK_SQL["04_ibac_rollback.sql"]
end
subgraph "Application Support"
PERMISSION_CATALOG["PermissionCatalog.php"]
ARABIC_ENCODING["ArabicEncoding.php"]
end
SCHEMA_SQL --> APP_USERS
SCHEMA_SQL --> APP_PERMISSIONS
SCHEMA_SQL --> APP_USERS_PERMISSIONS
SCHEMA_SQL --> APP_SETTINGS
SCHEMA_SQL --> APP_USER_ACTIVITY
SEED_PHP --> APP_PERMISSIONS
SEED_PHP --> APP_SETTINGS
BOOTSTRAP_PHP --> APP_USERS
BOOTSTRAP_PHP --> APP_USERS_PERMISSIONS
BOOTSTRAP_PHP --> APP_USER_ACTIVITY
PERMISSION_CATALOG --> SEED_PHP
ARABIC_ENCODING --> SEED_PHP
ARABIC_ENCODING --> BOOTSTRAP_PHP
```

**Diagram sources**
- [01_ibac_schema.sql:21-184](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L184)
- [02_ibac_seed.php:36-89](file://kyApp_API/database/oracle/02_ibac_seed.php#L36-L89)
- [02_ibac_seed.php:212-279](file://kyApp_API/database/oracle/02_ibac_seed.php#L212-L279)
- [03_ibac_bootstrap.php:135-185](file://kyApp_API/database/oracle/03_ibac_bootstrap.php#L135-L185)
- [PermissionCatalog.php:271-316](file://kyApp_API/app/Support/PermissionCatalog.php#L271-L316)
- [ArabicEncoding.php:143-162](file://kyApp_API/app/Support/ArabicEncoding.php#L143-L162)

**Section sources**
- [01_ibac_schema.sql:1-19](file://kyApp_API/database/oracle/01_ibac_schema.sql#L1-L19)
- [01_ibac_schema.sql:21-184](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L184)
- [02_ibac_seed.php:1-24](file://kyApp_API/database/oracle/02_ibac_seed.php#L1-L24)
- [03_ibac_bootstrap.php:1-14](file://kyApp_API/database/oracle/03_ibac_bootstrap.php#L1-L14)
- [04_ibac_rollback.sql:1-11](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L1-L11)

## Core Components
The core schema consists of five primary objects:
- `APP_USERS`: A pre-existing legacy table extended with an admin flag and wider password column.
- `APP_PERMISSIONS`: A permission catalog storing module-action pairs, bilingual names, core flags, active flags, and sort order.
- `APP_USERS_PERMISSIONS`: Direct user-to-permission grants without roles.
- `APP_SETTINGS`: System configuration entries for security and sessions, including value type, ranges, lockability, and bilingual labels.
- `APP_USER_ACTIVITY`: Lightweight audit trail for user actions, login attempts, session management, and system bootstrap.

Key characteristics:
- Primary keys are enforced via explicit constraints.
- Sequences generate IDs; triggers assign sequence values when inserts omit them.
- Indexes optimize lookups by module, user, permission, and activity time.
- Bilingual support uses Arabic-only or Arabic-and-English columns where needed.
- Legacy compatibility is preserved by altering `APP_USERS` instead of replacing it.

**Section sources**
- [01_ibac_schema.sql:21-184](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L184)

## Architecture Overview
The schema implements a minimal identity-based access control model:
- Users are identified by `USER_ID`.
- Permissions are defined centrally in `APP_PERMISSIONS`.
- Grants are assigned directly to users in `APP_USERS_PERMISSIONS`.
- An `IS_ADMIN` flag on `APP_USERS` acts as a global override.
- Security behavior is controlled by `APP_SETTINGS`.
- All significant operations are recorded in `APP_USER_ACTIVITY`.

```mermaid
erDiagram
APP_USERS {
number user_id PK
varchar2 user_name
varchar2 user_password
number is_admin
}
APP_PERMISSIONS {
number permission_id PK
varchar2 permission_code UK
varchar2 module_code
varchar2 action_code
varchar2 name_ar
varchar2 name_en
number is_core
number sort_order
number is_active
varchar2 description_ar
}
APP_USERS_PERMISSIONS {
number id PK
number user_id FK
number permission_id FK
number granted_by
date granted_on
date expires_on
number is_active
varchar2 note
}
APP_SETTINGS {
number setting_id PK
varchar2 setting_key UK
varchar2 setting_value
varchar2 value_type
varchar2 name_ar
varchar2 description_ar
number min_value
number max_value
number is_lockable
number sort_order
number updated_by
date updated_on
}
APP_USER_ACTIVITY {
number activity_id PK
number user_id
number target_user_id
varchar2 action_code
varchar2 module_code
varchar2 entity_type
varchar2 entity_id
varchar2 description_ar
varchar2 status
varchar2 ip_address
varchar2 user_agent
varchar2 platform
date created_on
}
APP_USERS ||--o{ APP_USERS_PERMISSIONS : "grants"
APP_PERMISSIONS ||--o{ APP_USERS_PERMISSIONS : "granted_to"
```

**Diagram sources**
- [01_ibac_schema.sql:26-168](file://kyApp_API/database/oracle/01_ibac_schema.sql#L26-L168)

## Detailed Component Analysis

### APP_USERS — Legacy User Table Extension
`APP_USERS` is not recreated; it is altered to remain compatible with existing ERP writes:
- `USER_PASSWORD` is widened to accommodate future hashing while preserving legacy plain-text passwords.
- `IS_ADMIN` is added as a numeric flag defaulting to inactive.
- A dedicated sequence `SEQ_APP_USERS_ID` is created for new user IDs, but no trigger is attached to avoid breaking legacy ERP insert paths.

Design implications:
- Existing ERP applications continue writing to `APP_USERS` without changes.
- New application code can use the sequence for generated IDs if desired.
- Admin privileges are represented by `IS_ADMIN = 1`.

```mermaid
flowchart TD
Start(["Legacy APP_USERS exists"]) --> WidenPassword["Widen USER_PASSWORD column"]
WidenPassword --> AddAdminFlag["Add IS_ADMIN flag"]
AddAdminFlag --> CreateSequence["Create SEQ_APP_USERS_ID"]
CreateSequence --> NoTrigger["Do NOT create auto-ID trigger<br/>to preserve ERP compatibility"]
NoTrigger --> End(["Legacy-safe extension complete"])
```

**Diagram sources**
- [01_ibac_schema.sql:21-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L33)
- [04_ibac_rollback.sql:33-38](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L33-L38)

**Section sources**
- [01_ibac_schema.sql:21-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L33)
- [04_ibac_rollback.sql:33-38](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L33-L38)

### APP_PERMISSIONS — Permission Catalog
`APP_PERMISSIONS` stores the authoritative list of permissions:
- `PERMISSION_ID`: Numeric primary key generated by a sequence and trigger.
- `PERMISSION_CODE`: Unique code following a module-action pattern, including wildcard forms.
- `MODULE_CODE` and `ACTION_CODE`: Structural fields for grouping and filtering.
- `NAME_AR` and `NAME_EN`: Bilingual display and descriptive names.
- `IS_CORE`: Indicates foundational view/create/update/delete actions.
- `SORT_ORDER`: Controls presentation order within modules.
- `IS_ACTIVE`: Allows deactivating a permission without removing historical grants.
- Audit timestamps and creator/updater fields are included.

Indexes:
- A composite index on `MODULE_CODE` and `SORT_ORDER` supports UI rendering and ordering.

Constraints:
- Primary key on `PERMISSION_ID`.
- Unique constraint on `PERMISSION_CODE`.
- Check constraints enforce binary flags.

```mermaid
classDiagram
class APP_PERMISSIONS {
+number PERMISSION_ID
+varchar2 PERMISSION_CODE
+varchar2 MODULE_CODE
+varchar2 ACTION_CODE
+varchar2 NAME_AR
+varchar2 NAME_EN
+number IS_CORE
+number SORT_ORDER
+number IS_ACTIVE
+varchar2 DESCRIPTION_AR
+date CREATED_ON
+number CREATED_BY
+date LAST_UPDATED_ON
+number LAST_UPDATED_BY
}
class SEQ_APP_PERMISSIONS
class TRG_APP_PERMISSIONS
APP_PERMISSIONS --> SEQ_APP_PERMISSIONS : "ID generated by"
APP_PERMISSIONS --> TRG_APP_PERMISSIONS : "BEFORE INSERT trigger"
```

**Diagram sources**
- [01_ibac_schema.sql:38-75](file://kyApp_API/database/oracle/01_ibac_schema.sql#L38-L75)

**Section sources**
- [01_ibac_schema.sql:35-75](file://kyApp_API/database/oracle/01_ibac_schema.sql#L35-L75)

### APP_USERS_PERMISSIONS — Direct User Grants
`APP_USERS_PERMISSIONS` implements direct user-to-permission assignment:
- `ID`: Primary key generated by a sequence and trigger.
- `USER_ID`: Foreign key referencing `APP_USERS.USER_ID`; deletions cascade.
- `PERMISSION_ID`: References `APP_PERMISSIONS.PERMISSION_ID`.
- `GRANTED_BY`, `GRANTED_ON`, `EXPIRES_ON`: Grant provenance and optional expiration.
- `IS_ACTIVE`: Soft-deletion style deactivation.
- `NOTE`: Optional human-readable reason.

Indexes:
- Composite index on `USER_ID` and `IS_ACTIVE` optimizes active-grant checks.
- Index on `PERMISSION_ID` supports reverse lookup from permission to users.

Constraints:
- Primary key on `ID`.
- Unique constraint on `(USER_ID, PERMISSION_ID)` prevents duplicate grants.
- Foreign keys enforce referential integrity.
- Check constraint enforces binary active flag.

```mermaid
sequenceDiagram
participant Admin as "Administrator"
participant API as "API Layer"
participant DB as "Oracle Database"
participant Seq as "SEQ_APP_USERS_PERM"
participant Trigger as "TRG_APP_USERS_PERM"
Admin->>API : "Grant permission to user"
API->>DB : "INSERT into APP_USERS_PERMISSIONS"
DB->>Trigger : "BEFORE INSERT"
Trigger->>Seq : "NEXTVAL"
Seq-->>Trigger : "New ID"
Trigger-->>DB : "Set ID"
DB-->>API : "Insert success"
```

**Diagram sources**
- [01_ibac_schema.sql:77-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L77-L112)

**Section sources**
- [01_ibac_schema.sql:77-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L77-L112)

### APP_SETTINGS — System Configuration
`APP_SETTINGS` provides editable system configuration:
- `SETTING_ID`: Primary key generated by a sequence and trigger.
- `SETTING_KEY`: Unique configuration key consumed by application code.
- `SETTING_VALUE`: Textual value interpreted according to `VALUE_TYPE`.
- `VALUE_TYPE`: Enumerated type (`int`, `bool`, `string`, `json`).
- `NAME_AR` and `DESCRIPTION_AR`: Bilingual labels and descriptions for the UI.
- `MIN_VALUE` and `MAX_VALUE`: Numeric bounds for integer settings.
- `IS_LOCKABLE`: Prevents sensitive settings from being edited through the interface.
- `SORT_ORDER`: Controls presentation order in the security settings screen.
- `UPDATED_BY` and `UPDATED_ON`: Audit fields for tracking changes.

Constraints:
- Primary key on `SETTING_ID`.
- Unique constraint on `SETTING_KEY`.
- Check constraint restricts `VALUE_TYPE`.

Seed behavior:
- The seed script performs idempotent upserts.
- Existing operator-edited values are preserved; metadata such as labels, ranges, and sort order are refreshed.

```mermaid
flowchart TD
Start(["Run 02_ibac_seed.php"]) --> LoadSettings["Load default settings array"]
LoadSettings --> UpsertCheck{"Setting exists?"}
UpsertCheck --> |Yes| UpdateMetadata["Update metadata only:<br/>type, labels, ranges, lockable, sort"]
UpsertCheck --> |No| InsertDefault["Insert default row"]
UpdateMetadata --> Done(["Seed complete"])
InsertDefault --> Done
```

**Diagram sources**
- [02_ibac_seed.php:212-279](file://kyApp_API/database/oracle/02_ibac_seed.php#L212-L279)

**Section sources**
- [01_ibac_schema.sql:114-146](file://kyApp_API/database/oracle/01_ibac_schema.sql#L114-L146)
- [02_ibac_seed.php:91-210](file://kyApp_API/database/oracle/02_ibac_seed.php#L91-L210)
- [02_ibac_seed.php:212-279](file://kyApp_API/database/oracle/02_ibac_seed.php#L212-L279)

### APP_USER_ACTIVITY — Audit Trail
`APP_USER_ACTIVITY` records lightweight audit events:
- `ACTIVITY_ID`: Primary key generated by a sequence and trigger.
- `USER_ID` and `TARGET_USER_ID`: Actor and target user identifiers; both nullable to support anonymous failed logins.
- `ACTION_CODE`, `MODULE_CODE`, `ENTITY_TYPE`, `ENTITY_ID`: Structured event classification.
- `DESCRIPTION_AR`: Arabic-ready description for UI display.
- `STATUS`: Success or failure indicator.
- Client context fields: IP address, user agent, platform.
- `CREATED_ON`: Event timestamp.

Important design choice:
- There is no foreign key on `USER_ID`. This allows recording failed logins for unknown usernames and preserves audit history even if a user is deleted.

Indexes:
- Composite indexes on `(USER_ID, CREATED_ON)`, `(TARGET_USER_ID, CREATED_ON)`, and `(MODULE_CODE, CREATED_ON)` optimize common audit queries.

```mermaid
flowchart TD
Action["User action or system event"] --> LogAttempt["Attempt to write APP_USER_ACTIVITY"]
LogAttempt --> WriteSuccess{"Write succeeds?"}
WriteSuccess --> |Yes| KeepRecord["Keep audit record"]
WriteSuccess --> |No| IgnoreFailure["Ignore failure<br/>audit must never break request"]
KeepRecord --> End(["Event logged"])
IgnoreFailure --> End
```

**Diagram sources**
- [01_ibac_schema.sql:148-189](file://kyApp_API/database/oracle/01_ibac_schema.sql#L148-L189)

**Section sources**
- [01_ibac_schema.sql:148-189](file://kyApp_API/database/oracle/01_ibac_schema.sql#L148-L189)

### Sequence Generation Strategy
Automatic ID generation uses Oracle sequences combined with `BEFORE INSERT` triggers:
- `SEQ_APP_PERMISSIONS` → `TRG_APP_PERMISSIONS` → `APP_PERMISSIONS.PERMISSION_ID`.
- `SEQ_APP_USERS_PERM` → `TRG_APP_USERS_PERM` → `APP_USERS_PERMISSIONS.ID`.
- `SEQ_APP_SETTINGS` → `TRG_APP_SETTINGS` → `APP_SETTINGS.SETTING_ID`.
- `SEQ_APP_ACTIVITY` → `TRG_APP_ACTIVITY` → `APP_USER_ACTIVITY.ACTIVITY_ID`.
- `SEQ_APP_USERS_ID` exists for new user IDs but has no trigger, preserving legacy ERP behavior.

```mermaid
sequenceDiagram
participant App as "Application"
participant Table as "Target Table"
participant Trigger as "BEFORE INSERT Trigger"
participant Seq as "Oracle Sequence"
App->>Table : "INSERT without ID"
Table->>Trigger : "BEFORE INSERT"
Trigger->>Seq : "NEXTVAL"
Seq-->>Trigger : "Generated ID"
Trigger-->>Table : "Assign ID to : NEW"
Table-->>App : "Insert completes"
```

**Diagram sources**
- [01_ibac_schema.sql:61-75](file://kyApp_API/database/oracle/01_ibac_schema.sql#L61-L75)
- [01_ibac_schema.sql:102-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L102-L112)
- [01_ibac_schema.sql:136-146](file://kyApp_API/database/oracle/01_ibac_schema.sql#L136-L146)
- [01_ibac_schema.sql:174-184](file://kyApp_API/database/oracle/01_ibac_schema.sql#L174-L184)
- [01_ibac_schema.sql:32-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L32-L33)

**Section sources**
- [01_ibac_schema.sql:32-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L32-L33)
- [01_ibac_schema.sql:61-75](file://kyApp_API/database/oracle/01_ibac_schema.sql#L61-L75)
- [01_ibac_schema.sql:102-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L102-L112)
- [01_ibac_schema.sql:136-146](file://kyApp_API/database/oracle/01_ibac_schema.sql#L136-L146)
- [01_ibac_schema.sql:174-184](file://kyApp_API/database/oracle/01_ibac_schema.sql#L174-L184)

### Bilingual Support Design
Bilingual support is implemented through separate Arabic and English columns:
- `APP_PERMISSIONS` includes `NAME_AR`, `NAME_EN`, and `DESCRIPTION_AR`.
- `APP_SETTINGS` includes `NAME_AR` and `DESCRIPTION_AR`.
- `APP_USER_ACTIVITY` includes `DESCRIPTION_AR` for ready-to-display audit messages.

Arabic text handling follows a strict path:
- The application connects as UTF-8 client to a Windows-1256 database.
- Raw CP1256 bytes would be corrupted by the driver.
- `ArabicEncoding::toOracleSearchChars()` maps each CP1256 byte to a Latin-1 character with the same code point so the original byte survives transport and storage.
- Read-time decoding uses `ArabicEncoding::fixMojibake()` to repair mojibake safely and idempotently.

```mermaid
flowchart TD
Input["UTF-8 Arabic text"] --> Encode["ArabicEncoding::toOracleSearchChars()"]
Encode --> OracleStore["Store in Oracle WE8MSWIN1252"]
OracleStore --> Read["Read from Oracle"]
Read --> Decode["ArabicEncoding::fixMojibake()"]
Decode --> Output["Safe UTF-8 Arabic output"]
```

**Diagram sources**
- [ArabicEncoding.php:122-162](file://kyApp_API/app/Support/ArabicEncoding.php#L122-L162)
- [ArabicEncoding.php:33-120](file://kyApp_API/app/Support/ArabicEncoding.php#L33-L120)
- [02_ibac_seed.php:10-24](file://kyApp_API/database/oracle/02_ibac_seed.php#L10-L24)

**Section sources**
- [01_ibac_schema.sql:38-57](file://kyApp_API/database/oracle/01_ibac_schema.sql#L38-L57)
- [01_ibac_schema.sql:118-134](file://kyApp_API/database/oracle/01_ibac_schema.sql#L118-L134)
- [01_ibac_schema.sql:152-168](file://kyApp_API/database/oracle/01_ibac_schema.sql#L152-L168)
- [ArabicEncoding.php:33-120](file://kyApp_API/app/Support/ArabicEncoding.php#L33-L120)
- [ArabicEncoding.php:122-162](file://kyApp_API/app/Support/ArabicEncoding.php#L122-L162)
- [02_ibac_seed.php:10-24](file://kyApp_API/database/oracle/02_ibac_seed.php#L10-L24)

### Legacy Table Modification Approach for APP_USERS
The legacy modification strategy prioritizes compatibility:
- Instead of recreating `APP_USERS`, the schema alters the existing table.
- `USER_PASSWORD` is widened to prevent truncation errors during migration to hashed passwords.
- `IS_ADMIN` is added to enable global administrative access.
- No trigger is created for user ID generation because a trigger could break ERP systems still inserting rows into `APP_USERS`.
- Rollback guidance preserves business data and warns about narrowing `USER_PASSWORD` only after confirming stored password lengths.

```mermaid
flowchart TD
Start(["Existing ERP writes APP_USERS"]) --> AssessRisk["Assess risk of changing insert behavior"]
AssessRisk --> AlterOnly["Alter existing columns and add flags"]
AlterOnly --> AddSequence["Add sequence for new IDs"]
AddSequence --> AvoidTrigger["Avoid trigger to protect ERP inserts"]
AvoidTrigger --> SafeRollback["Provide rollback guidance"]
SafeRollback --> End(["Compatibility maintained"])
```

**Diagram sources**
- [01_ibac_schema.sql:21-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L33)
- [04_ibac_rollback.sql:33-38](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L33-L38)

**Section sources**
- [01_ibac_schema.sql:21-33](file://kyApp_API/database/oracle/01_ibac_schema.sql#L21-L33)
- [04_ibac_rollback.sql:33-38](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L33-L38)

## Dependency Analysis
The schema dependencies follow a clear hierarchy:
- `APP_PERMISSIONS` is the root reference for permissions.
- `APP_USERS_PERMISSIONS` depends on both `APP_USERS` and `APP_PERMISSIONS`.
- `APP_SETTINGS` is independent but consumed by application logic controlling security and sessions.
- `APP_USER_ACTIVITY` is loosely coupled; it references users conceptually but does not enforce foreign keys to allow anonymous and historical audit records.

```mermaid
graph LR
APP_PERMISSIONS --> APP_USERS_PERMISSIONS
APP_USERS --> APP_USERS_PERMISSIONS
APP_SETTINGS -.-> API["Application security/session logic"]
APP_USERS_PERMISSIONS -.-> API
APP_USER_ACTIVITY -.-> API
```

**Diagram sources**
- [01_ibac_schema.sql:77-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L77-L112)
- [01_ibac_schema.sql:148-189](file://kyApp_API/database/oracle/01_ibac_schema.sql#L148-L189)

**Section sources**
- [01_ibac_schema.sql:38-112](file://kyApp_API/database/oracle/01_ibac_schema.sql#L38-L112)
- [01_ibac_schema.sql:148-189](file://kyApp_API/database/oracle/01_ibac_schema.sql#L148-L189)

## Performance Considerations
- Use the provided indexes for common query patterns:
  - Module-based permission listing via `APP_PERMISSIONS(MODULE_CODE, SORT_ORDER)`.
  - Active grant checks via `APP_USERS_PERMISSIONS(USER_ID, IS_ACTIVE)`.
  - Reverse permission-to-user lookups via `APP_USERS_PERMISSIONS(PERMISSION_ID)`.
  - Activity queries via composite indexes on user, target user, and module with creation time.
- Avoid unnecessary updates to `APP_SETTINGS` metadata when operator-edited values already exist; the seed script intentionally preserves runtime values.
- Keep audit writes non-fatal: failures should not break application requests.
- Prefer bound parameters over string interpolation to avoid encoding and injection issues.

[No sources needed since this section provides general guidance]

## Troubleshooting Guide
Common operational concerns:
- Arabic text corruption:
  - Ensure all Arabic values written to Oracle go through `ArabicEncoding::toOracleSearchChars()`.
  - Ensure all Arabic values read from Oracle go through `ArabicEncoding::fixMojibake()`.
- Permission catalog drift:
  - Use `PermissionCatalog::rows()` as the single source of truth for permission codes, labels, and ordering.
  - Re-run the seed script to synchronize the database with the application catalog.
- Administrator access:
  - Bootstrap promotes the first administrator safely and grants the system-wide wildcard permission only once.
  - If access is lost, verify `IS_ADMIN` and the presence of the system wildcard grant.
- Rollback safety:
  - Use the rollback script to drop only IBAC objects.
  - Restore `APP_USERS` carefully; narrowing `USER_PASSWORD` will fail if existing values exceed the narrower length.

**Section sources**
- [ArabicEncoding.php:33-120](file://kyApp_API/app/Support/ArabicEncoding.php#L33-L120)
- [ArabicEncoding.php:122-162](file://kyApp_API/app/Support/ArabicEncoding.php#L122-L162)
- [PermissionCatalog.php:271-316](file://kyApp_API/app/Support/PermissionCatalog.php#L271-L316)
- [02_ibac_seed.php:281-310](file://kyApp_API/database/oracle/02_ibac_seed.php#L281-L310)
- [03_ibac_bootstrap.php:135-185](file://kyApp_API/database/oracle/03_ibac_bootstrap.php#L135-L185)
- [04_ibac_rollback.sql:1-11](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L1-L11)
- [04_ibac_rollback.sql:33-38](file://kyApp_API/database/oracle/04_ibac_rollback.sql#L33-L38)

## Conclusion
The core schema establishes a secure, extensible foundation for identity-based access control:
- `APP_USERS` is extended safely to support admin flags and future password hashing without disrupting legacy ERP systems.
- `APP_PERMISSIONS` centralizes permission definitions with bilingual labels and structured sorting.
- `APP_USERS_PERMISSIONS` provides direct, auditable grants between users and permissions.
- `APP_SETTINGS` enables configurable security and session behavior with typed values and UI-friendly metadata.
- `APP_USER_ACTIVITY` captures essential audit information without compromising request reliability.
- Sequences and triggers automate ID generation consistently across most tables, while `APP_USERS` remains deliberately trigger-free for compatibility.
- Bilingual Arabic and English support is handled through explicit columns and a robust encoding helper that bridges UTF-8 application code and a Windows-1256 Oracle database.

[No sources needed since this section summarizes without analyzing specific files]