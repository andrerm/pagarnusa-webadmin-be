# PRD Module 02 — Member List (Daftar Anggota)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All workflows related to member data — self-registration, member list view, member detail view, verification & KTA number assignment, rejection, data search & filtering, and file storage behavior. Does not cover account management (Module 03) or KTA card image generation (Module 08).

---

## 1. Module Summary

The Member List module is the operational core of the system. It manages the complete lifecycle of a PagarNusa member record: from public self-registration, through the verification queue, to approved membership with an assigned KTA number. All data access is automatically restricted by the logged-in user's territorial scope.

---

## 2. Actors & Permissions

| Actor | View List | View Detail | Verify | Reject | Edit | Delete |
|---|---|---|---|---|---|---|
| Superadmin | All territories | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verifikator PW | Province scope | ✅ | ✅ | ✅ | ✅ | ❌ |
| Verifikator PC | District scope | ✅ | ✅ | ✅ | ✅ | ❌ |
| Observer | Assigned scope | ✅ | ❌ | ❌ | ❌ | ❌ |
| Public | — | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 3. User Stories

### US-MEMBER-01 — Public Self-Registration
> As a prospective member, I want to fill out a registration form so that I can apply to become a PagarNusa member.

**Acceptance Criteria:**
- Form is publicly accessible at `/form-daftar-noauth` — no login required
- Bot protection (reCAPTCHA v3) is active on every submission
- All required fields must be validated before submission
- On successful submission the record is saved with a pending/unverified status
- The system automatically resolves and stores the member's administrative district from the village code they provide (see Section 7.3 — Special District Resolution)
- User receives a confirmation message on screen
- If the same NIK already exists in the system, submission is blocked with a clear error

---

### US-MEMBER-02 — View Member List
> As an admin, I want to see a paginated list of members so that I can browse and manage records efficiently.

**Acceptance Criteria:**
- The list only shows members within the logged-in user's territorial scope
- Superadmin sees all members across all territories
- Each row shows: full name, NIK, territory, verification status, registration date
- Supports pagination with configurable page size (10 / 25 / 50, default 10)
- Supports keyword search across name, NIK, and KTA number
- Supports filtering by: verification status, province, district
- Sortable by name and registration date

---

### US-MEMBER-03 — View Member Detail
> As an admin, I want to view a member's complete profile so that I can review all data before making a verification decision.

**Acceptance Criteria:**
- All personal data sections are displayed (see Section 4 — Data Model)
- Uploaded files (KTP scan, profile photo) are viewable inline
- Verification history (verifier name, date, rejection reason if any) is visible
- Action buttons (Verify / Reject) are shown only to users with verification permission

---

### US-MEMBER-04 — Verify a Member & Assign KTA Number
> As a Verifikator PW or PC, I want to approve a member's registration and assign a KTA number so that they become an active PagarNusa member.

**Acceptance Criteria:**
- A Verifikator can only verify members within their own territorial scope
- On approval, the system generates a KTA number (see Section 5 — KTA Number Generation)
- The member's position label (`jabatanPn`) is computed and stored (see Section 6 — Position Label)
- The member's organizational detail record is created (see Section 7 — Organizational Detail)
- The verifier's identity and timestamp are recorded
- A confirmation dialog is shown before the action is committed
- This action cannot be reversed from the UI; only a Superadmin can reset it

---

### US-MEMBER-05 — Reject a Member
> As a Verifikator PW or PC, I want to reject a registration with a reason so that the applicant knows what to correct.

**Acceptance Criteria:**
- Rejection requires a mandatory written reason (minimum 10 characters)
- The rejection reason and timestamp are recorded against the member record
- Rejected members remain visible in the list with a "Rejected" status
- Re-submission for verification is only possible after a Superadmin resets the status

---

### US-MEMBER-06 — Edit Member Data
> As an admin, I want to update a member's information so that the record stays accurate.

**Acceptance Criteria:**
- All fields collected at registration are editable
- If a new file is uploaded for a field (photo or KTP scan), the old file is removed from storage
- If the member's organizational role changes, their position label is recomputed
- Superadmin can edit any member; Verifikator can only edit within their scope

---

### US-MEMBER-07 — Delete a Member (Superadmin only)
> As a Superadmin, I want to permanently delete a member record so that invalid data can be removed.

**Acceptance Criteria:**
- Only Superadmin can perform this action
- A confirmation dialog shows the member's full name before proceeding
- All associated data is permanently removed: the member record, uploaded files in storage, organizational detail records, and the reserved KTA sequence slot
- This cannot be undone

---

## 4. Data Model

The following fields are collected and stored per member. All map to the existing `pribadi` table in MySQL — no schema changes.

### 4.1 Identity
| Field | Description | Required |
|---|---|---|
| `noKtp` | NIK — 16-digit national ID number, unique across the system | ✅ |
| `namaLengkap` | Full name | ✅ |
| `tempatLahir` | Place of birth | ✅ |
| `tanggalLahir` | Date of birth | ✅ |
| `kelamin` | Gender — `"l"` (male) or `"p"` (female) | ✅ |
| `golonganDarah` | Blood type | — |
| `agama` | Religion | ✅ |
| `statusPernikahan` | Marital status | ✅ |

### 4.2 Contact
| Field | Description | Required |
|---|---|---|
| `noHp` | Phone number | ✅ |
| `email` | Email address | — |

### 4.3 Address & Territory
| Field | Description | Required |
|---|---|---|
| `alamatKtp` | KTP address (street, RT/RW) | — |
| `kelurahanDomisili` | 10-digit village/kelurahan code — primary territory field | ✅ |
| `kabupatenDomisili` | 4-digit district code — resolved automatically from `kelurahanDomisili` | Auto |
| `idKabupatenDomisili` | Internal district ID — resolved automatically | Auto |
| `idKelurahanDomisili` | Internal village ID — resolved automatically | Auto |
| `scopedata` | Copy of `kelurahanDomisili` — used for scope filtering | Auto |

### 4.4 Identity Documents
| Field | Description |
|---|---|
| `noKk` | Family card number |
| `noKta` | KTA number — assigned on verification, null before that |
| `publicId` | Public-facing unique ID for external API access |

### 4.5 Education & Employment
| Field | Description |
|---|---|
| `pendidikanTerakhir` | Last education level |
| `pekerjaan` | Occupation |
| `instansi` | Employer or institution (supports multiple entries) |

### 4.6 Role Flags
| Field | Default | Description |
|---|---|---|
| `isPelatih` | false | Member is an instructor |
| `isPengurus` | false | Member holds a position in an organizational unit |
| `isAdmin` | false | Member has a linked admin account |
| `isEmailFirstLogin` | true | Forces password change on first login |

### 4.7 File Storage
| Field | Description |
|---|---|
| `urlFoto` | Relative storage path of profile photo |
| `urlKtp` | Relative storage path of KTP scan |

### 4.8 Verification
| Field | Default | Description |
|---|---|---|
| `isVerified` | false | Verification status |
| `jabatanPn` | `"Unverified"` | Human-readable position label — computed on verification |
| `verifiedBy` | null | Name of the verifying admin |
| `verifiedAt` | null | Timestamp of verification |
| `rejectionReason` | null | Written reason if rejected |
| `rejectedAt` | null | Timestamp of rejection |

---

## 5. KTA Number Generation

A KTA number is generated automatically when a member is verified. It is a 14-character string structured as follows:

### 5.1 KTA Number Format

```
Segment          : [1–2]    [3–4]          [5–6]           [7–8]          [9–14]
Content          : Prefix   Province Code  District Code   Gender Code    Sequential No.
Example          : 86       33             74              08             000001
Assembled        : 86337408000001
```

| Segment | Length | Source |
|---|---|---|
| Prefix | 2 chars | Always `"86"` — fixed for all members |
| Province code | 2 chars | PagarNusa internal province code (`Provinsi.oldKodeWilayahPn`) |
| District code | 2 chars | PagarNusa internal district code (`Kabupaten.oldKodeWilayahPn`) |
| Gender code | 2 chars | `"06"` for female (`"p"`), `"08"` for male (`"l"`) |
| Sequential number | 6 chars | Zero-padded integer, scoped per district |

### 5.2 Sequential Number Padding

The sequential number is always zero-padded to 6 characters:

| Raw number | Padded result |
|---|---|
| 1 | `000001` |
| 42 | `000042` |
| 1000 | `001000` |
| 100000 | `100000` |

Numbers with 7 or more digits exceed the field and must be flagged as an overflow error — this should not occur in normal operation.

### 5.3 Sequential Number Assignment — Gap-Fill Strategy

The system maintains a `penomoran` (numbering) table that records which sequential numbers have been assigned per district. When a new KTA number is needed, the system finds the **smallest available number** using the following rules:

**Rule 1 — No records exist for this district yet:** Assign number 1.

**Rule 2 — Exactly one record exists:** Assign number 2.

**Rule 3 — Multiple records exist, sorted in ascending order:**
- If the first record's number is greater than 1, there is an unclaimed slot at the beginning — assign that slot (first record's number minus 1).
- Otherwise, scan through consecutive pairs. If a gap is found between two adjacent records (i.e. the difference is greater than 1), the smallest number in that gap is assigned (the lower record's number plus 1).
- If no gaps are found after scanning all records, assign the number after the last record (last record's number plus 1).

This ensures that numbers left vacant by deleted or reset members are reused before new numbers are issued, keeping the sequence compact.

### 5.4 Reservation

Once a number is assigned, a record is created in the `penomoran` table to reserve it. This reservation must be created in the same database transaction as the member verification update. If the transaction fails for any reason, no reservation is created and the number remains available.

When a verification is reset by a Superadmin, the `penomoran` reservation record is deleted, freeing the number for future reuse.

---

## 6. Position Label (`jabatanPn`)

`jabatanPn` is a human-readable string stored on the member record that describes their role within the organization. It is computed (not entered manually) at two points: during verification, and whenever the member's organizational role is updated.

### 6.1 Computation Rules

The value depends on whether the member holds an organizational position (`isPengurus`):

**If `isPengurus` is true:**
The label combines the member's position title and the name of the organizational unit they belong to.
- Format: `"{position title} {organizational unit name}"`
- Example: `"Ketua PC Kota Semarang"`
- Source: the member's `DetilKepengurusan` record provides the position title; the linked `Kepengurusan` record provides the unit name.

**If `isPengurus` is false:**
The label marks the member as a regular member of their district's organizational unit.
- Format: `"Anggota - {organizational unit name}"`
- Example: `"Anggota - PC Kota Semarang"`
- Source: the organizational unit (`Kepengurusan`) is found by matching the member's resolved district to the unit's territory.

### 6.2 When to Recompute

| Event | Recompute? |
|---|---|
| Member verified | ✅ Yes |
| Member's `isPengurus` flag changed on edit | ✅ Yes |
| Member's organizational unit or position changed on edit | ✅ Yes |
| Member's address or other non-organizational fields changed | ❌ No |
| Verification reset by Superadmin | ✅ Yes — reset to `"Unverified"` |

---

## 7. Organizational Detail (`DetilKepengurusan`)

A `DetilKepengurusan` record links a member to an organizational unit and their specific position within it. This record is created during verification and replaced (not partially updated) whenever the member's organizational role changes.

### 7.1 Fields Stored

| Field | Description |
|---|---|
| `pribadiId` | Links to the member |
| `kepengurusanId` | Links to the organizational unit |
| `jabatanId` | Links to the position/title definition |
| `jabatanPn` | Position title as a plain string |
| `kodeWilayah` | Territory code of the organizational unit |
| `idWilayah` | Internal territory ID — resolved from the linked Kepengurusan record |
| `isActive` | Activation flag — defaults to inactive (`0`) |

### 7.2 Replace Strategy on Edit

When a member's organizational role is updated, the existing `DetilKepengurusan` record(s) for that member are deleted and a new record is created from the updated form data. This is a full replacement, not a patch.

After replacement, `jabatanPn` on the `Pribadi` record must be recomputed (see Section 6).

### 7.3 Special District Resolution (`IsPcKhusus`)

When a new member registers, the system must resolve the correct administrative district from the 10-digit village code (`kelurahanDomisili`). This cannot always be done by simply taking the first 4 digits of the village code, because some districts in the system are "split" — their sub-districts administratively belong to a different PC (district organizational unit) than their geographic code implies.

**Resolution logic:**

1. Extract the first 4 digits of `kelurahanDomisili` to get the candidate district code.
2. Look up that district. If the district has a `kodefullPecahan` value (non-null), it is a split district and the geographic code is not reliable.
3. For split districts: traverse upward through the territory hierarchy — from the village record, find its parent sub-district, then find that sub-district's parent district. Use that resolved district as the actual administrative district.
4. For normal districts: use the district found in step 1 directly.

The resolved district's ID and code are stored in `idKabupatenDomisili` and `kabupatenDomisili` on the member record. These fields are critical for scope filtering and KTA number generation, so they must always reflect the administratively correct district.

---

## 8. File Storage

All uploaded files are stored in MinIO (S3-compatible object storage). The frontend never interacts with MinIO directly — all file operations go through the backend.

### 8.1 File Naming

Files are named using the district's legacy code (`Kabupaten.oldId`) and the member's NIK to ensure uniqueness and organization by district:

```
KTP scan     : {district.oldId}_ktp_{nik}.{extension}
Profile photo: {district.oldId}_pasfoto_{nik}.{extension}

Examples:
  3374_ktp_3374xxxxxxxxxxxx.jpg
  3374_pasfoto_3374xxxxxxxxxxxx.jpg
```

The district `oldId` used here is from the **resolved** district (after IsPcKhusus resolution, not the raw geographic code).

### 8.2 Storage Paths

```
KTP scan     : assets/id/{district.oldId}/{filename}
Profile photo: assets/pic/{district.oldId}/{filename}
```

All paths are stored relative to the configured storage root. The full URL is reconstructed at read time by combining the MinIO service URL, bucket name, root prefix, and relative path.

### 8.3 What Is Stored in the Database

`urlFoto` and `urlKtp` on the `Pribadi` record store only the **relative path** after the bucket and root prefix. The full URL is never stored — it is always reconstructed dynamically when serving data to the frontend.

### 8.4 File Rules

| Field | Filename keyword | Max size | Accepted types |
|---|---|---|---|
| KTP scan | Must contain `"ktp"` | 350 KB | JPG, PNG |
| Profile photo | Must contain `"pasfoto"` | 350 KB | JPG, PNG |

The frontend renames files before uploading to ensure the filename contains the correct keyword. File type and size are also validated on the backend.

### 8.5 File Operations by Event

| Event | Storage Operation |
|---|---|
| New registration | Upload both files; store relative paths in DB |
| Edit — new file provided | Delete old object from MinIO → upload new → update relative path in DB |
| Edit — no new file | No storage change; existing path retained |
| Delete member | Delete all associated MinIO objects before removing the DB record |
| View detail | Reconstruct full URL from relative path + environment configuration |

---

## 9. Secure Document Serving

Member documents (profile photo and KTP scan) are **never served as raw MinIO URLs** directly to the browser. All document access goes through a backend endpoint that fetches the file from MinIO and applies security rules before streaming the response. This is the mechanism that prevents unauthorized direct access to stored files.

### 9.1 Two Document Types, Two Behaviors

| Document type | Query param | Behavior |
|---|---|---|
| Profile photo | `jns=pasfoto` | Fetched from MinIO and served as-is — no modification |
| KTP scan | `jns=ktp` | Fetched from MinIO, **watermark overlaid**, then served |

### 9.2 KTP Watermark Rule

Every time a KTP scan is accessed — by any user, including Superadmin — a watermark is composited onto the image before it is returned. The watermark is never stored; it is applied in-memory on each request.

**Watermark content:**
```
Diakses:
{dd/MM/yyyy-HH:mm:ss}
{accessor's KTA number, or full name if KTA not yet assigned}
© PP Pagar Nusa
```

- Text color: **red**
- Font: system sans-serif (DejaVu-Sans or equivalent)
- Font size: 20pt, semi-bold weight
- Position: centered over the entire image
- Background: transparent (overlaid on the original image)

The **accessor's identity** — the person making the request, taken from their JWT — is embedded in the watermark, not the subject's identity. This creates an audit trail: if a KTP image leaks, it can be traced back to who accessed it.

### 9.3 Default Image Fallback

If a member's `urlFoto` or `urlKtp` is null, empty, or the object cannot be found in MinIO, the system returns a default placeholder image (`default.png`) rather than an error. This ensures the detail page always renders cleanly regardless of whether files were uploaded.

### 9.4 Document Serving Endpoint

**`GET /api/files/FotoPribadi/{publicid}?jns={pasfoto|ktp}`**

- Requires a valid JWT (authentication required)
- `publicid` identifies the member whose document is being accessed
- The accessor's identity is extracted from the JWT, not from a request parameter
- For `jns=pasfoto`: fetches from MinIO, returns as-is
- For `jns=ktp`: fetches from MinIO, composites watermark, returns modified image
- If file not found: returns `default.png`
- Response is a raw file stream (image/png or image/jpeg) — not a JSON wrapper

**`GET /api/files/FotoPribadiW/{publicid}?jns={pasfoto|ktp}`**

Watermarked variant — functionally identical to the above for the current implementation. Both endpoints apply the watermark on KTP and serve photo as-is. This endpoint exists as a named distinction for watermarked access and may diverge in behavior in future versions.

### 9.5 Frontend Integration Rule

The member detail page (Documents tab) must use these serving endpoints — not raw MinIO URLs — to display documents inline. The `urlFoto` and `urlKtp` fields returned by `GET /api/pribadis/:id` are relative storage paths, not displayable URLs. The frontend constructs the document viewer URL as:

```
/api/files/FotoPribadi/{member.publicId}?jns=pasfoto   ← for photo
/api/files/FotoPribadi/{member.publicId}?jns=ktp        ← for KTP scan
```

---

## 10. Territorial Scope Filtering

All member data queries are automatically restricted based on the logged-in user's territorial scope (stored in the JWT).

### 9.1 Scope Rules

| JWT Scope Value | Meaning | Filter Applied |
|---|---|---|
| `"-"` (literal dash) | Superadmin | No filter — all records returned |
| 2-digit string (e.g. `"33"`) | Province scope | Return members whose village code starts with this prefix |
| 4-digit string (e.g. `"3374"`) | District scope | Return members whose resolved district ID matches this district |

The 4-digit district filter uses the resolved `idKabupatenDomisili` (not a string prefix match) to correctly handle split-district members whose village codes do not start with the district's standard code prefix.

### 9.2 Enforcement

Scope filtering is applied at the data access layer on every query — it cannot be overridden by query parameters sent from the client.

---

## 11. Verification State Machine

```
         [Public submits registration]
                      ↓
                  PENDING
                 (isVerified: false, no rejectionReason)
                /                    \
        [Verify]                  [Reject + reason]
            ↓                            ↓
        VERIFIED                     REJECTED
     (isVerified: true)        (isVerified: false, rejectionReason set)
                                         ↓
                              [Superadmin resets status]
                                         ↓
                                     PENDING
```

A rejected member cannot re-enter the verification flow without a Superadmin first resetting their status. The reset clears all verification fields, deletes the `Penomoran` reservation if one exists, and resets `jabatanPn` to `"Unverified"`.

---

## 12. API Endpoints

**Base URL:** `/api/pribadis`

All endpoints except `POST /api/public/register` require a valid JWT. Scope filtering is applied automatically.

---

### GET `/api/pribadis`
Returns a paginated, scope-filtered member list.

**Query Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | number | `1` | Page number |
| `pageSize` | number | `10` | Items per page (max 50) |
| `keyword` | string | — | Search by name, NIK, or KTA number |
| `isVerified` | boolean | — | Filter by verification status |
| `provinsiCode` | string | — | Superadmin only — 2-digit province filter |
| `kabupatenCode` | string | — | Superadmin only — 4-digit district filter |
| `sortBy` | string | `created` | `namaLengkap` or `created` |
| `sortOrder` | string | `desc` | `asc` or `desc` |

**Response 200:**
```json
{
  "data": [
    {
      "id": 1,
      "noKtp": "3374xxxxxxxxxxxx",
      "namaLengkap": "Budi Santoso",
      "noKta": "86337408000001",
      "kabupatenDomisili": "3374",
      "isVerified": true,
      "jabatanPn": "Anggota - PC Kota Semarang",
      "verifiedAt": "2024-03-15T10:30:00Z",
      "created": "2024-03-10T08:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "pageSize": 10,
    "total": 245,
    "totalPages": 25
  }
}
```

---

### GET `/api/pribadis/:id`
Returns full member detail. Scope-checked before returning. File URLs are returned as reconstructed full URLs (not relative paths).

**Response 403:**
```json
{ "statusCode": 403, "message": "You do not have permission to access this member's data." }
```

---

### GET `/api/pribadis/:id/preview-kta`
Runs the KTA number generation logic in read-only mode (no DB write) and returns the number that would be assigned. Used by the frontend to show a preview in the verification confirmation dialog.

**Response 200:**
```json
{
  "noKta": "86337408000001",
  "jabatanPn": "Anggota - PC Kota Semarang"
}
```

---

### POST `/api/public/register`
Public self-registration. No authentication required.

**Request (multipart/form-data):**

| Field | Required | Notes |
|---|---|---|
| `namaLengkap` | ✅ | |
| `noKtp` | ✅ | 16 digits, must be unique |
| `tempatLahir` | ✅ | |
| `tanggalLahir` | ✅ | YYYY-MM-DD |
| `kelamin` | ✅ | `"l"` or `"p"` |
| `golonganDarah` | — | |
| `agama` | ✅ | |
| `statusPernikahan` | ✅ | |
| `noHp` | ✅ | |
| `email` | — | |
| `kelurahanDomisili` | ✅ | 10-digit village territory code |
| `noKk` | — | |
| `pendidikanTerakhir` | — | |
| `pekerjaan` | — | |
| `ktp` (file) | — | Filename must contain `"ktp"`, max 350KB |
| `pasfoto` (file) | — | Filename must contain `"pasfoto"`, max 350KB |
| `captchaToken` | ✅ | Bot protection token |

**System sets automatically on save:**
- Verification status → pending/unverified
- `jabatanPn` → `"Unverified"`
- `scopedata` → copied from `kelurahanDomisili`
- `kabupatenDomisili`, `idKabupatenDomisili`, `idKelurahanDomisili` → resolved via special district logic
- `urlFoto`, `urlKtp` → relative MinIO paths after upload

**Response 201:**
```json
{
  "message": "Registration submitted successfully. Please wait for admin verification.",
  "id": 1
}
```

**Response 409 — Duplicate NIK:**
```json
{ "statusCode": 409, "message": "A record with this NIK already exists in the system." }
```

---

### PUT `/api/pribadis/:id`
Update member data. Requires authentication and scope permission.

All fields are optional — only provided fields are updated. If a new file is provided for a file field, the old MinIO object is deleted before uploading the new one. If `isPengurus` or organizational fields change, `jabatanPn` is recomputed.

**Response 200:**
```json
{ "message": "Member data updated successfully.", "id": 1 }
```

---

### PUT `/api/pribadis/:id/verify`
Approve a member and assign a KTA number. Verifikator PW/PC and Superadmin only.

All of the following must happen in a single atomic database transaction:
1. Verify the caller's scope covers this member's territory
2. Generate the KTA number (Section 5)
3. Reserve the sequential number in `penomoran` table
4. Store the KTA number on the member record
5. Set verification status, verifier name (from JWT), and timestamp
6. Compute and store `jabatanPn` (Section 6)
7. If `isPengurus` is true: create the `DetilKepengurusan` record (Section 7)

**Response 200:**
```json
{
  "message": "Member verified successfully.",
  "noKta": "86337408000001",
  "verifiedBy": "Admin Jateng",
  "verifiedAt": "2024-04-01T09:00:00Z"
}
```

**Response 403:**
```json
{ "statusCode": 403, "message": "This member is outside your territorial scope." }
```

---

### PUT `/api/pribadis/:id/reject`
Reject a registration with a mandatory reason.

**Request:**
```json
{ "reason": "KTP scan is blurry and unreadable. Please resubmit a clear photo." }
```

**Response 400 — Reason too short:**
```json
{ "statusCode": 400, "message": "Rejection reason must be at least 10 characters." }
```

---

### PUT `/api/pribadis/:id/reset-verification`
Reset a member's status to pending. Superadmin only.

Clears: verification status, KTA number, verifier name and timestamp, rejection reason and timestamp, and `jabatanPn` (reset to `"Unverified"`). Also deletes the associated `penomoran` record to free the sequential slot for reuse.

---

### DELETE `/api/pribadis/:id`
Permanently delete a member. Superadmin only.

Must be executed in this order to avoid orphaned data:
1. Delete all MinIO objects (`urlFoto`, `urlKtp`)
2. Delete `DetilKepengurusan` records
3. Delete `penomoran` record
4. Delete linked `User` account (if any)
5. Delete the `Pribadi` record

**Response 200:**
```json
{ "message": "Member record permanently deleted." }
```

---

### GET `/api/public/check-nik?nik={value}`
Check whether a NIK already exists. Public endpoint for debounced frontend validation.

**Response 200:**
```json
{ "exists": false }
```

---

## 13. UI Flow

### 13.1 Member List Page — `/admin/daftar-anggota`

```
┌─────────────────────────────────────────────────────────┐
│  Member List                          [ + Add Member ]  │
│                                                         │
│  ┌──────────────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ 🔍 Search...     │  │ Status ▾ │  │ Territory  ▾ │  │
│  └──────────────────┘  └──────────┘  └──────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Name          │ NIK    │ Territory  │ Status │ ⋮ │   │
│  ├───────────────┼────────┼────────────┼────────┼───┤   │
│  │ Budi Santoso  │ 3374.. │ Semarang   │ ✅     │ ⋮ │   │
│  │ Ani Wijaya    │ 3374.. │ Semarang   │ ⏳     │ ⋮ │   │
│  │ Rudi Hartono  │ 3374.. │ Semarang   │ ❌     │ ⋮ │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  Showing 1–10 of 245    [< 1 2 3 ... >]  [10 ▾]       │
└─────────────────────────────────────────────────────────┘
```

**Status badges:**

| Condition | Badge | Color |
|---|---|---|
| Verified | ✅ Verified | Green |
| Unverified, no rejection reason | ⏳ Pending | Yellow |
| Unverified, has rejection reason | ❌ Rejected | Red |

**Row action menu (⋮):**
- View Detail
- Edit *(hidden for Observer)*
- Verify *(Pending records only; hidden for Observer)*
- Reject *(Pending records only; hidden for Observer)*
- Delete *(Superadmin only)*

---

### 13.2 Member Detail Page — `/admin/daftar-anggota/:id`

Tabbed layout with four sections:

| Tab | Content |
|---|---|
| Personal | NIK, name, DOB, birthplace, gender, blood type, religion, marital status, phone, email, education, occupation |
| Address | Full address, village code, resolved district and province names |
| Documents | KTP scan and profile photo displayed inline with lightbox |
| Organization | `isPelatih`, `isPengurus`, `jabatanPn`, KTA number, `publicId`, organizational unit and position detail |

---

### 13.3 Public Registration Form — `/form-daftar-noauth`

4-step multi-step form to avoid overwhelming the applicant:

```
Step 1 — Personal Information
  Full Name *, NIK *, Place of Birth *, Date of Birth *,
  Gender *, Blood Type, Religion *, Marital Status *

Step 2 — Contact & Address
  Phone *, Email,
  Territory Picker * (cascading: Province → District → Subdistrict → Village)
  → the selected village code is stored as kelurahanDomisili

Step 3 — Employment & Education
  Occupation, Institution, Last Education Level

Step 4 — Documents & Confirmation
  Profile Photo upload (max 350KB, JPG/PNG)
  KTP Scan upload (max 350KB, JPG/PNG)
  Declaration checkbox *
  [ ← Back ]   [ Submit ]
```

The frontend renames uploaded files before sending to ensure filenames contain the required keywords (`"pasfoto"` and `"ktp"` respectively).

**After successful submission:**
```
✅ Your registration has been submitted successfully.
   Our admin team will review your data.
   Please keep your NIK for reference: 3374xxxxxxxxxxxx
```

---

### 13.4 Verify Dialog

Before confirming, the frontend fetches the KTA preview from `/api/pribadis/:id/preview-kta` to show the member what will be assigned.

```
Confirm Verification
─────────────────────────────────────────
Member      : Budi Santoso (NIK: 3374...)
KTA number  : 86337408000001
Position    : Anggota - PC Kota Semarang

This action cannot be undone.

[ Cancel ]                    [ Verify ✅ ]
```

---

### 13.5 Reject Dialog

```
Reject Registration
─────────────────────────────────────────
Member: Budi Santoso

Rejection reason * (minimum 10 characters)
┌─────────────────────────────────────────┐
│                                         │
└─────────────────────────────────────────┘

[ Cancel ]                    [ Reject ❌ ]
```

---

## 14. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/pribadis` — paginated list with scope filtering, search, sort
- [ ] `GET /api/pribadis/:id` — full detail, scope check, return relative paths (not full URLs)
- [ ] `GET /api/pribadis/:id/preview-kta` — dry-run KTA generation, no DB write
- [ ] `POST /api/public/register` — NIK check, bot protection, special district resolution, file upload to MinIO, set all auto fields
- [ ] `PUT /api/pribadis/:id` — field update, file replacement in MinIO, recompute `jabatanPn` if organizational fields changed
- [ ] `PUT /api/pribadis/:id/verify` — atomic transaction: KTA generation + `penomoran` reservation + verification fields + `jabatanPn` + `DetilKepengurusan`
- [ ] `PUT /api/pribadis/:id/reject` — validate reason length, store reason and timestamp
- [ ] `PUT /api/pribadis/:id/reset-verification` — clear all verification fields, delete `penomoran` record, Superadmin only
- [ ] `DELETE /api/pribadis/:id` — ordered deletion: MinIO → `DetilKepengurusan` → `penomoran` → `User` → `Pribadi`, Superadmin only
- [ ] `GET /api/public/check-nik` — NIK existence check for frontend debounce
- [ ] `GET /api/files/FotoPribadi/:publicid?jns=` — secure document serving: photo as-is, KTP with watermark, default fallback
- [ ] `GET /api/files/FotoPribadiW/:publicid?jns=` — watermarked variant (same behavior, separate named route)
- [ ] KTP watermark composition — accessor identity from JWT, timestamp, copyright line, red centered text overlay
- [ ] Default image fallback — return `default.png` if MinIO object not found
- [ ] KTA sequential number logic — gap-fill algorithm (Section 5.3)
- [ ] KTA number assembly — format as described in Section 5.1
- [ ] Special district resolution — IsPcKhusus traversal (Section 7.3)
- [ ] Position label computation — `jabatanPn` rules (Section 6)
- [ ] `DetilKepengurusan` full-replace strategy on edit (Section 7.2)
- [ ] Scope-aware query filtering applied at data layer (Section 10)
- [ ] File upload middleware — size limit (350KB), type validation (JPG/PNG only)
- [ ] MinIO client — upload, delete, get-as-bytes, check-exists operations

### Frontend (Next.js)
- [ ] `/admin/daftar-anggota` — list page with search, filter, sort, pagination, status badges
- [ ] `/admin/daftar-anggota/:id` — detail page with 4 tabs
- [ ] Documents tab — use `/api/files/FotoPribadi/:publicid?jns=` endpoints, never raw MinIO URLs
- [ ] KTP scan displayed inline with lightbox — served with watermark from backend
- [ ] Profile photo displayed inline — served as-is from backend
- [ ] `/admin/daftar-anggota/:id/edit` — edit form with file upload capability
- [ ] `/form-daftar-noauth` — 4-step public registration form
- [ ] File upload component — client-side 350KB validation, auto-rename with keyword before upload
- [ ] Cascading territory picker — Province → District → Subdistrict → Village
- [ ] Verify dialog — fetch KTA preview before showing, display number and position label
- [ ] Reject dialog — reason textarea with minimum 10-character validation
- [ ] Delete confirmation dialog — Superadmin only
- [ ] Role-aware button visibility — based on permissions from `/api/auth/me`
- [ ] Debounced NIK uniqueness check on registration form

---

*This document is the PRD for Module 02 — Member List (Daftar Anggota).*
*Business logic source: legacy `AnggotaService.cs`, `IS3Client.cs`, `IFileService.cs`, `S3Settings.cs`, `FilesController.cs`*
*Next: PRD Module 03 — Account Management (Manajemen Akun)*
*Last updated: April 2026 | Version: 2.0*
