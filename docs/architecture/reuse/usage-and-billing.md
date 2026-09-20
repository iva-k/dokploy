# Reuse audit: usage, billing, and spending controls

Research date: 2026-09-20. Scope: phases A, D, F, G, and H of the [hosted platform plan](../hosted-platform-plan.md).
Beads references: `DOK-9q8.1`, `DOK-9q8.4`, `DOK-9q8.6`, `DOK-9q8.7`, and `DOK-9q8.8`.
This document adds reuse proposals and source examples. It does not adopt a dependency, approve a provider, or report implementation.

Use existing PostgreSQL, Drizzle, the Stripe SDK, SQLite, and UI components first.
The remaining product code connects verified resource intervals, organization ownership, provider delivery, and resource stop operations.
A new general billing engine is not required by the launch contract.

## Candidate and source register

Revisions below were checked against the primary repositories. They are research pins, not recommended production versions.
Commit activity is maintenance evidence; it is not a security audit or an availability guarantee.
Before adoption, select a supported release, inspect its dependency tree and advisories, and record the version.

| Candidate | License and maintenance evidence | Fit, weight, and proposal |
| --- | --- | --- |
| Installed Stripe Node SDK | MIT; repository commit 2026-09-17; inspected version 22.6.2 at [S1]. Local version is 17.2.0. | Reuse the SDK and upgrade through migration tests. Do not copy its HTTP, signature, retry, or API serialization implementation. |
| OpenTelemetry Collector Contrib | Apache-2.0; commit 2026-09-19 at [O1]. Docker Stats receiver is marked alpha; file storage is beta. | Optional complete worker telemetry agent. Adds a daemon and configuration. It does not provide the planned financial ledger. |
| cAdvisor | Apache-2.0 in the actual [license file][C1-license] and inspected Go headers; commit 2026-09-09 at [C1]. GitHub license metadata returned NOASSERTION. | Alternative complete container observer. Do not add both observers without a measured need. Host/container access requires the same trusted-worker boundary. |
| OpenMeter | Apache-2.0 in [license][M1-license]; commit 2026-09-17 at [M1]. | Closest full metering/entitlement service candidate. Its [development composition][M1-compose] includes Kafka and ClickHouse, with further Redis/PostgreSQL profiles and integrations. Evaluate operational cost before adoption. Use bounded source/test references if that service is not justified. |
| Kill Bill | Apache-2.0 in [license][K1-license] and inspected Java headers; commit 2026-08-20 at [K1]. | Complete subscription/invoice service candidate. Its Java service, catalog, persistence, and provider integration would overlap the existing Stripe path. Prefer its interval/catalog tests as references for the launch scope. |
| Lago | AGPL-3.0 in [license][L1-license]; deployment and API commits 2026-09-18 at [L1] and [L2]. | Strong full metering/billing candidate with PostgreSQL event storage and weighted aggregation. Its Rails API, Redis/Sidekiq workers, and billing service add operational scope. Benchmark complete deployment against the simple provider path; use the PostgreSQL query and tests below for focused adaptation if not adopted. |
| Stripe Metronome | Managed service; [current Stripe integration guidance][stripe-choice]. | Current vendor recommendation for new usage integrations. Obtain account eligibility, total fees, event/correction limits, and Checkout/Portal compatibility evidence in phase A. No cost or account access is assumed. |
| PostgreSQL and SQLite | Already used. PostgreSQL has exact numeric types and transaction/locking primitives; SQLite has atomic transactions. [Numeric][pg-numeric], [locking][pg-locks], [SQLite atomic commit][sqlite-atomic]. | Reuse as storage primitives. No additional ledger or decimal package is proposed for the initial contract. Existing `go-sqlite3` uses the [MIT license][sqlite-wrapper]. |

The user defers license review until launch or a funding decision. No candidate is excluded in this audit because of its license, and licensing is not a phase A gate here.
Record source commits, file paths, and stated licenses as provenance for that later review.
The OpenMeter files named below are under its root license; no narrower license file was found in those source directories.
Its separate collector and generated-client license files are separate provenance records.
The referenced Stripe files use its root MIT license; the OpenTelemetry and cAdvisor source/test headers state Apache-2.0.
Product documentation supplies behavior comparisons; the pinned repository files supply implementation examples.

<a id="b1"></a>
## B1. Extend the existing billing and UI code

Classification: existing code plus organization-specific integration. Recommended rung: internal reuse.

| Existing entry point | Reuse | Required adaptation |
| --- | --- | --- |
| [billing.ts](../../../apps/dokploy/server/utils/billing.ts), `getStripeClient`, `getCurrentPlan`, `getBillingStatus` | SDK setup, provider queries, trial display inputs. | Replace the organization-to-owner-user payment lookup with one billing account per organization. Keep the legacy migration path explicit. The current helper imports the proprietary organization-owner module; that source is included in reuse scope under the deferred license review. |
| [stripe.ts router](../../../apps/dokploy/server/api/routers/stripe.ts), `createCheckoutSession`, portal and invoice handlers | Checkout, hosted Portal, and invoice retrieval. | Resolve organization permissions and a trusted price mapping before provider calls. A browser return or unchecked metadata cannot grant entitlement. |
| [webhook.ts](../../../apps/dokploy/pages/api/stripe/webhook.ts) | Raw request body and `stripe.webhooks.constructEvent`. | Persist a verified event before acknowledgement, then process it through the durable inbox. Current direct mutations do not provide that inbox. |
| [plan-limits.ts](../../../apps/dokploy/server/api/utils/plan-limits.ts) | Existing resource-limit call sites and error shape. | Replace count-then-admit checks with transactional reservations for hosted resources. Current null-plan fallback selects legacy/unlimited limits; it cannot be the hosted default. |
| [billing components](../../../apps/dokploy/components/dashboard/settings/billing/), [onboarding wizard](../../../apps/dokploy/components/dashboard/onboarding/onboarding-wizard.tsx), [trial banner](../../../apps/dokploy/components/dashboard/billing/trial-banner.tsx) | Invoice rows, Portal entry, onboarding steps, trial state display. | Bind all reads to the selected organization and add freshness, actual units, continued storage, and stop-state text. Reuse installed Recharts and existing table/form components. |
| [stripe-notifications.ts](../../../apps/dokploy/server/utils/stripe-notifications.ts) and existing notification services | Invoice and payment-failure email delivery. | Add an organization recipient policy and durable notification identity. Payment, budget, and abuse restrictions remain separate causes. |

Do not build a card form, invoice PDF renderer, payment retry engine, or customer billing portal while the selected provider supplies them.
Preserve access to invoices and recovery/export functions during the applicable suspension period.
Validation belongs in the planned organization billing, provider event, entitlement, and browser tests.

<a id="b2"></a>
## B2. Reuse collection primitives; keep invoice evidence separate

Classification: commodity observation and persistence, plus resource-specific interval rules.
Recommended rung: existing lifecycle/Docker/SQLite facilities; optional complete telemetry agent.

The [Go monitor](../../../apps/monitoring/containers/monitor.go) calls formatted `docker stats`, parses floats, and keeps only the first container for each service name.
Its `seenServices` behavior omits other replicas. Its display samples cannot establish allocated capacity intervals or durable billable delivery.
Keep this code for current charts until their requirements change.

The [monitor database](../../../apps/monitoring/database/db.go) already opens SQLite through `mattn/go-sqlite3`.
Reuse that driver and standard `database/sql` transactions for a separate durable spool.
Store exact quantity strings or bounded integers; never use SQLite REAL for byte-time totals.
Persist source epoch, sequence, payload, and pending-delivery state before acknowledgement.
Define disk limits, busy handling, durable commit settings, recovery, and retention independently of monitoring sample cleanup.
A new queue engine or a custom WAL file format is not required to obtain these primitives.

| Candidate or reference | Exact source and test | Adaptation and limit |
| --- | --- | --- |
| OpenTelemetry Docker Stats receiver | [receiver.go][O1-receiver], [receiver_test.go][O1-tests], including `TestScrapeV2`, `TestScrapeV2Streaming`, and `TestRecordBaseMetrics`; [cgroup-v2 fixtures][O1-fixtures]. | Prefer the complete agent if required. For the existing Go worker, port only needed fixture cases and inspect raw counter handling. Add platform-controlled resource identity, replica/generation, reset, and interval tests. Receiver samples do not establish invoice completeness. |
| OpenTelemetry persistent export queue | [file storage configuration][O1-storage] and [client tests][O1-storage-tests]. | If using that agent, configure its storage-backed export queue, disk limits, and fsync policy. Disk persistence does not cover data lost before collection or supply permanent financial deduplication. Do not introduce it solely to replace the installed SQLite driver. |
| cAdvisor | [Docker handler][C1-handler] and [handler tests][C1-tests]. | Alternative observer or reference for Docker/container edge cases. Do not turn its CPU or memory samples into allocated-size charges. Its dependency and host access requirements must be tested on our worker image. |
| Existing control-plane records and Docker client | Existing `dockerode`, resource operations, build start/finish hooks, volume allocations, backup inventory, and Traefik configuration. | Compute quantities come from verified running allocation intervals. Storage comes from allocation or retained-object evidence. One controlled ingress/egress boundary supplies transfer. New code supplies the ownership and billable-unit mapping. |

[Vercel Fluid compute][vercel-compute] distinguishes active CPU, provisioned memory, and requests.
[Neon plans][neon-plans] use database compute units and a separate storage model.
Our initial allocation and database size-hour rules remain as defined in the plan.
Never add database size-hours to the same database's application CPU/memory charges.
Do not add container network totals to gateway totals for the same bytes.

<a id="b3"></a>
## B3. Match the ledger and close process to established implementations

Classification: domain-specific evidence and close policy on native transactional storage.
Recommended rung: PostgreSQL constraints/transactions; reference tests; narrow product code.

A complete OpenMeter deployment is the first alternative to custom metering services to evaluate.
Accept it only if it can preserve the plan's durable identities, signed corrections, exact quantities, resource history, reconciliation, and invoice evidence at acceptable operating cost.
Its current service composition is material for a small initial PostgreSQL/TypeScript platform.
Do not run a full third-party billing system and an independent local rating engine for the same invoice.

| Required code | Read or port from this pinned source | What stays local |
| --- | --- | --- |
| Source identity and duplicate replay tests | OpenMeter [`dedupe.Item` and `Deduplicator`][M1-dedupe], [`DeduplicatingCollector.Ingest`][M1-ingest], [`TestDeduplicatingCollector`][M1-ingest-tests]. | Use a PostgreSQL composite uniqueness constraint including tenant, source epoch, sequence, meter, and resource generation. Adapt the test's duplicate event case to Vitest and Go. Add different-tenant and different-generation cases. Do not copy concatenated cache keys as the authoritative identity. |
| Atomic acceptance and delivery outbox | Native PostgreSQL transaction plus the chosen durable worker from the control-plane reuse audit. OpenMeter's inspected `Ingest` wrapper marks uniqueness before it calls the collector. | Persist usage and its outbox item together. The inspected wrapper alone does not provide our atomic durable acceptance contract. Test collector failure before/after persistence; do not substitute a TTL dedupe cache for the ledger. |
| Prior-period scan and usage already billed | Kill Bill [`RawUsageOptimizer`][K1-optimizer] and [`TestRawUsageOptimizer`][K1-optimizer-tests]. | Read its bounded historical scan and tracking concepts. Port selected period-boundary and empty-history test inputs. Use our UTC intervals, immutable events, delivery batches, and explicit 48-hour close policy; do not transplant its Java invoice stack. |
| Price-version and removed-data behavior | Kill Bill [`TestInArrearWithCatalogVersions`][K1-catalog-tests], including `testWithChangeAcrossCatalogs`, `testWithChangeWithinCatalog`, and `testWithRemovedData`. | Translate relevant scenarios to our immutable price version and resource tombstone model. Provider invoice and local evidence must agree across the split. These tests do not themselves implement our correction policy. |
| Quantity snapshots and reconciliation | OpenMeter [`snapshotQuantity` and `summarizeMeterQueryRow`][M1-snapshot]. | Reference the query-to-snapshot boundary. Use our PostgreSQL rollups, watermark, and complete/delayed/estimated states; no ClickHouse, feature-credit model, or Go decimal graph is required by this adaptation. |
| Weighted capacity over time | Lago [PostgreSQL \`WeightedSumQuery\`][L2-weighted] and [\`WeightedSumService\` tests][L2-weighted-tests]. | Candidate SQL port: ordered change events, duration to the next event, and initial/end-of-period values. Translate Rails bind parameters to Drizzle, use our half-open UTC intervals and exact units, and add replica/generation keys. Our event schema remains authoritative. |
| Corrections and finalization | Lago [\`Invoices::FinalizeService\`][L2-finalize] and [matching specs][L2-finalize-tests], plus provider adjustments and the period tests above. | Port the already-finalized no-change scenario and the state transition outline. Add our reconciliation/late-data gate before finalization. Preserve original events and linked corrections; later adjustments cannot silently alter a paid invoice. |
| Event validation and enqueue failure | Lago [\`Events::CreateService\`][L2-create] and [matching specs][L2-create-tests]. | Read timestamp parsing, organization attribution, unique transaction ID, and enqueue-failure cases. Port these cases. Its inspected enqueue-failure path deletes the newly accepted row: use our atomic ledger/outbox transaction instead, because accepted billing evidence must remain immutable. |

OpenMeter, Lago, and Kill Bill provide implementation references. Their source presence is not proof of this platform's invoice accuracy.
Keep provider acknowledgement and local batch membership after provider idempotency windows expire.
A timeout after acceptance is an uncertain delivery, not permission to generate a new event identity.
If the provider cannot resolve an uncertain batch, hold/reconcile it instead of charging it again.
Collector gaps are missing evidence. They must not become zero usage or estimated invoice rows.

<a id="b4"></a>
## B4. Use native exact quantities and provider rating

Classification: native arithmetic plus product unit definitions.
Recommended rung: PostgreSQL numeric/integer, JavaScript BigInt, existing SDK.

Use [PostgreSQL exact numeric types][pg-numeric] for byte-milliseconds and decimal prices.
Keep large values as decimal strings across Drizzle, JSON, and provider boundaries.
Use BigInt only where integer operations are needed; convert it explicitly for JSON.
Keep quantity, currency, price version, period, and rounding policy together in estimates.
Do not use JavaScript Number for financial intermediate products or round each sample.

Reuse the selected provider's price, allowance, tax, and invoice model.
Implement only the local transparent estimate for the published linear launch units.
When fractional arithmetic must run in JavaScript, select a maintained decimal library at that implementation gate instead of writing a decimal engine.
This audit does not add one: SQL numeric and integer operations cover the current storage and accumulation contract.

The local golden fixtures must include the plan's two-replica example, a fractional interval, a price change, a cycle boundary, retained storage, a correction, and a quantity above Number.MAX_SAFE_INTEGER.
Adapt Kill Bill's catalog-change fixtures from B3 for time/version boundaries.
Compare the same fixture set with provider test-mode invoices.
The current [Stripe recording API documentation][stripe-record] accepts decimal values; do not copy older integer-only assumptions or convert decimal strings through floating point.

<a id="b5"></a>
## B5. Use provider APIs and add a durable organization inbox

Classification: commodity payments and signatures; domain-specific organization reconciliation.
Recommended rung: existing Stripe SDK/services, with a phase A provider decision.

Stripe now recommends [Metronome for new usage integrations][stripe-choice], including adding usage pricing to flat subscriptions.
The existing Dokploy code uses subscriptions, not an established Billing Meters integration.
The original plan's basic-Meters preference therefore needs an explicit fit decision against current vendor guidance.
Evaluate Metronome access, pricing, integration limits, correction/finalization behavior, and required Stripe features before choosing.
If basic Meters is retained, record the supported integration reason and account confirmation; SDK availability alone is insufficient.
No Metronome signup, contract, or purchase is part of this audit.

| Capability | Reuse or source example | Local adaptation and validation |
| --- | --- | --- |
| SDK and API migration | Installed Stripe integration plus [stripe-node source][S1], version migration notes, and the selected API version. | Upgrade from 17.2.0/`2024-09-30.acacia` in a separate bounded change. Pin the selected SDK/API combination and test changed invoice/subscription fields. The inspected 22.6.2 source pin is not automatic approval to deploy that version. |
| Signature and raw body | Official Pages Router [webhook example][S1-example], [`Webhooks.ts`][S1-webhooks], and [`Webhook.spec.ts`][S1-tests]. | Reuse `constructEvent` and SDK test-header generation. Port valid/invalid signature and body handling scenarios into our Vitest tests. Do not port HMAC code or treat the example as a durable inbox. |
| Meter delivery | SDK [`Billing/MeterEvents.ts`][S1-meter], [`MeterEventAdjustments.ts`][S1-adjust], and [recording documentation][stripe-record], if basic Meters is selected. | Use stable local batch identities and retry state. Test decimal payloads, timestamp limits, async rejection, rate limits, correction support, and provider reconciliation. Never use legacy `createUsageRecord` examples. |
| Event processing | Existing webhook handler plus [Stripe webhook guidance][stripe-webhooks]. | Insert the unique verified provider event and acknowledge only after persistence. A worker retrieves current provider state where required and updates the selected organization's trusted subscription/entitlements. Test duplicate, out-of-order, missed, and separate-but-equivalent events. |
| Lifecycle, dunning, invoices | Existing Checkout/Portal/invoices and provider subscription/payment features. [Stripe test clocks][stripe-clocks]. | Test independent billing for two organizations with one owner; trial expiry; payment failure; grace; cancel/refund; recovery; and restricted access. A local state transition cannot clear a separate abuse restriction. |

Current basic Meter documentation specifies a 35-day past timestamp limit and at most 5 minutes in the future.
It also reports asynchronous processing and errors; a successful submission does not alone establish reconciled invoice usage.
Make these adapter contracts explicit and recheck them for the chosen API version.
Only send reconciled quantities under the close policy. The provider's operational limits cannot silently change that policy.

<a id="b6"></a>
## B6. Keep reservation and resource stop rules in the platform

Classification: product-specific enforcement with native transaction primitives and reference scenarios.
Recommended rung: PostgreSQL locking/constraints, existing resource operations, and bounded OpenMeter references.

OpenMeter offers a broader entitlement model through [`GetEntitlementBalance`][M1-balance] and [`TestGetEntitlementBalance`][M1-balance-tests].
Use those sources to identify effective-time, reset, grant, and usage-boundary scenarios.
For the first release, adapt only scenarios that match the published plan; do not import credit grants or prepaid wallet behavior that the plan does not require.
Its [`HighWatermarkCache`][M1-watermark] is a reference for avoiding obsolete recalculations.
A cached balance is not a transactional reservation and is not proof that a workload stopped.

Use [PostgreSQL row locks][pg-locks] or a conditional update for the organization quota/spend reservation.
Commit the reservation, resource operation, and intended generation together.
The stop/resume operation must pass through the same durable reconciler as create/resize/delete.
Reuse the selected job engine for retry and scheduling; the worker's delivery guarantee does not supply quota atomicity.
Do not add Redis, a second entitlement service, or a state-machine library merely for these narrow rules.

New product code is limited to size/replica admission, lease ceilings, reservation settlement, restriction causes, and the mapping from a restriction to desired resource state.
Tests must exercise two concurrent requests for the last slot, duplicate requests, expired leases, worker loss, delayed collectors, a period reset, and payment recovery while an abuse restriction remains.
B3's replay and boundary fixtures and OpenMeter's balance tests supply concrete starting cases.

[Vercel Spend Management][vercel-spend] separates the budget from some fixed/integration charges and documents checking delays.
Our proposed thresholds remain 50%, 80%, and 100%; do not claim these are Vercel's thresholds.
Measure compute/build/egress stop delays and publish the bound.
Storage retention, taxes, and fixed charges remain visible after a variable-use stop.
Provider budget alerts are notifications; they do not replace our admission and workload controls.

<a id="b7"></a>
## B7. Reuse onboarding and usage presentation; enforce public signup limits

Classification: existing UI/auth plus hosted admission policy. Recommended rung: internal reuse.

The [Better Auth configuration](../../../packages/server/src/lib/auth.ts) already contains verification mail and a production `IS_CLOUD` verification condition.
Reuse verification and mail delivery through the hosted-mode boundary. Do not build another identity or email-verification system.
Use the auth reuse audit's shared rate-limit design; process-local limits alone cannot enforce a multi-instance public signup policy.
An empty account may be created before payment, but customer compute must wait for verified email and the plan's payment or bounded-trial admission checks.

Extend the billing/onboarding components listed in B1 and installed Recharts.
Use authorized local rollups for organization/project/resource/region filters.
Provider totals are a reconciliation input, not a replacement for the resource evidence and permission model.
Keep `complete`, `delayed`, and `estimated` distinct in the API and UI.
Never turn an estimated display into a submitted invoice quantity.

Reference [Vercel usage views][vercel-usage] for scoped usage and [Neon consumption API documentation][neon-consumption] for project-level consumption.
Use our actual units and observed freshness. The vendor interfaces do not imply that our service has serverless or scale-to-zero billing.
Show the budget action during signup and show continuing retained-storage charges at stop/cancel.
Use existing provider fraud/payment controls plus the platform's allocation quotas; do not infer trial eligibility from a client flag.
The browser acceptance path is public signup to app/database, filtered usage, spend stop, invoice, cancellation, and export.

<a id="b8"></a>
## B8. Cost evidence and adoption gates

Classification: product cost model and validation. Recommended rung: official price APIs, existing test tools, and source-derived fixtures.

Reuse the [Azure Retail Prices API][azure-prices] and current [Neon plan units][neon-plans] as inputs.
Keep supplier cost and customer billable quantity separate.
A provider backend remains eligible only when total direct cost is no greater than the operated alternative at comparable measured service requirements.
Show labor separately. Include retained backups, cross-cloud transfer, idle capacity, poolers, required support, and any metering-service minimums.
A free tier or a lower compute-only rate does not establish the required database cost comparison.

Resolve the following in the owning Beads issues and phase A ADR:

- Billing provider/API: Metronome versus a supported basic-Meters exception; include fees, availability, and required Checkout/Portal behavior.
- Metering path: PostgreSQL ledger plus existing worker spool versus a full OpenMeter service, with representative volume, replay, and operations tests.
- Telemetry path: existing collector integration versus one complete observer; account for the OTel receiver's alpha status and worker access.
- Meter definitions, price versions, finalization/correction windows, evidence retention, and tested stop delay.

Validation uses existing Vitest and Go tooling, native PostgreSQL/SQLite integration tests, and the selected provider's test facilities.
Port the relevant source/query/test portions, retain their provenance, and add the platform-specific denial, crash, replay, and recovery cases.
Run restart/disk-full tests for the spool, concurrent transaction tests for reservations, and provider acknowledgement/crash tests for delivery.
Pass the original plan's simulated billing cycle and 14-day internal shadow measurement gates before paid public use.
Documentation, sample code, successful SDK requests, and local unit tests are separate from release evidence.

[S1]: https://github.com/stripe/stripe-node/tree/9996a2d4f129c8b02f36f715b27a30c956087007
[S1-example]: https://github.com/stripe/stripe-node/blob/9996a2d4f129c8b02f36f715b27a30c956087007/examples/webhook-signing/nextjs/pages/api/webhooks.ts
[S1-webhooks]: https://github.com/stripe/stripe-node/blob/9996a2d4f129c8b02f36f715b27a30c956087007/src/Webhooks.ts
[S1-tests]: https://github.com/stripe/stripe-node/blob/9996a2d4f129c8b02f36f715b27a30c956087007/test/Webhook.spec.ts
[S1-meter]: https://github.com/stripe/stripe-node/blob/9996a2d4f129c8b02f36f715b27a30c956087007/src/resources/Billing/MeterEvents.ts
[S1-adjust]: https://github.com/stripe/stripe-node/blob/9996a2d4f129c8b02f36f715b27a30c956087007/src/resources/Billing/MeterEventAdjustments.ts
[O1]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4
[O1-receiver]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4/receiver/dockerstatsreceiver/receiver.go
[O1-tests]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4/receiver/dockerstatsreceiver/receiver_test.go
[O1-fixtures]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4/receiver/dockerstatsreceiver/testdata/mock/cgroups_v2
[O1-storage]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4/extension/storage/filestorage/README.md
[O1-storage-tests]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/c99c5bb4046f707f2a91ceda617fe0bebb3bc6d4/extension/storage/filestorage/client_test.go
[C1]: https://github.com/google/cadvisor/tree/5bf5d43ac6f60d7ee36a13b4d5b4a78ad2d0abc7
[C1-license]: https://github.com/google/cadvisor/blob/5bf5d43ac6f60d7ee36a13b4d5b4a78ad2d0abc7/LICENSE
[C1-handler]: https://github.com/google/cadvisor/blob/5bf5d43ac6f60d7ee36a13b4d5b4a78ad2d0abc7/container/docker/handler.go
[C1-tests]: https://github.com/google/cadvisor/blob/5bf5d43ac6f60d7ee36a13b4d5b4a78ad2d0abc7/container/docker/handler_test.go
[M1]: https://github.com/openmeterio/openmeter/tree/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af
[M1-license]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/LICENSE
[M1-compose]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/docker-compose.base.yaml
[M1-dedupe]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/dedupe/dedupe.go
[M1-ingest]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/ingest/dedupe.go
[M1-ingest-tests]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/ingest/dedupe_test.go
[M1-snapshot]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/billing/charges/usagebased/service/rating/quantitysnapshot.go
[M1-balance]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/entitlement/metered/balance.go
[M1-balance-tests]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/entitlement/metered/balance_test.go
[M1-watermark]: https://github.com/openmeterio/openmeter/blob/6d76d8a6fa90fbbab2d41035d31df2acec7ad3af/openmeter/entitlement/balanceworker/filters/highwatermark.go
[K1]: https://github.com/killbill/killbill/tree/cb60779c171391be558cd7aebb1eafea60ad2b82
[K1-license]: https://github.com/killbill/killbill/blob/cb60779c171391be558cd7aebb1eafea60ad2b82/LICENSE
[K1-optimizer]: https://github.com/killbill/killbill/blob/cb60779c171391be558cd7aebb1eafea60ad2b82/invoice/src/main/java/org/killbill/billing/invoice/usage/RawUsageOptimizer.java
[K1-optimizer-tests]: https://github.com/killbill/killbill/blob/cb60779c171391be558cd7aebb1eafea60ad2b82/invoice/src/test/java/org/killbill/billing/invoice/usage/TestRawUsageOptimizer.java
[K1-catalog-tests]: https://github.com/killbill/killbill/blob/cb60779c171391be558cd7aebb1eafea60ad2b82/beatrix/src/test/java/org/killbill/billing/beatrix/integration/usage/TestInArrearWithCatalogVersions.java
[L1]: https://github.com/getlago/lago/tree/53082583d6bf65f54717bebd41cea8f47e8601a4
[L1-license]: https://github.com/getlago/lago/blob/53082583d6bf65f54717bebd41cea8f47e8601a4/LICENSE
[L2]: https://github.com/getlago/lago-api/tree/efc21c45c3de3aa478651cc21deacfa08bda30f1
[L2-weighted]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/app/services/events/stores/postgres/weighted_sum_query.rb
[L2-weighted-tests]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/spec/services/billable_metrics/aggregations/weighted_sum_service_spec.rb
[L2-finalize]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/app/services/invoices/finalize_service.rb
[L2-finalize-tests]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/spec/services/invoices/finalize_service_spec.rb
[L2-create]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/app/services/events/create_service.rb
[L2-create-tests]: https://github.com/getlago/lago-api/blob/efc21c45c3de3aa478651cc21deacfa08bda30f1/spec/services/events/create_service_spec.rb
[stripe-choice]: https://docs.stripe.com/billing/subscriptions/usage-based
[stripe-record]: https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage-api
[stripe-webhooks]: https://docs.stripe.com/webhooks
[stripe-clocks]: https://docs.stripe.com/billing/testing/test-clocks
[vercel-compute]: https://vercel.com/docs/functions/usage-and-pricing
[vercel-spend]: https://vercel.com/docs/spend-management
[vercel-usage]: https://vercel.com/docs/pricing/manage-and-optimize-usage
[neon-plans]: https://neon.com/docs/introduction/plans
[neon-consumption]: https://neon.com/docs/guides/consumption-metrics
[pg-numeric]: https://www.postgresql.org/docs/current/datatype-numeric.html
[pg-locks]: https://www.postgresql.org/docs/current/explicit-locking.html
[sqlite-atomic]: https://www.sqlite.org/atomiccommit.html
[sqlite-wrapper]: https://github.com/mattn/go-sqlite3/blob/v1.14.24/LICENSE
[azure-prices]: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
