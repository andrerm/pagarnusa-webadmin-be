# PRD Module 01 — Authentication
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All authentication and authorization flows — login, logout, password reset, session lock, route protection, and JWT lifecycle.

---

## 1. Module Summary

The Authentication module is the foundation of the entire system. It controls who can access the system, under which role, and which territorial scope they are permitted to operate within. Every other module depends on this module's output: a JWT access token and user context object.

---

## 2. User Stories

### US-AUTH-01 — Login
> As a registered user, I want to log in with my username and password so that I can access the system according to my assigned role.

**Acceptance Criteria:**
- Valid credentials → redirect to role-appropriate dashboard
- Invalid credentials → show error message without revealing whether the username or password was wrong
- 5 consecutive failed attempts → account temporarily locked for 15 minutes
- reCAPTCHA v3 is active and validated on every login attempt
- If `firstLogin: true` → redirect to mandatory password change page before accessing any other module

**Role-based redirect after login:**

| Role | Redirect |
|---|---|
| Superadmin | `/admin/dashboard` |
| Verifikator PW | `/admin/daftar-anggota` |
| Verifikator PC | `/admin/daftar-anggota` |
| Observer | `/admin/daftar-anggota` (read-only) |

---

### US-AUTH-02 — Logout
> As a logged-in user, I want to log out so that my session ends securely.

**Acceptance Criteria:**
- Token is invalidated server-side via Redis blacklist
- Client-side cookies and localStorage are cleared
- User is redirected to `/login`

---

### US-AUTH-03 — Password Reset via Email
> As a user who has forgotten their password, I want to request a reset link so that I can create a new password.

**Acceptance Criteria:**
- User inputs email → system sends a reset link valid for 1 hour
- Reset link is single-use only
- New password must meet policy: minimum 8 characters, at least one uppercase letter, at least one number
- Upon successful reset, all active sessions for that user are invalidated

---

### US-AUTH-04 — Session Lock
> As a user stepping away from my computer, I want the screen to lock automatically after being idle so that my data remains secure.

**Acceptance Criteria:**
- 30 minutes of idle → screen lock overlay appears (not a logout/redirect)
- User unlocks with their password only, without a full re-login
- 3 consecutive wrong passwords on the lock screen → forced logout and redirect to `/login`

---

### US-AUTH-05 — Route Protection
> As the system, I want to protect all admin pages so they can only be accessed by authenticated users with the appropriate role.

**Acceptance Criteria:**
- Accessing an admin URL without a valid token → redirect to `/login`
- Accessing a page with an insufficient role → redirect to `/403`
- Expired access token → attempt silent refresh; if refresh token is also expired → redirect to `/login`
- Public pages (`/login`, `/forgot-password`, `/reset-password`, `/form-daftar-noauth`) do not require a token

---

## 3. Database Schema

Uses existing MySQL tables. Mapped via Prisma without any structural changes. Table names follow the legacy system convention.

```prisma
model User {
  id          String    @id @default(uuid())
  username    String    @unique
  email       String    @unique
  password    String                          // bcrypt hash, cost factor 12
  googleId    String?
  facebookId  String?
  isActive    Boolean   @default(true)
  firstLogin  Boolean   @default(true)        // true = must change password on first login
  lastLogin   DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  pribadi     Pribadi?  @relation(fields: [pribadiId], references: [id])
  pribadiId   String?   @unique

  userRoles   UserRole[]

  @@map("users")
}

model Role {
  id          String    @id @default(uuid())
  name        String    @unique              // "superadmin" | "verifikator_pw" | "verifikator_pc" | "observer"
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  userRoles   UserRole[]
  permissions Permission[]

  @@map("roles")
}

model UserRole {
  id          String    @id @default(uuid())
  userId      String
  roleId      String
  scope       String?                        // null = national | "33" = province | "3374" = district
  createdAt   DateTime  @default(now())

  user        User      @relation(fields: [userId], references: [id])
  role        Role      @relation(fields: [roleId], references: [id])

  @@unique([userId, roleId])
  @@map("user_roles")
}

model Permission {
  id          String    @id @default(uuid())
  roleId      String
  module      String                         // "daftar_anggota" | "manajemen_akun" | "wilayah" | etc.
  canRead     Boolean   @default(false)
  canCreate   Boolean   @default(false)
  canUpdate   Boolean   @default(false)
  canDelete   Boolean   @default(false)

  role        Role      @relation(fields: [roleId], references: [id])

  @@map("permissions")
}
```

### Redis Key Patterns

No database tables. All keys are stored in Redis with automatic TTL expiry.

| Key Pattern | Value | TTL |
|---|---|---|
| `auth:blacklist:{token_jti}` | `"1"` | Remaining token lifetime |
| `auth:failed_attempts:{username}` | integer (attempt count) | 15 minutes |
| `auth:reset_token:{token}` | `userId` | 1 hour |
| `auth:session_lock:{userId}` | `"1"` | 30 minutes since last activity |

### JWT Payload Structure

```json
{
  "sub": "userId",
  "jti": "unique_token_id",
  "role": "verifikator_pw",
  "scope": "33",
  "iat": 1234567890,
  "exp": 1234567890
}
```

| Token | TTL |
|---|---|
| Access Token | 15 minutes |
| Refresh Token | 7 days (rotated on every use) |

---

## 4. API Endpoints

**Base URL:** `/api/auth`

---

### POST `/api/auth/login`

**Request:**
```json
{
  "username": "admin01",
  "password": "Password123",
  "captchaToken": "recaptcha_v3_token"
}
```

**Response 200 — Success:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "uuid",
    "username": "admin01",
    "email": "admin@pagarnusa.or.id",
    "firstLogin": false,
    "role": "verifikator_pw",
    "scope": "33"
  }
}
```

**Response 401 — Invalid credentials:**
```json
{
  "statusCode": 401,
  "message": "Username or password is incorrect"
}
```

**Response 429 — Account locked:**
```json
{
  "statusCode": 429,
  "message": "Account temporarily locked. Please try again in 15 minutes."
}
```

> **Compatibility note:** The legacy endpoint `/users/authenticatew` is proxied by Nginx to this endpoint so that first-generation clients continue to function during the transition period.

---

### POST `/api/auth/logout`

**Header:** `Authorization: Bearer {accessToken}`

**Response 200:**
```json
{ "message": "Logged out successfully" }
```

---

### POST `/api/auth/refresh`

**Request:**
```json
{ "refreshToken": "eyJ..." }
```

**Response 200:**
```json
{ "accessToken": "eyJ..." }
```

**Response 401 — Refresh token expired or invalid:**
```json
{
  "statusCode": 401,
  "message": "Session expired. Please log in again."
}
```

---

### POST `/api/auth/forgot-password`

**Request:**
```json
{ "email": "admin@pagarnusa.or.id" }
```

**Response 200** (always 200 even if email is not found — prevents user enumeration):
```json
{ "message": "If this email is registered, a reset link has been sent." }
```

---

### POST `/api/auth/reset-password`

**Request:**
```json
{
  "token": "reset_token_from_email_link",
  "newPassword": "NewPassword123",
  "confirmPassword": "NewPassword123"
}
```

**Response 200:**
```json
{ "message": "Password changed successfully. Please log in again." }
```

**Response 400 — Token invalid or expired:**
```json
{
  "statusCode": 400,
  "message": "Reset link is invalid or has expired."
}
```

---

### POST `/api/auth/unlock-session`

**Header:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{ "password": "Password123" }
```

**Response 200:**
```json
{ "message": "Session unlocked successfully" }
```

**Response 401 — Wrong password:**
```json
{
  "statusCode": 401,
  "message": "Incorrect password."
}
```

---

### GET `/api/auth/me`

**Header:** `Authorization: Bearer {accessToken}`

**Response 200:**
```json
{
  "id": "uuid",
  "username": "admin01",
  "email": "admin@pagarnusa.or.id",
  "role": "verifikator_pw",
  "scope": "33",
  "permissions": {
    "daftar_anggota": { "read": true, "create": false, "update": true, "delete": false },
    "manajemen_akun": { "read": false, "create": false, "update": false, "delete": false },
    "wilayah":        { "read": true, "create": false, "update": false, "delete": false }
  }
}
```

---

## 5. UI Flow

### 5.1 Login Page — `/login`

```
┌─────────────────────────────────┐
│        PagarNusa Logo           │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Username                │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Password            👁  │    │
│  └─────────────────────────┘    │
│                                 │
│  [ Forgot Password? ]           │
│                                 │
│  ┌─────────────────────────┐    │
│  │         SIGN IN         │    │
│  └─────────────────────────┘    │
│                                 │
│  🔒 Protected by reCAPTCHA v3   │
└─────────────────────────────────┘
```

**UI states to handle:**

| State | UI Behavior |
|---|---|
| Default | Empty form, button enabled |
| Loading | Button disabled + spinner |
| Credential error | Inline error message below the form |
| Account locked | Error message + 15-minute countdown timer |
| First login | Redirect to mandatory password change page |

---

### 5.2 Forgot Password Page — `/forgot-password`

```
┌─────────────────────────────────┐
│  ← Back to Login                │
│                                 │
│  Reset Password                 │
│  Enter your registered email    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Email                   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │    SEND RESET LINK      │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**After submit** — show success state in place (no redirect):
```
✅ Password reset instructions have been sent to your email.
   Check your spam folder if it doesn't arrive within 5 minutes.
```

---

### 5.3 Reset Password Page — `/reset-password?token=xxx`

**State — token invalid or expired:**
```
❌ This reset link is invalid or has expired.
   [ Request a New Link ]
```

**State — token valid:**
```
┌─────────────────────────────────┐
│  Create New Password            │
│                                 │
│  ┌─────────────────────────┐    │
│  │ New Password        👁  │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Confirm Password    👁  │    │
│  └─────────────────────────┘    │
│                                 │
│  ✓ At least 8 characters        │
│  ✓ At least one uppercase letter│
│  ✓ At least one number          │
│                                 │
│  ┌─────────────────────────┐    │
│  │      SAVE PASSWORD      │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

### 5.4 Screen Lock Overlay

Appears as a full-screen overlay on top of the current active page after 30 minutes of idle. It is not a redirect — the content behind remains in memory.

```
┌─────────────────────────────────┐
│                                 │
│             🔒                  │
│        Session Locked           │
│                                 │
│  Enter your password to         │
│  continue as admin01            │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Password            👁  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │       UNLOCK            │    │
│  └─────────────────────────┘    │
│                                 │
│  [ Log out and switch account ] │
│                                 │
└─────────────────────────────────┘
```

**Behavior:**
- 3 wrong password attempts → forced logout → redirect to `/login`
- Click "Log out and switch account" → normal logout → redirect to `/login`
- Successful unlock → overlay dismissed, active page resumes

---

### 5.5 Mandatory Password Change Page (First Login)

Shown automatically after the first successful login. User cannot access any other module until this is completed.

```
┌─────────────────────────────────┐
│  Welcome, admin01!              │
│                                 │
│  For your account security,     │
│  please change your password    │
│  before continuing.             │
│                                 │
│  ┌─────────────────────────┐    │
│  │ New Password        👁  │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Confirm Password    👁  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │   SAVE & CONTINUE       │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

## 6. Business Rules & Implementation Notes

### Password Policy
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- Hashing: bcrypt with cost factor 12

### JWT & Token Management
- Access Token TTL: 15 minutes
- Refresh Token TTL: 7 days
- Refresh token is rotated on every use to prevent replay attacks
- On logout, the token's `jti` is stored in Redis blacklist until natural expiry

### reCAPTCHA v3
- Runs invisibly in the background on the login form
- Score threshold: 0.5 (reject if below threshold)
- If reCAPTCHA verification fails → login rejected with a generic error message

### Legacy System Compatibility
Legacy endpoint is mapped in Nginx:
```nginx
location /users/authenticatew {
  proxy_pass http://express:4000/api/auth/login;
}
```
This ensures existing integrations are not broken during the transition period.

### Scope in JWT Token
The `scope` field in the JWT is populated from `UserRole.scope`:
- `null` → Superadmin, access to all territories
- `"33"` → Verifikator PW, province scope (2-digit = province code)
- `"3374"` → Verifikator PC, district scope (4-digit = district code)

This scope value is consumed by all other modules as an automatic data filter.

---

## 7. Implementation Checklist

### Backend (Express.js)
- [ ] `POST /api/auth/login` — input validation, bcrypt check, reCAPTCHA verification
- [ ] Failed attempts counter in Redis (lockout after 5x, 15-minute TTL)
- [ ] JWT generation (access + refresh) with role & scope in payload
- [ ] `POST /api/auth/logout` — add token `jti` to Redis blacklist
- [ ] `POST /api/auth/refresh` — validate refresh token, issue new access token, rotate refresh token
- [ ] `POST /api/auth/forgot-password` — generate reset token, store in Redis, send email
- [ ] `POST /api/auth/reset-password` — validate Redis token, update password, invalidate token
- [ ] `POST /api/auth/unlock-session` — verify password, clear session lock in Redis
- [ ] `GET /api/auth/me` — decode token, query permissions from DB
- [ ] `authenticate` middleware — protect all `/api/admin/*` routes
- [ ] `authorize(module, action)` middleware — RBAC check per endpoint
- [ ] Nginx proxy rule for `/users/authenticatew` → `/api/auth/login`

### Frontend (Next.js)
- [ ] `/login` page — form, error states, lockout countdown timer
- [ ] `/forgot-password` page — form with inline success state
- [ ] `/reset-password` page — token validation, password rules indicator
- [ ] Screen lock overlay — idle timer (30 min), wrong attempt counter (3x)
- [ ] Mandatory password change page — first login flow
- [ ] NextAuth.js session management with JWT
- [ ] Silent access token refresh via TanStack Query interceptor
- [ ] Route guard: redirect to `/login` if not authenticated
- [ ] Route guard: redirect to `/403` if role lacks permission
- [ ] Store role & scope in session for use by other modules

---

*This document is the PRD for Module 01 — Authentication.*
*Next: PRD Module 02 — Member List (Daftar Anggota)*
*Last updated: April 2026 | Version: 2.0*
