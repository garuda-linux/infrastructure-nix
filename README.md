# Garuda Linux server configurations

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org) [![run nix flake check](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/flake_check.yml/badge.svg?branch=main)](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/flake_check.yml)

## General information

- Our current infrastructure is hosted in one of [these](https://www.hetzner.com/dedicated-rootserver/ax102).
- The only other server not being contained in this dedicated server is our mail server.
- Both servers are being backed up to Hetzner storage boxes via [Borg](https://www.borgbackup.org/).
- After multiple different setups, we settled on NixOS as our main OS as it provides reproducible and atomically updated system states
- Most (sub)domains are protected by Cloudflare while also making use of its caching feature. Exemptions are services such as our mail server and parts violating Cloudflares rules such as proxying Piped content.

## Devshell and tooling

This NixOS flake provides a [devshell](https://github.com/numtide/devshell) which contains all deployment tools as well as handy aliases for common tasks.
The only requirement for using it is having the Nix package manager available and having flakes enabled. It can be installed on various distributions via:

```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

After that, the shell can be invoked as follows:

```
nix-shell # Assuming flakes are not enabled, this bootstraps the needed files and sets up the pre-commit hook
nix develop # The intended way to use the devshell, contains all the aliases
```

To enable flakes and the direct usage of `nix develop` follow this [wiki article](https://nixos.wiki/wiki/Flakes#Other_Distros:_Without_Home-Manager). After running `nix develop``, new commands are available to perform the following actions:

```
[infra-nix]

 ansible-core   - Radically simple IT automation
 apply          - Apply the infra-nix configuration pushed to the servers
 buildiso       - Spawn a buildiso shell on the builder
 clean          - Runs the garbage collection on the servers
 deploy         - Deploy the local NixOS configuration to the servers
 update         - Performs a full system update on the servers bumping flake lock
 update-forum   - Updates the Discourse container of our forum
 update-toolbox - Updates the locked Chaotic toolbox commit and deploys the changes
 update-website - Updates the locked website commit and deploys the changes
```

## General structure

A general overview of the folder structure can be found below:

```
├── assets
├── devshell
├── docker-compose
│   ├── all-in-one
│   ├── github-runner
│   └── proxied
├── home-manager
├── host_vars
│   ├── garuda-build
│   ├── garuda-mail
│   └── immortalis
├── nixos
│   ├── hosts
│   │   ├── garuda-build
│   │   ├── garuda-mail
│   │   └── immortalis
│   ├── modules
│   │   └── static
│   └── services
│       ├── chaotic
│       ├── docker-compose-runner
│       └── monitoring
├── playbooks
├── scripts
└── secrets
```

## Immortalis (Hetzner dedicated)

### General

This system utilizes a NixOS host which uses [nixos-containers](https://nixos.wiki/wiki/NixOS_Containers) to build declarative `systemd-nspawn` machines for different purposes. To make the best use of the available resources, common directories are shared between containers. This includes `/home` (home-manager / NixOS configurations writing to home are generated by the host and disabled for the containers), Pacman and Chaotic cache, the `/nix` directory, and a few others. Further details can be found in the [Nix expression](hhttps://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/hosts/immortalis/containers.nix) of the host.

All directories containing important data were mapped to `/data_1` and `/data_2` in order to have them all in one place. The first mostly contains web services' files, the latter only builds related directories such as the Pacman cache.

The current line-up looks as follows:

```
nico@immortalis ~ (main)> machinectl
MACHINE        CLASS     SERVICE        OS    VERSION ADDRESSES
chaotic-kde    container systemd-nspawn nixos 23.11   10.0.5.90
docker         container systemd-nspawn nixos 23.11   10.0.5.100
docker-proxied container systemd-nspawn nixos 23.11   10.0.5.110
forum          container systemd-nspawn nixos 23.11   10.0.5.70
github-runner  container systemd-nspawn nixos 23.11   10.0.5.130
iso-runner     container systemd-nspawn nixos 23.11   10.0.5.40
lemmy          container systemd-nspawn nixos 23.11   10.0.5.120
mastodon       container systemd-nspawn nixos 23.11   10.0.5.80
meshcentral    container systemd-nspawn nixos 23.11   10.0.5.60
postgres       container systemd-nspawn nixos 23.11   10.0.5.50
repo           container systemd-nspawn nixos 23.11   10.0.5.30
temeraire      container systemd-nspawn nixos 23.11   10.0.5.20
web-front      container systemd-nspawn nixos 23.11   10.0.5.10
```

We are seeing:

- 1 ISO builder (`iso-runner`)
- 1 reverse proxy serving all the websites and services (`web-front`)
- 2 Docker dedicated nspawn containers (`docker` & `docker-proxied)
- 4 Chaotic-AUR builders (`chaotic-kde`, `github-runner`, `repo` & `temeraire`)
- 5 app dedicated containers (`forum`, `lemmy`, `mastodon`, `meshcentral` & `postgres`)

### Connecting to the server

After connecting to the host via `ssh -p 666 $user@116.202.208.112`, containers can generally be entered by running `nixos-container login $containername`, eg. `nixos-container login web-front`. Some containers may also be connected via SSH using the following ports:

- 22: `temeraire` (needs to be 22 to allow pushing packages to the main Chaotic-AUR node via rsync)
- 223: `repo`
- 224: `forum`
- 225: `docker`
- 226: `chaotic-kde`
- 227: `iso-runner`
- 228: `web-front`
- 229: `postgres` (access the database in `127.0.0.1` via `ssh -p 229 nico@116.202.208.112 -L 5432:127.0.0.1:5432`)

### Docker containers

Some services not packaged in NixOS or being easier to deploy this way are serviced via the Docker engine. This contains services like Piped, Whoogle, and Matrix. We use a custom [NixOS module](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/garuda/services/docker-compose-runner/docker-compose-runner.nix?ref_type=heads) to deploy those with the rest of the system. Secrets are handled via our own secret management which consists of a git submodule `secret` (private repo with `ansible-vault` encrypted files) and `garuda-lib` (see secrets section). Those contain a `docker-compose` directory in which the `.env` files for the `docker-compose.yml` are stored.

### Chaotic-AUR / repository

Our repository leverages [Chaotic-AUR's](https://aur.chaotic.cx) [toolbox](https://github.com/chaotic-aur/toolbox) to provide the main node for the `[chaotic-aur]` repository as well as 2 more instances building the `[garuda]` and `[chaotic-kde]` repositories. Users of the `chaotic_op` group may build packages on the corresponding nixos-container via the [chaotic](https://github.com/chaotic-aur/toolbox/blob/main/README.md) command:

```
chaotic get $package # pull PKGBUILD
chaotic mkd $package # build package in the previously cloned directory
chaotic bump $package # increment pkgver of $package by 0.1 to allow a rebuild
chaotic rm $package # remove package from the repository
```

Further information may be obtained by clicking `chaotic seen above`. The corresponding builders are:

- `[chaotic-aur]`: `temeraire`
- `[garuda]`: `repo`
- `[chaotic-kde]`: `chaotic-kde`

### Squid proxy

Squid is being installed on the host machine to proxy outgoing requests via random IPv6 addresses of the /64 subnet Hetzner provides for services that need it, eg. Piped, the Chaotic-AUR builders, and other services that are getting rate limited quickly. The process is not entirely automated, which means that we currently have a pool of IPv6 addresses active and need to switch them whenever those are getting rate-limited again.
Since we supply an invalid IPv4 to force outgoing IPv6, the log files were somewhat cluttered by (expected) errors. Systemd-unit logging has been set to `LogLevelMax=1` to un-clutter the journal and needs to increased again if debugging needs to be done.

### Backups

Backups are provided by daily Borg runs. Only the `/data_1` directory is backed up (minus `/data_1/{dockercache,dockerdata}`) as the rest are either Nix generated or build-related files which can easily recovered from another repository mirror. The corresponding systemd-unit is named `borgbackup-job-backupToHetzner`.

### Tailscale / mesh network

While Tailscale was commonly used to connect multiple VMs before, this server only has it active on the host. However, we are leveraging Tailscale's [subnet router](https://tailscale.com/kb/1019/subnets/) feature to serve the `10.0.5.0/24` subnet via Tailscale, which means that other Tailscale clients may access the `nixos-containers` via their IP if `tailscale up --accept-routes` was used to set up the service.

## Secrets

Secrets are managed via a custom Git submodule that contains `ansible-vault` encrypted files as well as a custom NixOS module `garuda-lib` which makes them available to our services. The submodule is available in the `secrets` directory. To view or edit any of these files, one can use the following commands:

```
ansible-vault decrypt secrets/pathtofile
ansible-vault edit secrets/pathtofile
ansible-vault encrypt secrets/pathtofile
```

Further information on `ansible-vault` can be found in its [documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html).
It is important to keep the `secrets` directory in the latest state before deploying a new configuration as misconfigurations might happen otherwise.

## CI tooling

We have using pull/push based mirroring for this git repository. This allows easy access to Renovate without having to run a custom instance mirroring changes to both Github and GitLab. The following tasks have been automated as of now:

- `nix flake check` runs for every labeled PR and commit on main.
- [Renovate](https://renovatebot.com/) periodically checks `docker-compose.yml` and other supported files for version updates. It has a [dependency dashboard](https://github.com/garuda-linux/infrastructure-nix/issues/5) as well as the [developer interface](https://developer.mend.io/github/garuda-linux/infrastructure-nix) to check logs of individual runs. Minor updates appear as grouped PRs while major updates are separated from those. Note that this only applies to the GitHub side.

## Monitoring

Our current monitoring stack mostly relies on Netdata to provide insight into current system loads and trends. The major reason for using it was that it provides the most vital metrics and alerts out of the box without having to create in-depth configurations. Might switch to Prometheus/Grafana/Loki stack in the future. We used to set up children -> parent streaming in the past, though after transitioning to one big host this didn't really make sense anymore. Instead, up to 10GB of data gets stored on individual hosts. While Netdata agents do have their own dashboard, the [Dashboard provided by Netdata](https://app.netdata.cloud/spaces/garuda-infra/rooms/all-nodes) is far superior and allows a better insight, eg. by offering the functions feature. Additional services like Squid or Nginx have been configured to be monitored by Netdata plugins as well. Further information can be found in its [documentation](https://learn.netdata.cloud/).

To access the dashboard (linked before), use `team@garudalinux.org` as login, the login will be completed after opening the link sent here.

## Common maintenance tasks

### Rebuilding / updating the forum container

Sometimes Discourse needs its container to build rebuild via cli rather than the webinterface. This can be done with:

```
ssh -p 224 $user@116.202.208.112
cd /var/discourse
sudo ./launcher rebuild app
```

### Building ISO files

To build Garuda ISO, one needs to connect to the `iso-runner` container and execute the `buildiso` command, which opens a shell containing the needed environment:

```
ssh -p 227 $user@116.202.208.112 # if one ran nix develop before, this can be skipped
buildiso
buildiso -i # updates the iso-profiles repo
buildiso -p dr460nized
```

Further information on available commands can be found in the [garuda-tools](https://gitlab.com/garuda-linux/tools/garuda-tools) repository.
After the build process is finished, builds can be found on [iso.builds.garudalinux.org](https://iso.builds.garudalinux.org/iso/garuda/) - no automatic pushing to Sourceforge and Cloudflare R2 happens by default, see below for more information on how to achieve this.

### Deploying a new ISO release

We are assuming all ISOs have been tested for functionality before executing any of those commands.

```
ssh -p 227 $user@116.202.208.112
buildall # builds all ISO provided in the buildall command
deployiso -FS # sync to Cloudflare R2 and Sourceforge
deployiso -FSR # sync to Cloudflare R2 and Sourceforge while also updating the latest (stable, non-nightly) release
deployiso -Sd # to delete the old ISOs on Sourceforge once they aren't needed anymore
deployiso -FSRd # oneliner for the above-given commands
```

### Updating the system

One needs to have the [infra-nix](https://gitlab.com/garuda-linux/infra-nix) repo cloned locally. Then proceed by updating the `flake.lock` file, pushing it to the server & building the configurations:

```
nix flake update
ansible-playbook garuda.yml -l $servername # Eg. immortalis for the Hetzner host
deploy # Skip using above command and use this one in case nix develop was used
```

Then you can either apply it via Ansible or connect to the host to view more details about the process while it runs:

```
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@116.202.208.112 # Manually, examplary on immortalis
sudo nixos-rebuild switch
```

Keep in mind that this will restart every service whose files changed since the last system update. On our Hetzner server, this includes a restart of every declarative `nixos-container` if needed, causing a small downtime.

### Changing system configurations

Most system configurations are contained in individual Nix files in the `nix` directory of this repo. This means changing anything must not be done manually but by editing the corresponding file and pushing/applying the configuration afterward.

```
ansible-playbook garuda.yml -l $servername # Eg. immortalis for the Hetzner host
deploy # In case nix develop is used
```

As with the system update, one can either apply via Ansible or manually:

```
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@116.202.208.112 # Manually, exemplary on immortalis
sudo nixos-rebuild switch
```

### Changing Docker configurations

If configurations of services running in Docker containers need to be altered, one needs to edit the corresponding `docker-compose.yml` (`./nix/docker-compose/$name`) file or .env file in the `secrets` directory (see the secrets section for details on that topic). The deployment is done the same way as with normal system configuration.

### Updating Docker containers

Docker containers sometimes use the `latest` tag in case no current tag is available or in case of services like Piped and Searx, where it is often crucial to have the latest build to bypass Google's restrictions. Containers using the `latest` tag are automatically updated via [watchtower](https://containrrr.dev/watchtower/) on a daily basis. The remaining ones can be updated changing its version in the corresponding `docker-compose.yml` and then running `deploy` & `apply`. If containers are to be updated manually, this can be achieved by connecting to the host, running `nixos-container root-login $containername` and executing:

```
cd /var/garuda/docker-compose-runner/$name/ # replace $name with the actual docker-compose.yml or autocomplete via tab
sudo docker compose pull
sudo docker compose up -d
```

The updated containers will be pulled and automatically recreated using the new images.

### Rotating IPv6

Sometimes it is needed to rotate the available IPv6 addresses to solve the current ones being rate-limited for outgoing requests of Piped, Searx, etc. This can be achieved by editing the hosts Nix file `immortalis.nix`, replacing the existing values of the `networking.interfaces."eth0".ipv6.addresses` keys seen [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/hosts/immortalis.nix?ref_type=heads#L30). Then, proceed doing the same with the [squid configuration](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/hosts/immortalis.nix?ref_type=heads#L219). Possible IPv6 addresses need to be generated from our available /64 subnet space and can't be chosen completely random.

### Checking whether backups were successful

To check whether backups to Hetzner are still working as expected, connect to the server and execute the following:

```
systemctl status borgbackup-job-backupToHetzner
```

This should yield a successful unit state. The only exception is having an exit code != `0`` due to files having changed during the run.

### Updating the website content or Chaotic-AUR toolbox

This needs to be done by updating the flake input (git repo URL of the website) [src-garuda-website](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L60) or [src-chaotic-toolbox](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L44):

```
cd nix
nix flake lock --update-input src-garuda-website # website
nix flake lock --update-input src-chaotic-toolbox # toolbox
```

After that deploy as usual (by running `deploy`). The commit and corresponding hash will be updated and NixOS will use it to build the website or toolbox using the new revision automatically.

### Updating the Garuda startpage content

Our startpage consists of a simple [homer](https://github.com/bastienwirtz/homer) deployment. Its configuration is stored in the [startpage](https://gitlab.com/garuda-linux/website/startpage) repo, which gets cloned to the docker-compose.yml's directory to serve the files. In order, updating is currently done manually after pushing the changes to the repo (might automate this soon via systemd timer!):

```
ssh -p 225 $user@116.202.208.112
cd /var/garuda/docker-compose-runner/all-in-one/startpage
git pull
sudo docker restart homer
```
