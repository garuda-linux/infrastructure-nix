# Documentation

## Building it

The documentation is created by using mbook, which generates Markdown files and generates HTML pages for them.

Additionally, these plugins are used:

- [mdbook-emoji](https://github.com/almereyda/mdbook-emoji) - parses :emoji: codes such as `:dragon:` -> :dragon:

The documentation can be build by running:

```sh
nix build .#docs
```

The files can then be found at `./result/`, which is a symlink to the corresponding path in `/nix/store`.

## Deployment

Deployment to Cloudflare pages automated and happens whenever a commit to main occurs. A [GitHub actions workflow](https://github.com/garuda-linux/infrastructure-nix/blob/main/.github/workflows/pages.yml) builds and pushes it to the `cf-pages` branch, which will then be used by the Cloudflare pages app to deploy the new version from.
