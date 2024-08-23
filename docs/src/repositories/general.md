# Repositories

## Notifications for new events at GitLab

Since GitLab has an inbuilt Telegram integration, we can leverage this feature to send notifications to our
dedicated [Telegram development updates channel](https://t.me/garuda_updates).
Posts are sent for all kinds of relevant, but non-confidential events like commits, comments or new merge requests.
Failed pipelines would also be reported here.

## Backing up current repositories

Current repositories may be backed up using [ghorg](https://github.com/gabrie30/ghorg).
To use ghorg, one needs a GitLab access token and the application itself. To generate a fitting token,
follow [these instructions](https://github.com/gabrie30/ghorg?tab=readme-ov-file#gitlab-setup).

```sh
ghorg clone --scm gitlab --token "glpat-1234567890" garuda-linux # regular system
nix run nixpkgs#ghorg -- clone --scm gitlab --token "glpat-1234567890" garuda-linux # oneliner on Nix
```

## Archive

We have an [archive repository](https://gitlab.com/garuda-linux/archive) for all files, which are no longer needed for
our current operations.
It contains old PKGBUILDs and settings packages, eg. The state of the ones before we moved to a unified PKGBUILD
repository.
