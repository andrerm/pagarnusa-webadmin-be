---
name: new-module
description: Use when starting backend module
---

<!-- Tip: Use /create-prompt in chat to generate content with agent assistance -->

/create-prompt 
I am building a new Express.js module for PagarNusa WebAdmin v2.0.
Read the PRD file currently open in the editor before generating any code.
Read agent-context.sql  for the database schema.
Read copilot-instructions.md for hard rules.

Generate in this order:
1. Prisma model (if new table needed)
2. TypeScript DTOs (request and response types)
3. Service layer (business logic, NO db calls in controller)
4. Controller (route handlers only, calls service)
5. Route file (registers all endpoints)
6. Unit test stubs for each service method

Follow all rules in copilot-instructions.md strictly.