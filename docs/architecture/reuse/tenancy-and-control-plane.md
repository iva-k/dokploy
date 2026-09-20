# Reuse plan: tenancy and control plane

Survey date: 2026-09-20. Scope: [hosted-platform plan](../hosted-platform-plan.md), phases B, C, F, G, and H. These are proposals and implementation references. No package, service, or architecture change is approved here. The user deferred license decisions to the launch or funding review; license metadata below does not exclude a candidate or block technical planning.

Keep `organization.id` as the tenant ID. Keep public self-service signup in the first paid release, one application VM per organization, and the database-provider cost gate. Beads remains the task authority. This document does not change task status.

## Source and license register

The links below pin the source used in this survey. A main-branch pin is a reference, not a recommended package version. Confirm the installed API and release notes before an upgrade. License labels are source metadata for the deferred review. This audit copies no source code.

| Key | Verified license and source pin | Maintenance evidence checked on the survey date | Fit and boundary |
| --- | --- | --- | --- |
| BA | [Better Auth, MIT](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/LICENSE.md), commit `41b7dc15de41a8726422c392a4857d8764828891` | Latest release [v1.7.5](https://github.com/better-auth/better-auth/releases/tag/v1.7.5), 2026-09-14; pinned commit dated 2026-09-17 | Already installed at 1.6.23. Reuse its public plugins; do not assume the newer reference APIs exist in 1.6.23. |
| DR | [Drizzle ORM, Apache-2.0](https://github.com/drizzle-team/drizzle-orm/blob/0fd1cc61f1ff6553234d29042461fc5e9aa551c3/LICENSE), commit `0fd1cc61f1ff6553234d29042461fc5e9aa551c3` | Pinned commit dated 2026-09-19; repository not archived | Already installed. Keep the PostgreSQL/postgres-js adapter; do not replace it with Prisma. |
| PG | [PostgreSQL license](https://github.com/postgres/postgres/blob/e73841ffbceea314cf9fa3f64a5eae9f87a46449/COPYRIGHT), commit `e73841ffbceea314cf9fa3f64a5eae9f87a46449` | Pinned commit dated 2026-09-19; [18.6 release](https://www.postgresql.org/docs/release/18.6/), 2026-08-13 | Use supported PostgreSQL 18 for implementation. The master-branch tests are reference material, not a server build recommendation. |
| PB | [pg-boss, MIT](https://github.com/timgit/pg-boss/blob/ce5a55e76c976c84c27b3062f3a7e4225f82a904/LICENSE), commit `ce5a55e76c976c84c27b3062f3a7e4225f82a904` | [12.33.2](https://github.com/timgit/pg-boss/releases/tag/12.33.2) released 2026-09-18; pinned commit dated 2026-09-19 | Whole-package candidate. Its released 12.33.2 Drizzle adapter supports postgres-js. Requires Node >=22.12; this repository specifies Node 24. |
| GW | [Graphile Worker, MIT](https://github.com/graphile/worker/blob/4cda192c5df254392a1dff350e5d73f7d2c18a85/LICENSE.md), commit `4cda192c5df254392a1dff350e5d73f7d2c18a85` | [v0.18.0](https://github.com/graphile/worker/releases/tag/v0.18.0) released 2026-09-08 | Whole-package alternative. SQL enqueue fits the existing driver. Requires Node >=22.18. |
| TR | [Traefik, MIT](https://github.com/traefik/traefik/blob/e75250a31ae773e50e9c16514e3aebcb92059042/LICENSE.md), commit `e75250a31ae773e50e9c16514e3aebcb92059042` | [v3.7.13](https://github.com/traefik/traefik/releases/tag/v3.7.13) released 2026-09-04; pinned commit dated 2026-09-14 | Existing routing and ACME integration. Check the deployed image version separately. |
| PI | [Pino, MIT](https://github.com/pinojs/pino/blob/1de1212b31f569c50bb14ca11e13a8f8bb2b2407/LICENSE), commit `1de1212b31f569c50bb14ca11e13a8f8bb2b2407` | Pinned commit dated 2026-09-05; repository not archived | Already installed at 9.4.0. Use its redaction API; logs do not replace durable audit records. |

Internal source provenance is described in [LICENSE.MD](../../../LICENSE.MD). `lib/auth.ts` imports `createAuditLog` and `resolveOrganizationDefaultRole` from proprietary services; `services/permission.ts` imports `hasValidLicense`. Retain these as technical reuse candidates. Record their production imports for the deferred launch/funding review; no license checks are changed by this audit.

<a id="t1"></a>
## T1. Identity, organization roles, and API keys

**Classification and rung:** commodity identity and membership; internal code plus installed Better Auth. Product-specific roles remain configuration and authorization glue.

**Existing targets:** `packages/server/src/db/schema/account.ts` organization/member/invitation/API-key tables; `packages/server/src/lib/auth.ts` organization plugin and `validateRequest`; `lib/access-control.ts` `ac.newRole`; `services/permission.ts` `checkPermission`; `apps/dokploy/server/api/routers/organization.ts`.

Reuse account IDs, membership records, invitation flow, session verification, and plugin access-control statements. Add developer, viewer, and billing roles through the existing auth composition. Keep platform-operator access separate. The existing API-key plugin uses `references: "user"`; tenant metadata alone must not confer organization membership or billing rights.

**Read-before-build code and tests:**

- BA [`hasPermission`](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/plugins/organization/has-permission.ts) and [`removeMember` / `updateMemberRole`](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/plugins/organization/routes/crud-members.ts): use the plugin API rather than duplicate its membership engine.
- BA [member-route tests](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/plugins/organization/routes/crud-members.test.ts) and [organization API-key tests](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/api-key/src/org-api-key.test.ts): adapt non-member denial, role changes, organization/user key separation, and key-management permissions into local Vitest fixtures. These are MIT test-port candidates.
- Confirm organization-owned key support in the selected release before changing the existing key schema. Preserve existing user keys through an explicit migration; do not reinterpret them silently.

**Remaining custom work:** map hosted roles to this product's resource actions; enforce organization selection for keys and sessions; define member-removal and last-owner behavior; separate legacy and hosted permission modes. The existing proprietary wrappers remain reuse candidates. The public Better Auth APIs also provide a reference if the later composition decision requires a different adapter; no replacement is selected for license reasons in this audit.

**Alternatives:** a second identity service or policy engine would add a second account/policy model while installed Better Auth already supplies membership and RBAC. Reconsider one only if a measured requirement is missing.

**Validation:** extend `__test__/permissions/check-permission.test.ts`, `resolve-permissions.test.ts`, and `__test__/api/api-key-name.test.ts`. Cover a user in two organizations, key revocation, removal during an active session, duplicate memberships, owner transfer, and billing-member denial for secrets and deployment changes.

**Product reference:** Vercel distinguishes team and project [access roles](https://vercel.com/docs/rbac/access-roles). Neon provides organization and [project-scoped organization API keys](https://neon.com/docs/manage/orgs-api). Use these as capability references; their role names are not this service's contract.

<a id="t2"></a>
## T2. Tenant ownership across database, API, jobs, and WebSockets

**Classification and rung:** native PostgreSQL constraints and RLS, installed Drizzle transactions, and internal authorization functions. Tenant relationship rules are custom glue.

**Existing targets:** `packages/server/src/db/index.ts` uses Drizzle's postgres-js driver; `db/schema/project.ts` and `environment.ts`; `services/permission.ts` `checkProjectAccess`, `checkServiceAccess`, `checkEnvironmentAccess`; `apps/dokploy/server/api/trpc.ts` `protectedProcedure` / `withPermission`; `server/wss/authorize.ts` `canAccessDockerOverWss` / `canAccessTerminalOverWss`.

Keep these entry points and make ownership checks consistent. Authentication, role checks, and ownership checks are separate inputs. Derive the tenant from verified context. Load durable operation ownership from the database rather than trusting a supplied job payload. Require composite ownership constraints for linked tenant resources.

**Read-before-build code and tests:**

- PG [`src/test/regress/sql/rowsecurity.sql`](https://github.com/postgres/postgres/blob/e73841ffbceea314cf9fa3f64a5eae9f87a46449/src/test/regress/sql/rowsecurity.sql): adapt its `USING` / `WITH CHECK`, forced-RLS, bypass-role, and `SELECT FOR UPDATE` cases. Reuse test structure and SQL assertions under the PostgreSQL license; do not copy its full test harness.
- DR [`PostgresJsSession` / `PostgresJsTransaction`](https://github.com/drizzle-team/drizzle-orm/blob/0fd1cc61f1ff6553234d29042461fc5e9aa551c3/drizzle-orm/src/postgres-js/session.ts): reference how transactions hold the driver connection. Set the organization context with transaction-local `set_config(..., true)` inside that transaction, and route every scoped query through its `tx`.
- PostgreSQL [RLS rules](https://www.postgresql.org/docs/18/ddl-rowsecurity.html) define owner/superuser/`BYPASSRLS` behavior. Use a separate migration owner and a runtime role that cannot bypass RLS. RLS does not make customer SQL safe on the platform database.

**Remaining custom work:** the tenant transaction wrapper, typed owned-resource loaders, stable denial errors, composite foreign keys, and authenticated operation context. Select the smallest common helper after tracing all callers. No policy DSL is required.

**Alternatives:** per-customer control-plane databases would replace the current organization schema and migrations. They do not remove the need to check API and worker ownership. Keep the plan's shared control-plane schema; the customer database and workload isolation boundaries remain separate.

**Validation:** use a real PostgreSQL connection pool. Cover pool reuse from tenant A to B, missing tenant context, read/write/insert/upsert/restore denial, foreign tenant IDs, concurrent member removal, and errors that do not reveal another tenant's resource. Extend `permissions/service-access.test.ts` and `wss/authorize.test.ts`; mocks alone cannot prove RLS or transaction scope.

**Product reference:** Vercel's team/project boundary and Neon's organization/project boundary motivate the required scope. Neither vendor's account documentation proves a particular internal RLS implementation.

<a id="t3"></a>
## T3. Durable resource operations, outbox, and scheduling

**Classification and rung:** commodity queue/retry/scheduling; custom resource state and fencing. Keep the plan's native PostgreSQL outbox as the baseline. Evaluate a whole PostgreSQL job library as a proposed amendment before implementing a queue engine.

**Existing targets:** `apps/dokploy/server/queues/in-memory-queue.ts`, `deployments-queue.ts`, `queue-types.ts`, and `queueSetup.ts`; proposed `packages/server/src/services/resource-operation.ts` and `resource-allocation.ts`. Retain deployment handlers and their tested ordering rules; replace only the hosted durability boundary if the amendment is accepted.

| Option | Transaction fit | What is reused | Additional ownership and gaps |
| --- | --- | --- | --- |
| Native outbox baseline | Insert allocation, operation, quota reservation, and outbox row in the same existing Drizzle transaction | Native transactions, uniqueness, row locks; existing handlers | We own polling, lease expiry, retry schedules, poison jobs, cleanup, and recovery tests. `node-schedule` alone is not durable. |
| pg-boss 12.33.2 candidate | `boss.send(..., { db: fromDrizzle(tx, sql) })`; official adapter supports postgres-js | Durable dispatch, scheduling, retries, concurrency, and queue administration | Adds a package, its schema, and normally a `pg` worker pool. Keep product operations and fencing outside its queue tables. |
| Graphile Worker 0.18.0 alternative | Call SQL `graphile_worker.add_job` through `tx.execute` in the existing transaction | Durable dispatch, retries, named queues, cron, and worker recovery | Adds a package/schema and `pg` worker pool. SQL enqueue privileges need a controlled wrapper for the restricted application role. |

**Pinned integration and test references:**

- PB [`fromDrizzle`](https://github.com/timgit/pg-boss/blob/ce5a55e76c976c84c27b3062f3a7e4225f82a904/src/adapters/drizzle.ts), [adapter tests](https://github.com/timgit/pg-boss/blob/ce5a55e76c976c84c27b3062f3a7e4225f82a904/test/adapterTest.ts), and [array parameter tests](https://github.com/timgit/pg-boss/blob/ce5a55e76c976c84c27b3062f3a7e4225f82a904/test/drizzleArrayParamTest.ts). The adapter also exists in the [12.33.2 release source](https://github.com/timgit/pg-boss/blob/12.33.2/src/adapters/drizzle.ts). Use the package export; do not copy its placeholder parser.
- GW [`src/worker.ts`](https://github.com/graphile/worker/blob/4cda192c5df254392a1dff350e5d73f7d2c18a85/src/worker.ts), [`workerUtils.addJob.test.ts`](https://github.com/graphile/worker/blob/4cda192c5df254392a1dff350e5d73f7d2c18a85/__tests__/workerUtils.addJob.test.ts), and [`resetLockedAt.test.ts`](https://github.com/graphile/worker/blob/4cda192c5df254392a1dff350e5d73f7d2c18a85/__tests__/resetLockedAt.test.ts). Use its [SQL API](https://worker.graphile.org/docs/sql-add-job); do not port the worker engine.
- Graphile's [job-key rules](https://worker.graphile.org/docs/job-key) allow a further job when a matching job is running. A job key is not a substitute for the product's unique request key or resource-generation fence.

**Proposed decision:** first run a small pg-boss spike against the installed Drizzle/postgres-js versions. Compare it with the baseline for transaction atomicity, worker-role privileges, recovery, and operating cost. Prefer whole-package reuse if that spike passes. Graphile Worker is a second candidate where SQL enqueue is the better fit. Do not adopt both.

**Remaining custom work:** desired/observed resource state, request identity, generation checks, provider idempotency keys, cancellation, orphan reconciliation, and organization admission. Enqueue only an operation ID; re-read its authority and generation in the handler. Keep network calls outside database transactions. A worker can repeat after an external API succeeds and its acknowledgement is lost; neither queue makes cloud side effects exactly once.

**Validation:** commit/rollback must affect the operation and job together. Kill a worker before and after provider acknowledgement; expire a lease; replay an old generation; stop during resize; retry a canceled create. Extend existing `queues/concurrency.test.ts` and `in-memory-queue.test.ts` behavior where it still applies. Prove that reconciliation finds an allocation without a completed local acknowledgement.

**Alternatives:** Redis-backed scheduling would add another durable store to the existing PostgreSQL design. A full workflow platform introduces an additional control plane. Neither is selected for the first resource-operation contract.

**Product reference:** Vercel exposes project deployment states and actions in [deployment management](https://vercel.com/docs/deployments/managing-deployments); Neon exposes project [operations](https://api-docs.neon.tech/reference/listprojectoperations). Reuse that visible asynchronous-operation pattern without assuming either vendor uses one of these queue libraries.

<a id="t4"></a>
## T4. Secrets, encryption, and audit events

**Classification and rung:** internal helpers, native Node cryptography, installed logging, and native PostgreSQL append permissions. Secret authorization and audit event meaning remain domain logic.

**Existing targets:** `packages/server/src/lib/encryption.ts` `encryptValue` / `decryptValue` / `exportEncryptionKeys`; `lib/encryption-secret.ts`; `db/schema/utils.ts` `encryptedText`; `services/vault-provider.ts` `findVaultProviderInOrganization`, `maskVaultProviderConfig`, `mergeVaultProviderConfig`; `utils/vault/`; `db/schema/audit-log.ts`.

Reuse the existing AES-256-GCM implementation and its dedicated `ENCRYPTION_KEY` support. Reuse vault adapters, masking, and secret environment injection. The hosted database service must add role-scoped secret references, rotation state, overlap rules, and audited secret reads. Do not add a crypto library or write another cipher implementation.

**Observed adaptation:** `encryptedText.fromDriver` catches decryption errors and returns the raw ciphertext. A hosted connection path must treat a failed decrypt as unavailable; it must not inject that value into an application. The existing fallback keys and backup-key export also need explicit hosted backup/restore and access rules.

**Audit reuse and optional adapter:** reuse the existing `createAuditLog` service and `db/schema/audit-log.ts` where they meet the hosted event contract. If the later composition decision requires a separate adapter, insert the same defined event record through Drizzle. Grant the runtime role insert and authorized read access, with no update/delete permission. Use a separate role for controlled retention. Preserve tenant, actor, action, resource identity, request/operation ID, and time; exclude secret values. This is a small product adapter around native PostgreSQL, not a new logging platform.

**Reference and test ports:** PI [`lib/redaction.js` `redaction`](https://github.com/pinojs/pino/blob/1de1212b31f569c50bb14ca11e13a8f8bb2b2407/lib/redaction.js) and [`test/redact.test.js`](https://github.com/pinojs/pino/blob/1de1212b31f569c50bb14ca11e13a8f8bb2b2407/test/redact.test.js) show nested and wildcard redaction cases. Use installed Pino's API; adapt the relevant tests for connection URLs, auth headers, database passwords, and errors. Structured process logs are supplementary evidence and can be lost; commit required audit events with the product operation where applicable.

**Alternatives:** a new hosted vault adds a service contract and cost before the installed adapters and encryption have been evaluated. A database query-audit extension does not supply the authenticated product actor and operation semantics. Do not describe table permissions as proof against a privileged database operator.

**Validation:** extend `__test__/env/encryption.test.ts` and `vault.test.ts`. Cover wrong keys, restored keys, rotation overlap/expiry, ciphertext corruption, tenant/provider mismatch, billing-role denial, log redaction, and audit update/delete rejection with the actual runtime role.

**Product reference:** Vercel attaches [environment variables](https://vercel.com/docs/environment-variables) to deployment environments; Neon offers [pooled and direct PostgreSQL connections](https://neon.com/docs/connect/connection-pooling). The local contract adds the secret-read permission and rotation behavior in the original plan.

<a id="t5"></a>
## T5. Custom domains, ownership, and TLS

**Classification and rung:** existing Traefik/ACME and domain services; native DNS and crypto for a small ownership workflow.

**Existing targets:** `packages/server/src/services/domain.ts` `createDomain`, `validateDomain`, `getServerIpCandidates`; `services/certificate.ts` `createCertificate`; `utils/traefik/`; domain routers and `__test__/domains/domain-validation.test.ts`.

Reuse route rendering, certificate configuration, DNS provider integration, and ACME renewal. The current `validateDomain` checks routing and accepts recognized CDN addresses; that does not prove which tenant controls the domain. Add a normalized unique domain claim, random verification token, DNS TXT proof, claim expiry, and an explicit release/transfer rule before publishing a hosted route. Use `node:dns/promises` and `node:crypto`; no general domain service SDK is needed for that glue.

**Pinned reference and tests:** TR [ACME `Provider`](https://github.com/traefik/traefik/blob/e75250a31ae773e50e9c16514e3aebcb92059042/pkg/provider/acme/provider.go), [provider tests](https://github.com/traefik/traefik/blob/e75250a31ae773e50e9c16514e3aebcb92059042/pkg/provider/acme/provider_test.go), and [ACME integration tests](https://github.com/traefik/traefik/blob/e75250a31ae773e50e9c16514e3aebcb92059042/integration/acme_test.go). Reuse Traefik as a component. Adapt `TestProvider_sanitizeDomains` and renewal failure scenarios as contract tests rather than porting its certificate implementation.

**Remaining custom work:** claim ownership, tenant authorization, DNS propagation state, route activation order, and recovery after an interrupted activation. ACME domain validation and customer account ownership are separate checks. A wildcard claim must not let a second tenant claim a conflicting host without the specified ownership decision.

**Alternatives:** a second ACME library would duplicate Traefik's certificate lifecycle. Vercel's domain API would make hosting depend on a separate Vercel account and service; use its documented behavior as a reference only. A Vercel-specific platform starter would still need its domain-provider calls replaced for the existing Traefik deployment; it does not remove the local claim workflow.

**Validation:** cover simultaneous claims, case/IDNA normalization, expired or replayed TXT proof, CDN routing without ownership, tenant deletion, dangling DNS, renewal failure, and wildcard conflicts. Keep existing domain command-injection tests.

**Product reference:** Vercel documents [TXT ownership claims](https://vercel.com/docs/domains/working-with-domains/claim-domain-ownership). Neon connection hostnames are provider-issued database endpoints; they do not replace application-domain ownership checks.

<a id="t6"></a>
## T6. Public signup and abuse controls

**Classification and rung:** installed auth/email primitives plus gateway controls; conditional hosted CAPTCHA; product-specific admission state.

**Existing targets:** `packages/server/src/lib/auth.ts` `emailVerification`, `emailAndPassword`, and auth hooks; existing email utilities; `apps/dokploy/components/dashboard/onboarding/onboarding-wizard.tsx`; `server/api/utils/plan-limits.ts`. Verification mail and mandatory verification currently depend on `IS_CLOUD`; introduce the plan's explicit hosted mode without changing unrelated self-hosted behavior.

Reuse Better Auth email verification and endpoint rate limiting. Select shared persistence for limits used across control-plane instances, and configure trusted proxy handling. Better Auth documents that server-side `auth.api` calls bypass its client-endpoint limiter; protect the relevant tRPC and internal allocation entry points separately. These rate counters are not the atomic resource quota in T7. [Rate-limit documentation](https://better-auth.com/docs/1.6/concepts/rate-limit)

**Optional service candidate:** Cloudflare Turnstile through the Better Auth CAPTCHA plugin. It requires a service account/terms decision; this audit does not enable it. Verify the chosen release's API because the source pin is newer than installed Better Auth.

**Pinned source and test ports:** BA [`cloudflareTurnstile`](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/plugins/captcha/verify-handlers/cloudflare-turnstile.ts), [CAPTCHA tests](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/plugins/captcha/captcha.test.ts), and [rate-limiter tests](https://github.com/better-auth/better-auth/blob/41b7dc15de41a8726422c392a4857d8764828891/packages/better-auth/src/api/rate-limiter/rate-limiter.test.ts). Reuse the plugin; adapt rate-limit-before-CAPTCHA, provider-failure, missing-token, hostname, and action tests. Follow Cloudflare's [server validation contract](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/) for token expiry and replay.

**Remaining custom work:** no allocation until verified identity plus payment or an approved bounded trial; caps on organizations and concurrent signup operations; abuse restriction reasons that payment or budget recovery cannot erase. Public registration remains open at release. Rate limits, CAPTCHA, and payment eligibility address different conditions.

**Alternatives:** do not write a CAPTCHA solver/challenge system. The existing Better Auth plugin covers the integration that a standalone demonstration would need to duplicate. Adding Redis solely for signup limits is not selected before testing existing database-backed controls. Do not claim client-side widgets alone enforce admission.

**Validation:** concurrent signups, mail failure, resend limits, expired verification, stolen/replayed challenge, proxy header spoofing, provider outage, server-side bypass attempts, and allocation before/after eligibility. Use a test provider response and a real shared limit store; do not send bulk production mail.

**Product reference:** Vercel and Neon provide account/project creation. This service's bounded-trial, payment, and abuse policy remains the original plan's own contract; do not attribute its exact thresholds to either vendor.

<a id="t7"></a>
## T7. Concurrent quota and allocation admission

**Classification and rung:** native PostgreSQL row locks/conditional updates plus existing entitlement entry points. Quota dimensions and release rules are product-specific.

**Existing targets:** `apps/dokploy/server/api/utils/plan-limits.ts`; proposed entitlement/reservation records, `resource-allocation.ts`, and `resource-operation.ts`; current Drizzle transactions. Hosted unknown-plan behavior must deny allocation as specified in the original plan.

Use one transaction to lock the organization's admission record, re-read its current entitlement, reserve all required capacity, and insert the operation/outbox job. Use a unique request/operation key. All writers of the same quota must follow the same lock/order rule. Do not use a read-count-then-insert check across separate transactions.

**Read-before-build reference:** PG [`src/test/isolation/specs/eval-plan-qual.spec`](https://github.com/postgres/postgres/blob/e73841ffbceea314cf9fa3f64a5eae9f87a46449/src/test/isolation/specs/eval-plan-qual.spec) contains concurrent account updates, `RETURNING`, rollback, and update/delete condition rechecks. Port the two-session test pattern into local Vitest integration tests for the last available slot; change the schema/assertions to quota reservations. Use PostgreSQL's [transaction isolation contract](https://www.postgresql.org/docs/18/transaction-iso.html), not queue marketing claims, to select the lock and retry behavior.

**Remaining custom work:** quota units, pending-versus-active reservations, expiration, fenced release, cancellation, stale entitlement handling, and a deterministic lock order for multiple quota records. Admission idempotency must survive job retries and resource deletion. Budget and usage workers use these same reservations; a second reservation ledger in a queue library would create conflicting authority.

**Alternatives:** Better Auth organization limits cover auth entities, not cloud resources. A generic request-rate limiter cannot atomically reserve a VM/database with an operation record. PostgreSQL already provides the necessary concurrency primitive; a distributed lock service is not selected.

**Validation:** two independent database connections request the final slot; one succeeds and one receives quota exhaustion. Test rollback, repeated request IDs, resize reservations, delayed cancellation, double release, stale worker generations, and entitlement changes during admission. Verify that no rejected request creates a cloud operation or billable allocation.

**Product reference:** Vercel [Spend Management](https://vercel.com/docs/spend-management) distinguishes budget controls from fixed charges. Neon [platform provisioning](https://neon.com/blog/provision-postgres-neon-api) exposes project resource controls. Keep admission quotas separate from the measured spend controls in the billing plan.

<a id="t8"></a>
## T8. Customer UI, contract tests, and migration tests

**Classification and rung:** internal components, installed validation/query/chart libraries, and native PostgreSQL test fixtures. No dashboard framework or new ORM is proposed.

**Existing targets:** `apps/dokploy/components/dashboard/organization/handle-organization.tsx`; `dashboard/onboarding/`; `dashboard/settings/billing/show-billing.tsx` and `show-invoices.tsx`; `components/ui/chart.tsx`; `dashboard/application/environment/show-environment.tsx`; existing notifications; `apps/dokploy/drizzle/` and `__test__/vitest.config.ts`.

Reuse organization switching, billing/invoice views, onboarding layout, environment secret controls, TanStack Query/Table, Zod, Recharts, and existing chart primitives. Add usage freshness, units, organization/project filters, retained-storage estimates, and operation states to those components. Keep authorization on the server. Do not add a customer-facing screen for every internal queue or billing record.

**Reference and test ports:** DR [postgres-js integration tests](https://github.com/drizzle-team/drizzle-orm/blob/0fd1cc61f1ff6553234d29042461fc5e9aa551c3/integration-tests/tests/pg/postgres-js.test.ts) include default/custom-schema/custom-table migrator cases. Adapt their create/migrate/assert/cleanup pattern to the installed Drizzle version; keep local Vitest and CI PostgreSQL/Docker setup. BA membership/key tests from T1 and PG RLS/isolation tests from T2/T7 supply concrete authorization and concurrency fixtures.

**Remaining custom work:** the usage/budget data contract, display of delayed or incomplete data, organization-scoped cache keys, migration/backfill assertions, and browser flows specific to this service. Do not port an external admin dashboard merely to obtain charts already installed here.

**Migration validation:** preserve user/member/resource IDs; stop on ambiguous organization ownership; encrypt legacy database credentials; keep user subscriptions marked legacy; prevent one subscription from being copied to several organizations. Re-run migrations on the intended previous schema, verify row counts and constraints, and test rollback of feature activation while retaining accepted usage and provider events.

**UI validation:** switching organizations clears or segregates cached usage, invoices, and secrets; billing members cannot fetch secret values; operation errors and delayed usage are visible; signup reaches app/database creation through public registration. Use the existing test runner and Linux integration environment; add a new test library only for a demonstrated gap.

**Product reference:** Vercel's [usage view](https://vercel.com/docs/pricing/manage-and-optimize-usage) and Neon's [organization model](https://neon.com/docs/manage/organizations) are product references for scope and filters. Do not copy their UI assets or claim their internals are open source.

## Implementation boundaries and remaining decisions

| Decision | Evidence required before selection |
| --- | --- |
| Auth/permission/audit composition | Test existing adapters against the hosted contract. Retain source provenance for the user's deferred launch/funding license review. |
| Native outbox or one PostgreSQL job library | Prove same-transaction enqueue, restart recovery, least-privilege worker roles, version compatibility, and schema upgrade/backup behavior. |
| Better Auth upgrade and organization-owned keys | Test the existing 1.6.23 configuration, selected target release, existing user-key migration, and role semantics. |
| CAPTCHA service and shared rate-limit store | Confirm terms/cost, hosted-mode endpoints, proxy trust, provider failures, and trial admission behavior. |
| Audit retention and encryption-key recovery | Define retained fields, access roles, deletion rules, backup key handling, and a tested restore procedure. |

These decisions do not permit managed database costs above the operated-infrastructure comparison. None requires writing a new authentication engine, database driver, cryptographic cipher, ACME client, chart library, or queue engine before the listed reuse candidates are evaluated.
