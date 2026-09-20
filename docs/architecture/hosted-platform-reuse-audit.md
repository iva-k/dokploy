# Hosted platform reuse audit and implementation guidance

Research date: 2026-09-20.

This audit extends the [hosted platform plan](hosted-platform-plan.md). It covers 26 capability groups across phases A-I. The detailed maps give existing repository targets, third-party source references, source and maintenance evidence, adaptation work, and validation cases:

- [Tenancy and control plane](reuse/tenancy-and-control-plane.md): T1-T8.
- [Database and infrastructure](reuse/database-and-infrastructure.md): D1-D10.
- [Usage and billing](reuse/usage-and-billing.md): B1-B8.

The candidates are proposals. This audit does not adopt dependencies or change the service contract. Per the user's instruction on 2026-09-20, licensing review is deferred until the product launch decision or funding review. Licensing does not determine the technical ranking in this audit. This timing amendment also applies to licensing work mentioned in Phase A of the original plan; its feature text is preserved. Beads epic `DOK-9q8`, its eight child issues, and `DOK-0xv` remain the task authority. Their notes link to this guidance.

## Constraints retained from the platform plan

The first paid release has public self-service signup. The tenant is the existing organization. The customer can deploy applications, create PostgreSQL in the same project, and use an external database. Application isolation remains one organization per VM for the first release.

The default database option remains operated PostgreSQL. A managed provider is eligible only when its total direct cost is equal to or below our own Azure or similar infrastructure for the approved workload and service envelope. Show labor separately. Source availability, a free allowance, or reduced implementation work does not establish cost parity. Use the [database cost fixtures](reuse/database-and-infrastructure.md#d8) and the original plan's four scenarios at 10, 100, and 1000 databases.

Vercel and Neon define feature comparisons, not source-code availability or equivalent service guarantees. Vercel documents [teams](https://vercel.com/docs/accounts), [usage](https://vercel.com/docs/pricing/manage-and-optimize-usage), [spending controls](https://vercel.com/docs/spend-management), and [provider-based PostgreSQL integration](https://vercel.com/docs/postgres). Neon documents [organizations](https://neon.com/docs/manage/organizations), [pooling](https://neon.com/docs/connect/connection-pooling), [database branches](https://neon.com/docs/introduction/branching), and [embedded platform services](https://neon.com/platforms). Each detailed map relates those features to this plan and states the remaining implementation work.

## Reuse method and proposed composition

Use an existing repository function first, then a native feature or installed dependency, then a maintained project. Use a source port only when a package does not fit. A reference identifies behavior and test cases; it does not establish that its code or guarantees can be copied unchanged.

The proposed minimum composition is:

| Area | First candidate | Work retained in this repository |
| --- | --- | --- |
| Identity and tenant access | Existing Better Auth organization and API-key plugins, permission services, Drizzle, PostgreSQL constraints and RLS | Organization-scoped access across every API, job, socket, and linked resource; role and billing separation |
| Cloud and application operations | Existing Dockerode, remote execution, network and Traefik paths; official Azure SDK and Bicep modules; BuildKit | Desired state, organization placement, idempotency, allocation generations, leases, orphan reconciliation |
| Durable execution | Keep the transactional outbox contract; evaluate one PostgreSQL worker package against the current driver and transaction path | Domain operation state and fencing remain local even if a package executes jobs |
| Managed PostgreSQL | PostgreSQL image, PgBouncer, pgBackRest, existing logical export/restore and secret providers | Resource profiles, scoped roles, endpoints, credential rotation, restore authorization and operation state |
| Usage | Native allocation events and exact counters; existing Go collector infrastructure; evaluate collector components only where needed | Stable source identity, immutable usage, completeness, correction and reconciliation rules |
| Billing | Existing Stripe SDK, Checkout, Portal and invoice UI; evaluate the current Stripe/Metronome product fit | Organization mapping, trusted entitlements, durable delivery/inbox, policy and invoice reconciliation |
| Customer UI and tests | Existing forms, tables, charts, notifications, Vitest and Go tests | Usage filters, freshness, retained-storage cost display, negative tenant tests, restart and recovery fixtures |

Do not install every candidate in the maps. Select one implementation per boundary. The audit does not select a second ORM, identity service, analytics cluster, or general pricing engine.

## Capability coverage

Classification: **C** is a commodity capability; **D** is a service-specific rule; **G** is integration code. A mixed entry uses a reusable component for C and defines the remaining D/G work.

| Group and requirement | Class | Proposed reuse and code guidance | Owning phase / Beads issue |
| --- | --- | --- | --- |
| T1 Identity, organizations, roles and API keys | C + D | [Existing Better Auth and role integration](reuse/tenancy-and-control-plane.md#t1) | B / `DOK-9q8.2` |
| T2 Ownership across rows, APIs, jobs and sockets | D + G | [Existing authorization, native RLS, upstream policy tests](reuse/tenancy-and-control-plane.md#t2) | B / `DOK-9q8.2` |
| T3 Durable operations, outbox and schedules | C + D | [Worker package comparison and transaction adapters](reuse/tenancy-and-control-plane.md#t3) | C / `DOK-9q8.3` |
| T4 Secrets, key recovery and audit events | C + D | [Existing encryption, vault and audit paths](reuse/tenancy-and-control-plane.md#t4) | A, B, E / `DOK-9q8.1`, `.2`, `.5` |
| T5 Custom domains, ownership and TLS | C + D | [Existing Traefik/domain code and proof-of-ownership guidance](reuse/tenancy-and-control-plane.md#t5) | C / `DOK-9q8.3` |
| T6 Public signup and abuse controls | C + D | [Existing email verification and Better Auth controls](reuse/tenancy-and-control-plane.md#t6) | G / `DOK-9q8.7` |
| T7 Concurrent resource admission | D + G | [PostgreSQL quota reservations and race tests](reuse/tenancy-and-control-plane.md#t7) | C, F, G / `DOK-9q8.3`, `.6`, `.7` |
| T8 UI, contract and migration tests | C + D | [Installed UI/test tools and source test patterns](reuse/tenancy-and-control-plane.md#t8) | B, G, H / `DOK-9q8.2`, `.7`, `.8` |
| D1 PostgreSQL process and image lifecycle | C + G | [Existing database deployment and official image](reuse/database-and-infrastructure.md#d1) | E / `DOK-9q8.5` |
| D2 Pooling and database credentials | C + D | [PgBouncer and scoped role/secret integration](reuse/database-and-infrastructure.md#d2) | E / `DOK-9q8.5` |
| D3 Physical backup, PITR and retention | C + D | [pgBackRest and existing logical exports](reuse/database-and-infrastructure.md#d3) | E / `DOK-9q8.5` |
| D4 External databases and embedded Neon | C + G | [Standard connection secrets and conditional provider adapter](reuse/database-and-infrastructure.md#d4) | A, E / `DOK-9q8.1`, `.5` |
| D5 Tenant VM lifecycle | C + D | [Official Azure modules/SDK and local resource operations](reuse/database-and-infrastructure.md#d5) | C / `DOK-9q8.3` |
| D6 Disposable application builds | C + D | [BuildKit and current builder integration](reuse/database-and-infrastructure.md#d6) | C / `DOK-9q8.3` |
| D7 Networks and runtime resource limits | C + D | [Existing Docker network/resource paths and cloud controls](reuse/database-and-infrastructure.md#d7) | C, E / `DOK-9q8.3`, `.5` |
| D8 Equal-workload database cost comparison | D + G | [Vendor price inputs and native PostgreSQL workload fixtures](reuse/database-and-infrastructure.md#d8) | A / `DOK-9q8.1` |
| D9 CDN and later function/edge runtime | C + D | [Established delivery/runtime candidates](reuse/database-and-infrastructure.md#d9) | I / `DOK-0xv` |
| D10 Later database preview copies | C + D | [Restore/copy tools and preview lifecycle references](reuse/database-and-infrastructure.md#d10) | I / `DOK-0xv` |
| B1 Billing account, Checkout, Portal and invoices | C + D | [Existing Stripe integration and UI](reuse/usage-and-billing.md#b1) | F / `DOK-9q8.6` |
| B2 Meter collection and durable delivery | C + D | [Go collector, native counters and collector candidates](reuse/usage-and-billing.md#b2) | D / `DOK-9q8.4` |
| B3 Ledger, correction, reconciliation and close | D + G | [Pinned metering implementations and test cases](reuse/usage-and-billing.md#b3) | D, F / `DOK-9q8.4`, `.6` |
| B4 Exact quantities, allowances and rating | C + D | [Native integer/numeric arithmetic and billing references](reuse/usage-and-billing.md#b4) | A, D, F / `DOK-9q8.1`, `.4`, `.6` |
| B5 Provider events, invoice delivery and lifecycle | C + D | [Stripe SDK and signed webhook/replay references](reuse/usage-and-billing.md#b5) | F / `DOK-9q8.6` |
| B6 Entitlements, spend limits and suspension | D + G | [Admission/entitlement examples and local policy](reuse/usage-and-billing.md#b6) | F, G / `DOK-9q8.6`, `.7` |
| B7 Usage display and paid public onboarding | C + D | [Current charts/forms and Vercel/Neon behavior references](reuse/usage-and-billing.md#b7) | G / `DOK-9q8.7` |
| B8 Billing cost inputs and release evidence | D + G | [Provider test tools and reconciliation fixtures](reuse/usage-and-billing.md#b8) | A, H / `DOK-9q8.1`, `.8` |

## Internal reuse findings

The source review found eight groups that can be extended before a replacement is considered:

1. Better Auth already supplies organization membership and API keys.
2. Permission services and WebSocket authorization provide existing access-check integration points.
3. Dockerode, remote execution, network services and Traefik already implement deployment and routing primitives.
4. PostgreSQL deployment, logical backup and restore already exist.
5. Encryption, encrypted database fields and vault providers already exist.
6. Stripe Checkout, Portal, invoices and billing UI already exist.
7. Organization/onboarding screens, tables, charts and notifications already exist.
8. Vitest fixtures, permission/API-key/queue tests, and the Go monitoring application already exist.

These are partial coverage findings. For example, DNS routing checks do not prove tenant domain ownership; current user-linked Stripe records do not meet organization billing; and the operational collector's service de-duplication and formatted floating-point statistics cannot be used unchanged for invoices. The detailed maps identify each gap.

## Whole-platform alternatives and additional test ports

The audit also checked broader projects before proposing local service-specific code.

| Project and evidence | Fit decision for this plan |
| --- | --- |
| [Coolify at `89e8506`](https://github.com/coollabsio/coolify/tree/89e8506023af83016e3ccd64dc1327f51a7f8674), commit dated 2026-09-19 | Use selected backup and tenant-access test cases as port candidates. Its PHP/Laravel application is a different control plane. Replacing this TypeScript application would also require migration of existing auth, deployments and billing. It is not the proposed whole-service replacement. |
| [CapRover at `43f9980`](https://github.com/caprover/caprover/tree/43f998061ec95bb69835ad3824543242534438f9), commit dated 2026-09-19 | Use selected TypeScript/Dockerode functions and tests as references or port candidates below. The existing repository already has deployment primitives; a second complete control plane would duplicate those paths. Its platform-domain check does not supply organization-bound ownership. |
| [Supabase at `2a75ff7`](https://github.com/supabase/supabase/tree/2a75ff7ae6e0059b34f2c242febd2916d17fc5de), commit dated 2026-09-19 | Its [self-hosting documentation](https://supabase.com/docs/guides/self-hosting) describes a single project and excludes the managed platform's branching, managed backups/PITR and management API. The complete stack is not a reusable multi-tenant database control plane for this plan. Evaluate individual components for the missing behavior. |
| OpenMeter, Lago and Kill Bill | See the [metering and billing comparison](reuse/usage-and-billing.md#b3). Their service models and dependencies must fit before whole-product reuse. A source reference does not require deploying the full product. |

Additional Coolify test-port candidates use the pinned source above:

| Source | Local adaptation | Required difference or limit |
| --- | --- | --- |
| [`ScheduledDatabaseBackup::ownedByCurrentTeamAPI`](https://github.com/coollabsio/coolify/blob/89e8506023af83016e3ccd64dc1327f51a7f8674/app/Models/ScheduledDatabaseBackup.php) and [`TeamScopedBackupStorageTest.php`](https://github.com/coollabsio/coolify/blob/89e8506023af83016e3ccd64dc1327f51a7f8674/tests/Feature/TeamScopedBackupStorageTest.php) | Translate the two-team fixtures to existing Vitest/Drizzle tests. Exercise another organization's backup ID on move, disable, export and restore; verify that the stored row is unchanged. Target the proposed `managed-postgres.test.ts` and tenant-isolation tests. | Use authenticated `organizationId` and the full project/environment relation. Do not copy Laravel or assume a team-scoped query alone covers linked resources. |
| [`BackupRetentionAndStaleDetectionTest.php`](https://github.com/coollabsio/coolify/blob/89e8506023af83016e3ccd64dc1327f51a7f8674/tests/Feature/BackupRetentionAndStaleDetectionTest.php) | Adapt overlap, expired execution, recent execution, storage deletion failure and retention cases into database operation tests. | Keep pgBackRest responsible for physical/WAL retention. Apply our last-valid-backup and suspension policy. Do not port its floating-point storage casts into billable records. |
| [`RestoreJobFinishedShellEscapingTest.php`](https://github.com/coollabsio/coolify/blob/89e8506023af83016e3ccd64dc1327f51a7f8674/tests/Unit/RestoreJobFinishedShellEscapingTest.php) | Reuse the hostile path/container-name case categories in the existing restore command tests. Use literal arguments or an existing command-escaping utility. | Port the cases to the actual Node/SSH execution boundary. A test of PHP `escapeshellarg` is not proof of our command safety. |

These are proposed ports of behavior and tests. No source code is copied in this audit.

Additional TypeScript examples from CapRover `43f9980`:

| Source | Local adaptation | Boundary that remains local |
| --- | --- | --- |
| [`DockerApi.updateService` and `ensureServiceConnectedToNetwork`](https://github.com/caprover/caprover/blob/43f998061ec95bb69835ad3824543242534438f9/src/docker/DockerApi.ts) | Compare service inspection, update-version handling, network attachment and registry authentication with our existing Dockerode utilities before adding another helper. | Organization placement, desired generation, retry classification and resource-operation fencing still require our contract and tests. The upstream in-process methods are not a durable operation system. |
| [`ensureAppsExist`](https://github.com/caprover/caprover/blob/43f998061ec95bb69835ad3824543242534438f9/src/routes/user/apps/appdefinition/AppDefinitionRouter.ts) and [`AppDeletion.test.ts`](https://github.com/caprover/caprover/blob/43f998061ec95bb69835ad3824543242534438f9/tests/AppDeletion.test.ts) | Adapt the all-input validation and inherited-object-key cases to bulk resource operations in Vitest. | Query authenticated organization ownership for every ID before mutation, and verify no side effects on a mixed authorized/unauthorized request. Existence alone is insufficient. |
| [`DomainResolveChecker.verifyCaptainOwnsDomainOrThrow`](https://github.com/caprover/caprover/blob/43f998061ec95bb69835ad3824543242534438f9/src/user/system/DomainResolveChecker.ts) | Reference the generated challenge and exact-response checks when defining domain verification tests. | This checks routing to the platform. Add organization-bound DNS ownership proof, expiry and transfer rules from T5; do not port the bypass option or treat platform routing as customer ownership. |

## Implementation handoff

Follow the original phase dependencies. Add these reuse checks to each phase's existing acceptance work; do not start all candidate integrations together.

| Phase | Reuse decision or implementation boundary | Evidence required before its existing gate can pass |
| --- | --- | --- |
| A | Record the technical component composition, one job execution choice, billing provider fit, database backend cost result and priced workload | ADR with selected versions, dependency/operating cost, source references and rejected alternatives; no assumed managed-provider parity |
| B | Extend Better Auth, current services and native tenant constraints | Two-organization allow/deny fixtures, pooled-connection RLS reset, jobs/sockets/API keys and owner lifecycle |
| C | Use vendor provisioning and build tools; integrate durable jobs with the same transaction as admission/outbox | Driver-level atomic enqueue proof, duplicate/restart/fencing cases, VM/network isolation, orphan reconciliation and concurrent reservation |
| D | Extend reliable source collection; define only the service-specific event and reconciliation contract locally | Full replay, two replicas, counter reset, gaps, corrections, exact totals and no duplicate billable boundary |
| E | Configure database/pool/backup engines and reuse existing service boundaries | Direct/pooled access, scoped roles, rotation, export, tenant-denied restore, host-loss recovery, disk/connection failure and retention |
| F | Upgrade/use the supported provider SDK; extend local billing ownership and event storage | Duplicate/out-of-order webhook tests, crash after provider acknowledgement, test invoices and trusted entitlements |
| G | Reuse current UI/auth/notification components; integrate the budget policy | Public signup before resource allocation, cost freshness, race-safe quotas, measured stop delay, separate suspension causes and retained-storage display |
| H | Reuse installed tests, migration tools and provider test facilities | Original release evidence, including a simulated cycle and 14 days of internal live shadow measurement; package tests alone do not satisfy this gate |
| I | Reuse a CDN/runtime and database copy tools only after the later feature contract is defined | Separate CDN and execution meters, sandbox and regional database tests, preview cleanup/costs; no promise of Neon copy-on-write behavior |

## Open technical decisions and source-port rules

The remaining technical decisions are the durable worker choice, whether collector components justify another service, the current Stripe/Metronome account/product fit, and the database cost comparison. Later runtime and preview decisions stay with `DOK-0xv`. Candidate versions in source links are research pins, not approved deployment versions. The license review is separate and deferred as stated above; it is not a prerequisite for this technical selection.

For each adopted package or port, the implementation change must record:

1. The source commit or package version, exact files/symbols and the upstream source link.
2. Whether the component is used unchanged, wrapped, or ported; the local destination and behavior that remains service-specific.
3. The adapted tests and our additional tenant, replay, accounting and recovery cases.
4. The update path and local changes that must be checked when the upstream version changes.

Check supported Node/PostgreSQL versions and relevant published security fixes at implementation time. A recent commit supplies maintenance evidence. It does not establish a security review, production readiness, performance, or a support commitment. Keep source provenance with any later port so the separate licensing review can identify it.

No product code, dependency manifest, cloud resource, payment account or selling price is changed by this audit.
