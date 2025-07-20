# General structure

A general overview of the folder structure can be found below:

```shell
├── ansible
│   ├── host_vars
│   │   ├── aerialis
│   │   └── stormwing
│   └── playbooks
├── assets
├── compose
│   ├── chaotic-backend
│   ├── chaotic-v4
│   ├── docker
│   │   └── configs
│   ├── docker-proxied
│   ├── firedragon-runner
│   ├── github-runner
│   ├── gitlab-runner
│   └── mastodon
├── docs
│   ├── src
│   │   ├── hosts
│   │   │   ├── aerialis
│   │   │   └── stormwing
│   │   ├── repositories
│   │   ├── services
│   │   ├── users
│   │   └── websites
├── home-manager
├── nixos
│   ├── hosts
│   │   ├── aerialis
│   │   └── stormwing
│   ├── modules
│   │   ├── special
│   │   └── static
│   └── services
│       ├── compose-runner
│       └── monitoring
├── scripts
└── secrets
```

## Secrets in this repository

Secrets are managed via the sops-nix module, which allows us to encrypt sensitive files and supply them in an encrypted way to our hosts.
They will then be decrypted at runtime by using the hosts ed25519 SSH host key.
This is done by using the `sops` tool, which encrypts files using a key stored in the `~/.config/sops/` directory.
The submodule is available in the `secrets` directory once it has been set up for the first time. It can be initialized by running:

```sh
git submodule init
git submodule update
```

To view or edit any of these files, one can use the following commands:

```sh
sops secrets/filename.yaml # opens editor for the file
sops -e secrets/filename.yaml # encrypts the file
sops -d secrets/filename.yaml # decrypts the file
```

This assumes a fitting sops key is available in the `~/.config/sops/` directory.
It is important to keep the `secrets` directory in the latest state before deploying a new configuration as misconfigurations might happen otherwise.

## Passwords in general

Our mission-critical passwords that maintainers and team members need to have access to are stored in our [Bitwarden instance](vault.garudalinux.org).
After creating an account, maintainers need to be invited to the Garuda Linux organisation in order to access the stored credentials.

## Linting and formatting

We utilize [pre-commit-hooks](https://github.com/cachix/pre-commit-hooks.nix) to automatically set up the pre-commit-hook with all the tools once `nix-shell` or `nix develop` is run for the first time.
Checks can then be executed by running one of the following configs:

```sh
nix flake check # checks flake outputs and runs pre-commit at the end
pre-commit run --all-files # only runs the pre-commit tools on all files
```

Its configuration can be found in the `flake.nix` file. ([click me](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/flake.nix)). At the time of writing, the following tools are being run:

- [actionlint](https://github.com/rhysd/actionlint)
- [ansible-lint](https://github.com/ansible/ansible-lint)
- [commitizen](https://github.com/commitizen-tools/commitizen)
- [deadnix](https://github.com/astro/deadnix)
- [nil](https://github.com/oxalica/nil)
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)
- [prettier](https://prettier.io/)
- [statix](https://github.com/nerdypepper/statix)
- [yamllint](https://github.com/adrienverge/yamllint)

It is recommended to run `pre-commit run --all-files` before trying to commit changes. Then use `cz commit` to generate a `commitizen` complying commit message.

## CI/CD

We have used pull-/push-based mirroring for this git repository, which allows easy access to Renovate without having to run a custom instance of it. The following tasks have been implemented as of now:

- `nix flake check` runs for every labeled PR and commit on main.
- [Renovate](https://renovatebot.com/) periodically checks `docker-compose.yml` and other supported files for version updates. It has a [dependency dashboard](https://github.com/garuda-linux/infrastructure-nix/issues/5) as well as the [developer interface](https://developer.mend.io/github/garuda-linux/infrastructure-nix) to check logs of individual runs. Minor updates appear as grouped PRs while major updates are separated from those. Note that this only applies to the GitHub side.
- Deployment of our [mdBook-based](https://github.com/rust-lang/mdBook) documentation to Cloudflare pages.
- Deployment of our Website to Cloudflare pages.

Workflows will generally only be executed if a relevant file has been changed, eg. `nix flake check` won't run if only the README was changed.

## Monitoring

Our current monitoring stack mostly relies on Netdata to provide insight into current system loads and trends.
The major reason for using it was that it provides the most vital metrics and alerts out of the box without having to create in-depth configurations.
Might switch to the Prometheus/Grafana/Loki stack in the future. We used to set up children -> parent streaming in the past, though after transitioning to one big host this didn't make sense anymore.
Instead, up to 10GB of data gets stored on individual hosts.
While Netdata agents do have their dashboard, the [Dashboard provided by Netdata](https://app.netdata.cloud/spaces/garuda-infra/rooms/all-nodes) is far superior and allows a better insight, eg. by offering the functions feature.
Additional services like Squid or Nginx have been configured to be monitored by Netdata plugins as well. Further information can be found in its [documentation](https://learn.netdata.cloud/).
To access the previously linked dashboard, use `team@garudalinux.org` as login, the login will be completed after opening the link sent here.
