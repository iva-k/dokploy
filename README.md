<div align="center">
  <a href="https://dokploy.com">
    <img src=".github/sponsors/logo.png" alt="Dokploy - Open Source Alternative to Vercel, Heroku and Netlify." width="100%"  />
  </a>
  </br>
  </br>
  <p>Join us on Discord for help, feedback, and discussions!</p>
  <a href="https://discord.gg/2tBnJ3jDJc">
    <img src="https://discordapp.com/api/guilds/1234073262418563112/widget.png?style=banner2" alt="Discord Shield"/>
  </a>
</div>
<br />


Dokploy is a free, self-hostable Platform as a Service (PaaS) that simplifies the deployment and management of applications and databases.

## ✨ Features

Dokploy includes multiple features to make your life easier.

- **Applications**: Deploy any type of application (Node.js, PHP, Python, Go, Ruby, etc.).
- **Databases**: Create and manage databases with support for MySQL, PostgreSQL, MongoDB, MariaDB, libsql, and Redis.
- **Backups**: Automate backups for databases to an external storage destination.
- **Docker Compose**: Native support for Docker Compose to manage complex applications.
- **Multi Node**: Scale applications to multiple nodes using Docker Swarm to manage the cluster.
- **Templates**: Deploy open-source templates (Plausible, Pocketbase, Calcom, etc.) with a single click.
- **Traefik Integration**: Automatically integrates with Traefik for routing and load balancing.
- **Real-time Monitoring**: Monitor CPU, memory, storage, and network usage for every resource.
- **Docker Management**: Easily deploy and manage Docker containers.
- **CLI/API**: Manage your applications and databases using the command line or through the API.
- **Notifications**: Get notified when your deployments succeed or fail (via Slack, Discord, Telegram, Email, etc.).
- **Multi Server**: Deploy and manage your applications remotely to external servers.
- **Self-Hosted**: Self-host Dokploy on your VPS.

## 🚀 Getting Started

To get started, run the following command on a VPS:

Want to skip the installation process? [Try the Dokploy Cloud](https://app.dokploy.com).

```bash
curl -sSL https://dokploy.com/install.sh | bash
```

For detailed documentation, visit [docs.dokploy.com](https://docs.dokploy.com).


[Github Sponsors](https://github.com/sponsors/Siumauricio)

### Contributors 🤝

<a href="https://github.com/dokploy/dokploy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=dokploy/dokploy" alt="Contributors" />
</a>

## 📺 Video Tutorial

<a href="https://youtu.be/mznYKPvhcfw">
  <img src="https://dokploy.com/banner.png" alt="Watch the video" width="400"/>
</a>

## 🤝 Contributing

Check out the [Contributing Guide](CONTRIBUTING.md) for more information.

## Azure test deployment

Pushes to `iva-k/dokploy` on `canary` run `.github/workflows/azure-deploy.yml`.
The workflow builds the root Dockerfile, pushes an image tagged with the commit
SHA to Azure Container Registry, and updates the VM service by image digest.
It checks the service image and the Dokploy health endpoint before success.

- Test address: http://135.225.72.84:3000
- Resource group: `rg-dokploy-test`, region: `swedencentral`.
- VM: `vm-dokploy-test`, Ubuntu 24.04, `Standard_B2ls_v2`, 64 GB disk.
- Registry: `ivakdokploytest.azurecr.io`, Basic tier.
- Deployment branch: `canary`. Other branches do not deploy.
- Access: TCP 22, 80, 443, and 3000 from `178.237.219.140/32` only.
- GitHub uses OIDC through `id-dokploy-github`; no Azure password is stored.
- The VM identity has `AcrPull`; the GitHub identity has `AcrPush` on this
  registry and `Virtual Machine Contributor` on this VM.
- GitHub variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
- PostgreSQL data and Dokploy settings persist on the VM disk. No scheduled
  backup is configured for this test instance.

Use GitHub Actions **Deploy Dokploy to Azure** to inspect or rerun deployments.
Concurrent deployment runs are serialized. Docker rolls back failed service
updates. Database migrations are not reversed by an image rollback.
To redeploy an earlier source revision, revert the change and push to `canary`.
Do not use the panel's upstream update action to deploy this fork.

If your public IP changes, update the `AllowTestClient` rule in
`nsg-dokploy-test`. For encrypted panel access during testing, run
`ssh -L 3000:localhost:3000 azureuser@135.225.72.84` and open
http://localhost:3000. Create the initial admin account through that tunnel.
The public IP endpoint uses HTTP; no domain or TLS certificate is configured.

The VM, disk, public IP, and registry incur Azure charges. Remove the resource
group when the test is no longer required; removal also deletes its stored data.

## Hosted platform design

The [public hosted platform plan](docs/architecture/hosted-platform-plan.md)
defines the proposed tenant, usage, billing, and managed PostgreSQL behavior.
It includes Vercel and Neon references, an Azure cost comparison gate, and
public-release criteria. The document is a design proposal. Beads stores its
implementation tasks and dependencies.

## Task management

This repository uses [Beads](https://github.com/gastownhall/beads) for mutable task state.
Install the `bd` command on the workstation before contributing, then run:

```bash
bd prime
bd ready
bd update <id> --claim
```

Create discovered work with `bd create` and close it with `bd close` after its acceptance criteria and validation pass. Keep requirements, decisions, architecture, and release criteria in durable documents. Do not use Markdown TODO lists or status ledgers for mutable work.

This checkout uses local embedded Dolt with no configured Beads remote. Do not run remote synchronization unless a remote is explicitly configured and authorized. The pull request and automated release checklists remain process and validation gates, not task storage.

Run `bash scripts/test-azure-deploy.sh` to check deployment success and failure
handling with command stubs. The Azure workflow runs this check before building.
Live verification also requires a successful workflow run and a healthy service
using that run's image digest.
