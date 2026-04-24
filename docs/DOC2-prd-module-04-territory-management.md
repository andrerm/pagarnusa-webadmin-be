# PRD Module 04 — Territory Management (Manajemen Wilayah)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All workflows related to Indonesia's administrative territory hierarchy — browsing, searching, filtering by level, parent-based navigation, lookup by exact code, and managing (add/edit) territory records. Territory data is foundational and consumed by every other module for scope filtering, member registration, and KTA generation.

---

## 1. Module Summary

The Territory Management module maintains Indonesia's four-level administrative hierarchy: Province → District/City (Kabupaten/Kota) → Sub-district (Kecamatan) → Village (Kelurahan/Desa). This data is read-only for most users — it is used as a reference throughout the system. Only Superadmins can add or edit territory records.

A critical characteristic of this module is the **split-district (IsPcKhusus) behavior**: some districts in the system have sub-districts that administratively belong to a different PagarNusa PC (district organizational unit) than their geographic code implies. The territory endpoints must handle this transparently so that callers always get the correct organizational territory rather than the raw geographic one.

All territory endpoints are **publicly accessible** — no authentication is required to read territory data. This supports the public registration form (Module 02) which needs to populate the cascading territory picker without a login.

---

## 2. Actors & Permissions

| Actor | Browse / Search | Lookup by Code | Add Territory | Edit Territory |
|---|---|---|---|---|
| Public (unauthenticated) | ✅ | ✅ | ❌ | ❌ |
| Observer | ✅ | ✅ | ❌ | ❌ |
| Verifikator PW / PC | ✅ | ✅ | ❌ | ❌ |
| Superadmin | ✅ | ✅ | ✅ | ✅ |

---

## 3. Territory Hierarchy

```
Province (Provinsi)
  └── District / City (Kabupaten / Kota)          [kodeFull: 4 digits, e.g. "3374"]
        └── Sub-district (Kecamatan)               [kodeFull: 6 digits, e.g. "337401"]
              └── Village (Kelurahan / Desa)        [kodeFull: 10 digits, e.g. "3374011001"]
```

Each level has a parent reference (`idParent`) pointing to the level above. This parent relationship is the backbone of cascading navigation and split-district resolution.

---

## 4. Data Model

All four levels map to existing tables in MySQL. No schema changes.

### 4.1 Shared Fields (all four levels)

| Field | Description |
|---|---|
| `id` | Internal auto-increment ID |
| `nama` | Territory name |
| `kodeFull` | Full standard administrative code (BPS code) |
| `kodeShort` | Short/abbreviated code |
| `kode` | Additional code variant (legacy) |
| `idParent` | FK to the parent level's `id` |

### 4.2 Province-specific Fields (`provinsi`)

| Field | Description |
|---|---|
| `oldKodeWilayahPn` | 2-character PagarNusa internal province code — used in KTA number generation |

### 4.3 District-specific Fields (`kabupaten`)

| Field | Description |
|---|---|
| `oldId` | Legacy district ID — used as prefix in MinIO file paths |
| `oldKodeWilayahPn` | 2-character PagarNusa internal district code — used in KTA number generation |
| `isPcKhusus` | Boolean flag — marks this district as a split/special PC |
| `kodefullPecahan` | If non-null, this district's sub-districts may belong to a different administrative PC. The value indicates the original geographic code before the split. |

---

## 5. Query Modes

The territory API supports three distinct query modes, each serving a different use case. The `tingkatan` (level) path parameter — `prov`, `kab`, `kecam`, `kelu` — is required on all modes to specify which level of the hierarchy to query.

### Mode 1 — Browse with Filters (`GET /api/wilayahs/{tingkatan}`)

General-purpose browsable list of any territory level. Supports search, filter, sort, and pagination. This is the primary mode for the admin management table.

**Special behavior for split districts — Sub-district (`kecam`) and Village (`kelu`) levels:**

When querying sub-districts or villages, the system checks whether the request is targeting a split-district area. A split-district query is identified when the filter contains a district code starting with `"358"` (the known prefix for split-district codes in the system).

If a split-district is detected:
- The system extracts the 4-digit district code from the filter string
- It looks up the district record by that code
- For **sub-districts**: returns all sub-districts whose `idParent` matches the looked-up district's internal ID, rather than relying on a code prefix match
- For **villages**: returns all villages that belong to any sub-district under the looked-up district, traversing one level down through the hierarchy
- After applying the parent-based lookup, the district code portion is removed from the remaining filters so that any additional filter conditions are still applied cleanly

If no split-district is detected, the query runs normally against the full table with whatever filters were provided.

**Max page size:** 50 records.

---

### Mode 2 — Lookup by Exact Code (`GET /api/wilayahs/bykfull/{tingkatan}`)

Returns records that match an exact `kodeFull` value. Used when the system needs to resolve a specific territory by its known code — for example, resolving a member's `kelurahanDomisili` code to a full territory record.

**Parameter:** `q` — the exact `kodeFull` value to look up.

Returns a paginated result (though typically a single record).

---

### Mode 3 — Children by Parent Code (`GET /api/wilayahs/prnt/{tingkatan}`)

Returns all territory records at the requested level whose parent matches the provided parent code. This is the mode used by the **cascading territory picker** in the registration form and scope assignment UI.

**Parameter:** `prnt` — the `kodeFull` of the parent territory.

Navigation logic by level:
- `prov` — returns all provinces (no parent needed; `prnt` ignored)
- `kab` — finds the province whose `kodeFull` matches `prnt`, then returns all districts with that province as parent
- `kecam` — finds the district whose `kodeFull` matches `prnt`, then returns all sub-districts with that district as parent
- `kelu` — finds the sub-district whose `kodeFull` matches `prnt`, then returns all villages with that sub-district as parent

This mode does **not** apply split-district special handling — it navigates strictly by the parent-child relationship in the database. Split-district resolution is only needed in Mode 1 when filtering by prefix.

**Max page size:** 50 records.

---

## 6. User Stories

### US-WILAYAH-01 — Browse Territory List by Level
> As an admin, I want to browse all territories at a given level so that I can verify and manage territory records.

**Acceptance Criteria:**
- Level is selected via a tab or selector (Province / District / Sub-district / Village)
- Results are paginated (max 50 per page)
- Supports search by name or code
- Supports filter by parent territory
- Split-district behavior applied transparently for sub-district and village levels (see Section 5, Mode 1)

---

### US-WILAYAH-02 — Lookup Territory by Exact Code
> As the system, I want to look up a territory by its exact administrative code so that I can resolve a member's territory code into a full record.

**Acceptance Criteria:**
- Accepts any level (`prov`, `kab`, `kecam`, `kelu`) and an exact `kodeFull` value
- Returns the matching record(s)
- Used internally by other modules — not a user-facing search

---

### US-WILAYAH-03 — Navigate Hierarchy (Children by Parent)
> As a user filling in an address, I want to select my village by cascading through province → district → sub-district → village so that I pick the correct territory code.

**Acceptance Criteria:**
- Each selection in the cascade triggers a fetch of the next level's children
- Children are fetched using the selected parent's `kodeFull`
- The final selected village's `kodeFull` is the 10-digit code stored as `kelurahanDomisili`
- The cascade is used in: public registration form, scope assignment in account management, and any admin form that requires territory selection

---

### US-WILAYAH-04 — Add Territory Record (Superadmin)
> As a Superadmin, I want to add a new territory record at any level so that the hierarchy stays current with administrative changes.

**Acceptance Criteria:**
- Superadmin only — requires authentication
- Level is specified as part of the request (`prov`, `kab`, `kecam`, `kelu`)
- All required fields must be provided (name, `kodeFull`, `idParent` for levels below province)
- For district (`kab`): `isPcKhusus` and `oldKodeWilayahPn` must also be set correctly — these affect KTA generation and split-district behavior

---

### US-WILAYAH-05 — Edit Territory Record (Superadmin)
> As a Superadmin, I want to edit an existing territory record so that names or codes can be corrected.

**Acceptance Criteria:**
- Superadmin only — requires authentication
- Level and record ID are specified in the request
- Editable fields per level:

| Level | Editable Fields |
|---|---|
| Province | `nama`, `kodeFull`, `kodeShort`, `kode` |
| District | `nama`, `kodeFull`, `kodeShort`, `kode`, `idParent`, `isPcKhusus`, `oldKodeWilayahPn` |
| Sub-district | `nama`, `kodeFull`, `kodeShort`, `kode`, `idParent` |
| Village | `nama`, `kodeFull`, `kodeShort`, `kode`, `idParent` |

> **Warning:** Changing a `kodeFull` or `idParent` on a district or sub-district record may affect scope filtering and split-district resolution for all existing member records linked to that territory. This should be done with caution.

---

## 7. Split-District (IsPcKhusus) Behavior — Detailed Rules

This is the most critical business rule in this module. It exists because Indonesia's official administrative boundaries do not always align with PagarNusa's organizational boundaries.

### 7.1 What Is a Split District?

A split district is a `kabupaten` record where `kodefullPecahan` is not null. This means some of its sub-districts and villages, while geographically coded under this district, are organizationally managed by a different PagarNusa PC.

The known indicator in the current system is that split-district codes start with `"358"`. This is used as the detection signal in filter-based queries.

### 7.2 Detection Rule

When a browse query (Mode 1) is made for sub-districts (`kecam`) or villages (`kelu`):
- If the filter contains a district code starting with `"358"` → this is a split-district query
- If it does not → treat as a normal query

### 7.3 Resolution for Sub-districts

When a split-district is detected in a sub-district query:
1. Extract the 4-digit district code from the filter
2. Find the district record with that `kodeFull`
3. Return all sub-districts where `idParent` equals the found district's internal `id`
4. Remove the extracted code from the filter string before applying any remaining filters

This ensures sub-districts are returned based on their organizational parent (the actual PC), not just their geographic code prefix.

### 7.4 Resolution for Villages

When a split-district is detected in a village query:
1. Extract the 4-digit district code from the filter
2. Find the district record with that `kodeFull`
3. Return all villages that belong to any sub-district that is a child of the found district — i.e., traverse one level: district → sub-districts → villages
4. Remove the extracted code from the filter string before applying remaining filters

> **Note:** A raw database query traversing two levels (district → sub-district → village) is used here rather than a code prefix match, because MySQL's collation handling of string prefix matching can produce incorrect results for these edge-case codes. The parent ID traversal is the reliable method.

### 7.5 Lookup by Parent (Mode 3) — No Split Handling

The children-by-parent mode (Mode 3) does not apply split-district logic. It navigates purely by the `idParent` relationship, which is always correct regardless of split status. Split handling is only needed in Mode 1 (filter-based browse) because prefix-based code matching breaks down for split areas.

---

## 8. API Endpoints

All endpoints are publicly accessible (no JWT required) unless the request is a write operation (POST or PUT), which requires Superadmin authentication.

**Base URL:** `/api/wilayahs`

---

### GET `/api/wilayahs/{tingkatan}`

Browse territory records at the specified level with filtering, search, sort, and pagination.

**Path parameter — `tingkatan`:**

| Value | Level |
|---|---|
| `prov` | Province |
| `kab` | District / City |
| `kecam` | Sub-district |
| `kelu` | Village |

**Query parameters:** standard pagination (`page`, `pageSize` max 50), filter, search, sort.

Split-district logic is applied transparently for `kecam` and `kelu` levels.

**Response 200:**
```json
{
  "data": [
    {
      "id": 1,
      "nama": "Jawa Tengah",
      "kodeFull": "33",
      "kodeShort": "JT",
      "kode": "33",
      "idParent": null,
      "oldKodeWilayahPn": "33",
      "isPcKhusus": false
    }
  ],
  "meta": {
    "page": 1,
    "pageSize": 10,
    "total": 38,
    "totalPages": 4
  }
}
```

---

### GET `/api/wilayahs/bykfull/{tingkatan}?q={kodeFull}`

Look up territory records by exact `kodeFull` value.

**Query parameter:** `q` — the exact code to match.

Returns a paginated result set (typically one record).

---

### GET `/api/wilayahs/prnt/{tingkatan}?prnt={parentKodeFull}`

Return all child territory records at the specified level whose parent matches the given `kodeFull`.

**Query parameter:** `prnt` — the `kodeFull` of the parent territory.

Used by the cascading territory picker.

---

### POST `/api/wilayahs`

Add a new territory record. Superadmin only.

**Request:**
```json
{
  "tingkatan": "kab",
  "data": {
    "nama": "Kota Baru",
    "kodeFull": "3399",
    "kodeShort": "KB",
    "kode": "3399",
    "idParent": 5,
    "isPcKhusus": false,
    "oldKodeWilayahPn": "99"
  }
}
```

**Response 200:**
```json
{ "message": "Territory record added successfully." }
```

**Response 400 — Invalid or missing `tingkatan`:**
```json
{ "statusCode": 400, "message": "Bad request. Valid levels are: prov, kab, kecam, kelu." }
```

---

### PUT `/api/wilayahs/{id}`

Update an existing territory record. Superadmin only.

**Request:**
```json
{
  "tingkatan": "kab",
  "data": {
    "nama": "Kota Semarang (Updated)",
    "kodeFull": "3374",
    "kodeShort": "SMG",
    "kode": "3374",
    "idParent": 5,
    "isPcKhusus": false,
    "oldKodeWilayahPn": "74"
  }
}
```

**Response 200:**
```json
{ "message": "Territory record updated successfully." }
```

---

## 9. UI Flow

### 9.1 Territory Management Page — `/admin/manajemen-wilayah`

```
┌──────────────────────────────────────────────────────────────┐
│  Territory Management                   [ + Add Territory ]  │
│                                                              │
│  [ Province ] [ District ] [ Sub-district ] [ Village ]      │
│                                                              │
│  ┌──────────────────────────┐  ┌───────────────────────┐    │
│  │ 🔍 Search by name/code   │  │  Filter by parent   ▾ │    │
│  └──────────────────────────┘  └───────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Name              │ Code   │ PN Code │ Special │  ⋮   │  │
│  ├───────────────────┼────────┼─────────┼─────────┼──────┤  │
│  │ Jawa Tengah       │ 33     │ 33      │ —       │  ⋮   │  │
│  │ Jawa Barat        │ 32     │ 32      │ —       │  ⋮   │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Showing 1–10 of 38    [< 1 2 3 4 >]    [10 ▾]             │
└──────────────────────────────────────────────────────────────┘
```

**Column visibility per level:**

| Column | Province | District | Sub-district | Village |
|---|---|---|---|---|
| Name | ✅ | ✅ | ✅ | ✅ |
| kodeFull | ✅ | ✅ | ✅ | ✅ |
| PN Code (`oldKodeWilayahPn`) | ✅ | ✅ | — | — |
| Special (`isPcKhusus`) | — | ✅ | — | — |
| Parent | — | Province name | District name | Sub-district name |

**Row action menu (⋮) — Superadmin only:**
- Edit

---

### 9.2 Add / Edit Territory Form

Presented as a modal or side drawer. Fields shown depend on the selected level.

```
┌──────────────────────────────────────┐
│  Add District                        │
│                                      │
│  Name *              [             ] │
│  kodeFull *          [             ] │
│  kodeShort           [             ] │
│  kode                [             ] │
│  Parent Province *   [   ▾         ] │
│  PN Code *           [             ] │
│  Special PC          [ ] Yes         │
│                                      │
│  [ Cancel ]          [ Save ]        │
└──────────────────────────────────────┘
```

The "Special PC" (`isPcKhusus`) checkbox is only shown for the District level. The "PN Code" field is shown for Province and District levels only (used in KTA number generation).

---

### 9.3 Cascading Territory Picker (Component — used across modules)

This is a reusable component used in the public registration form (Module 02) and the scope assignment drawer (Module 03).

```
┌──────────────────────────────────────────────────────────┐
│  Territory Selection                                     │
│                                                          │
│  Province *    [ Jawa Tengah               ▾ ]          │
│  District *    [ Kota Semarang             ▾ ]          │
│  Sub-district *[ Semarang Selatan          ▾ ]          │
│  Village *     [ Pleburan                  ▾ ]          │
│                                                          │
│  Selected code: 3374031001                               │
└──────────────────────────────────────────────────────────┘
```

**Behavior rules:**
- Each dropdown is disabled until the level above it is selected
- When a selection changes at any level, all levels below it are cleared and their options reloaded
- The final output is the 10-digit village `kodeFull` — this is the value stored as `kelurahanDomisili`
- For the scope picker (Module 03): stops at Province level for Verifikator PW, stops at District level for Verifikator PC — the village level is not needed for scope assignment

---

## 10. Business Rules Summary

| Rule | Detail |
|---|---|
| All read endpoints are public | No authentication required to browse or search territory data |
| Write operations are Superadmin only | Add and Edit require a valid JWT with Superadmin scope |
| Hierarchy is parent-based | Each record has an `idParent` FK; navigation always uses this, not code prefix matching |
| Split-district detection | Filter-based queries for `kecam` and `kelu` that include a code starting with `"358"` are treated as split-district queries |
| Split-district resolution | Returns records by parent ID traversal, not code prefix — ensures correct organizational grouping |
| Mode 3 (parent-based) skips split logic | Children-by-parent queries use the `idParent` directly and never need split handling |
| Max page size | 50 records per page across all modes |
| Province and district PN codes are critical | `oldKodeWilayahPn` on `provinsi` and `kabupaten` is used in KTA number generation — must be set correctly |
| District `oldId` is critical for file storage | `kabupaten.oldId` is used in MinIO file path naming — must be set correctly for any new district |

---

## 11. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/wilayahs/{tingkatan}` — browse by level, pagination max 50, search, filter, sort
- [ ] Split-district detection for `kecam` and `kelu` levels — detect `"358"` prefix in filter
- [ ] Split-district resolution for `kecam` — parent ID lookup instead of code prefix match
- [ ] Split-district resolution for `kelu` — two-level traversal (district → sub-districts → villages)
- [ ] Filter string cleanup after split-district code extraction — prevent double-filtering
- [ ] `GET /api/wilayahs/bykfull/{tingkatan}` — exact `kodeFull` match lookup, all four levels
- [ ] `GET /api/wilayahs/prnt/{tingkatan}` — children by parent `kodeFull`, all four levels, no split handling
- [ ] `POST /api/wilayahs` — add territory record by level, Superadmin only
- [ ] `PUT /api/wilayahs/{id}` — update territory record by level and ID, Superadmin only
- [ ] All read endpoints marked as public (no JWT required)
- [ ] All write endpoints guarded by Superadmin authentication

### Frontend (Next.js)
- [ ] `/admin/manajemen-wilayah` — tabbed territory list with level selector, search, filter, pagination
- [ ] Level-aware column display — show/hide columns based on active level tab
- [ ] Add/Edit territory modal — level-aware field visibility (PN code, Special PC flag)
- [ ] Cascading territory picker component — reusable, used in registration form and scope assignment
- [ ] Cascading picker: disable lower levels until parent is selected; clear on parent change
- [ ] Cascading picker: configurable stop level (province-only mode for PW scope, district-only for PC scope)
- [ ] Cascading picker: output the final 10-digit village `kodeFull`

---

*This document is the PRD for Module 04 — Territory Management (Manajemen Wilayah).*
*Business logic source: legacy `WilayahsController.cs`, `WilayahService.cs`*
*Next: PRD Module 05 — Organizational Structure (Manajemen Kepengurusan)*
*Last updated: April 2026 | Version: 2.0*
