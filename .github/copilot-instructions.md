---
name: pagarnusa-webadmin-v2
description: "Instructions for PagarNusa WebAdmin v2.0 re-engineering. Use when: developing any backend/frontend module, designing APIs, managing authentication, handling file uploads, or implementing territorial scope filtering. Enforces hard rules for security, file handling, transactions, and naming conventions across the full stack."
---

# PagarNusa WebAdmin v2.0 — Agent Instructions

This document is the authoritative reference for all development work on PagarNusa WebAdmin. Every code generation, refactor, and architecture decision must follow these rules.

---

## 1. System Context

**PagarNusa WebAdmin** is a re-engineered administrative platform for member registration, verification, account management, and organizational structure across Indonesia's 4-level territorial hierarchy.

- **Deployment:** Docker Compose on Linode VPS (Nginx proxy → Next.js + Express.js)
- **Core users:** Superadmin, Verifikator PW (provincial), Verifikator PC (district), Observer, Public
- **No data migration:** Prisma maps to existing MySQL schema (read-only on existing columns)
- **Reference:** Read [DOC1-overview-architecture.md](./useful-docs/DOC1-overview-architecture.md) before any module work

---

## 2. Technology Stack

### Backend
- **Framework:** Express.js + TypeScript
- **ORM:** Prisma (existing MySQL schema, no migrations on existing columns)
- **Image Processing:** Sharp (composite dynamic text onto template image)
- **Batch Processing:** Bull Queue
- **File Compression:** Archiver (ZIP exports)
- **QR Code:** qrcode library

### Frontend
- **Framework:** Next.js 16.2.4+ + TypeScript
- **UI:** shadcn/ui + Tailwind CSS
- **Data:** TanStack Query
- **Forms:** React Hook Form + Zod
- **Auth Client:** NextAuth.js

### Storage & Cache
- **Database:** MySQL (existing, preserved as-is)
- **File Storage:** MinIO (S3-compatible, existing)
- **Cache & Session:** Redis (optional, configurable)

### Authentication & JWT
- **Token Strategy:** JWT with rotation
- **Access Token:** 15 minutes
- **Refresh Token:** 7 days
- **Rotation:** On use (refresh token reissued on every use)

---

## 3. Hard Security Rules

### Authentication & Authorization
- **Never** store or log plain-text passwords — always hash (bcrypt/Argon2) before storing
- **Superadmin identification:** JWT scope === `"-"` (literal dash/hyphen only)
- **Territorial scope format:**
  - `"-"` = National (Superadmin only)
  - 2-digit (e.g., `"33"`) = Province
  - 4-digit (e.g., `"3374"`) = District
- **Scope filtering:** Apply ONLY at SERVICE layer, never in controllers
- **Route guards:** NextAuth.js on frontend, custom JWT middleware on backend
- **Password reset:** Must use time-limited token, never resets to default

### File Handling
- **Never return raw MinIO URLs** to frontend — ALWAYS route through `/api/files/`
- **KTP uploads:** Must be watermarked before serving to frontend (use Sharp)
- **File size limit:** 350KB max per file (compress if larger before upload)
- **Allowed types:** JPG, PNG only
- **Filename requirement:** Must contain `"ktp"` or `"pasfoto"` in the filename
- **Compression rule:** If upload > 350KB, compress first then validate
- **Access pattern:** Frontend → Nginx → Express → MinIO (never direct MinIO URLs)

### Database Transactions
- **All verification actions** (approve, reject, update status) must run inside a DB transaction
- **KTA generation:** Batch operations must be transactional
- **Example:** Verify member → update status + log verifier + emit queue event — all in one transaction

### Configuration & Environment
- **No hardcoded values** for:
  - Max file size (use `process.env.MAX_FILE_SIZE`)
  - Hash salt/rounds (use `process.env.BCRYPT_ROUNDS`)
  - JWT secrets (use `process.env.JWT_ACCESS_SECRET`, etc.)
  - Redis URL (use `process.env.REDIS_URL`, make optional)
  - S3/MinIO credentials (use env vars)
- **Environment support:** Prod, Dev, Staging — all must work with same codebase
- **Config structure:** Create `src/config/index.ts` (backend) and `lib/config.ts` (frontend) to centralize all env-dependent values

---

## 4. API Response Format

All backend API responses must follow this exact shape:

```typescript
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;  // Optional, for list endpoints
  message: string;        // Human-readable message
  statusCode: number;     // HTTP status code
  isError: boolean;       // true if error, false if success
}

interface PaginationMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}
```

**Examples:**
```typescript
// Success
{ data: { id: 1, name: "John" }, message: "Member created", statusCode: 201, isError: false }

// List with pagination
{ data: [...], meta: { page: 1, pageSize: 10, total: 150, totalPages: 15 }, message: "Members retrieved", statusCode: 200, isError: false }

// Error
{ data: null, message: "Invalid file size", statusCode: 400, isError: true }
```

---

## 5. Naming Conventions

### Files & Folders
- **Files:** kebab-case (e.g., `member-service.ts`, `kta-controller.ts`, `auth-guard.ts`)
- **Directories:** lowercase with hyphens for multi-word (e.g., `src/services`, `src/file-handlers`)

### Code Identifiers
- **Classes:** PascalCase (e.g., `MemberService`, `KtaGenerator`, `AuthMiddleware`)
- **Functions/Methods:** camelCase (e.g., `getMemberById()`, `verifyAndUpdateStatus()`)
- **Variables:** camelCase (e.g., `accessToken`, `fileBuffer`, `scopeCode`)
- **Constants:** UPPER_SNAKE_CASE (e.g., `MAX_FILE_SIZE`, `JWT_EXPIRY_ACCESS`)
- **Enums:** PascalCase (e.g., `VerificationStatus`, `UserRole`)

### Database & ORM
- **Table names:** Follow existing MySQL schema exactly (no renames)
- **Prisma models:** Use `@@map()` to alias to existing table names
- **Example:**
  ```typescript
  model Member {
    id Int @id
    @@map("pribadi")
  }
  ```

### API Routes
- **Pattern:** `/api/{module}/{action}` or `/api/{module}/{resource}` (REST)
- **Examples:**
  - `POST /api/members/register` — Public self-registration
  - `GET /api/members/{id}` — Get member by ID
  - `POST /api/members/{id}/verify` — Verify member (Verifikator only)
  - `POST /api/auth/login` — User login
  - `GET /api/territories/provinces` — List provinces

---

## 6. Prisma & Database

### Schema Mapping
- **Always use `@@map()`** to alias models to existing table names:
  ```typescript
  model Pribadi {
    idpribadi Int @id @map("idpribadi")
    nama String
    @@map("pribadi")
  }
  ```

### Migration Policy
- **Never run migrations that alter existing columns** (schema is read-only for existing data)
- **New tables only** — if a new feature requires a new table, create it via migration
- **No column renames, no type changes** on existing columns
- **Foreign keys:** Respect existing FK constraints

### Querying Patterns
- Use Prisma's type-safe API (no raw SQL unless absolutely necessary)
- Implement filtering at the service layer, not in controllers
- Leverage Prisma's `where` clause for scope filtering:
  ```typescript
  // Service: filter by territory scope
  const members = await prisma.pribadi.findMany({
    where: { idKabupatenDomisili: parseInt(userScope) }
  });
  ```

---

## 7. Scope Filtering (Most Important)

**Rule:** Scope filtering MUST happen in the SERVICE layer, validated before returning data to the controller.

### Territory Codes
- `-` = National (Superadmin) — can see everything
- `33` = Province (2-digit) — can see that province + all sub-districts
- `3374` = District (4-digit) — can see that district + all sub-villages

### Service Layer Example
```typescript
// member.service.ts
async getMembersByScope(scope: string, userId: number): Promise<Member[]> {
  let whereClause = {};
  
  if (scope === "-") {
    // Superadmin: no filter
  } else if (scope.length === 2) {
    // Provincial: filter by 2-digit province code
    whereClause = { idKabupatenDomisili: { startsWith: scope } };
  } else if (scope.length === 4) {
    // District: filter by 4-digit district code
    whereClause = { idKabupatenDomisili: scope };
  }
  
  return prisma.pribadi.findMany({ where: whereClause });
}

// member.controller.ts
async getMembers(req: Request, res: Response) {
  const userScope = req.user.scope; // From JWT token
  const members = await this.memberService.getMembersByScope(userScope, req.user.id);
  return res.json(apiResponse(members, 'Members retrieved'));
}
```

---

## 8. Verification & Transaction Pattern

All verification actions must follow this pattern:

```typescript
async verifyMember(memberId: number, verifierId: number, status: "approved" | "rejected", notes?: string) {
  return await prisma.$transaction(async (tx) => {
    // 1. Fetch member (with lock if supported)
    const member = await tx.pribadi.findUniqueOrThrow({
      where: { idpribadi: memberId }
    });

    // 2. Update verification status
    const updated = await tx.pribadi.update({
      where: { idpribadi: memberId },
      data: {
        is_verified: status === "approved" ? 1 : 0,
        verifier: verifierId,
        verified_date: new Date()
      }
    });

    // 3. Log the action
    await tx.verificationLog.create({
      data: {
        memberId,
        verifierId,
        status,
        notes,
        timestamp: new Date()
      }
    });

    // 4. Emit event (to queue/bus)
    await emitEvent('member.verified', { memberId, status });

    return updated;
  });
}
```

---

## 9. File Upload Handling

### Frontend Upload
```typescript
const handleUpload = async (file: File) => {
  // 1. Validate size (350KB)
  if (file.size > 350 * 1024) {
    // Option A: Reject
    // Option B: Compress then upload
    const compressed = await compressImage(file);
    await uploadToApi(compressed);
    return;
  }

  // 2. Validate type
  if (!["image/jpeg", "image/png"].includes(file.type)) {
    throw new Error("Only JPG/PNG allowed");
  }

  // 3. Validate filename
  if (!file.name.includes("ktp") && !file.name.includes("pasfoto")) {
    throw new Error("Filename must contain 'ktp' or 'pasfoto'");
  }

  // 4. Send to backend
  await uploadToApi(file);
};
```

### Backend Upload Endpoint
```typescript
// POST /api/files/upload
async uploadFile(req: Request, res: Response) {
  const file = req.file;
  
  // 1. Validate
  if (!file || file.size > parseInt(process.env.MAX_FILE_SIZE!)) {
    return res.status(400).json(apiError("File too large"));
  }
  
  // 2. Upload to MinIO
  const filePath = await minioService.upload(file.buffer, file.originalname);
  
  // 3. Watermark if KTP
  if (file.originalname.includes("ktp")) {
    await this.watermarkKtp(filePath);
  }
  
  // 4. Save reference to DB (if needed)
  await prisma.fileReference.create({
    data: { userId: req.user.id, filePath, uploadedAt: new Date() }
  });
  
  return res.json(apiResponse({ fileId: filePath }, "File uploaded"));
}

// GET /api/files/{fileId}
async getFile(req: Request, res: Response) {
  const { fileId } = req.params;
  
  // 1. Check authorization (user owns this file or is admin)
  const fileRef = await prisma.fileReference.findUnique({ where: { id: fileId } });
  if (fileRef.userId !== req.user.id && req.user.scope !== "-") {
    return res.status(403).json(apiError("Unauthorized"));
  }
  
  // 2. Get from MinIO
  const buffer = await minioService.download(fileId);
  
  // 3. Watermark if KTP
  if (fileId.includes("ktp")) {
    const watermarked = await sharp(buffer).composite([...]).toBuffer();
    return res.type("image/jpeg").send(watermarked);
  }
  
  return res.type("image/jpeg").send(buffer);
}
```

---

## 10. Module Development Process

### Before Coding
1. Read the relevant PRD: `DOC2-prd-module-{number}.md`
2. Identify entity models from `agent-context.sql`
3. Plan API endpoints (method, path, request, response)
4. Check territorial scope implications
5. Determine if transactions are needed

### Module PRDs
- **Module 01:** Authentication — Login, logout, session, RBAC
- **Module 02:** Member List — Registration, verification, member data
- **Module 03:** Account Management — Admin users, role & scope assignment
- **Module 04:** Territory Management — 4-level hierarchy
- **Module 05:** Organizational Structure — Kepengurusan & periods
- **Module 06:** Position Management — Jabatan catalog
- **Module 07:** Profile — Self-service profile & documents
- **Module 08:** KTA Generation — Image composition + ZIP export

---

## 11. Common Patterns

### Service Layer Dependency Injection
```typescript
// member.service.ts
export class MemberService {
  constructor(
    private prisma: PrismaClient,
    private minioService: MinIOService,
    private logger: Logger
  ) {}

  async getMembersByScope(scope: string) { ... }
}
```

### Controller Pattern
```typescript
// member.controller.ts
export class MemberController {
  constructor(private memberService: MemberService) {}

  async getMembers(req: Request, res: Response) {
    try {
      const members = await this.memberService.getMembersByScope(req.user.scope);
      return res.json(apiResponse(members, "Success"));
    } catch (err) {
      return res.status(500).json(apiError(err.message));
    }
  }
}
```

### Middleware Pattern (Scope Validation)
```typescript
// auth-guard.ts
export const requireScope = (allowedScopes: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const userScope = req.user?.scope;
    if (!allowedScopes.includes(userScope)) {
      return res.status(403).json(apiError("Insufficient permissions"));
    }
    next();
  };
};

// Usage in routes
router.post("/members/:id/verify", requireScope(["-", "PW", "PC"]), memberController.verifyMember);
```

---

## 12. Error Handling

All errors must return standardized API responses:

```typescript
// errors.ts
export const apiError = (message: string, statusCode = 400) => ({
  data: null,
  message,
  statusCode,
  isError: true
});

// Usage
if (!member) return res.status(404).json(apiError("Member not found", 404));
```

---

## 13. Environment Variables & Configuration

Create a centralized config file:

```typescript
// src/config/index.ts (Backend)
export const config = {
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET!,
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || "15m",
    refreshSecret: process.env.JWT_REFRESH_SECRET!,
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || "7d",
  },
  files: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE || "358400"),
    allowedTypes: ["image/jpeg", "image/png"],
  },
  bcrypt: {
    rounds: parseInt(process.env.BCRYPT_ROUNDS || "10"),
  },
  redis: {
    enabled: process.env.REDIS_ENABLED === "true",
    url: process.env.REDIS_URL || "redis://localhost:6379",
  },
  minio: {
    endpoint: process.env.MINIO_ENDPOINT!,
    accessKey: process.env.MINIO_ACCESS_KEY!,
    secretKey: process.env.MINIO_SECRET_KEY!,
    bucketName: process.env.MINIO_BUCKET || "pagarnusa",
  },
};
```

**Example `.env.development`:**
```
JWT_ACCESS_SECRET=dev-secret-key-change-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_SECRET=dev-refresh-key-change-in-production
JWT_REFRESH_EXPIRY=7d
MAX_FILE_SIZE=358400
BCRYPT_ROUNDS=10
REDIS_ENABLED=false
REDIS_URL=redis://localhost:6379
```

---

## 14. Testing & Quality

- **Unit tests:** Service layer (business logic)
- **Integration tests:** API endpoints with DB
- **E2E tests:** Critical flows (registration → verification → KTA generation)
- **Linting:** ESLint + Prettier (configured in both fe/be repos)
- **Type checking:** `tsc --noEmit` before deployment

---

## 15. Quick Reference: When to Ask

❌ **Do NOT ask for:** How to use Express, Next.js, Prisma, TypeScript fundamentals
✅ **DO ask for:**
- Scope filtering logic for a specific scenario
- Transaction patterns for complex operations
- API response format for a new endpoint
- File handling for a new upload type
- Module integration patterns

---

*Updated: April 2026 | Version: 2.0*
*Related: [DOC1-overview-architecture.md](./useful-docs/DOC1-overview-architecture.md), Module PRDs (DOC2-prd-module-01 through 07)*
