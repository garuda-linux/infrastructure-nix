# Documentation

## Building it

The documentation is created by using [mdBook](https://rust-lang.github.io/mdBook/index.html), which generates Markdown files and generates HTML pages for them. The documentation can be build by running:

```sh
nix build .#docs # plain simple
```

The files can then be found at `./result/`, which is a symlink to the corresponding path in `/nix/store`.
mdBook is also able automatically serve the current content and update it automatically whenever a change is detected.
This makes testing and previewing content easy.

```sh
mdbook serve --open # the latter additionally opens the website in a browser
```

## Useful information

While the general syntax for writing Markdown applies to mdBook, it has several extensions beyond the standard CommonMark specification.

- [Markdown syntax](https://rust-lang.github.io/mdBook/format/markdown.html)
- [mdBook specific features](https://rust-lang.github.io/mdBook/format/mdbook.html)

Especially importing code blocks as Markdown is really handy to keep content always up-to-date and helps providing a full text searchable code documentation.

## Deployment

Deployment to Cloudflare pages automated and happens whenever a commit to main occurs.
A [GitHub actions workflow](https://github.com/garuda-linux/infrastructure-nix/blob/main/.github/workflows/pages.yml) builds and pushes it to the `cf-pages` branch, which will then be used by the Cloudflare pages app to deploy the new version from.

```yaml
{{#include ../../../.github/workflows/pages.yml}}
```
