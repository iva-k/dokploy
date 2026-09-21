# Hosted platform implementation-agent prompt

Copy the instructions below into the implementation agent. Read live Beads records before work. This document defines the execution contract; it does not store task progress.

## Objective and authority

Implement the first paid public self-service release in [the platform plan](hosted-platform-plan.md), phases A-H, under epic `DOK-9q8`. Use the [reuse audit](hosted-platform-reuse-audit.md) and its source/test maps. Complete one ready, bounded Beads task at a time. Phase I under `DOK-0xv` contains later design and feasibility tasks; it does not block the first release and does not authorize those later production features.

Read the current `AGENTS.md`, `D:/Dev/Personal/Tools/Skills/DEVELOPMENT.md`, the project Beads skill, and the applicable task and parent acceptance criteria. Use the shared development workflow and applicable verification/review procedures. Use simple technical English. Beads is the only authority for mutable tasks, dependencies, ownership, blockers, notes, and closure. Do not create a Markdown progress ledger or use an executor that requires one. Use inline execution or bounded delegation where authorized, with complete Beads briefs and evidence.

The planning baseline is commit `06a14eb130684f1ac9c66dce42de890eb6616184` on `canary`. The task breakdown and this prompt were added after that revision. Inspect the current checkout and changes before work; do not reset it to the planning baseline. No hosted feature is proved complete by these planning artifacts.

The authorized Git destination is `https://github.com/iva-k/dokploy.git`. The user explicitly excluded the original Dokploy project. Verify fetch and push URLs before every publication. Never push to `upstream` or `Dokploy/dokploy`. Earlier authorization covers committing and pushing this planning work; apply the active implementation request to later code publication. A push to `canary` can start the existing Azure test-deployment workflow. Do not infer permission for purchases, new paid accounts, live payment collection, public launch, or destructive operations from a task record. Preserve explicit authorization already given.

## Start from the task graph

Run from the repository root:

```powershell
git status --short
git log -1 --oneline
git remote -v
bd prime
bd ready
bd ready --parent DOK-9q8 --label hosted-leaf --json
```

Inspect a ready leaf with `bd show <id>`, then claim it with `bd update <id> --claim`. Read its dependencies and parent before editing. At creation, the two ready leaves are `DOK-9q8.1.1` (A1, service and meter contract) and `DOK-9q8.1.3` (A3, transactional worker feasibility). This is an initial graph fact, not a persistent ready-work list. Re-query Beads on every continuation.

| Phase gate | Leaf scope |
| --- | --- |
| `DOK-9q8.1` | A1-A6: service contract, repeatable database cost fixtures, worker feasibility, billing feasibility, measured database comparison, final decisions |
| `DOK-9q8.2` | B1-B6: hosted mode and real PostgreSQL tests, roles, owned queries/RLS, API/job/socket checks, owner lifecycle, secrets/audit |
| `DOK-9q8.3` | C1-C6: admission and operations, application VMs, isolated builds, limits/leases, domains/TLS, application reconciliation |
| `DOK-9q8.4` | D1-D5: usage ledger, compute/build collectors, storage/transfer collection, exact aggregation, reconciled period close |
| `DOK-9q8.5` | E0-E7: database capacity, creation, connections, secret binding, backups, restore/export, lifecycle, customer screens |
| `DOK-9q8.6` | F1-F5: organization billing account, provider inbox, usage delivery, entitlement projection, payment lifecycle |
| `DOK-9q8.7` | G1-G4: usage/invoice screens, budgets, public signup, complete application/database journey |
| `DOK-9q8.8` | H1-H6: migration rehearsal, fork CI, isolation/recovery drills, live shadow run, candidate review, authorized launch |
| `DOK-0xv` | I1-I4: later CDN/regions, function runtime, preview copies, database scaling/availability designs |

There are 46 A-H leaves and 4 later leaves. All have the `hosted-leaf` label. The phase records are acceptance gates, not duplicate implementation tasks. Existing phase dependencies remain in force; leaves also have explicit prior-phase blockers. A phase gate may close only after every child is closed with evidence and the phase's own acceptance criteria pass. Parent-child links alone do not prove this condition. Never close a phase to expose blocked leaves early. Do not add a blocking cycle between a parent and its children.

## Constraints to preserve

- Public self-service signup is part of the first paid release. Account and empty-project creation need not allocate compute. Allocation requires verified identity, accepted payment setup or a bounded trial, and admission checks.
- Reuse existing organizations, Better Auth, services, deployment utilities, UI components and tests. Follow the selected reuse map before writing code. Install only selected components. For a port, record upstream commit, file/symbol, local destination, changes, adapted tests, and update method. Check current version compatibility and relevant security fixes when adopting a component. Do not repeat the whole reuse survey.
- Licensing review is deferred by the user to the launch decision or fundraising. It is not a coding or technical-selection prerequisite. Keep source provenance for that separate review.
- Use one organization VM boundary for application execution. Keep the control plane, disposable builds, and database capacity separate. Deny host administration, privileged containers, arbitrary host mounts, raw Compose, and customer access to infrastructure credentials in hosted mode.
- Use operated PostgreSQL unless a managed provider passes the measured total-direct-cost gate at comparable service requirements in all required scenarios. Compare 10, 100, and 1000 databases across all four plan scenarios; show labor separately. Implement only the selected backend. Preserve ordinary external-database connections and self-hosted behavior.
- Provide standard PostgreSQL, direct and pooled TLS URLs, scoped roles, fixed sizes, secret injection/rotation, backup/restore, and logical export/import. Use the selected engine, PgBouncer and pgBackRest/provider facilities. Do not build a storage or backup engine. Shared database hosts require the specified isolation evidence; otherwise use the per-tenant database VM fallback and repeat its cost comparison.
- The proposed recovery target is 7 days of history, RPO at most 5 minutes, and RTO at most 60 minutes for up to 20 GiB. Restore into a separate instance. Keep the last valid backup while a database is retained. A single primary does not establish automatic HA.
- Keep exact usage evidence separate from estimates, quotas and payment state. Count every replica/generation; bill transfer at one boundary. Do not bill unsupported estimates. The proposed period-close window is 48 hours, subject to Phase A's recorded contract and provider limits.
- Keep billing on the organization. Preserve the proposed 72-hour payment grace and 30-day suspension retention unless Phase A records an approved change. A payment event clears only the payment restriction. Preserve export/recovery access and disclosed retained-storage charges.
- Budget alerts are 50%, 80%, and 100%, with stop by default for new public accounts. Reconcile at least every minute; collector staleness over 5 minutes denies growth and allows bounded leases to expire. Publish measured stop delay/overshoot. A variable-use budget is not an unconditional cap on the whole invoice.
- Phase A must supply unresolved region, currency, prices, supported sizes, worker/backend/provider choices, limiter/proxy/bot-check policy, and enforcement bounds. Do not invent approved rates, measured cost parity, or account capabilities. Mark only dependent work blocked and continue other ready work.

Use Vercel as the feature reference for teams, projects, deployments, usage, spend controls, CDN and functions. Use Neon as the reference for PostgreSQL connections, recovery, previews and later scaling. Keep the dated links in the platform plan and reuse maps; verify current official documentation when an implementation decision depends on it. State the supported behavior and differences explicitly. A full database copy does not establish Neon copy-on-write branching, and a CDN does not establish edge code execution.

## Shared implementation ownership

Read the producer task and its accepted interface before implementing a consumer. Change a shared interface in its owning task or a linked correction task, with affected consumers recorded in Beads.

| Owner | Contract |
| --- | --- |
| B1, `DOK-9q8.2.1` | Explicit hosted mode and real-PostgreSQL integration/coverage harness. The policy mutation check is fixture-only; B3 owns service RLS. |
| C1, `DOK-9q8.3.1` | Atomic entitlement/admission and quota reservation, durable resource operations, generations/fencing, transactional dispatch. F/G reuse this authority. Unknown production entitlement denies allocation. |
| C2, `DOK-9q8.3.2` | Application VM lifecycle and provider/bootstrap primitives. |
| C5, `DOK-9q8.3.5` | Domain ownership/TLS and the first minimal browser test harness. E/G/H extend that harness. |
| E0, `DOK-9q8.5.1` | Selected database capacity, private target readiness, placement reservations and host replacement. E1 consumes it. |
| E2/E3, `DOK-9q8.5.3` / `DOK-9q8.5.4` | E2 supplies private endpoints, roles and secret references. E3 owns customer connection reveal, application binding and rotation. |
| D1, `DOK-9q8.4.1` | Authenticated immutable usage and transactional outbox. Identity includes organization, source, epoch, sequence, meter, resource ID and generation. |
| D5, `DOK-9q8.4.5` | Reconciled period-close batches and late-usage policy. No provider delivery or 14-day acceptance claim. |
| F1/F2/F3, `DOK-9q8.6.1` / `.2` / `.3` | Organization billing ownership; durable provider inbox/current state; closed-batch delivery and invoice reconciliation. |
| F4, `DOK-9q8.6.4` | Trusted billing state projected into C1's entitlements. F5 schedules payment lifecycle operations. |
| G2, `DOK-9q8.7.2` | Budget reservations/restriction causes and stop/resume through C1, C4 and the resource lifecycle. |

Accept delayed usage from an older generation when the immutable allocation or tombstone and observation interval prove its identity. Reject forged attribution through a reused resource name. Replays after deletion or resize must not disappear from accounting.

The existing `getMountPath` already handles PostgreSQL 18 paths. Extend and test it. Do not treat a generic Docker update error as evidence that a resource is absent. The existing encrypted-text reader can return its raw stored value on decrypt failure; hosted secret reads must fail closed, with an explicit legacy migration path.

## Task execution and closure

1. Inspect the task, parent, prerequisites, current code, interfaces, tests and selected reuse references. Identify existing code to extend and the required behavior. Record a short implementation/check approach in the claimed Bead. Proposed file names are targets; adapt them to verified repository structure without changing the contract.
2. Implement the complete bounded slice and relevant tests. Preserve tenant checks in synchronous and asynchronous paths. Do not add placeholder handlers, duplicate frameworks, a second generic pricing engine, or unused backend adapters. Record discovered work as linked Beads issues; do not hide incomplete acceptance behind a follow-up.
3. Test the required success, denial, concurrency, crash/retry, stale-state and recovery cases for that task. Use actual PostgreSQL for transactions, RLS, constraints and worker/outbox behavior. Use authorized infrastructure/provider fixtures where acceptance requires them. A mocked adapter proves only its local contract.
4. Run narrow checks first, then the task's required builds, coverage and final checks. Inspect the diff and generated artifacts. Review against `AGENTS.md`, accepted contracts and reuse choices. Obtain the required independent review, resolve findings, and rerun invalidated checks. Preserve valid evidence only for the same applicable source and environment.
5. Save revision-bound verification evidence and link it in the task. State any unavailable provider, infrastructure or live check. Close with `bd close <id>` only after all acceptance and required checks pass. If a required input is absent, keep the task open, record the exact blocker/next action, and work on another ready task.
6. Re-query the graph. When all leaves in a phase pass, review its original acceptance criteria and close the phase gate with linked evidence. H5 requires final candidate review. H6 requires the authorized public cutover and live acceptance; technical readiness alone does not close it or the root epic.

The default `apps/dokploy/__test__/setup.ts` mocks `@dokploy/server/db`. B1 must add a separate real-PostgreSQL configuration. The following real-database invocation is a proposed command until B1 delivers it:

```powershell
pnpm --filter=dokploy exec vitest --config __test__/vitest.integration.config.ts --run
```

Use the exact narrower paths and coverage flags in each Bead. Require full coverage of new domain lines, statements, functions and branches, with explicit adverse-case tests. Coverage totals alone do not prove tenant isolation or invoice correctness. Run applicable final checks from the repository root:

```powershell
pnpm server:build
pnpm --filter=dokploy run test --run
pnpm typecheck
pnpm build
pnpm format-and-lint
```

For collector changes, run Go tests, coverage and build from `apps/monitoring`. Add a browser runner only in its owning task if the inspected checkout still lacks one. Retain exact commands, working directories, exit codes and artifacts. Do not claim an unavailable Linux, PostgreSQL, browser, cloud or provider test passed.

For H4, run both the simulated billing cycle and 14 actual days of internal live shadow measurement. Clock simulation does not replace elapsed observation. For E/H restore gates, distinguish seeded historical fixtures from actually aged retention evidence. Use the specified setup, workload, failure, result and cleanup procedures in those Beads. Never bill customers to obtain shadow evidence.

## Verification record

Store immutable evidence under a task/candidate path, for example `docs/evidence/hosted/<task-id>/<candidate>/verification.json`, and link it from Beads. This is a verification artifact, not a mutable task ledger. Use the following machine-readable fields with actual values:

| Field | Required value |
| --- | --- |
| `task_id`, `base_revision`, `final_revision` | Canonical Bead and exact tested source revisions; include a diff hash/manifest if the tested tree was uncommitted |
| `changed_files`, `environment` | File list, OS/runtime/database/provider versions and fixture identity; no credentials |
| `checks` | Array of command, working directory, result, exit code, timestamp and artifact link |
| `coverage` | New-domain scope, line/statement/function/branch results and report links |
| `review` | Reviewer/method, reviewed candidate, findings, dispositions and final review artifact |
| `reuse` | Selected source versions/symbols, local use or port, additional tests and update boundary |
| `decisions`, `deviations` | Durable decision references and any approved contract changes |
| `limitations`, `unverified` | Specific missing evidence and claims that the record cannot establish |

Do not include secrets, raw customer data or payment details. Keep live status, next task, blockers and resume instructions in Beads. An evidence-only commit after the tested source commit must identify the tested code revision; do not imply that tests ran on a later untested change.

## External inputs and acceptance

Obtain only inputs needed by ready work. Do not request resource provisioning before its design and authority decisions are resolved.

| Input | Owner action and verification |
| --- | --- |
| A1/A6 commercial and service decisions | Product owner supplies region, currency, price/allowance approval and bounded trial/service terms. Agent records the accepted profile and unresolved consumers. |
| A4/F provider test access | Operator supplies the selected test account through the approved secret channel. Existing Stripe names are `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`; never store values in Beads. Verify test mode, supported APIs, signatures and provider timestamp/correction windows. |
| A5/B1/C/E fixture infrastructure | Operator supplies an authorized Linux/PostgreSQL/Docker or cloud fixture with the selected scope, quotas and cost limit. Verify real database connectivity, identity, network controls and cleanup. Use isolated fixtures; do not alter production to satisfy a test. |
| G3 public onboarding services | A6 selects the rate-limit store, proxy trust and bot check. Operator configures any selected service/account; G3 verifies rate limits and outage behavior. |
| E/H recovery and operations | Operator supplies approved backup destinations, scoped credentials, recovery-key access and on-call ownership. Verify real restore and control-plane recovery without exposing secrets. |
| H6 public release | Product/operator owner supplies launch authorization and the release configuration. The agent verifies H1-H5 evidence, runs the cutover/rollback procedure and records live acceptance. Leave H6 open if this input is missing. |

At the planning baseline, Azure test deployment passed in [run 35479247301](https://github.com/iva-k/dokploy/actions/runs/35479247301). Other fork automation runs failed. H2 owns the current fork CI review and repairs. That earlier Azure result proves neither the new hosted features nor a later candidate. Inspect fresh checks before release; distinguish workflow configuration, local validation, remote CI, staging and public launch.

Before an authorized Git commit that includes task changes, run `bd export -o .beads/issues.jsonl`. The export is a passive snapshot. A Git push does not synchronize the live embedded Dolt database; do not configure a Beads remote or run remote Dolt synchronization. Preserve unrelated work and existing task ownership.

Return the completed task IDs, concrete changes, actual verification/review results, evidence links, unresolved inputs and next ready Bead. Distinguish implemented code, configured resources, local tests, CI, live acceptance and release. Continue authorized ready work until the requested scope is complete or a specific required input blocks all remaining work.
