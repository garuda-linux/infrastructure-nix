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

### Updating the system

One needs to have the [infra-nix](https://gitlab.com/garuda-linux/infra-nix) repo cloned locally. Then proceed by
updating the `flake.lock` file, pushing it to the server & building the configurations:

```sh
nix flake update
ansible-playbook garuda.yml -l $servername # Eg. aerialis
deploy # Skip using the above command and use this one in case nix develop was used
```

Then you can either apply it via Ansible or connect to the host to view more details about the process while it runs:

```sh
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@builds.garudalinux.org
sudo nixos-rebuild switch
```

Keep in mind that this will restart every service whose files changed since the last system update. On our Hetzner
server, this includes a restart of every declarative `nixos-container` if needed, causing a small downtime.

### Changing system configurations

Most system configurations are contained in individual Nix files in the `nix` directory of this repo. This means
changing anything must not be done manually but by editing the corresponding file and pushing/applying the configuration
afterward.

```sh
ansible-playbook garuda.yml -l $servername # Eg. aerialis
deploy # In case nix develop is used
```

As with the system update, one can either apply via Ansible or manually:

```sh
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@builds.garudalinux.org
sudo nixos-rebuild switch
```

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
running `deploy` & `apply`.
If containers are to be updated manually, this can be achieved by connecting to the host,
running `nixos-container root-login $containername`, and executing:

```sh
cd /var/garuda/compose-runner/$name/ # replace $name with the actual docker-compose.yml or autocomplete via tab
sudo docker compose pull
sudo docker compose up -d
```

The updated containers will be pulled and automatically recreated using the new images.

### Checking whether backups were successful

To check whether backups to Hetzner are still working as expected, connect to the server and execute the following:

```sh
systemctl status borgbackup-job-backupToHetzner
```

This should yield a successful unit state. The only exception is having an exit code != `0` due to files having changed
during the run.

### Updating Chaotic-AUR toolbox

This needs to be done by updating the flake input (git repo URL of the
website) [src-chaotic-toolbox](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L44):

```sh
cd nix
nix flake lock --update-input src-chaotic-toolbox # toolbox
```

After that deploy as usual by running `deploy` and `apply`. The commit and corresponding hash will be updated and NixOS
will use it to build the toolbox using the new revision automatically.
