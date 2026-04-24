# PRD Module 07 — KTA Card Generation & Batch Export
## (Generate Kartu Tanda Anggota)
## PagarNusa WebAdmin v2.0

> **Prerequisite:** Read `DOC1-overview-architecture.md` first to understand the overall system context.
>
> **Scope of this document:** All workflows related to generating the digital member ID card (e-KTA) — single card generation per member, the full card composition specification, QR code embedding, batch generation for multiple members, and ZIP download. This module depends on verified member data (Module 02) and MinIO file access (IS3Client).

---

## 1. Module Summary

The KTA (Kartu Tanda Anggota) card is the official PagarNusa digital member ID. It is a generated image produced by compositing multiple layers: a fixed template image as the background, the member's profile photo from MinIO, dynamic text fields from the database, and an embedded QR code pointing to the member's public verification URL.

Cards can be generated one at a time for individual members, or in batch for a group of members, with the batch output compressed into a ZIP file for download.

This module is new functionality — it was present in the legacy system as a single-card endpoint (`GET /api/files/ekta/{publicid}`) but batch generation and ZIP export are being added in this version.

---

## 2. Actors & Permissions

| Actor | Generate Single Card | Batch Generate | Download ZIP |
|---|---|---|---|
| Superadmin | ✅ Any member | ✅ | ✅ |
| Verifikator PW | ✅ Within province scope | ✅ Within scope | ✅ |
| Verifikator PC | ✅ Within district scope | ✅ Within scope | ✅ |
| Observer | ❌ | ❌ | ❌ |

Only **verified members** (`isVerified: true`) can have a KTA card generated. Attempting to generate a card for an unverified member must return a clear error.

---

## 3. User Stories

### US-KTA-01 — Generate a Single KTA Card
> As an admin, I want to generate a KTA card for a single verified member so that they can receive their digital member ID.

**Acceptance Criteria:**
- Member must be verified (`isVerified: true`) — unverified members are rejected
- The card is generated on-demand and returned as a downloadable PNG file
- The generated file is named `ekta_{noKta}.png`
- The card composition follows the full specification in Section 5
- The member must be within the caller's territorial scope

---

### US-KTA-02 — Batch Generate KTA Cards
> As an admin, I want to generate KTA cards for multiple verified members at once so that I can efficiently produce cards for a group.

**Acceptance Criteria:**
- Accepts a list of member `publicId` values
- Only verified members in the list are processed; unverified entries are skipped with a note in the response
- All members in the list must be within the caller's territorial scope; out-of-scope entries are skipped
- Generation is processed asynchronously — the caller does not wait for all cards to finish before receiving a response
- Progress can be tracked via a job status endpoint
- When all cards are complete, they are compressed into a single ZIP file

---

### US-KTA-03 — Download Batch ZIP
> As an admin, I want to download the ZIP file containing all generated KTA cards so that I can distribute them.

**Acceptance Criteria:**
- The ZIP file is available for download after the batch job completes
- ZIP filename format: `ekta_batch_{timestamp}.zip`
- Each card inside the ZIP is named `ekta_{noKta}.png`
- The download link expires after a defined period (implementation detail for the coding agent to determine)
- The ZIP is stored temporarily in MinIO and cleaned up after download or expiry

---

### US-KTA-04 — Check Batch Job Status
> As an admin, I want to check the progress of a batch generation job so that I know when the ZIP is ready.

**Acceptance Criteria:**
- Returns the current status of the job: pending, processing, completed, or failed
- Returns progress count: how many cards have been generated vs total requested
- When status is completed, returns the download URL for the ZIP
- When status is failed, returns a description of what went wrong

---

## 4. Prerequisites for Card Generation

Before a card can be generated for a member, the following must be true:

| Prerequisite | Source | Notes |
|---|---|---|
| `isVerified: true` | `Pribadi.isVerified` | Card cannot be generated for unverified members |
| `noKta` is set | `Pribadi.noKta` | KTA number must exist — assigned during verification |
| `urlFoto` is set | `Pribadi.urlFoto` | Profile photo must exist in MinIO |
| `idKabupatenDomisili` is set | `Pribadi.idKabupatenDomisili` | Needed to resolve district name for card text |
| KTA template asset exists | Server asset | `depan-masterv2.jpg` must be present on the backend server |
| Font assets exist | Server assets | `GothamRegular.otf`, `GothamBold.otf` must be present |

If `urlFoto` is missing, the system should use the default placeholder photo rather than failing the generation. All other prerequisites are hard requirements.

---

## 5. Card Composition Specification

The KTA card is produced by compositing four layers onto a base template image in a defined order. The composition must produce a consistent, pixel-accurate result regardless of the underlying image library used.

### 5.1 Layer Order (bottom to top)

```
Layer 1 (bottom) : KTA template image        — the background card design
Layer 2          : Member profile photo       — placed in the photo area
Layer 3          : Text fields                — name, KTA number, district
Layer 4 (top)    : QR code                   — placed in the QR area
```

### 5.2 Layer 1 — Base Template

- Source: server-side asset file `depan-masterv2.jpg`
- This is the fixed card design — borders, logo, color blocks, layout guides
- All other layers are composited on top of this at absolute pixel positions
- The card dimensions are defined by this template

### 5.3 Layer 2 — Member Profile Photo

- Source: fetched from MinIO using the member's `urlFoto` relative path
- Placed at position: **x = 650, y = 125** (from top-left of the base image)
- Resized to exactly **285 × 380 pixels** before compositing
- Resize must maintain the fill — the photo is scaled to fit the target dimensions regardless of original aspect ratio

### 5.4 Layer 3 — Text Fields

Three text fields are rendered as separate text layers and composited individually:

**Field 1 — Member Name**

| Property | Value |
|---|---|
| Content | Member's full name, truncated to 45 characters maximum |
| Position | x: 290, y: 300 |
| Text box size | Width: 280px, Height: 70px |
| Font | GothamRegular (server asset: `GothamRegular.otf`) |
| Font size | 21pt |
| Color | White |
| Alignment | Left (West gravity) |
| Background | Transparent |

**Field 2 — KTA Number**

| Property | Value |
|---|---|
| Content | `Pribadi.noKta` (e.g. `86337408000001`) |
| Position | x: 290, y: **330** (if name ≤ 17 chars) or **340** (if name > 17 chars) |
| Text box size | Width: 280px, Height: 70px |
| Font | GothamBold (server asset: `GothamBold.otf`) |
| Font size | 20pt |
| Color | White |
| Alignment | Left (West gravity) |
| Background | Transparent |

**Field 3 — District Name**

| Property | Value |
|---|---|
| Content | `Kabupaten.nama` of the member's `idKabupatenDomisili` |
| Position | x: 290, y: **360** (if name ≤ 17 chars) or **370** (if name > 17 chars) |
| Text box size | Width: 280px, Height: 70px |
| Font | GothamBold (server asset: `GothamBold.otf`) |
| Font size | 20pt |
| Color | White |
| Alignment | Left (West gravity) |
| Background | Transparent |

**Name length vertical shift rule:**
When the member's full name (before truncation) is longer than 17 characters, the KTA number and district name fields each shift **10 pixels downward** to accommodate the name potentially wrapping onto a second line within its text box. The name field position (y: 300) never shifts.

**Name truncation rule:**
The name rendered on the card is truncated to a maximum of 45 characters. If the name is longer than 45 characters, it is cut at 45 characters before rendering. The full name remains unchanged in the database.

### 5.5 Layer 4 — QR Code

| Property | Value |
|---|---|
| Content | `https://salam.pagarnusa.or.id/cqr/{Pribadi.publicId}` |
| Error correction | Medium |
| Module size | 5 pixels per QR module |
| Border/quiet zone | 1 module |
| Colors | Black modules on white background |
| Position | x: 80, y: 315 (composited onto base image) |

The QR code is generated from the member's public verification URL. Scanning the QR code on the card takes the viewer to a public page that confirms the member's validity and displays their name and KTA number. The QR content must always use `publicId` — not the KTA number or any internal ID.

### 5.6 Output Specification

| Property | Value |
|---|---|
| Format | PNG |
| Filename | `ekta_{noKta}.png` |
| Delivery | Direct file download (Content-Disposition: attachment) |
| Color space | As-is from the template (no conversion required) |

---

## 6. Batch Generation Architecture

Batch generation must be non-blocking — the server cannot hold an HTTP connection open while generating potentially dozens of images. The architecture uses a job queue to handle this asynchronously.

### 6.1 Flow

```
Admin selects members → POST /api/kta/batch
          ↓
System creates a batch job record → returns jobId immediately
          ↓
Queue worker picks up job
          ↓
For each member: generate card (Section 5) → add to ZIP in-memory
          ↓
Upload completed ZIP to MinIO under a temp path
          ↓
Update job record: status = completed, zipUrl = MinIO path
          ↓
Admin polls GET /api/kta/batch/:jobId/status
          ↓
Status = completed → admin calls GET /api/kta/batch/:jobId/download
          ↓
Backend fetches ZIP from MinIO → streams to browser as download
```

### 6.2 Batch Job Record

Stored in the database (or Redis for short-lived jobs) to track progress:

| Field | Description |
|---|---|
| `jobId` | Unique identifier for the batch job |
| `requestedBy` | `publicId` of the admin who initiated the job |
| `totalRequested` | Total number of members requested |
| `totalProcessed` | Number of cards successfully generated so far |
| `totalSkipped` | Number of members skipped (unverified or out of scope) |
| `status` | `pending` → `processing` → `completed` / `failed` |
| `zipPath` | MinIO relative path of the ZIP file (set when completed) |
| `createdAt` | Job creation timestamp |
| `completedAt` | Completion timestamp |
| `expiresAt` | When the ZIP and job record will be cleaned up |

### 6.3 Skipping Rules During Batch

A member entry in the batch request is silently skipped (counted in `totalSkipped`) if:
- The member is not verified (`isVerified: false`)
- The member is outside the caller's territorial scope
- The member has no profile photo and no default photo is available
- The member's `noKta` is null

The batch job does not fail because of skipped members — it completes with whatever cards were successfully generated.

### 6.4 ZIP Structure

```
ekta_batch_{timestamp}.zip
├── ekta_86337408000001.png
├── ekta_86337408000002.png
├── ekta_86337408000042.png
└── ...
```

Each file inside the ZIP is an individual KTA card PNG, named by the member's KTA number.

---

## 7. API Endpoints

**Base URL:** `/api/kta`

All endpoints require a valid JWT. Territorial scope is applied automatically.

---

### GET `/api/files/ekta/{publicid}`

Generate a single KTA card and return it as a downloadable PNG.

> **Note:** This endpoint path matches the legacy system (`/api/files/ekta/{publicid}`) and is preserved for URL compatibility. It lives under `/api/files/` not `/api/kta/`.

**Path parameter:** `publicid` — the member's public ID.

**Behavior:**
1. Look up member by `publicId`
2. Verify member is within caller's scope
3. Check `isVerified: true` — reject if not
4. Fetch profile photo from MinIO using `urlFoto`
5. Compose card per Section 5 specification
6. Return as PNG file download

**Response:** Raw PNG file stream
- Content-Type: `image/png`
- Content-Disposition: `attachment; filename=ekta_{noKta}.png`

**Response 400 — Member not verified:**
```json
{ "statusCode": 400, "message": "Member is not yet verified. KTA card cannot be generated." }
```

**Response 403 — Out of scope:**
```json
{ "statusCode": 403, "message": "This member is outside your territorial scope." }
```

---

### POST `/api/kta/batch`

Initiate a batch KTA generation job. Returns a job ID immediately — generation runs asynchronously.

**Request:**
```json
{
  "publicIds": [
    "pub-uuid-1",
    "pub-uuid-2",
    "pub-uuid-3"
  ]
}
```

**Behavior:**
1. Validate all `publicIds` are within caller's scope (out-of-scope entries are noted, not rejected)
2. Create a batch job record with status `pending`
3. Enqueue the job for background processing
4. Return the `jobId` immediately

**Response 202 — Job accepted:**
```json
{
  "jobId": "batch-job-uuid",
  "totalRequested": 3,
  "message": "Batch generation started. Use the jobId to check progress."
}
```

---

### GET `/api/kta/batch/:jobId/status`

Check the status and progress of a batch job.

**Response 200:**
```json
{
  "jobId": "batch-job-uuid",
  "status": "processing",
  "totalRequested": 3,
  "totalProcessed": 2,
  "totalSkipped": 0,
  "completedAt": null,
  "downloadAvailable": false
}
```

**When completed:**
```json
{
  "jobId": "batch-job-uuid",
  "status": "completed",
  "totalRequested": 3,
  "totalProcessed": 3,
  "totalSkipped": 0,
  "completedAt": "2024-04-01T09:15:00Z",
  "downloadAvailable": true
}
```

---

### GET `/api/kta/batch/:jobId/download`

Download the completed ZIP file.

**Behavior:**
1. Verify job belongs to the requesting user
2. Verify job status is `completed`
3. Fetch ZIP from MinIO using stored `zipPath`
4. Stream to browser as file download

**Response:** Raw ZIP file stream
- Content-Type: `application/zip`
- Content-Disposition: `attachment; filename=ekta_batch_{timestamp}.zip`

**Response 404 — Job not completed or not found:**
```json
{ "statusCode": 404, "message": "Batch job not found or not yet completed." }
```

---

## 8. UI Flow

### 8.1 Single Card Generation

Triggered from the member detail page (Module 02) or the member list row action menu:

```
Member Detail Page — `/admin/daftar-anggota/:id`
─────────────────────────────────────────────────
[ Personal ] [ Address ] [ Documents ] [ Organization ]

                              [ Generate KTA Card ⬇ ]
```

Clicking "Generate KTA Card" triggers a direct download of the PNG file from `GET /api/files/ekta/{publicId}`. No intermediate dialog needed — the browser handles the file download natively.

If the member is not yet verified, the button is disabled with a tooltip: "Member must be verified before a KTA card can be generated."

---

### 8.2 Batch Generation Page — `/admin/generate-kta`

```
┌──────────────────────────────────────────────────────────────┐
│  Generate KTA Cards                                          │
│                                                              │
│  ┌──────────────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ 🔍 Search...     │  │ Status ▾ │  │  Territory     ▾ │  │
│  └──────────────────┘  └──────────┘  └──────────────────┘  │
│                                                              │
│  ☑ Select All (245 members)                                  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ☑ │ Name          │ KTA Number      │ Territory      │   │
│  ├───┼───────────────┼─────────────────┼────────────────┤   │
│  │ ☑ │ Budi Santoso  │ 86337408000001  │ Kota Semarang  │   │
│  │ ☑ │ Ani Wijaya    │ 86337408000002  │ Kota Semarang  │   │
│  │ ☐ │ Rudi H.       │ ⏳ Pending      │ Kota Semarang  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  2 selected (1 unverified — will be skipped)                 │
│                                                              │
│              [ Generate Selected KTA Cards ⬇ ]              │
└──────────────────────────────────────────────────────────────┘
```

Notes on list behavior:
- Only shows members within the caller's territorial scope
- Unverified members are shown but cannot be selected (checkbox disabled, dimmed row)
- Pending members show "⏳ Pending" instead of a KTA number
- The count line warns how many will be skipped before the user submits

---

### 8.3 Batch Progress & Download

After submitting the batch request, the page transitions to a progress view:

```
┌──────────────────────────────────────────────────────────────┐
│  Generating KTA Cards...                                     │
│                                                              │
│  ████████████████████░░░░░░░░   2 / 3 cards generated       │
│                                                              │
│  Please wait. You can leave this page — the job will         │
│  continue in the background.                                 │
│                                                              │
│  Job ID: batch-job-uuid                                      │
└──────────────────────────────────────────────────────────────┘
```

When complete:

```
┌──────────────────────────────────────────────────────────────┐
│  ✅ KTA Cards Ready                                          │
│                                                              │
│  3 cards generated successfully.                             │
│  0 members skipped.                                          │
│                                                              │
│             [ ⬇ Download ZIP (ekta_batch_xxx.zip) ]         │
└──────────────────────────────────────────────────────────────┘
```

The progress bar auto-polls `GET /api/kta/batch/:jobId/status` every 2 seconds until the status is `completed` or `failed`.

---

## 9. Business Rules Summary

| Rule | Detail |
|---|---|
| Verified members only | KTA generation is blocked for unverified members |
| Scope enforced | Cards can only be generated for members within the caller's territorial scope |
| Legacy endpoint preserved | `GET /api/files/ekta/{publicid}` path kept for URL compatibility |
| Batch is async | Large batches must not block the HTTP thread — use a job queue |
| Batch skips gracefully | Unverified or out-of-scope members are skipped, not errored |
| Name truncated at 45 chars | Longer names are cut before rendering on the card |
| Vertical position shifts at 17 chars | KTA number and district name shift down 10px when name > 17 chars |
| QR encodes public verification URL | `https://salam.pagarnusa.or.id/cqr/{publicId}` — never internal IDs |
| Photo resized to 285×380 | Regardless of original dimensions |
| ZIP stored temporarily in MinIO | Cleaned up after download or expiry |
| Output filename | Single: `ekta_{noKta}.png`, Batch ZIP: `ekta_batch_{timestamp}.zip` |

---

## 10. Server-Side Assets Required

These files must be present on the backend server at a known path (e.g. inside an `assets/` directory). They are not stored in MinIO — they are part of the application deployment.

| Asset | Purpose |
|---|---|
| `depan-masterv2.jpg` | KTA card background template |
| `GothamRegular.otf` | Font for member name text |
| `GothamBold.otf` | Font for KTA number and district text |
| `GothamLight.otf` | Available font (referenced in legacy but not used in current active composition) |
| `default.png` | Fallback profile photo when `urlFoto` is not set |

---

## 11. Implementation Checklist

### Backend (Express.js)
- [ ] `GET /api/files/ekta/:publicid` — single card generation: scope check, verified check, photo fetch from MinIO, full composition per Section 5, return PNG download
- [ ] Card composition engine — base template load, photo resize and composite at (650,125), three text layers at specified positions, QR composite at (80,315)
- [ ] Name truncation at 45 characters before rendering
- [ ] Vertical position shift logic — KTA and district fields shift y+10 when `nama.length > 17`
- [ ] QR code generation — encode `https://salam.pagarnusa.or.id/cqr/{publicId}`, medium error correction, 5px module size, 1px border
- [ ] `POST /api/kta/batch` — validate publicIds, create job record, enqueue job, return jobId
- [ ] Batch queue worker — process each member: scope check, verified check, generate card, accumulate in ZIP
- [ ] `GET /api/kta/batch/:jobId/status` — return job progress and completion state
- [ ] `GET /api/kta/batch/:jobId/download` — fetch ZIP from MinIO, stream as download
- [ ] ZIP assembly — collect generated PNGs, compress into ZIP, upload to MinIO temp path
- [ ] Batch job cleanup — delete ZIP from MinIO after download or after expiry
- [ ] Fallback to default photo if `urlFoto` missing or MinIO fetch fails
- [ ] Font files and template asset loading from known server path

### Frontend (Next.js)
- [ ] "Generate KTA Card" button on member detail page — disabled with tooltip if member not verified
- [ ] `/admin/generate-kta` — batch generation page with member list, checkboxes, scope-filtered
- [ ] Unverified member rows shown as dimmed with disabled checkboxes
- [ ] Pre-submit warning showing how many selected members will be skipped
- [ ] Progress view — auto-polling status every 2 seconds, progress bar display
- [ ] Completion view — success summary and ZIP download button
- [ ] Failure view — error message and retry option

---

*This document is the PRD for Module 07 — KTA Card Generation & Batch Export.*
*Business logic source: legacy `FilesController.cs` (`GetImageKta`, `GenerateQrCode`)*
*This completes the full PRD set for PagarNusa WebAdmin v2.0.*
*Last updated: April 2026 | Version: 2.0*
