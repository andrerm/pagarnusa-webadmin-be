# PRD Module 03 — Account Management (Manajemen Akun)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All workflows related to administrator account management — listing admin users, assigning roles, setting territorial scope, activating/suspending accounts, resetting passwords, and managing the role catalog. Does not cover member self-registration (Module 02) or the profile self-service page (Module 07).

---

## 1. Module Summary

The Account Management module governs who can operate the system and with what level of access. Only Superadmins can manage accounts. The core operations are: assigning a role to a user, assigning a territorial scope that limits what data that user can see and interact with, and controlling whether an account is active or suspended.

An important distinction from Module 02: **every admin user in this system is also a verified member** (`Pribadi`). Admin accounts are not standalone — they are always linked to a `Pribadi` record. This means an admin user's territorial scope is stored on their linked `Pribadi` record (the `scopedata` field), not on the `User` record itself.

---

## 2. Actors & Permissions

| Actor | View Admin List | Assign Role | Set Scope | Activate / Suspend | Reset Password | Manage Role Catalog |
|---|---|---|---|---|---|---|
| Superadmin | ✅ All | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verifikator PW | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Verifikator PC | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Observer | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

All operations in this module are Superadmin-only.

---

## 3. User Stories

### US-ACCT-01 — View Admin User List
> As a Superadmin, I want to see a list of all administrator accounts so that I can manage their roles and access.

**Acceptance Criteria:**
- Only users who have been assigned an admin role (role IDs 1–4: Superadmin, Verifikator PW, Verifikator PC, Observer) are shown
- Each row displays: full name, username, email, assigned role, KTA number, position label (`jabatanPn`), scope data, active status, and last login timestamp
- Supports pagination, keyword search, and sorting
- Linked member data (`Pribadi`) is included in each result row — not fetched separately

---

### US-ACCT-02 — Assign Role & Scope to an Admin User
> As a Superadmin, I want to assign a role and territorial scope to an admin user so that their access is correctly restricted.

**Acceptance Criteria:**
- Only Superadmin can perform this action (verified via JWT scope containing `"-"`)
- The operation updates two things atomically:
  1. The user's role in the `UserRole` table
  2. The `scopedata` field on their linked `Pribadi` record
- Scope is provided as a territory code string:
  - Empty or null → national access (Superadmin level)
  - 2-digit string (e.g. `"33"`) → province scope
  - 4-digit string (e.g. `"3374"`) → district scope
- The role catalog is fetched separately and presented as a dropdown (see US-ACCT-06)
- The user being updated is identified by their `publicId` (from the linked `Pribadi` record), not by their user ID

---

### US-ACCT-03 — Activate or Suspend an Admin Account
> As a Superadmin, I want to activate or suspend an admin account so that I can control system access without deleting accounts.

**Acceptance Criteria:**
- Only Superadmin can perform this action (verified via a whitelist of allowed operator emails stored in the system config — see Section 5.3)
- The `isActive` flag on the `User` record is toggled (1 = active, 0 = suspended)
- A suspended user cannot log in even with valid credentials
- The action is confirmed with a dialog showing the user's full name and the new status
- Deletion of user accounts is not supported in this module — suspend is the alternative

---

### US-ACCT-04 — Generate Password Reset Link for an Admin
> As a Superadmin, I want to generate a password reset link for an admin user so that they can regain access if locked out.

**Acceptance Criteria:**
- Identified by the user's `publicId`
- Before generating a new link, all existing unused reset links for that user are marked as used/expired
- A new single-use reset link is generated with a validity window of 10 minutes
- The reset link token is stored in a `linkresetpwd` table with: member ID, unique token, used status flag, and expiry timestamp
- The link (or token) is returned to the Superadmin to be shared with the user manually (no email sending in this version)

---

### US-ACCT-05 — Change Own Password
> As any logged-in admin, I want to change my own password so that I can keep my account secure.

**Acceptance Criteria:**
- The user must provide their current password, which is verified before any change is made
- The new password is hashed before storage (see Section 5.1 — Password Hashing)
- The user's identity is taken from their JWT token — they cannot change another user's password via this endpoint
- No password policy is enforced at the API level in this version (length/complexity handled by frontend)

---

### US-ACCT-06 — View Role Catalog
> As a Superadmin, I want to view all available roles so that I can assign the correct one to an admin user.

**Acceptance Criteria:**
- Returns a list of all roles in the system with their ID and name
- Supports pagination, search, and filtering
- Roles are master data — they are not created or deleted through the UI in this version
- The list is used as the source for the role dropdown in the assign-role workflow

---

### US-ACCT-07 — Check if Username Exists
> As the system, I want to check whether a username is already taken before creating a new account so that duplicate usernames are prevented.

**Acceptance Criteria:**
- Returns a boolean indicating whether the username exists
- Used internally during account creation to block duplicates before attempting a save

---

## 4. Data Model

### 4.1 User

Maps to the existing `users` table. No schema changes.

| Field | Description |
|---|---|
| `iduser` | Internal auto-increment ID |
| `username` | Login username — defaults to the member's NIK on creation |
| `email` | Email address — sourced from linked `Pribadi` |
| `password` | Hashed password (see Section 5.1) |
| `fullname` | Full name — sourced from linked `Pribadi` |
| `surname` | First part of the name (split from full name) |
| `lastname` | Last part of the name (split from full name) |
| `isactive` | Account status — `1` = active, `0` = suspended |
| `lastlogin` | Timestamp of last successful login |
| `idpribadi` | Foreign key linking to the `Pribadi` record |
| `created` | Record creation timestamp |
| `updated` | Last update timestamp |

### 4.2 UserRole

Maps to the existing `user_roles` table. Links a user to a role. One record per user.

| Field | Description |
|---|---|
| `iduser` | FK → User |
| `idroles` | FK → Role |
| `created` | Record creation timestamp |

### 4.3 Role

Maps to the existing `roles` table. Master data — not modified through the UI.

| Field | Description |
|---|---|
| `id` | Role ID |
| `name` | Role name (e.g. "Superadmin", "Verifikator PW", "Verifikator PC", "Observer") |

### 4.4 LinkResetPwd

Maps to the existing `linkresetpwd` table. Stores password reset tokens.

| Field | Description |
|---|---|
| `id` | Unique token (GUID) — this is the reset link identifier |
| `idpribadi` | FK → Pribadi (the member whose password is being reset) |
| `isused` | Flag — `0` = unused/valid, `1` = used/expired |
| `validuntil` | Expiry timestamp — 10 minutes from creation |

### 4.5 Scope Data on Pribadi

The `scopedata` field on the `Pribadi` record is the authoritative source of a user's territorial scope. It is updated alongside the role assignment. Its value determines what data the user can access across all modules:

| Value | Meaning |
|---|---|
| `"-"` (dash) | Superadmin — no territorial restriction |
| 2-digit string | Province-level scope |
| 4-digit string | District-level scope |

---

## 5. Business Rules

### 5.1 Password Hashing

Passwords are hashed using SHA-256 combined with a server-side salt value from the system configuration. The same hashing logic must be applied consistently across:
- Initial account creation (default password = member's NIK)
- Password change (new password input)
- Password verification (comparing entered password with stored hash)

> **Note for implementation:** The legacy system uses SHA-256 + salt. The new system should use a stronger algorithm such as **bcrypt** with a cost factor. The hashing strategy should be decided at implementation time. What matters is that the same strategy is used for both creating and verifying passwords, and that plain-text passwords are never stored.

### 5.2 Default Credentials on Account Creation

When an admin account is created from a verified member:
- **Username** defaults to the member's KTA number (`noKta` / `nokta`)
- **Password** defaults to the member's NIK (`noKtp`), hashed
- The `isEmailFirstLogin` flag on `Pribadi` is set to `true` so the user is prompted to change their password on first login

When an account is created directly (not from a verified member):
- **Username** defaults to the member's NIK
- **Password** is set from the registration form input if provided; otherwise defaults to the NIK, hashed

### 5.3 Activate / Suspend Authorization

The activate/suspend operation has an additional authorization layer on top of the Superadmin role check: the requesting user's email must be present in a predefined whitelist stored in the system configuration (`Others:Woops` or equivalent). This is a secondary guard that limits which Superadmins can toggle account status. If the requester's email is not in the whitelist, the action is rejected with a 403 response.

### 5.4 Role Assignment Authorization

Role and scope assignment is gated by the Superadmin scope marker: the requesting user's JWT must contain a scope value of `"-"`. If it does not, the request is rejected with a 403 response. This check is in addition to the standard JWT authentication check.

### 5.5 Reset Link Lifecycle

When a password reset link is requested for a user:
1. All previously issued unused reset links for that user are immediately invalidated (marked as used)
2. A new unique token is generated and stored with a 10-minute expiry
3. Only one valid reset link exists per user at any given time

A reset link becomes invalid once it is used or once its `validuntil` timestamp has passed. The system should reject any attempt to use an expired or already-used token.

### 5.6 Admin List Composition

The admin user list is not simply the `users` table. It is a joined view that combines:
- `users` — for account credentials and status
- `user_roles` — to filter only users with admin roles (role IDs 1–4)
- `roles` — to show the role name
- `pribadi` — to show member-level fields (`jabatanPn`, `scopedata`, `nokta`, `publicId`)

Users without a role assignment, or users assigned roles outside the range 1–4, are excluded from this list.

---

## 6. API Endpoints

**Base URL:** `/api/users`

All endpoints in this module require a valid JWT. Most require Superadmin scope.

---

### GET `/api/users/muser`

Returns a paginated list of admin users (joined view — see Section 5.6).

**Query Parameters:** pagination, keyword search, sort (same pattern as Module 02)

**Response 200:**
```json
{
  "data": [
    {
      "iduser": 1,
      "username": "86337408000001",
      "fullname": "Budi Santoso",
      "email": "budi@pagarnusa.or.id",
      "isactive": 1,
      "lastlogin": "2024-04-01T08:30:00Z",
      "idroles": 2,
      "namaRole": "Verifikator PW",
      "publicid": "pub-uuid",
      "nokta": "86337408000001",
      "jabatanPn": "Anggota - PC Kota Semarang",
      "scopedata": "33"
    }
  ],
  "meta": {
    "page": 1,
    "pageSize": 10,
    "total": 12,
    "totalPages": 2
  }
}
```

---

### GET `/api/users/:id`

Returns a single user record by internal user ID.

---

### PUT `/api/users/setrole/:iduser`

Assign a role and territorial scope to an admin user. Superadmin only (JWT scope must be `"-"`).

**Request:**
```json
{
  "publicId": "pub-uuid",
  "stringRole": { "id": 2, "name": "Verifikator PW" },
  "scopedata": "33"
}
```

The `publicId` is used to locate and update the linked `Pribadi.scopedata`. The `stringRole.id` updates the `UserRole.idroles`. Both updates must happen together — if either fails, neither should be committed.

**Response 200:**
```json
{ "message": "Role updated successfully." }
```

**Response 403 — Not a Superadmin:**
```json
{ "statusCode": 403, "message": "Not allowed." }
```

---

### PUT `/api/users/:id`

Activate or suspend an admin account. Superadmin only, with additional email whitelist check (Section 5.3).

**Request:**
```json
{ "isactive": 0 }
```

`isactive: 1` = activate, `isactive: 0` = suspend.

**Response 200:**
```json
{ "message": "Account Budi Santoso has been suspended." }
```

**Response 403 — Email not in whitelist:**
```json
{ "statusCode": 403, "message": "Not allowed." }
```

---

### GET `/api/users/getlink/:publicid`

Generate a password reset link for an admin user. Superadmin only.

**Behavior:**
1. Locate the `Pribadi` record by `publicId`
2. Mark all existing unused reset links for that member as used
3. Create a new reset token (GUID) with a 10-minute expiry
4. Return the token to the Superadmin

**Response 200:**
```json
{
  "id": "generated-guid-token",
  "idpribadi": 1,
  "isused": 0,
  "validuntil": "2024-04-01T09:10:00Z"
}
```

---

### PUT `/api/users/rpw`

Change own password. Any authenticated admin.

The user's identity is taken from the JWT — they cannot change another user's password.

**Request:**
```json
{
  "oldPassword": "CurrentPassword",
  "newPassword": "NewSecurePassword"
}
```

**Behavior:**
1. Extract `publicId` from JWT
2. Find linked `Pribadi` and then linked `User`
3. Verify `oldPassword` matches the stored hash
4. Hash `newPassword` and update the `User` record

**Response 200:**
```json
{ "message": "Password changed successfully." }
```

**Response 400 — Old password does not match:**
```json
{ "statusCode": 400, "message": "Current password is incorrect." }
```

---

### POST `/api/users/checkuser`

Check whether a username already exists. Public endpoint (no auth required) — used during registration.

**Request:**
```json
{ "username": "3374xxxxxxxxxxxx" }
```

**Response 200:**
```json
{ "isEmailFirstLogin": false }
```

> **Note on field naming:** The `isEmailFirstLogin` field is reused here as a "username exists" indicator — `false` means the username exists (not a first-time login), `true` means it does not exist. This is legacy naming from the original system and should be kept for compatibility. In the new system, consider aliasing this as `exists` in the response for clarity, while maintaining backward compatibility for the legacy endpoint.

---

### GET `/api/roles`

Returns the full list of available roles. Used to populate the role dropdown in the assign-role UI.

**Response 200:**
```json
{
  "data": [
    { "id": 1, "name": "Superadmin" },
    { "id": 2, "name": "Verifikator PW" },
    { "id": 3, "name": "Verifikator PC" },
    { "id": 4, "name": "Observer" }
  ]
}
```

---

### GET `/api/userroles`

Returns all user-role assignments. Used for internal role management.

---

## 7. UI Flow

### 7.1 Admin User List Page — `/admin/manajemen-akun`

```
┌──────────────────────────────────────────────────────────────┐
│  Account Management                                          │
│                                                              │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ 🔍 Search...     │  │   Role    ▾  │  │  Status   ▾  │  │
│  └──────────────────┘  └──────────────┘  └──────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Name        │ Role          │ Scope  │ Status │  ⋮  │   │
│  ├─────────────┼───────────────┼────────┼────────┼─────┤   │
│  │ Budi S.     │ Verifikator PW│ 33     │ 🟢     │  ⋮  │   │
│  │ Ani W.      │ Verifikator PC│ 3374   │ 🟢     │  ⋮  │   │
│  │ Rudi H.     │ Observer      │ 33     │ 🔴     │  ⋮  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Showing 1–10 of 12    [< 1 2 >]   [10 ▾]                  │
└──────────────────────────────────────────────────────────────┘
```

**Status indicators:**
- 🟢 Active (`isactive: 1`)
- 🔴 Suspended (`isactive: 0`)

**Row action menu (⋮):**
- Set Role & Scope
- Activate / Suspend *(label changes based on current status)*
- Generate Reset Link
- View linked Member Profile *(links to Module 02 detail page)*

---

### 7.2 Set Role & Scope Drawer/Modal

Triggered from the row action menu. Opens as a side drawer or modal:

```
┌──────────────────────────────────────┐
│  Set Role & Scope                    │
│  User: Budi Santoso                  │
│                                      │
│  Role *                              │
│  ┌────────────────────────────────┐  │
│  │ Verifikator PW              ▾  │  │
│  └────────────────────────────────┘  │
│                                      │
│  Territorial Scope *                 │
│  ┌────────────────────────────────┐  │
│  │ 33 — Jawa Tengah            ▾  │  │
│  └────────────────────────────────┘  │
│  (Scope is auto-cleared for Superadmin role) │
│                                      │
│  [ Cancel ]        [ Save Changes ]  │
└──────────────────────────────────────┘
```

**Scope selection behavior:**
- If role = Superadmin → scope field is disabled and set to `"-"` automatically
- If role = Verifikator PW → scope picker shows province list (2-digit codes)
- If role = Verifikator PC → scope picker shows district list (4-digit codes)
- If role = Observer → scope picker shows province or district depending on intended coverage

---

### 7.3 Activate / Suspend Confirmation Dialog

```
┌──────────────────────────────────────┐
│  Suspend Account                     │
│                                      │
│  You are about to suspend:           │
│  Budi Santoso (@86337408000001)      │
│                                      │
│  Suspended users cannot log in.      │
│  This can be reversed at any time.   │
│                                      │
│  [ Cancel ]          [ Suspend 🔴 ]  │
└──────────────────────────────────────┘
```

---

### 7.4 Generate Reset Link Dialog

```
┌──────────────────────────────────────┐
│  Generate Password Reset Link        │
│                                      │
│  User: Budi Santoso                  │
│                                      │
│  A new reset link will be generated  │
│  and valid for 10 minutes.           │
│  Any existing links will be voided.  │
│                                      │
│  [ Cancel ]           [ Generate ]   │
└──────────────────────────────────────┘

After generation:
┌──────────────────────────────────────┐
│  ✅ Reset link generated             │
│                                      │
│  Token: xxxxxxxx-xxxx-xxxx-xxxx      │
│  Valid until: 01 Apr 2024, 09:10     │
│                                      │
│  Share this token with the user      │
│  to allow them to reset their        │
│  password.                           │
│                                      │
│  [ Copy Token ]       [ Close ]      │
└──────────────────────────────────────┘
```

---

### 7.5 Change Password Page — `/admin/profil/ganti-password`

> This page is part of Module 07 (Profile) but calls the `/api/users/rpw` endpoint documented here.

```
┌──────────────────────────────────────┐
│  Change Password                     │
│                                      │
│  Current Password *  [          👁]  │
│  New Password *      [          👁]  │
│  Confirm Password *  [          👁]  │
│                                      │
│          [ Save New Password ]       │
└──────────────────────────────────────┘
```

---

## 8. Key Business Rules Summary

| Rule | Detail |
|---|---|
| Admin users are always linked members | Every `User` record has a linked `Pribadi` — accounts cannot exist without a member record |
| Scope lives on Pribadi | Territorial scope (`scopedata`) is stored on `Pribadi`, not on `User` or `UserRole` |
| Role and scope updated together | Changing a role must also update `scopedata` in the same operation |
| Superadmin scope marker | JWT scope value of `"-"` (literal dash) identifies a Superadmin |
| Default username | New accounts use the KTA number as username (if created from a verified member) or NIK (if created at registration) |
| Default password | Always defaults to the member's NIK, hashed |
| First login flag | Set to `true` on account creation — forces password change before full access |
| Reset link validity | 10 minutes; single-use; previous links voided on new generation |
| Suspend not delete | Accounts are suspended, not deleted — all data is preserved |
| Whitelist for activate/suspend | A secondary email whitelist controls who can toggle account status |

---

## 9. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/users/muser` — joined admin user list (users + user_roles + roles + pribadi), role filter (IDs 1–4), pagination and search
- [ ] `GET /api/users/:id` — single user by ID
- [ ] `PUT /api/users/setrole/:iduser` — atomic update of `UserRole.idroles` + `Pribadi.scopedata`; Superadmin scope check (JWT scope === `"-"`)
- [ ] `PUT /api/users/:id` — toggle `isactive`; Superadmin check + email whitelist check
- [ ] `GET /api/users/getlink/:publicid` — void existing reset links, create new token with 10-min expiry
- [ ] `PUT /api/users/rpw` — verify old password hash, update to new password hash; identity from JWT
- [ ] `POST /api/users/checkuser` — username existence check, public endpoint
- [ ] `GET /api/roles` — full role catalog list
- [ ] `GET /api/userroles` — user-role assignment list
- [ ] Password hashing utility — consistent hash function used for creation, verification, and reset
- [ ] Superadmin guard middleware — reusable check for JWT scope === `"-"`
- [ ] Email whitelist check — for activate/suspend endpoint

### Frontend (Next.js)
- [ ] `/admin/manajemen-akun` — admin list with search, role filter, status filter, pagination
- [ ] Set Role & Scope drawer/modal — role dropdown (from `/api/roles`), dynamic scope picker based on selected role, scope auto-clear for Superadmin role
- [ ] Activate/suspend confirmation dialog — context-aware label (Activate vs Suspend)
- [ ] Generate reset link dialog — show token and validity after generation, copy-to-clipboard button
- [ ] Role-aware rendering — all actions hidden for non-Superadmin users
- [ ] Last login display — human-readable relative time (e.g. "2 hours ago")
- [ ] Link to member detail — row links to `/admin/daftar-anggota/:id` for the linked member

---

*This document is the PRD for Module 03 — Account Management (Manajemen Akun).*
*Business logic source: legacy `UsersController.cs`, `UserService.cs`, `UserRolesController.cs`, `RolesController.cs`*
*Next: PRD Module 04 — Territory Management (Manajemen Wilayah)*
*Last updated: April 2026 | Version: 2.0*
