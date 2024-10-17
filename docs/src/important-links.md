# Important links

This is a collection of important links when working with the infrastructure:

## Most important

- [The infrastructure-nix repository](https://github.com/garuda-linux/infrastructure-nix)

## Nix-related

- [Devshell documentation](https://numtide.github.io/devshell/)
- [Flake-parts documentation](https://flake.parts)
  - [Pre-commit-hooks flake-module](https://flake.parts/options/pre-commit-hooks-nix)
- [Home Manager options search](https://mipmip.github.io/home-manager-option-search/)
- [NixOS mailserver documentation](https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html)
- [The Nix documentation](https://nixos.org/manual/nixos/stable/)
- [The Nix package and option search](https://search.nixos.org)

## Tools documentation

- [Chaotic toolbox](https://github.com/chaotic-aur/toolbox)
- [Chaotic infra 4.0](./services/chaotic-4.0.md)
- [mdBook](https://github.com/rust-lang/mdBook)

## Web interfaces

- [Chaotic-AUR Syncthing](https://syncthing-build.garudalinux.net/)
- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [Freshping](https://garudalinux.freshping.io/)
- [Freshstatus](https://garudalinux.freshstatus.io/admin/incidents/public)
- [Hetzner Robot](https://accounts.hetzner.com/)
- [Netdata](https://app.netdata.cloud)
- [PGAdmin](https://pgadmin.garudalinux.net)
- [Renovate Dashboard](https://developer.mend.io/github/garuda-linux)
- [Tailscale](https://login.tailscale.com/)

## Services to be administrated

- [Vaultwarden](https://vault.garudalinux.org)
- [Discourse](https://forum.garudalinux.org)
- [Chaotic-AUR](https://aur.chaotic.cx)
- [Firefox syncserver](https://ffsync.garudalinux.org)
- [Lemmy](https://lemmy.garudalinux.org)
- [Lingva](https://lingva.garudalinux.org)
- [Mastodon](https://social.garudalinux.org)
- [Nextcloud](https://cloud.garudalinux.org)
- [PrivateBin](https://bin.garudalinux.org)
- [Redlib](https://reddit.garudalinux.org)
- [SearxNG](https://searx.garudalinux.org)
- [TheLounge](https://irc.garudalinux.org)
- [Whoogle](https://search.garudalinux.org)
- [WikiJs](https://wiki.garudalinux.org)

## Additional pages

- [Startpage](https://start.garudalinux.org)
  - This one needs to be updated by pulling latest changes from the repository. It lives inside the `docker`
    nixos-container, `/var/garuda/docker-compose-runner/docker/startpage`.
- [Website](https://garudalinux.org)
  - This one is hosted on Cloudflare pages and will automatically update
    whenever a new commit is pushed to the repository.
    See commit pipelines for more information.
