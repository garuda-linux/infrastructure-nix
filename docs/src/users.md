# Users

There are multiple kinds of users which are able to make use of our infrastructure.
A current list of users is available [here](./users/current_users.md).

## Adding new users

New users can be added by supplying a fitting configuration in the `users.nix` module.
In case of a password being required, its hash needs to be generated as follows:

```sh
nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt' > /path/to/hashedPasswordFile
```

The file then needs to be `ansible-vault` encrypted and added to our [secrets](https://gitlab.com/garuda-linux/infra-nix-secrets) repository.
This one is only available to members of our GitLab org and usually cloned as git submodule to `./secrets`.

## Onboarding a new admin

After confirming the trustworthyness of a new admin, the following actions need to be executed:

- Add them to the [admin users](./users/current_users.md#admins)
- Add their ssh public key to the [flake inputs](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/flake.nix?ref_type=heads#L59) and [specialArgs](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/nixos/flake-module.nix?ref_type=heads#L38)
- Make them owner of the [GitLab organisation](https://gitlab.com/garuda-linux)
- Add them to our [Bitwarden organisation](https://vault.garudalinux.org) to allow access to passwords and email accounts
- Add them to the Cloudflare Account
- Make them admin of [Discourse](https://forum.garudalinux.org)
- Make them admin of [Matrix](https://matrix.garudalinux.org)
