# PagarNusa WebAdmin v2 — System Overview

> This document serves as the primary context for AI agents to understand the business processes, architecture, and technology decisions of the PagarNusa WebAdmin second-generation system. Read this before reading any module PRD.

---

## 1. About the System

**PagarNusa WebAdmin** is a web-based administrative platform for PagarNusa — an Indonesian organization that manages member registrations, hierarchical organizational structures across territorial boundaries, user access control, and profile verification workflows.

This system is the **second generation**, re-engineered from the ground up to improve maintainability, developer experience, and cloud deployment readiness.

---

## 2. System Users

| Role | Description | Territory Scope |
|---|---|---|
| Superadmin | System administrator, unrestricted access | National |
| Verifikator PW | Provincial-level verifier | Province (2-digit code, e.g. `33`) |
| Verifikator PC | District-level verifier | District (4-digit code, e.g. `3374`) |
| Observer | Read-only access | Per assignment |
| Public | New member applicants (self-registration) | — |

---

## 3. Core Business Processes

### 3.1 Member Registration & Verification
Prospective members fill out a self-registration form via a public-facing page. Data includes personal identity, education, employment, address, and identity documents (KTP, KK). Once submitted, records enter a verification queue. Verifikator PW or PC reviews and approves based on their assigned territorial scope. Verification results are recorded with the verifier's identity and a timestamp.

### 3.2 Account Management & RBAC
Superadmins manage administrator accounts. Each account is assigned a role and a territorial scope that restricts which data the user can view and manage. Scope is assigned by the Superadmin — verifiers cannot select their own scope.

### 3.3 Territory Management
The system maintains Indonesia's four-level administrative hierarchy: Province → Regency/City → District → Village/Kelurahan. This hierarchy is used as the basis for access scope restriction and member data filtering.

### 3.4 Organizational Structure Management
Defines organizational units (Kepengurusan) across hierarchy levels with active periods, role assignments, and structural relationships between units.

### 3.5 Position Management
A catalog of positions and titles linked to organizational levels, enabling assignment of individuals to specific roles within the organizational structure.

### 3.6 Member Card Generation (KTA)
The system programmatically generates member ID card images: a template image (background/frame) stored in MinIO is composited with dynamic data from the database (name, KTA number, territory, expiry date, etc.) using an SVG text layer. Supports batch generation for multiple members at once, compressed into a ZIP file for download.

### 3.7 Profile Management
Users can view and edit their personal profile, upload photos and documents (350KB limit per file), and perform QR code-based authorization confirmation.

---

## 4. Key Workflows

```
[Public]
  Self-Registration Form
        ↓
  Record created in system (status: pending)
        ↓
[Verifikator PW / PC]
  Review member data
        ↓
  Approve / Reject + verification notes
        ↓
  Status updated: verified (with timestamp & verifier name)
```

```
[Superadmin]
  Create new admin account
        ↓
  Assign role (Verifikator PW / PC / Observer)
        ↓
  Assign territorial scope (province or district)
        ↓
  Verifikator can only access data within their scope
```

---

## 5. Tech Stack

### Frontend
- **Framework:** Next.js + TypeScript
- **UI Components:** shadcn/ui + Tailwind CSS
- **Data Fetching & State:** TanStack Query
- **Form & Validation:** React Hook Form + Zod
- **Auth Client:** NextAuth.js

### Backend
- **Framework:** Express.js + TypeScript
- **ORM:** Prisma
- **Image Processing:** Sharp (composite dynamic text onto template image)
- **Batch & Queue:** Bull Queue
- **ZIP Export:** Archiver
- **QR Code:** qrcode library

### Data & Storage
- **Database:** MySQL (using existing data, schema unchanged)
- **File Storage:** MinIO (S3-compatible, existing)
- **Cache & Session:** Redis

### Infrastructure
- **Container:** Docker Compose
- **Proxy:** Nginx (reverse proxy + SSL termination)
- **SSL:** Let's Encrypt
- **Hosting:** Linode VPS
- **CI/CD:** GitHub Actions

### AI Development
- GitHub Copilot Agent
- Claude.ai
- ChatGPT

---

## 6. System Architecture

### Project Structure
Two separate repositories deployed independently:

```
GitHub
├── pagarnusa-webadmin-fe    → Next.js (Frontend)
└── pagarnusa-webadmin-be    → Express.js (Backend API)
```

### Deployment Topology (Linode VPS)

```
Internet
    ↓
Nginx (port 80/443)
├── /*      → Next.js container (port 3000)        [Frontend]
└── /api/*  → Express.js container (port 4000)     [Backend API]

Docker Compose Services:
├── nginx
├── nextjs      (port 3000)
├── express     (port 4000)
├── mysql       (port 3306)  ← existing data
├── minio       (port 9000)  ← existing files
└── redis       (port 6379)  ← new
```

### Communication Pattern
The frontend never calls the backend directly. All browser requests to `/api/*` are proxied by Nginx to the Express.js backend. This enables a CORS-free setup and a single domain for both services.

### URL Preservation
All legacy URLs from the first-generation system are preserved via Nginx configuration so that users experience no disruption. Legacy API endpoints (including `/users/authenticatew`) are proxied to compatible new endpoints in Express.js.

```nginx
# Nginx configuration example
location /api/pribadis        { proxy_pass http://express:4000; }
location /api/users           { proxy_pass http://express:4000; }
location /users/authenticatew { proxy_pass http://express:4000/api/auth/login; }
location /form-daftar-noauth  { proxy_pass http://nextjs:3000; }
location /                    { proxy_pass http://nextjs:3000; }
```

### CI/CD Pipeline

```
Push to main branch (fe or be repo)
        ↓
GitHub Actions: build → test → build Docker image
        ↓
SSH into Linode VPS
        ↓
docker compose pull → docker compose up -d --build
        ↓
Health check → done
```

### Cloud Migration Path
Because the entire system runs in containers, migrating to a cloud provider (GCP Cloud Run, AWS ECS, Fly.io) only requires changing the deploy target in GitHub Actions — no application code changes needed.

---

## 7. Key Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Project structure | 2 separate repos | Independent deployment, parallel team work |
| Database | Existing MySQL | Zero data migration, zero risk |
| ORM | Prisma | Auto-generates types from existing schema |
| File storage | Existing MinIO | Proven, S3-compatible |
| Cache | Redis (new) | Session, rate limiting, queue |
| Container | Docker Compose | Sufficient for VPS, easy to scale to k8s |
| Image generation | Sharp + SVG | Dynamic DB text composited onto template image |
| Batch export | Bull Queue + Archiver | Non-blocking processing, ZIP download |

---

## 8. System Modules

| No | Module | Description |
|---|---|---|
| 1 | Authentication | Login, logout, password reset, session lock, RBAC route guards |
| 2 | Member List (Daftar Anggota) | Registration, verification, member data management |
| 3 | Account Management | Admin users, role & scope assignment |
| 4 | Territory Management | 4-level administrative hierarchy |
| 5 | Organizational Structure | Org units (Kepengurusan) & periods |
| 6 | Position Management | Position/title catalog (Jabatan) |
| 7 | Profile | Self-service profile & document upload |
| 8 | KTA Generation | Batch image generation + ZIP export |

---

## 9. System Assumptions

- Existing MySQL data and schema are not modified. Prisma maps to the existing schema as-is.
- Verifiers receive their territorial scope from a Superadmin — they cannot select it themselves.
- Members can hold multiple role flags simultaneously (`isPelatih`, `isPengurus`).
- File uploads are limited to 350KB per file.
- The system is web-only — no native mobile app.
- Email notifications are not implemented in this generation.
- configuration such as max file size, salt for hash and others should be configurable and adapt with environment deployment (Prod / Dev / Staging)

---

*This document must be read before any module PRD.*
*Last updated: April 2026 | Version: 2.0*
