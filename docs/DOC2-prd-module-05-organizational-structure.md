# PRD Module 05 — Organizational Structure & Position Management
## (Manajemen Kepengurusan & Jabatan)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All workflows related to organizational units (Kepengurusan) and their associated positions/titles (Jabatan) — browsing, creating, editing, and understanding how these records connect to member verification and position label generation. Does not cover member assignment to these units (handled in Module 02) or territory management (Module 04).

---

## 1. Module Summary

PagarNusa is a hierarchical organization with formal units at multiple levels — national (PP), provincial (PW), and district (PC). Each unit is called a **Kepengurusan** (organizational body) and operates within a defined territory and time period. Within each unit, members hold specific **Jabatan** (positions or titles) such as Ketua (chairperson), Sekretaris (secretary), and so on.

These two entities — Kepengurusan and Jabatan — are reference/master data that other modules depend on:
- **Module 02 (Member List):** Uses Kepengurusan and Jabatan to compose the `jabatanPn` label and create `DetilKepengurusan` records during verification
- **Module 03 (Account Management):** Displays `jabatanPn` in the admin user list
- **Module 07 (Profile):** Displays a member's organizational affiliation

Both the Kepengurusan and Jabatan list endpoints are **publicly accessible** — no authentication is required to read them. This allows the registration and verification forms to populate dropdowns without requiring login.

This PRD covers both Kepengurusan (Module 05a) and Jabatan (Module 05b) in a single document because they are tightly related and both follow a simple CRUD pattern.

---

## 2. Actors & Permissions

| Actor | Browse Kepengurusan | Browse Jabatan | Add Kepengurusan | Edit Kepengurusan | Add/Edit Jabatan |
|---|---|---|---|---|---|
| Public (unauthenticated) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Observer | ✅ | ✅ | ❌ | ❌ | ❌ |
| Verifikator PW / PC | ✅ | ✅ | ❌ | ❌ | ❌ |
| Superadmin | ✅ | ✅ | ✅ | ✅ | ✅ |

> **Note:** Delete operations for both Kepengurusan and Jabatan are not implemented in this version. Inactive units are managed via the `isActive` flag, not deletion.

---

## 3. Kepengurusan (Organizational Unit)

### 3.1 What Is a Kepengurusan?

A Kepengurusan is a formal organizational body at a specific territorial and hierarchical level. Examples:
- **PP** (Pengurus Pusat) — National board
- **PW** (Pengurus Wilayah) — Provincial board, e.g. "PW Jawa Tengah"
- **PC** (Pengurus Cabang) — District board, e.g. "PC Kota Semarang"

Each Kepengurusan operates for a defined period (start and end date) and is linked to a specific territory.

### 3.2 Data Model

Maps to the existing `kepengurusans` table. No schema changes.

| Field | Description |
|---|---|
| `idKepengurusan` | Internal auto-increment ID |
| `namaKepengurusan` | Full name of the organizational unit, e.g. "PC Kota Semarang" |
| `levelId` | Numeric level indicator — determines the organizational tier (PP, PW, PC, etc.) |
| `kodeWilayah` | Territory code associated with this unit |
| `idWilayah` | Internal ID of the linked territory (`kabupaten.id` for PC-level, `provinsi.id` for PW-level) |
| `periodeMulai` | Start date of this unit's active period |
| `periodeSelesai` | End date of this unit's active period |
| `isActive` | Active status flag — used to mark units as current or historical |
| `isPengurus` | Flag indicating whether this unit has organizational members assigned |

### 3.3 Level IDs

The `levelId` field determines the hierarchical tier of the Kepengurusan. The system currently uses at least 3 tiers. Default filtering in related modules uses `levelId == 3` (PC level) as the most commonly accessed tier. The full mapping is:

| levelId | Tier | Description |
|---|---|---|
| 1 | PP | National board (Pengurus Pusat) |
| 2 | PW | Provincial board (Pengurus Wilayah) |
| 3 | PC | District board (Pengurus Cabang) |

> Additional levels may exist in the data. The coding agent should confirm with the database before assuming this is exhaustive.

### 3.4 Relationship to Other Modules

- **`idWilayah`** is the key field that links a Kepengurusan to a territory. When composing `jabatanPn` for a member, the system finds the Kepengurusan whose `idWilayah` matches the member's resolved district ID (`idKabupatenDomisili`).
- **`namaKepengurusan`** is used directly in the `jabatanPn` label — it appears as part of strings like `"Anggota - PC Kota Semarang"` or `"Ketua PC Kota Semarang"`.
- **`kodeWilayah`** is stored on `DetilKepengurusan` when a member is assigned to this unit.

---

## 4. Jabatan (Position / Title)

### 4.1 What Is a Jabatan?

A Jabatan is a named position or title within an organizational unit. Examples: Ketua (Chair), Wakil Ketua (Vice Chair), Sekretaris (Secretary), Bendahara (Treasurer), Anggota (Member).

Jabatan records are master data — they define the catalog of available positions that can be assigned to members within a Kepengurusan.

### 4.2 Data Model

Maps to the existing `jabatans` table. No schema changes.

| Field | Description |
|---|---|
| `id` | Internal auto-increment ID |
| `nama` | Position name, e.g. "Ketua", "Sekretaris" |
| `levelId` | Links the position to an organizational level — same level system as Kepengurusan |

### 4.3 Relationship to Other Modules

- When a member with `isPengurus: true` is verified, a Jabatan is selected from this catalog and stored as `jabatanId` and `jabatanPn` on the `DetilKepengurusan` record.
- The `jabatanPn` value (position name string) from the selected Jabatan is used directly in the member's position label: `"{jabatan.nama} {kepengurusan.namaKepengurusan}"`.
- Jabatan is filtered by `levelId` to show only positions relevant to the Kepengurusan level being assigned.

---

## 5. User Stories

### US-KEPENG-01 — Browse Organizational Units
> As an admin, I want to browse all organizational units so that I can verify the organizational structure is correctly set up.

**Acceptance Criteria:**
- List is publicly accessible — no login required
- Supports pagination, keyword search (by name or territory code), filter by `levelId`, filter by `isActive`, and sort
- Each row shows: unit name, level, territory code, period (start–end), active status
- Default view shows all units; filtering by level or territory is optional

---

### US-KEPENG-02 — Add an Organizational Unit
> As a Superadmin, I want to create a new organizational unit so that a newly formed board is represented in the system.

**Acceptance Criteria:**
- Requires Superadmin authentication
- All required fields must be provided: `namaKepengurusan`, `levelId`, `kodeWilayah`, `idWilayah`, `periodeMulai`
- `isActive` defaults to active (`1`) on creation
- `periodeSelesai` is optional at creation — can be set when the period ends

---

### US-KEPENG-03 — Edit an Organizational Unit
> As a Superadmin, I want to edit an organizational unit so that I can update its period, status, or linked territory.

**Acceptance Criteria:**
- Requires Superadmin authentication
- All fields are editable: `namaKepengurusan`, `levelId`, `kodeWilayah`, `idWilayah`, `periodeMulai`, `periodeSelesai`, `isActive`, `isPengurus`
- Editing `namaKepengurusan` or `idWilayah` may affect the `jabatanPn` label of all members linked to this unit — this is not automatically recomputed; it is the responsibility of the admin to ensure consistency

---

### US-KEPENG-04 — Browse Positions (Jabatan)
> As an admin, I want to browse all available positions so that I can select the correct one when assigning a role to a member.

**Acceptance Criteria:**
- List is publicly accessible — no login required
- Supports pagination, keyword search by name, filter by `levelId`, and sort
- Used as the source for position dropdowns in the member verification and edit forms

---

## 6. Business Rules

### 6.1 Public Read Access

Both `GET /api/kepengurusans` and `GET /api/jabatans` are publicly accessible without a JWT token. This is required because the member verification form and public registration form must be able to populate Kepengurusan and Jabatan dropdowns without the user being logged in.

### 6.2 No Delete in This Version

Neither Kepengurusan nor Jabatan records are deleted through the UI. Organizational units that are no longer active are marked with `isActive: 0`. This preserves historical data integrity — existing `DetilKepengurusan` records that reference past units remain valid.

### 6.3 idWilayah Is the Linking Key

The `idWilayah` field on a Kepengurusan is the most important field for system behavior. It is the internal territory ID (either `kabupaten.id` for PC-level or `provinsi.id` for PW-level) that links an organizational unit to a geographic area. When composing a member's `jabatanPn`, the system looks up the Kepengurusan by matching `idWilayah` to the member's resolved territory ID — not by matching `kodeWilayah` string. This must be set correctly when creating or editing a unit.

### 6.4 levelId Filtering Convention

When fetching Kepengurusan records in the context of member verification (Module 02), the default filter is `levelId == 3` (PC level). Other modules or UI flows may use different level filters. The API does not hardcode this filter — it is applied by the caller via query parameters.

### 6.5 Jabatan Is Filtered by levelId

When displaying the position dropdown for a member being assigned to a Kepengurusan, the Jabatan list should be filtered to show only positions with the same `levelId` as the selected Kepengurusan. This ensures a PC-level member is not accidentally assigned a national-tier position title.

### 6.6 namaKepengurusan Appears in jabatanPn

Because `namaKepengurusan` is embedded directly into the `jabatanPn` string on member records, changing the name of a Kepengurusan in this module will create a discrepancy with existing member records. The system does not auto-propagate the change. Admins should be warned of this when editing the name.

---

## 7. API Endpoints

### 7.1 Kepengurusan Endpoints

**Base URL:** `/api/kepengurusans`

---

#### GET `/api/kepengurusans`

Returns a paginated, filterable list of organizational units. Publicly accessible.

**Query parameters:** standard pagination (`page`, `pageSize`), search by name or `kodeWilayah`, filter by `levelId`, filter by `isActive`, sort.

**Response 200:**
```json
{
  "data": [
    {
      "idKepengurusan": 1,
      "namaKepengurusan": "PC Kota Semarang",
      "levelId": 3,
      "kodeWilayah": "3374",
      "idWilayah": 45,
      "periodeMulai": "2022-01-01",
      "periodeSelesai": "2025-12-31",
      "isActive": 1,
      "isPengurus": 1
    }
  ],
  "meta": {
    "page": 1,
    "pageSize": 10,
    "total": 34,
    "totalPages": 4
  }
}
```

---

#### POST `/api/kepengurusans`

Create a new organizational unit. Requires authentication (Superadmin).

**Request:**
```json
{
  "namaKepengurusan": "PC Kota Baru",
  "levelId": 3,
  "kodeWilayah": "3399",
  "idWilayah": 99,
  "periodeMulai": "2024-01-01",
  "periodeSelesai": null,
  "isActive": 1,
  "isPengurus": 0
}
```

**Response 200:**
```json
{ "message": "Organizational unit added successfully." }
```

---

#### PUT `/api/kepengurusans/{id}`

Update an existing organizational unit. Requires authentication (Superadmin).

Editable fields: `namaKepengurusan`, `levelId`, `kodeWilayah`, `idWilayah`, `periodeMulai`, `periodeSelesai`, `isActive`, `isPengurus`.

**Request:** same shape as POST, all fields optional.

**Response 200:**
```json
{ "message": "Organizational unit updated successfully." }
```

---

### 7.2 Jabatan Endpoints

**Base URL:** `/api/jabatans`

---

#### GET `/api/jabatans`

Returns a paginated, filterable list of positions. Publicly accessible.

**Query parameters:** standard pagination, search by `nama`, filter by `levelId`, sort.

**Response 200:**
```json
{
  "data": [
    {
      "id": 1,
      "nama": "Ketua",
      "levelId": 3
    },
    {
      "id": 2,
      "nama": "Sekretaris",
      "levelId": 3
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

## 8. UI Flow

### 8.1 Organizational Units Page — `/admin/manajemen-kepengurusan`

```
┌──────────────────────────────────────────────────────────────┐
│  Organizational Structure              [ + Add Unit ]        │
│                                                              │
│  ┌──────────────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ 🔍 Search...     │  │ Level  ▾ │  │    Status      ▾ │  │
│  └──────────────────┘  └──────────┘  └──────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Unit Name        │ Level │ Territory │ Period   │  ⋮  │  │
│  ├──────────────────┼───────┼───────────┼──────────┼─────┤  │
│  │ PC Kota Semarang │ PC    │ 3374      │ 2022–2025│  ⋮  │  │
│  │ PW Jawa Tengah   │ PW    │ 33        │ 2022–2025│  ⋮  │  │
│  │ PP               │ PP    │ —         │ 2022–2025│  ⋮  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Showing 1–10 of 34    [< 1 2 3 4 >]    [10 ▾]             │
└──────────────────────────────────────────────────────────────┘
```

**Status indicator:** Active / Inactive based on `isActive` flag.

**Row action menu (⋮) — Superadmin only:**
- Edit

---

### 8.2 Add / Edit Organizational Unit Form

Presented as a modal or side drawer:

```
┌──────────────────────────────────────────────────┐
│  Add Organizational Unit                         │
│                                                  │
│  Unit Name *         [                         ] │
│  Level *             [ PC (3)                ▾ ] │
│  Territory Code *    [                         ] │
│  Linked Territory *  [ Kota Semarang          ▾ ] │
│  Period Start *      [ 2024-01-01               ] │
│  Period End          [ 2025-12-31               ] │
│  Status              [●] Active  [ ] Inactive    │
│  Has Members         [ ] Yes                     │
│                                                  │
│  ⚠ Changing the unit name will not automatically │
│    update member jabatanPn labels.               │
│                                                  │
│  [ Cancel ]                   [ Save ]           │
└──────────────────────────────────────────────────┘
```

The "Linked Territory" field (`idWilayah`) is a searchable picker that resolves to the internal territory ID. It uses the territory API (Module 04) to look up districts (for PC level) or provinces (for PW level).

---

### 8.3 Position (Jabatan) Reference — `/admin/jabatan`

Jabatan is a read-only reference table for most users. A simple list view:

```
┌──────────────────────────────────────────────────┐
│  Positions (Jabatan)                             │
│                                                  │
│  ┌────────────────────────┐  ┌─────────────────┐ │
│  │ 🔍 Search by name...   │  │    Level      ▾ │ │
│  └────────────────────────┘  └─────────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────────┐ │
│  │ Position Name    │ Level                     │ │
│  ├──────────────────┼───────────────────────────┤ │
│  │ Ketua            │ PC                        │ │
│  │ Sekretaris       │ PC                        │ │
│  │ Bendahara        │ PC                        │ │
│  └──────────────────────────────────────────────┘ │
│                                                  │
│  Showing 1–10 of 12    [< 1 2 >]    [10 ▾]      │
└──────────────────────────────────────────────────┘
```

---

### 8.4 Kepengurusan & Jabatan Dropdowns (Used in Module 02)

When a Verifikator verifies a member with `isPengurus: true`, two dropdowns are shown in the verification form:

```
Organizational Assignment
─────────────────────────────────────────
Organizational Unit *
[ PC Kota Semarang (2022–2025)         ▾ ]

Position *
[ Ketua                                ▾ ]
  (filtered to levelId matching selected unit)
```

- The Kepengurusan dropdown shows only active units (`isActive: 1`) filtered by the verifier's scope
- The Jabatan dropdown is filtered by the `levelId` of the selected Kepengurusan
- These selections feed directly into `prepareDetilKepengurusanToSave()` and the `jabatanPn` composition (documented in Module 02)

---

## 9. Business Rules Summary

| Rule | Detail |
|---|---|
| Both list endpoints are public | No authentication needed to read Kepengurusan or Jabatan lists |
| No deletion supported | Units are deactivated via `isActive: 0`, never deleted |
| `idWilayah` is the linking key | Used to match Kepengurusan to a member's territory — must be set correctly |
| `levelId` default for member context | Module 02 filters Kepengurusan by `levelId == 3` (PC level) by default |
| Jabatan is filtered by level | Position dropdown should match the `levelId` of the selected Kepengurusan |
| Name change does not propagate | Changing `namaKepengurusan` does not auto-update existing member `jabatanPn` labels |
| Period end is optional | `periodeSelesai` can be null for ongoing units |

---

## 10. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/kepengurusans` — public, paginated list with search, filter by `levelId` and `isActive`, sort
- [ ] `POST /api/kepengurusans` — create new unit, Superadmin only
- [ ] `PUT /api/kepengurusans/:id` — update all editable fields, Superadmin only
- [ ] `GET /api/jabatans` — public, paginated list with search, filter by `levelId`, sort
- [ ] Both GET endpoints marked public (no JWT required)
- [ ] Both write endpoints (POST, PUT) guarded by Superadmin authentication

### Frontend (Next.js)
- [ ] `/admin/manajemen-kepengurusan` — unit list with search, level filter, status filter, pagination
- [ ] Add/Edit Kepengurusan modal — all fields, territory picker for `idWilayah`, warning message about name change impact on `jabatanPn`
- [ ] `/admin/jabatan` — read-only position list with search and level filter
- [ ] Kepengurusan dropdown component (reused in Module 02) — shows active units, filtered by verifier's scope
- [ ] Jabatan dropdown component (reused in Module 02) — filtered by `levelId` of selected Kepengurusan

---

*This document is the PRD for Module 05 — Organizational Structure & Position Management (Manajemen Kepengurusan & Jabatan).*
*Business logic source: legacy `KepengurusansController.cs`, `JabatansController.cs`*
*Next: PRD Module 06 — Profile (Profil)*
*Last updated: April 2026 | Version: 2.0*
