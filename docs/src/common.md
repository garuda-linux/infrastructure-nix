## Common maintenance tasks

### Rebuilding / updating the forum container

Sometimes Discourse needs its container to build rebuild via cli rather than the webinterface. This can be done with:

```sh
ssh -p 224 $user@116.202.208.112
cd /var/discourse
sudo ./launcher rebuild app
```

### Building ISO files

To build Garuda ISO, one needs to connect to the `iso-runner` container and execute the `buildiso` command, which opens a shell containing the needed environment:

```sh
ssh -p 227 $user@116.202.208.112 # if one ran nix develop before, this can be skipped
buildiso
buildiso -i # updates the iso-profiles repo
buildiso -p dr460nized
```

Further information on available commands can be found in the [garuda-tools](https://gitlab.com/garuda-linux/tools/garuda-tools) repository.
After the build process is finished, builds can be found on [iso.builds.garudalinux.org](https://iso.builds.garudalinux.org/iso/garuda/) - no automatic pushing to Sourceforge and Cloudflare R2 happens by default, see below for more information on how to achieve this.

### Deploying a new ISO release

We are assuming all ISOs have been tested for functionality before executing any of those commands.

```sh
ssh -p 227 $user@116.202.208.112
build all # builds all ISO provided in the buildall command
deployiso -FS # sync to Cloudflare R2 and Sourceforge
deployiso -FSR # sync to Cloudflare R2 and Sourceforge while also updating the latest (stable, non-nightly) release
deployiso -Sd # to delete the old ISOs on Sourceforge once they aren't needed anymore
deployiso -FSRd # oneliner for the above-given commands
```

### Updating the system

One needs to have the [infra-nix](https://gitlab.com/garuda-linux/infra-nix) repo cloned locally. Then proceed by updating the `flake.lock` file, pushing it to the server & building the configurations:

```sh
nix flake update
ansible-playbook garuda.yml -l $servername # Eg. immortalis for the Hetzner host
deploy # Skip using the above command and use this one in case nix develop was used
```

Then you can either apply it via Ansible or connect to the host to view more details about the process while it runs:

```sh
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@116.202.208.112 # Manually, exemplary on immortalis
sudo nixos-rebuild switch
```

Keep in mind that this will restart every service whose files changed since the last system update. On our Hetzner server, this includes a restart of every declarative `nixos-container` if needed, causing a small downtime.

### Changing system configurations

Most system configurations are contained in individual Nix files in the `nix` directory of this repo. This means changing anything must not be done manually but by editing the corresponding file and pushing/applying the configuration afterward.

```sh
ansible-playbook garuda.yml -l $servername # Eg. immortalis for the Hetzner host
deploy # In case nix develop is used
```

As with the system update, one can either apply via Ansible or manually:

```sh
ansible-playbook apply.yml -l $servername # Ansible

apply # Nix develop shell

ssh -p 666 $user@116.202.208.112 # Manually, exemplary on immortalis
sudo nixos-rebuild switch
```

#### Adding a user

Adding users needs to be done in `users.nix`:

- Add a new user [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/modules/users.nix?ref_type=heads#L14)
- Add the SSH public key to [flake inputs](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/flake.nix?ref_type=heads#L43)
- Add the specialArgs `keys.user` as seen [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/flake-module.nix?ref_type=heads#L38)
- Deploy & apply the configuration

### Changing Docker configurations

If configurations of services running in Docker containers need to be altered, one needs to edit the corresponding `docker-compose.yml` (`./nix/docker-compose/$name`) file or `.env` file in the `secrets` directory (see the secrets section for details on that topic). The deployment is done the same way as with normal system configuration.

### Updating Docker containers

Docker containers sometimes use the `latest` tag in case no current tag is available or in the case of services like Piped and Searx, where it is often crucial to have the latest build to bypass Google's restrictions. Containers using the `latest` tag are automatically updated via [watchtower](https://containrrr.dev/watchtower/) daily. The remaining ones can be updated by changing their version in the corresponding `docker-compose.yml` and then running `deploy` & `apply`. If containers are to be updated manually, this can be achieved by connecting to the host, running `nixos-container root-login $containername`, and executing:

```sh
cd /var/garuda/docker-compose-runner/$name/ # replace $name with the actual docker-compose.yml or autocomplete via tab
sudo docker compose pull
sudo docker compose up -d
```

The updated containers will be pulled and automatically recreated using the new images.

### Rotating IPv6

Sometimes it is needed to rotate the available IPv6 addresses to solve the current ones being rate-limited for outgoing requests of Piped, Searx, etc. This can be achieved by editing the hosts Nix file `immortalis.nix`, replacing the existing values of the `networking.interfaces."eth0".ipv6.addresses` keys seen [here](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/hosts/immortalis.nix?ref_type=heads#L30). Then, proceed doing the same with the [squid configuration](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/hosts/immortalis.nix?ref_type=heads#L219). Possible IPv6 addresses need to be generated from our available /64 subnet space and can't be chosen completely random.

### Checking whether backups were successful

To check whether backups to Hetzner are still working as expected, connect to the server and execute the following:

```sh
systemctl status borgbackup-job-backupToHetzner
```

This should yield a successful unit state. The only exception is having an exit code != `0` due to files having changed during the run.

### Updating the website content or Chaotic-AUR toolbox

This needs to be done by updating the flake input (git repo URL of the website) [src-garuda-website](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L60) or [src-chaotic-toolbox](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nix/flake.nix?ref_type=heads#L44):

```sh
cd nix
nix flake lock --update-input src-garuda-website # website
nix flake lock --update-input src-chaotic-toolbox # toolbox
```

After that deploy as usual by running `deploy` and `apply`. The commit and corresponding hash will be updated and NixOS will use it to build the website or toolbox using the new revision automatically.

### Updating the Garuda startpage content

Our startpage consists of a simple [homer](https://github.com/bastienwirtz/homer) deployment. Its configuration is stored in the [startpage](https://gitlab.com/garuda-linux/website/startpage) repo, which gets cloned to the docker-compose.yml's directory to serve the files. In order, updating is currently done manually after pushing the changes to the repo (might automate this soon via systemd timer!):

```sh
ssh -p 225 $user@116.202.208.112
cd /var/garuda/docker-compose-runner/all-in-one/startpage
git pull
sudo docker restart homer
```
