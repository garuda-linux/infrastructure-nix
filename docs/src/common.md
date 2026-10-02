## Common maintenance tasks

### Rebuilding / updating the forum container

Sometimes Discourse needs its container to build rebuild via cli rather than the webinterface. This can be done with:

```sh
ssh -p 666 $user@aerialis.garudalinux.org
sudo nixos-container root-login forum
cd /var/discourse
./launcher rebuild app
```

### Building ISO files

To build Garuda ISO, one needs to connect to the `iso-runner` container and execute the `buildiso` command, which opens
a shell containing the needed environment:

```sh
ssh -p 220 $user@builds.garudalinux.org # if one ran nix develop before, this can be skipped
buildiso
buildiso -i # updates the iso-profiles repo
buildiso -p dr460nized
```

Further information on available commands can be found in
the [garuda-tools](https://gitlab.com/garuda-linux/tools/garuda-tools) repository.
After the build process is finished, builds can be found
on [iso.builds.garudalinux.org](https://iso.builds.garudalinux.org/iso/garuda/).
No automatic pushing to Sourceforge and Cloudflare R2 happens by default, see below for more information on how to
achieve this.

### Deploying a new ISO release

We are assuming all ISOs have been tested for functionality before executing any of those commands.

```sh
ssh -p 220 $user@builds.garudalinux.org
buildall # builds all ISO provided in the buildall command
deployiso -FS # sync to Cloudflare R2 and Sourceforge
deployiso -FSR # sync to Cloudflare R2 and Sourceforge while also updating the latest (stable, non-nightly) release
deployiso -Sd # to delete the old ISOs on Sourceforge once they aren't needed anymore
deployiso -FSRd # oneliner for the above-given commands
```

### Deploying configurations

Deployments happen via [colmena](https://colmena.cli.rs) from a local clone of the
[infra-nix](https://gitlab.com/garuda-linux/infra-nix) repo. The hive is derived from `nixosConfigurations` in
`nixos/flake-module.nix`, so every host added there is deployable automatically. Systems are built locally and the
closure is copied to the servers, connecting as the `deploy` user on port 666. Your SSH key needs to be authorized for
that user (see `users.nix`).

All commands below are available in the devshell (`nix develop`). Arguments are passed through to colmena, so
`--on aerialis` (or `--on @tag`, comma-separated) limits a command to specific hosts:

```sh
deploy                 # build and switch all servers to the local configuration
deploy --on aerialis   # only one host
deploy boot            # activate on next boot instead of switching right away
deploy --build-on-target --on stormwing # build on the server itself instead of locally
clean                  # garbage collect on all servers
restart --on stormwing # reboot a server
```

Plain colmena works too, e.g. `colmena build` to only build or `colmena exec --on aerialis -- uptime`.

Keep in mind that switching restarts every service whose files changed since the last deployment. On our Hetzner
servers, this includes a restart of every declarative `nixos-container` if needed, causing a small downtime.

### Updating the system

```sh
update # nix flake update + colmena apply boot
restart --on $servername # once ready for the reboot
```

The new generation is only activated on the next boot. Use `nix flake update && deploy` instead to switch right away.
Remember to commit the updated `flake.lock`.

### Changing system configurations

Most system configurations are contained in individual Nix files in the `nixos` directory of this repo. This means
changing anything must not be done manually but by editing the corresponding file and deploying the configuration
afterward via `deploy`.

#### Adding a user

Adding users needs to be done in `users.nix`:

- Add a new
  user [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/modules/users.nix?ref_type=heads#L14)
- Add the SSH public key
  to [flake inputs](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/flake.nix?ref_type=heads#L43)
- Add the specialArgs `keys.user` as
  seen [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/flake-module.nix?ref_type=heads#L38)
- Deploy & apply the configuration

### Changing Docker configurations

If configurations of services running in Docker containers need to be altered, one needs to edit the
corresponding `compose.yml` (`./compose/$name`) file or `.env` entry of our sops file in the `secrets` directory (see
the secrets section for details on that topic).
The deployment is done the same way as with normal system configuration.

### Updating Docker containers

Docker containers sometimes use the `latest` tag in case no current tag is available or in the case of services like
Piped and Searx, where it is often crucial to have the latest build to bypass Google's restrictions.
Containers using the `latest` tag are automatically updated via [watchtower](https://containrrr.dev/watchtower/) daily.
The remaining ones can be updated by changing their version in the corresponding `compose.yml` and then
running `deploy`.

Every compose stack is managed by a `compose-runner-$name` systemd service, which syncs the compose files and the `.env`
file to `/var/garuda/compose-runner/$name` and recreates the stack on every start. Don't run `docker compose up`/`down`
there by hand, as the service won't notice and the next restart overrides it anyway. To restart a stack, connect to the
host, run `nixos-container root-login $containername` and restart its service:

```sh
systemctl restart compose-runner-$name # e.g. compose-runner-docker
systemctl status compose-runner-$name
journalctl -u compose-runner-$name -f
```

To pull newer images for tags that don't change (like `latest`) manually, pull first and then restart the service:

```sh
cd /var/garuda/compose-runner/$name
docker compose pull
systemctl restart compose-runner-$name
```

### Checking whether backups were successful

Backups run through `borgmatic`, which is configured per host with `garuda.backup.borgmatic` (see
`nixos/services/backup.nix`). To check whether backups to Hetzner are still working as expected, connect to the server
and execute the following:

```sh
systemctl status borgmatic.service
journalctl -u borgmatic
```

This should yield a successful unit state. The only exception is having an exit code != `0` due to files having changed
during the run. The "Borg backup age" and "Borg backup count" panels in Grafana are a quicker way to spot a stalled
backup.

### Checking monitoring and alerts

The monitoring stack can be reached at:

- [grafana.garudalinux.net](https://grafana.garudalinux.net) for dashboards
- [prometheus.garudalinux.net](https://prometheus.garudalinux.net) for queries and scrape targets
- [alertmanager.garudalinux.net](https://alertmanager.garudalinux.net) to review and silence alerts

These are all secured by Cloudflare Zerotrust.

Alerts are additionally delivered to any configured Target. Alert rules live in `nixos/services/monitoring/prometheus-rules/` 
and dashboards are committed as JSON in `nixos/services/monitoring/dashboards/`. See [Monitoring](./services/monitoring.md) for details.

### Updating Chaotic-AUR toolbox

This needs to be done by updating the flake input (git repo URL of the
website) [src-chaotic-toolbox](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L44):

```sh
cd nix
nix flake lock --update-input src-chaotic-toolbox # toolbox
```

After that deploy as usual by running `deploy`. The commit and corresponding hash will be updated and NixOS
will use it to build the toolbox using the new revision automatically.
