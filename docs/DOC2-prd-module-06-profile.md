# PRD Module 06 — Profile (Profil)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** The self-service profile experience for logged-in admin users — viewing their own profile, editing personal information, uploading a profile photo, changing their password, and the QR-based authorization confirmation workflow. This module is user-facing and personal — it only ever operates on the currently logged-in user's own data.

---

## 1. Module Summary

The Profile module gives every logged-in admin user a personal space to view and manage their own account and member data. Unlike Module 02 (which manages *other* members' data) and Module 03 (which manages *other* accounts), the Profile module is strictly self-service — a user can only see and modify their own record.

An important characteristic of this module: **every admin user is also a member** (`Pribadi`). The profile page therefore shows a combined view — account-level data (username, last login, role) merged with member-level data (personal identity, address, organizational position, KTA number). Editing the profile means editing the underlying `Pribadi` record, not just the `User` record.

---

## 2. Actors & Permissions

| Actor | View Own Profile | Edit Own Profile | Change Own Password | Upload Photo | QR Confirmation |
|---|---|---|---|---|---|
| Superadmin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verifikator PW | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verifikator PC | ✅ | ✅ | ✅ | ✅ | ✅ |
| Observer | ✅ | ✅ | ✅ | ✅ | ✅ |

All authenticated users have equal access to their own profile. No user can view or edit another user's profile through this module.

---

## 3. User Stories

### US-PROFIL-01 — View Own Profile
> As a logged-in admin, I want to view my complete profile so that I can see my personal data, role, and organizational position in one place.

**Acceptance Criteria:**
- Profile data is assembled from both the `User` record and the linked `Pribadi` record
- The user's identity is taken from their JWT — they cannot view another user's profile via this endpoint
- Displays all personal data sections: identity, contact, address, education, employment, organizational affiliation
- Displays account information: username, role name, territorial scope, last login timestamp
- Displays KTA number and `jabatanPn` (position label)
- Profile photo is shown if uploaded, with a placeholder if not

---

### US-PROFIL-02 — Edit Own Profile
> As a logged-in admin, I want to edit my personal information so that my profile stays accurate.

**Acceptance Criteria:**
- Only the currently logged-in user's own `Pribadi` record is editable
- Editable fields: all personal data fields collected at registration (name, contact, address, education, employment, etc.)
- Non-editable fields via this form: `noKtp` (NIK), `noKta` (KTA number), `isVerified`, `jabatanPn`, `scopedata`, role — these are managed by admins in other modules
- If `kelurahanDomisili` is changed, the system must re-resolve `kabupatenDomisili`, `idKabupatenDomisili`, and `idKelurahanDomisili` using the same special-district resolution logic as Module 02 (Section 7.3 of Module 02 PRD)
- Changes are saved immediately on submit — no draft/approval flow

---

### US-PROFIL-03 — Upload / Replace Profile Photo
> As a logged-in admin, I want to upload or replace my profile photo so that my account has a recognizable image.

**Acceptance Criteria:**
- File must be JPG or PNG, maximum 350KB
- If a previous photo exists, the old MinIO object is deleted before the new one is uploaded
- The stored value in `Pribadi.urlFoto` is updated to the new relative MinIO path
- File naming and storage path follow the same convention as Module 02 (Section 8 of Module 02 PRD): `{district.oldId}_pasfoto_{nik}.{ext}` stored under `assets/pic/{district.oldId}/`
- Photo is immediately reflected on the profile page after upload — no page reload required

---

### US-PROFIL-04 — Change Own Password
> As a logged-in admin, I want to change my password so that I can keep my account secure.

**Acceptance Criteria:**
- User must provide their current password; it is verified against the stored hash before any change is made
- If the current password does not match, the request is rejected with a clear error
- The new password is hashed before storage using the same hashing strategy as the rest of the system
- The user's identity is taken from their JWT — they cannot change another user's password via this endpoint
- After a successful password change, the current session remains valid (no forced logout)
- Frontend enforces basic complexity rules before submitting (min 8 characters, uppercase, number) — the API does not enforce complexity in this version

---

### US-PROFIL-05 — QR Code Authorization Confirmation (Konfirmasi QR)
> As a logged-in admin, I want to confirm my identity via QR code so that I can authorize certain actions that require additional verification.

**Acceptance Criteria:**
- A QR code is generated and displayed containing the user's `publicId` or a derived token
- Scanning the QR code with an authorized device completes the confirmation
- The confirmation state is recorded — subsequent actions that required QR confirmation can proceed
- QR codes expire after a defined time window (implementation detail for the coding agent to determine based on use case)
- This workflow is used in contexts where an extra layer of identity confirmation is required beyond the JWT session

---

### US-PROFIL-06 — First Login Password Change (Mandatory)
> As a newly created admin account, I must change my default password before I can access any module so that the system is not left with default credentials.

**Acceptance Criteria:**
- Triggered automatically when `Pribadi.isEmailFirstLogin` is `true` after login
- The user is redirected to a mandatory password change page and cannot navigate elsewhere until completed
- Uses the same change-password endpoint as US-PROFIL-04 but does not require the old password to be entered — the default password (NIK-based) is used internally
- On successful change, `isEmailFirstLogin` is set to `false` and the user proceeds to their role-based dashboard
- This flow is initiated by the Authentication module (Module 01) but the endpoint that processes it lives in this module

---

## 4. Data Model

The Profile module reads and writes across two existing tables. No schema changes.

### 4.1 Fields Displayed on Profile

**From `User` table:**

| Field | Displayed As |
|---|---|
| `username` | Login username |
| `email` | Email address |
| `isactive` | Account status |
| `lastlogin` | Last login timestamp |
| `created` | Account creation date |

**From `Pribadi` table (via `idpribadi` FK):**

| Field | Displayed As |
|---|---|
| `noKtp` | NIK (read-only on profile) |
| `noKta` | KTA number (read-only on profile) |
| `namaLengkap` | Full name |
| `tempatLahir` | Place of birth |
| `tanggalLahir` | Date of birth |
| `kelamin` | Gender |
| `golonganDarah` | Blood type |
| `agama` | Religion |
| `statusPernikahan` | Marital status |
| `noHp` | Phone number |
| `email` | Email (from Pribadi — may differ from User.email) |
| `alamatKtp` | KTP address |
| `kelurahanDomisili` | Domicile village code |
| `noKk` | Family card number |
| `pendidikanTerakhir` | Last education |
| `pekerjaan` | Occupation |
| `instansi` | Institution/employer |
| `isPelatih` | Instructor flag |
| `isPengurus` | Organizational member flag |
| `jabatanPn` | Position label (read-only on profile) |
| `urlFoto` | Profile photo (reconstructed full URL) |
| `scopedata` | Territorial scope (read-only on profile) |
| `isVerified` | Verification status (read-only on profile) |

**From `UserRole` + `Role` (via join):**

| Field | Displayed As |
|---|---|
| `role.name` | Role name (e.g. "Verifikator PW") |
| `userRole.scope` | Territorial scope code |

### 4.2 Fields Editable via Profile

Only `Pribadi` fields are editable through the profile form. `User` table fields (username, email, isactive) are not editable here.

Editable fields: `namaLengkap`, `tempatLahir`, `tanggalLahir`, `kelamin`, `golonganDarah`, `agama`, `statusPernikahan`, `noHp`, `email` (Pribadi.email only), `alamatKtp`, `kelurahanDomisili`, `noKk`, `pendidikanTerakhir`, `pekerjaan`, `instansi`, `urlFoto`.

---

## 5. MinIO File Handling for Profile Photo

Profile photo handling follows the same rules as Module 02 (Section 8). Key points specific to the profile context:

- The file naming convention uses the district's `oldId` resolved from the member's current `kelurahanDomisili`
- If the user has changed their `kelurahanDomisili` since the last upload, the new photo is stored under the new district's path — the old photo under the old path is deleted
- The stored value in `urlFoto` is always the relative path (not the full URL)
- The full URL is reconstructed at read time using the MinIO environment configuration

---

## 6. Secure Document Serving on Profile

The same secure document serving rules from Module 02 apply here. The profile page never displays raw MinIO URLs — documents are always fetched through the backend's file-serving endpoint.

**Profile photo** (`jns=pasfoto`): fetched from MinIO and served as-is. No watermark.

**KTP scan** (`jns=ktp`): fetched from MinIO, watermark composited in-memory, then served. The watermark applies even when a user views their **own** KTP scan — the system does not make an exception for self-access.

The watermark on KTP contains the accessor's KTA number (or name if KTA not yet assigned), a timestamp, and the copyright line `© PP Pagar Nusa`, rendered in red centered text over the image.

**If no photo is uploaded**, the backend returns a default placeholder image (`default.png`) rather than an error.

The frontend constructs document viewer URLs for the profile Documents tab as:
```
/api/files/FotoPribadi/{user.publicId}?jns=pasfoto
/api/files/FotoPribadi/{user.publicId}?jns=ktp
```

See Module 02, Section 9 for the full secure document serving specification.

---

## 7. Password Change Flow

The password change logic is the same endpoint used in Module 03 (`PUT /api/users/rpw`) but accessed from the profile context. The key behavioral rules:

1. The user's `publicId` is extracted from their JWT token
2. The linked `Pribadi` record is found using `publicId`
3. The linked `User` record is found using `Pribadi.idpribadi`
4. The provided current password is hashed and compared to the stored hash
5. If they match, the new password is hashed and saved
6. If they do not match, the request is rejected — no change is made

For the **first login flow** specifically, step 4 is bypassed — the system accepts the change without verifying the old password, because the default password is system-generated (the member's NIK) and the user may not know it explicitly.

---

## 8. QR Code Confirmation Workflow

The QR confirmation feature (`konfirmasi-qr`) provides an additional verification layer for sensitive actions. The exact use cases where QR confirmation is required are determined at the application level, but the workflow is:

1. The system generates a time-limited QR code containing the user's `publicId`
2. The QR code is displayed on screen for the user to scan with an authorized mobile device
3. The mobile device submits the scanned `publicId` back to the system to confirm the user's physical presence
4. The system records the confirmation and grants the action that required it
5. The confirmation token expires after the defined window — the QR must be scanned before expiry

The QR generation and validation endpoints are part of this module. The specific actions that require QR confirmation are to be determined during implementation based on the organization's security requirements.

---

## 9. API Endpoints

All endpoints in this module require a valid JWT. The user's identity is always derived from the token — no user ID is passed in the URL for read/write operations on own profile.

---

### GET `/api/profil/me`

Returns the complete profile of the currently logged-in user — assembled from `User`, `Pribadi`, `UserRole`, and `Role`.

**Response 200:**
```json
{
  "user": {
    "iduser": 1,
    "username": "86337408000001",
    "email": "budi@pagarnusa.or.id",
    "isactive": 1,
    "lastlogin": "2024-04-01T08:30:00Z",
    "role": "Verifikator PW",
    "scope": "33"
  },
  "pribadi": {
    "id": 1,
    "noKtp": "3374xxxxxxxxxxxx",
    "noKta": "86337408000001",
    "namaLengkap": "Budi Santoso",
    "tempatLahir": "Semarang",
    "tanggalLahir": "1990-05-15",
    "kelamin": "l",
    "golonganDarah": "A",
    "agama": "Islam",
    "statusPernikahan": "Menikah",
    "noHp": "08123456789",
    "email": "budi@pagarnusa.or.id",
    "alamatKtp": "Jl. Merdeka No. 1",
    "kelurahanDomisili": "3374031001",
    "noKk": "33740000000001",
    "pendidikanTerakhir": "S1",
    "pekerjaan": "Wiraswasta",
    "isPelatih": false,
    "isPengurus": true,
    "jabatanPn": "Anggota - PC Kota Semarang",
    "isVerified": true,
    "fotoUrl": "https://minio.../assets/pic/3374/3374_pasfoto_3374xxxx.jpg",
    "publicId": "pub-uuid"
  }
}
```

---

### PUT `/api/profil/me`

Update the currently logged-in user's own `Pribadi` record.

**Request (multipart/form-data):** All editable `Pribadi` fields. All optional — only provided fields are updated.

If `kelurahanDomisili` is included, the backend re-resolves `kabupatenDomisili`, `idKabupatenDomisili`, and `idKelurahanDomisili` using the special-district resolution logic.

If a new photo file is included, the old MinIO object is deleted and replaced.

**Response 200:**
```json
{ "message": "Profile updated successfully." }
```

---

### PUT `/api/users/rpw`

Change own password. Identity taken from JWT.

> This endpoint is defined in Module 03 but is surfaced in the profile UI. See Module 03, Section 6 for full behavioral rules.

**Request:**
```json
{
  "oldPassword": "CurrentPassword123",
  "newPassword": "NewSecurePassword123"
}
```

**Response 200:**
```json
{ "message": "Password changed successfully." }
```

**Response 400:**
```json
{ "statusCode": 400, "message": "Current password is incorrect." }
```

---

### PUT `/api/profil/first-login-password`

Mandatory password change for first-login users. Does not require `oldPassword`.

**Request:**
```json
{
  "newPassword": "NewSecurePassword123",
  "confirmPassword": "NewSecurePassword123"
}
```

On success, sets `Pribadi.isEmailFirstLogin` to `false`.

**Response 200:**
```json
{ "message": "Password set successfully. Welcome to the system." }
```

---

### GET `/api/profil/qr`

Generate a QR code for the currently logged-in user.

**Response 200:**
```json
{
  "qrToken": "generated-token",
  "qrImageUrl": "data:image/png;base64,...",
  "expiresAt": "2024-04-01T09:15:00Z"
}
```

---

### POST `/api/profil/qr/confirm`

Validate a scanned QR token.

**Request:**
```json
{ "qrToken": "generated-token" }
```

**Response 200:**
```json
{ "message": "QR confirmation successful.", "confirmed": true }
```

**Response 400 — Token expired or invalid:**
```json
{ "statusCode": 400, "message": "QR token is invalid or has expired." }
```

---

## 10. UI Flow

### 9.1 Profile Page — `/admin/profil`

```
┌────────────────────────────────────────────────────────────────┐
│  My Profile                                    [ Edit Profile ]│
│                                                                │
│  ┌──────────┐  Budi Santoso                                    │
│  │  [Photo] │  KTA: 86337408000001                            │
│  │          │  Role: Verifikator PW  │  Scope: Jawa Tengah    │
│  └──────────┘  jabatanPn: Anggota - PC Kota Semarang          │
│                Last login: 01 Apr 2024, 08:30                  │
│                                                                │
│  [ Personal ] [ Address ] [ Documents ] [ Organization ]       │
│  ──────────────────────────────────────────────────────────    │
│                                                                │
│  NIK          : 3374xxxxxxxxxxxx          (read-only)          │
│  Date of Birth: 15 May 1990, Semarang                          │
│  Gender       : Male                                           │
│  Blood Type   : A                                              │
│  Religion     : Islam                                          │
│  Marital Status: Married                                       │
│  Phone        : 08123456789                                    │
│  Email        : budi@pagarnusa.or.id                           │
│                                                                │
│              [ Change Password ]   [ QR Confirmation ]         │
└────────────────────────────────────────────────────────────────┘
```

---

### 9.2 Edit Profile Form

Presented as a full page or side panel. Same tabbed layout as the detail view but with editable fields.

**Read-only fields shown but not editable:**
- NIK (`noKtp`)
- KTA number (`noKta`)
- Role and scope (managed in Module 03)
- `jabatanPn` (computed, managed in Module 02)
- Verification status

**Profile photo section:**
```
┌──────────────────────────────────────┐
│  [Current Photo]                     │
│                                      │
│  [ Upload New Photo ]                │
│  Max 350KB · JPG or PNG only         │
└──────────────────────────────────────┘
```

---

### 9.3 Change Password Page — `/admin/profil/ganti-password`

```
┌──────────────────────────────────────┐
│  Change Password                     │
│                                      │
│  Current Password *  [          👁]  │
│  New Password *      [          👁]  │
│  Confirm Password *  [          👁]  │
│                                      │
│  ✓ At least 8 characters            │
│  ✓ At least one uppercase letter    │
│  ✓ At least one number              │
│                                      │
│        [ Save New Password ]         │
└──────────────────────────────────────┘
```

---

### 9.4 QR Confirmation Page — `/admin/profil/konfirmasi-qr`

```
┌──────────────────────────────────────┐
│  QR Authorization                    │
│                                      │
│  Scan this QR code with the          │
│  authorized PagarNusa mobile app     │
│  to confirm your identity.           │
│                                      │
│  ┌──────────────────────────────┐    │
│  │                              │    │
│  │        [QR Code Image]       │    │
│  │                              │    │
│  └──────────────────────────────┘    │
│                                      │
│  Valid for: 10:00 ⏱ (countdown)      │
│                                      │
│  [ Generate New QR ]                 │
└──────────────────────────────────────┘
```

After successful scan and confirmation:
```
✅ Identity confirmed successfully.
   You may now proceed with the authorized action.
```

---

### 9.5 First Login Mandatory Password Change

Shown immediately after first login, before any module is accessible:

```
┌──────────────────────────────────────┐
│  Welcome, Budi Santoso!              │
│                                      │
│  For your account security, please   │
│  set a new password before           │
│  continuing.                         │
│                                      │
│  New Password *      [          👁]  │
│  Confirm Password *  [          👁]  │
│                                      │
│  ✓ At least 8 characters            │
│  ✓ At least one uppercase letter    │
│  ✓ At least one number              │
│                                      │
│        [ Save & Continue ]           │
└──────────────────────────────────────┘
```

---

## 11. Business Rules Summary

| Rule | Detail |
|---|---|
| Self-service only | All profile endpoints operate exclusively on the logged-in user's own data |
| Identity from JWT | User identity is never taken from URL parameters — always from the JWT token |
| Profile is a combined view | Data assembled from `User` + `Pribadi` + `UserRole` + `Role` |
| NIK and KTA are read-only | Cannot be changed through the profile module |
| Role and scope are read-only | Managed only by Superadmin in Module 03 |
| `jabatanPn` is read-only | Computed during verification in Module 02 |
| Address change triggers re-resolve | Changing `kelurahanDomisili` must re-trigger the special-district resolution logic |
| Photo replacement deletes old file | Old MinIO object removed before uploading new one |
| Password requires current password | Except for first-login flow where old password is bypassed |
| First login blocks module access | `isEmailFirstLogin: true` forces password change before any navigation |
| QR token is time-limited | Expires after defined window; must be regenerated if expired |

---

## 12. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/profil/me` — assemble profile from User + Pribadi + UserRole + Role using JWT identity
- [ ] `PUT /api/profil/me` — update own Pribadi fields; re-resolve territory if `kelurahanDomisili` changed; replace MinIO photo if new file provided
- [ ] `PUT /api/profil/first-login-password` — set new password without old password check; set `isEmailFirstLogin: false`
- [ ] `GET /api/profil/qr` — generate QR token and image for logged-in user
- [ ] `POST /api/profil/qr/confirm` — validate submitted QR token, check expiry
- [ ] Reuse `PUT /api/users/rpw` (Module 03) for authenticated password change from profile
- [ ] Reuse `GET /api/files/FotoPribadi/:publicid?jns=` (Module 02) for serving own documents — no separate endpoint needed
- [ ] All endpoints identity-gated via JWT — no user ID in URL

### Frontend (Next.js)
- [ ] `/admin/profil` — combined profile view with 4 tabs; photo display with placeholder fallback
- [ ] Documents tab — use `/api/files/FotoPribadi/:publicid?jns=` endpoints, never raw MinIO URLs
- [ ] KTP scan displayed with watermark (applied server-side — frontend just renders the streamed image)
- [ ] Display note to user that KTP access is logged and watermarked
- [ ] Edit profile form — editable fields only; read-only fields shown as static text
- [ ] Profile photo upload — 350KB validation, JPG/PNG only, immediate preview after upload
- [ ] `/admin/profil/ganti-password` — password change form with complexity indicator
- [ ] `/admin/profil/konfirmasi-qr` — QR display with countdown timer, regenerate button
- [ ] First login flow — intercept after login if `isEmailFirstLogin: true`, block navigation until complete
- [ ] Role and scope displayed as human-readable labels (resolved from role catalog and territory data)

---

*This document is the PRD for Module 06 — Profile (Profil).*
*Business logic synthesized from: `UsersController.cs`, `UserService.cs`, `AnggotaService.cs`, `IS3Client.cs`, `FilesController.cs` (cross-module analysis)*
*Next: PRD Module 07 — KTA Card Generation & Batch Export*
*Last updated: April 2026 | Version: 2.0*
