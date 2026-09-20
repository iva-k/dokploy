# Database and infrastructure reuse map

Survey date: 2026-09-20. Scope: sections 4, 5, 8, and 10 of the [hosted platform plan](../hosted-platform-plan.md). Related Beads work: `DOK-9q8.1`, `.3`, `.5`, `.8`, and `DOK-0xv`.

These are proposals and implementation references. No dependency, provider, runtime, or infrastructure change is made by this audit. Beads stores work state. The existing plan remains the feature contract.

License labels below record source provenance. Per the user's instruction, licensing decisions are deferred to a separate launch or funding review. They do not exclude technical candidates in this audit. This document does not copy third-party implementation code.

The smallest proposed launch set reuses existing Dokploy services, Dockerode, PostgreSQL, PgBouncer, pgBackRest, and BuildKit. Azure Verified Modules and the Azure SDK are candidates for missing VM operations. A Neon backend is conditional on the direct-cost comparison. No PostgreSQL storage engine, SQL proxy, backup engine, container builder, or general cloud orchestration framework needs to be written here.

## Source snapshots

The commit dates below are maintenance evidence observed on the survey date. They are not support, compatibility, or vulnerability guarantees. A source snapshot is a reading reference; implementation must select tested release versions and image digests. Check the selected package and image advisories before use.

| ID | Project and pinned source | License provenance | Observed maintenance and use |
| --- | --- | --- | --- |
| S1 | [Official PostgreSQL image, `4a1f78f`](https://github.com/docker-library/postgres/tree/4a1f78ff7e7a6e7ecb6a584c540c07946ad66e80) | [MIT packaging](https://github.com/docker-library/postgres/blob/4a1f78ff7e7a6e7ecb6a584c540c07946ad66e80/LICENSE); PostgreSQL and image packages have their own notices. | Commit 2026-08-13; PostgreSQL 18 image definitions are present. Use the image and entrypoint, not a new bootstrap implementation. |
| S2 | [PgBouncer, `c8dea5e`](https://github.com/pgbouncer/pgbouncer/tree/c8dea5e88e8f9d474080111bdefcc8fc84aa6454) | [ISC](https://github.com/pgbouncer/pgbouncer/blob/c8dea5e88e8f9d474080111bdefcc8fc84aa6454/COPYRIGHT). | Commit 2026-09-19; auth, TLS, COPY, and prepared-statement tests are present. Use the service intact. |
| S3 | [pgBackRest, `ce19dae`](https://github.com/pgbackrest/pgbackrest/tree/ce19dae6a2d6ab3665374ead04c270fd45d563fb) | [MIT](https://github.com/pgbackrest/pgbackrest/blob/ce19dae6a2d6ab3665374ead04c270fd45d563fb/LICENSE). | Commit 2026-09-17; backup, restore, expire, archive, and verification test suites are present. Use the packaged executable. |
| S4 | [BuildKit, `99bd9de`](https://github.com/moby/buildkit/tree/99bd9de47d29269020476c3eea5898f6038fa0a1) | [Apache-2.0](https://github.com/moby/buildkit/blob/99bd9de47d29269020476c3eea5898f6038fa0a1/LICENSE). | Commit 2026-09-18; rootless guidance and daemonless examples are present. Reuse the builder runtime. |
| S5 | [Azure Verified Modules, `0fde2cf`](https://github.com/Azure/bicep-registry-modules/tree/0fde2cff4f9d07898b5e2ba6569d08d9bbf120d7) | [MIT](https://github.com/Azure/bicep-registry-modules/blob/0fde2cff4f9d07898b5e2ba6569d08d9bbf120d7/LICENSE). | Commit 2026-09-19; VM and NSG modules have example and test directories. Consume versioned modules. |
| S6 | [Azure JavaScript SDK, `5954f62`](https://github.com/Azure/azure-sdk-for-js/tree/5954f620f55da18ec39fc6e2bbc3f02e4a8acd52/sdk/compute/arm-compute) | [MIT for arm-compute](https://github.com/Azure/azure-sdk-for-js/blob/5954f620f55da18ec39fc6e2bbc3f02e4a8acd52/sdk/compute/arm-compute/LICENSE); inspected samples also have MIT headers. | Commit 2026-09-18; typed operations, lifecycle samples, and a test directory are present. Use the SDK, not copied HTTP clients. |
| S7 | [Neon TypeScript SDK, `ea3e9c7`](https://github.com/neondatabase/neon-pkgs/tree/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/packages/sdk) | [Apache-2.0](https://github.com/neondatabase/neon-pkgs/blob/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/LICENSE). | Commit 2026-09-18. [`@neon/sdk` 6.0.0](https://registry.npmjs.org/@neon%2fsdk/6.0.0) published 2026-09-16; metadata lists Node >=20.19.0 and no runtime dependencies. Conditional whole-package candidate. |
| S8 | [PostgreSQL 18 stable, `051db77`](https://github.com/postgres/postgres/tree/051db7737c18b1c5d25cdc4ad508608c4b53fafc) | [PostgreSQL License](https://github.com/postgres/postgres/blob/051db7737c18b1c5d25cdc4ad508608c4b53fafc/COPYRIGHT). | Stable-branch commit 2026-09-19. Use `pgbench`, `pg_dump`, `pg_restore`, and SQL features. |
| S9 | [Neon engine, `fa50421`](https://github.com/neondatabase/neon/tree/fa504217c61bbcaf5c512d75830564541f917f8f) | [Apache-2.0 root](https://github.com/neondatabase/neon/blob/fa504217c61bbcaf5c512d75830564541f917f8f/LICENSE); submodules and bundled components are separate. | Commit 2026-08-31. Reference selected branching tests; do not port the storage engine for this plan. |
| S10 | [workerd, `552e0d9`](https://github.com/cloudflare/workerd/tree/552e0d9fb5671d43290cddf16e80c0d22a18a5cf) | [Apache-2.0](https://github.com/cloudflare/workerd/blob/552e0d9fb5671d43290cddf16e80c0d22a18a5cf/LICENSE); bundled dependencies have separate notices. | Commit 2026-09-19. Later JavaScript/Wasm runtime candidate; not a launch dependency. |

For any later source adaptation, record the exact file, commit, symbols, changes, and associated notices. Root license metadata alone is not a per-file audit of an entire repository. The entries below distinguish a whole-component integration from an example or test-case port.

<a id="d1"></a>
## D1. Managed PostgreSQL image and provisioning

Classification: commodity database runtime plus product-specific lifecycle. Proposed rung: existing code and the official image, with a small managed profile.

Internal targets:

- [`buildPostgres`](../../../packages/server/src/utils/databases/postgres.ts) already assembles image, mounts, network, resource limits, and Docker service calls through Dockerode.
- [`postgres` schema](../../../packages/server/src/db/schema/postgres.ts), [`postgres` router](../../../apps/dokploy/server/api/routers/postgres.ts), and [`getRemoteDocker`](../../../packages/server/src/utils/servers/remote-docker.ts) supply resource records, API shape, and worker access.
- Keep existing logical export/import. Do not create a second database type system or Docker client.

Read before implementation: S1 [`docker-entrypoint.sh`](https://github.com/docker-library/postgres/blob/4a1f78ff7e7a6e7ecb6a584c540c07946ad66e80/docker-entrypoint.sh), especially `file_env`, `docker_init_database_dir`, and `docker_process_init_files`; S1 [PostgreSQL 18 Dockerfile](https://github.com/docker-library/postgres/blob/4a1f78ff7e7a6e7ecb6a584c540c07946ad66e80/18/bookworm/Dockerfile).

Use the entrypoint unchanged where possible. Adapt only managed configuration and initialization SQL. PostgreSQL 18 uses `PGDATA=/var/lib/postgresql/18/docker` and declares `/var/lib/postgresql` as its volume. Test that layout explicitly; do not copy a PostgreSQL 17 mount recipe.

Residual code: allowed size/image/extension profiles, platform administration role, customer roles, database identity, operation generation, health/readiness, and minor-update policy. `POSTGRES_USER` initializes a privileged server account. It must not become the default application credential.

Use PostgreSQL's packaged `pgcrypto`, `pg_trgm`, and `uuid-ossp` extensions for the plan's allowlist. If vector search is selected, evaluate [pgvector `efa08fd`](https://github.com/pgvector/pgvector/tree/efa08fda9ec485d80292d0487a77939c087dedcc) as a whole extension; do not implement vector indexing. It has a [PostgreSQL-style license](https://github.com/pgvector/pgvector/blob/efa08fda9ec485d80292d0487a77939c087dedcc/LICENSE) and a 2026-09-08 commit. Read its [HNSW WAL test](https://github.com/pgvector/pgvector/blob/efa08fda9ec485d80292d0487a77939c087dedcc/test/t/010_hnsw_wal.pl) and [low-memory build test](https://github.com/pgvector/pgvector/blob/efa08fda9ec485d80292d0487a77939c087dedcc/test/t/045_hnsw_low_memory_build.pl) before adding PostgreSQL 18 image, recovery, extension-upgrade, and size-profile tests. Vector support remains an optional capacity decision.

The current `buildPostgres` catch block calls `createService` after any inspect/update error. The hosted adapter must distinguish missing resources from transient or failed updates and reconcile by immutable resource identity before another create. A library cannot supply the organization's ownership and billing generation rules.

Selection gate and validation: pinned PostgreSQL 18 digest; repeat create after acknowledgement loss; reject arbitrary hosted image/command/mount overrides; restart with the same volume; retain data through a minor update; deny customer superuser and file access; pass extension and ORM compatibility tests. Integration load is medium: most deployment mechanics exist, but the managed contract does not.

Vercel connects PostgreSQL through [Marketplace providers](https://vercel.com/docs/postgres). Neon exposes [project creation with PostgreSQL version and region](https://api-docs.neon.tech/reference/createproject). Our launch keeps an integrated product surface with one selected backend.

<a id="d2"></a>
## D2. Pooling, connection roles, and secret injection

Classification: commodity SQL pooling and encryption plus connection-binding rules. Proposed rung: whole PgBouncer service and existing secret code.

Use S2 [`etc/pgbouncer.ini`](https://github.com/pgbouncer/pgbouncer/blob/c8dea5e88e8f9d474080111bdefcc8fc84aa6454/etc/pgbouncer.ini) as configuration guidance. Reuse TLS, authentication, transaction pooling, and connection-limit features; do not implement a PostgreSQL proxy. [PgBouncer features](https://www.pgbouncer.org/features.html) describe transaction-mode restrictions.

Port test cases, not the pooler: S2 [`test_auth.py`](https://github.com/pgbouncer/pgbouncer/blob/c8dea5e88e8f9d474080111bdefcc8fc84aa6454/test/test_auth.py) covers SCRAM and reconnect behavior; [`test_prepared.py`](https://github.com/pgbouncer/pgbouncer/blob/c8dea5e88e8f9d474080111bdefcc8fc84aa6454/test/test_prepared.py) includes `test_prepared_statement` and `test_discard_or_deallocate_all`; [`test_ssl.py`](https://github.com/pgbouncer/pgbouncer/blob/c8dea5e88e8f9d474080111bdefcc8fc84aa6454/test/test_ssl.py) supplies TLS test scenarios. Translate relevant cases into the managed-service integration harness.

Internal targets:

- [`withResolvedVaultRefs`](../../../packages/server/src/utils/vault/index.ts), [`findVaultProviderInOrganization`](../../../packages/server/src/services/vault-provider.ts), and [`azureClient`](../../../packages/server/src/utils/vault/azure.ts) already resolve scoped external secrets.
- [`encryptValue`/`decryptValue`](../../../packages/server/src/lib/encryption.ts) and [`encryptedText`](../../../packages/server/src/db/schema/utils.ts) are existing encryption primitives. Extend [`encryption.test.ts`](../../../apps/dokploy/__test__/env/encryption.test.ts) and [`vault.test.ts`](../../../apps/dokploy/__test__/env/vault.test.ts).
- `databasePassword` needs the planned migration. Existing `encryptedText` returns the raw stored value on decryption failure. A managed credential read must fail closed; reuse the primitive with explicit failure handling rather than assume this column adapter satisfies that contract.

Residual code: role/grant templates, credential versions with overlap, app/environment binding, authorization and redaction, certificate identity, connection allowlists, and secret rollback. Keep platform administration credentials separate from customer URLs. Reuse the installed client for connection checks; no second secrets platform is required solely for this feature.

Selection gate and validation: pooled and direct TLS URLs, certificate validation, SCRAM, limits across all pools, prepared statements, session-sensitive migrations on direct connections, revoked old credentials, rotation during live traffic, and cross-organization binding denial. Integration load is medium; PgBouncer still needs a deployed process, configuration updates, and operational monitoring.

Neon also uses PgBouncer and recommends direct connections for session-dependent work and some migration/export operations. Reuse that distinction in the connection UI; do not copy Neon's connection-count allowance. [Neon pooling](https://neon.com/docs/connect/connection-pooling)

<a id="d3"></a>
## D3. Physical backup, WAL, retention, restore, and export

Classification: commodity backup engine plus resource and retention policy. Proposed rung: pgBackRest intact, existing logical export, and translated recovery test scenarios.

Internal reuse: [`runPostgresBackup`](../../../packages/server/src/utils/backups/postgres.ts), [`getPostgresBackupCommand`](../../../packages/server/src/utils/backups/utils.ts), [`restorePostgresBackup`](../../../packages/server/src/utils/restore/postgres.ts), and [`getPostgresRestoreCommand`](../../../packages/server/src/utils/restore/utils.ts). Keep these for `pg_dump`/`pg_restore` portability. Extend existing [backup command tests](../../../apps/dokploy/__test__/utils/backups.test.ts), [injection cases](../../../apps/dokploy/__test__/backups/db-backup-restore-injection.test.ts), and [credential redaction tests](../../../apps/dokploy/__test__/backups/redact-credentials.test.ts).

Use pgBackRest `stanza-create`, `check`, `backup`, `info --output=json`, `verify`, `expire`, and `restore`. Its [guide](https://pgbackrest.org/user-guide.html) documents WAL archive, repository encryption, Azure/S3 repositories, and restore targets. Configure and invoke the tool; do not port its C backup or WAL code.

Pinned reference and test-case adaptation:

| Source | What to reuse in our tests or configuration |
| --- | --- |
| S3 [`doc/xml/user-guide.xml`](https://github.com/pgbackrest/pgbackrest/blob/ce19dae6a2d6ab3665374ead04c270fd45d563fb/doc/xml/user-guide.xml) | Stanza, archive, encrypted repository, retention, and restore command sequence. Run it against our image/storage profile. |
| S3 [`restoreTest.c`](https://github.com/pgbackrest/pgbackrest/blob/ce19dae6a2d6ab3665374ead04c270fd45d563fb/test/src/module/command/restoreTest.c) | Target selection, timeline, missing metadata, and checksum/error scenarios at our adapter boundary. |
| S3 [`expireTest.c`](https://github.com/pgbackrest/pgbackrest/blob/ce19dae6a2d6ab3665374ead04c270fd45d563fb/test/src/module/command/expireTest.c) and [`checkTest.c`](https://github.com/pgbackrest/pgbackrest/blob/ce19dae6a2d6ab3665374ead04c270fd45d563fb/test/src/module/command/checkTest.c) | Retention-chain and archive-readiness failure cases. Add our suspended-resource and last-valid-backup conditions. |

Residual code: per-resource stanza/repository scope, worker credential delivery, durable schedule and operation records, backup status ingestion, object-byte attribution, policy validation, and restore into a new resource. The present `node-schedule` path is not a durable hosted scheduler; use the resource-operation mechanism selected for phase C.

Do not set object-store lifecycle deletion independently of pgBackRest's required backup/WAL chain. Do not equate seven retained full backups with seven days of continuous recovery. Apply the plan's history and last-valid-backup rules explicitly, including stopped and suspended resources. Keep archive credentials separate from restore/deletion authority.

Selection gate and validation: PostgreSQL 18 compatibility, WAL lag, missing/corrupt objects, oldest promised restore point, restore after VM loss, stop/start and 30-day suspension retention, and recovery within the plan's measured 5-minute RPO/60-minute RTO target. Check selected pgBackRest release notes for fixes and required version alignment. Integration load is high in operations and tests, even though the backup engine is reused. [pgBackRest releases](https://pgbackrest.org/release.html)

Neon's [branching](https://neon.com/docs/introduction/branching) supplies a product reference for recovery and isolated copies. It does not make a normal PostgreSQL volume a Neon branch.

<a id="d4"></a>
## D4. External databases and conditional Neon backend

Classification: existing secret binding for external services; commodity provider API for managed databases. Proposed rung: existing code for external URLs; S7 only if a managed provider passes D8.

External Neon, self-managed PostgreSQL, and other compatible databases remain secret-backed connection strings in the selected application environment. Reuse D2's vault/env resolution and current Postgres.js connection support. Do not force an external connection through the managed provisioning or billing path.

For an eligible embedded Neon offer, evaluate current [`@neon/sdk`](https://github.com/neondatabase/neon-pkgs/blob/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/packages/sdk/README.md). `createNeonClient`, project and branch resources, `operations.waitFor`, typed errors, retries, and readiness polling cover provider mechanics. Avoid copying SDK retry and polling implementations into this repository.

Read S7 [`src/neon/client.ts`](https://github.com/neondatabase/neon-pkgs/blob/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/packages/sdk/src/neon/client.ts), [`wait-for-readiness.test.ts`](https://github.com/neondatabase/neon-pkgs/blob/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/packages/sdk/src/neon/wait-for-readiness.test.ts), and [`e2e/workflows.e2e.test.ts`](https://github.com/neondatabase/neon-pkgs/blob/ea3e9c73fc88f11b31ebf942fbcd1f9ac1c7eb63/packages/sdk/e2e/workflows.e2e.test.ts). Borrow readiness, usable-connection, cancellation, timeout, and typed-error cases. Match installed SDK version to the examples; old API-client method signatures differ.

Residual code: organization-to-provider-resource mapping, restricted regions/sizes, secret custody, durable external operation IDs, resource generations, quotas, observed usage, and deletion/retention rules. Persist operation references before a long readiness wait. An SDK retry is not proof that an ambiguous project-creation response is safe to replay.

Selection gate and validation: **provider direct cost must be <= our operated direct cost for every required scenario**, at matched throughput, latency, retention, and isolation. Keep labor in a separate comparison. Include both clouds' transfer charges, minimum commitments, quotas, and required support. Confirm provider terms and selected-region availability before activation. No provider is approved by this survey.

Neon [project creation](https://api-docs.neon.tech/reference/createproject) returns operations that must finish before use; its [API use cases](https://api-docs.neon.tech/reference/use-cases) include project, endpoint, role, and branch control. Integration load is medium after the commercial/cost choice; implementing both backends at launch is outside the plan.

<a id="d5"></a>
## D5. Azure VM provisioning and durable lifecycle

Classification: commodity cloud resource APIs plus platform resource state. Proposed rung: versioned Azure Verified Modules and the official SDK.

Internal targets: [`server` schema](../../../packages/server/src/db/schema/server.ts), [`getRemoteDocker`](../../../packages/server/src/utils/servers/remote-docker.ts), and deployment calls. [`azure-deploy.sh`](../../../scripts/azure-deploy.sh) updates the existing test service; it is not a tenant VM provisioner.

Use S5 [VM module](https://github.com/Azure/bicep-registry-modules/blob/0fde2cff4f9d07898b5e2ba6569d08d9bbf120d7/avm/res/compute/virtual-machine/main.bicep) with its [Linux minimal test deployment](https://github.com/Azure/bicep-registry-modules/blob/0fde2cff4f9d07898b5e2ba6569d08d9bbf120d7/avm/res/compute/virtual-machine/tests/e2e/linux.defaults/main.test.bicep) as the read-before-build template. Configure our permitted SKU, image, disk, identity, NIC, and network policy. Consume modules instead of maintaining copied resource definitions. [Bicep module documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules)

Use S6 [`virtualMachinesCreateOrUpdateSample.ts`](https://github.com/Azure/azure-sdk-for-js/blob/5954f620f55da18ec39fc6e2bbc3f02e4a8acd52/sdk/compute/arm-compute/samples-dev/virtualMachinesCreateOrUpdateSample.ts), [`virtualMachinesDeallocateSample.ts`](https://github.com/Azure/azure-sdk-for-js/blob/5954f620f55da18ec39fc6e2bbc3f02e4a8acd52/sdk/compute/arm-compute/samples-dev/virtualMachinesDeallocateSample.ts), and [`operations.ts`](https://github.com/Azure/azure-sdk-for-js/blob/5954f620f55da18ec39fc6e2bbc3f02e4a8acd52/sdk/compute/arm-compute/src/api/virtualMachines/operations.ts). These show current create/start/deallocate/delete and long-operation interfaces. Adapt the small call-site examples; retain the SDK implementation. Select the released SDK first because older examples use different `begin*` APIs.

Residual code: immutable resource naming and tags, organization reservation, desired generation, lease/fence, provider operation reference, reconciliation, orphan cleanup, and cost-state transitions. Keep one authority for each field: Bicep resource shape and platform desired state must not fight independent imperative resize loops. A cloud SDK handles transport; it does not provide our tenant transaction.

Selection gate and validation: interrupted create, repeated request, expired worker lease, partial disk/NIC failure, resource rename rejection, deallocation with retained disks, interrupted deletion, and restart reconciliation. Use only our separate test subscription/resource scope for future live tests. Integration load is medium to high; no cloud action occurs in this audit.

The plan's one-organization-per-application-VM boundary remains. Vercel's [build isolation](https://vercel.com/docs/builds) is a behavior reference, not evidence that a Docker container on a shared VM supplies the same boundary.

<a id="d6"></a>
## D6. Disposable builds and image delivery

Classification: commodity builder plus tenant scheduling. Proposed rung: existing builder adapters and BuildKit runtime.

Reuse [`getBuildCommand`](../../../packages/server/src/utils/builders/index.ts), [`getDockerCommand`](../../../packages/server/src/utils/builders/docker-file.ts), [`getRailpackCommand`](../../../packages/server/src/utils/builders/railpack.ts), and registry credentials. The Dockerfile path already supports build secrets; the Railpack path already invokes buildx. Do not create another Dockerfile parser or build graph.

Read S4 [`examples/buildctl-daemonless/buildctl-daemonless.sh`](https://github.com/moby/buildkit/blob/99bd9de47d29269020476c3eea5898f6038fa0a1/examples/buildctl-daemonless/buildctl-daemonless.sh), including `startBuildkitd`, `waitForBuildkitd`, and exit cleanup. Adapt the readiness/cleanup sequence into the worker lifecycle, or use the maintained script. Read [`docs/rootless.md`](https://github.com/moby/buildkit/blob/99bd9de47d29269020476c3eea5898f6038fa0a1/docs/rootless.md) before selecting worker flags.

Rootless examples contain security relaxations and network limitations. They do not replace the disposable VM boundary. Do not copy `--oci-worker-no-process-sandbox` or privileged-container flags into a shared customer host and treat that as isolation.

Residual code: build reservation, disposable worker assignment, tenant-scoped cache and registry paths, cancellation/deadline, active-time lifecycle events, and orphan cleanup. Keep build credentials short-lived where supported. Queued time and platform-caused retries must retain the plan's billing treatment.

Selection gate and validation: malicious Dockerfile, access to host/control-plane sockets and metadata, cache reads across organizations, secret leakage into logs/layers, timeout with child processes, abandoned worker cleanup, cancelled builds, and build restart after acknowledgement loss. S4 [`client/client_test.go`](https://github.com/moby/buildkit/blob/99bd9de47d29269020476c3eea5898f6038fa0a1/client/client_test.go) is the upstream integration-test entry point; port only cases that map to our worker contract. Integration load is medium; the build engine is already in the deployment path.

Vercel describes isolated environments, automatic cleanup, environment variables, and build outputs in its [build documentation](https://vercel.com/docs/builds). Match those user-visible behaviors without claiming its infrastructure implementation.

<a id="d7"></a>
## D7. Network isolation and CPU, memory, IO, and disk limits

Classification: native operating-system/cloud controls plus tenant policy. Proposed rung: current network/Docker code, native controls, and an NSG module.

Reuse [`resolveServiceNetworks`, `createNetwork`, and `inspectNetwork`](../../../packages/server/src/services/network.ts), [`calculateResources`](../../../packages/server/src/utils/docker/utils.ts), and the D1 service resource configuration. Existing Compose network tests supply network-shape fixtures; add hosted-mode policy tests instead of importing customer-controlled Compose behavior into the hosted profile.

Use S5 [network-security-group module](https://github.com/Azure/bicep-registry-modules/blob/0fde2cff4f9d07898b5e2ba6569d08d9bbf120d7/avm/res/network/network-security-group/main.bicep). Azure NSG rules support network filtering; the [default rules](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview) must be accounted for explicitly. A tag or separate Docker network name is not an access-control test.

Use Docker CPU/memory settings and native cgroup v2 `cpu.max`, `memory.max`, `pids.max`, and `io.max` where the selected host/runtime exposes them. Disk capacity requires the selected volume/filesystem's quota or fixed allocation; cgroup IO limits are throughput limits, not storage-byte quotas. [Docker resource controls](https://docs.docker.com/engine/containers/resource_constraints/), [Linux cgroup interface](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)

Residual code: allowed app-to-database bindings, worker profile rendering, applied-policy inspection, lease-expiry enforcement, tenant/volume identity, and egress attribution. This is a small policy/control adapter. Do not write a firewall, kernel scheduler, or storage quota engine. Shared database hosts remain conditional on the plan's isolation tests.

Selection gate and validation: tenant-to-tenant and app-to-control-plane traffic, metadata access, default NSG paths, direct database port bypass, DNS/IPv6 egress, OOM, fork/process limits, CPU contention, IO saturation, disk exhaustion, reboot persistence, and actual enforcement after resize. If runtime APIs cannot enforce a required IO or volume limit, use the plan's per-tenant database-VM fallback and repeat D8. Integration load is medium to high because actual host enforcement needs live tests.

<a id="d8"></a>
## D8. Database cost and performance fixtures

Classification: commodity benchmark and price APIs plus our cost model. Proposed rung: native PostgreSQL tools and a small checked-in fixture runner; no cost platform dependency.

Use PostgreSQL 18 [`pgbench`](https://www.postgresql.org/docs/18/pgbench.html), `psql`, and existing Node/Go command/test support. Read S8 [`001_pgbench_with_server.pl`](https://github.com/postgres/postgres/blob/051db7737c18b1c5d25cdc4ad508608c4b53fafc/src/bin/pgbench/t/001_pgbench_with_server.pl) for reproducible server-backed test setup and assertion patterns. Port representative workload/result cases into our harness, not the PostgreSQL test framework.

Use the [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices) and [Neon plan definitions](https://neon.com/docs/introduction/plans) as dated inputs. Save filtered meter IDs, region/currency, effective dates, fetched time, and raw input provenance with benchmark results. Public list prices are not an account quote.

Residual code is a fixture runner and exact arithmetic report for the plan's 10/100/1,000-database scenarios. Record startup and restore time, throughput, p50/p95 latency, WAL rate, working set, pooling settings, disk/IO limit, and transfer volume. Run identical datasets, workload scripts, and concurrency, including intermittent and always-on use. Do not infer equal service from matching CPU labels.

Report operated and provider **direct costs** separately from staff labor. Include VM utilization and spare capacity, allocated disks/IO, backup history, object requests, poolers/gateways, platform share, both sides of cross-cloud transfer, minimum commitments, and required support. Test the actual isolation layout; shared-host arithmetic cannot approve a per-tenant-VM deployment.

Selection gate: a managed provider is eligible only when every required scenario passes direct-cost parity and the same service tests. Selling prices remain a separate business input. This audit approves no numerical price, margin, reservation, or provider. Integration load is low for tooling and significant for measured evidence.

<a id="d9"></a>
## D9. Later CDN and edge execution

Classification: commodity delivery network/runtime plus product routing and usage policy. Proposed rung: existing gateway for regional delivery; managed CDN or intact runtime only in phase I.

Reuse current [`domain` service](../../../packages/server/src/services/domain.ts), [`certificate` service](../../../packages/server/src/services/certificate.ts), and [`Traefik configuration`](../../../packages/server/src/utils/traefik). Vercel's [CDN](https://vercel.com/docs/cdn) combines routing, caching, and compute-facing delivery. A second reverse proxy alone does not provide a global CDN.

| Candidate | Proposed use and remaining work |
| --- | --- |
| [Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview) | Later managed CDN candidate if regions, caching behavior, tenant attribution, purge API, and measured total cost fit. Requires provider configuration, domain/routing mapping, and cache/security tests. No purchase is approved. |
| S10 workerd | Later JavaScript/Wasm runtime candidate. Read [`samples/helloworld/config.capnp`](https://github.com/cloudflare/workerd/blob/552e0d9fb5671d43290cddf16e80c0d22a18a5cf/samples/helloworld/config.capnp), [`worker.js`](https://github.com/cloudflare/workerd/blob/552e0d9fb5671d43290cddf16e80c0d22a18a5cf/samples/helloworld/worker.js), and [`samples/unit-tests`](https://github.com/cloudflare/workerd/tree/552e0d9fb5671d43290cddf16e80c0d22a18a5cf/samples/unit-tests). Adapt bindings and tests, not the runtime. Our deployment, identity, limits, routing, secrets, and meters remain. |
| [gVisor `26f3455`](https://github.com/google/gvisor/tree/26f3455a4cb9a377354c33aeac049080a077c79c) | Whole-runtime candidate for a later density decision. Apache-2.0 root; commit 2026-09-19. It changes the Linux execution/compatibility boundary and needs workload and syscall tests. Do not port its kernel implementation. |
| [Firecracker `23b09b9`](https://github.com/firecracker-microvm/firecracker/tree/23b09b943fa3cd4a04004fe55724f0b5c2410f45) | Whole microVM runtime candidate after host/KVM, image, networking, lifecycle, and cost tests. Apache-2.0 root; commit 2026-09-17. It does not supply a complete tenant scheduler or edge network. Do not port the VMM. |

The pinned [workerd README](https://github.com/cloudflare/workerd/blob/552e0d9fb5671d43290cddf16e80c0d22a18a5cf/README.md) states that workerd alone is not a hardened sandbox and requires an appropriate external boundary for hostile code. Keep the VM boundary until an explicit alternative passes the plan's tests.

Open design gate: supported runtime/API contract, region/cold-start targets, sandbox boundary, request/CPU accounting, egress policy, and cost. Integration load is high; none of these candidates is needed for the first regional application/database release.

<a id="d10"></a>
## D10. Later preview database copies and higher availability

Classification: existing restore/export capability plus environment/expiry policy. Proposed rung: D1/D3 operations, existing project environments, and reference test cases.

Use pgBackRest restore-to-new-instance for a physical copy or the existing `pg_dump`/`pg_restore` pipeline where logical portability is needed. Reuse environment and secret binding after the copy passes readiness checks. Do not build copy-on-write storage for full-copy previews.

Read S9 [`test_branching.py`](https://github.com/neondatabase/neon/blob/fa504217c61bbcaf5c512d75830564541f917f8f/test_runner/regress/test_branching.py), especially `test_duplicate_creation` and `test_branching_with_pgbench`. Adapt duplicate-create and parent/copy data-independence test cases to our full-copy service. Neon's internal LSN/timeline machinery is not a code-port candidate for this architecture.

Residual code: source authorization, copy operation identity, destination quotas, production-data policy, binding, TTL/expiry through the durable scheduler, and cleanup with storage billing. Validate copy consistency under writes, source deletion during copy, repeated requests, interrupted restore, independent writes, revoked credentials, and expiry while an application still refers to the copy.

Neon's [branches are copy-on-write](https://neon.com/docs/introduction/branching); our full copy consumes full destination storage and has a measured copy delay. Vercel [preview environments](https://vercel.com/docs/deployments/environments) provide the application-facing reference. Show database copy readiness and expiry separately from deployment readiness.

If a later architecture already uses Kubernetes, evaluate [CloudNativePG `1a97720`](https://github.com/cloudnative-pg/cloudnative-pg/tree/1a9772003fa6b74ce0f8094b1d3e95dfda031f32) as a whole PostgreSQL operator instead of recreating operator logic. Apache-2.0 root; commit 2026-09-19. Its [`Cluster` API](https://github.com/cloudnative-pg/cloudnative-pg/blob/1a9772003fa6b74ce0f8094b1d3e95dfda031f32/api/v1/cluster_types.go) and [defaulting tests](https://github.com/cloudnative-pg/cloudnative-pg/blob/1a9772003fa6b74ce0f8094b1d3e95dfda031f32/api/v1/cluster_defaults_test.go) are service-profile references. Do not introduce Kubernetes only to adopt this operator.

Selection gate: phase I scope and cost decision, tested copy/expiry semantics, production-data handling, and retained backup policy. Automatic suspend/wake, online scale, replicas, and failover remain separate designs. Integration load is medium for full copies and high for a changed HA/runtime architecture.

For a later VM-based HA offer, evaluate [Patroni `eec38cd`](https://github.com/patroni/patroni/tree/eec38cd0b8f51d23c8a965515bd0df6dd05a5df1) intact before writing leader election or failover. MIT root; commit 2026-09-17. Its [`tests/test_ha.py`](https://github.com/patroni/patroni/blob/eec38cd0b8f51d23c8a965515bd0df6dd05a5df1/tests/test_ha.py) and [`tests/test_postgresql.py`](https://github.com/patroni/patroni/blob/eec38cd0b8f51d23c8a965515bd0df6dd05a5df1/tests/test_postgresql.py) are failure-scenario references. It adds a distributed configuration store and multi-node operations; this cost and topology do not fit the launch single-primary contract without an explicit amendment.

## Expected custom code boundary

The remaining original code is organization ownership, desired-state and operation records, profile validation, provider/resource mapping, connection binding, usage identity, policy rendering, and tests that join these components. These rules depend on this platform's contract. The sources above provide native mechanisms, existing implementations, or concrete test patterns for the rest.

Before implementation, record the selected candidate/version, mapped local targets, rejected technical alternatives, and validation in the relevant Beads issue. This document supplies guidance; it does not change issue state or claim a completed feature.
