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

### mdBook syntax

While the general syntax for writing Markdown applies to mdBook, it has several extensions beyond the standard CommonMark specification.

- [Markdown syntax](https://rust-lang.github.io/mdBook/format/markdown.html)
- [mdBook specific features](https://rust-lang.github.io/mdBook/format/mdbook.html)

Especially importing code blocks as Markdown is really handy to keep content always up-to-date and helps providing a full text searchable code documentation.

### Updating mdBook plugins contents

Some of the mdBook parts are plugins that need their content to be updated from time to time. Namely, thats:

- mdbook-admonish: run `mdbook-admonish` inside the `docs` folder
- mdbook-emojicodes: works without CSS, so no updates needed
- mdbook-catppuccin: run `mdbook-catppuccin` inside the `docs` folder (might need to grab binary from [its website](https://github.com/catppuccin/mdBook/releases), no Nix package available yet)

## Deployment

Deployment to Cloudflare pages automated and happens whenever a commit to main occurs.
A [GitHub actions workflow](https://github.com/garuda-linux/infrastructure-nix/blob/main/.github/workflows/pages.yml) builds and pushes it to the `cf-pages` branch, which will then be used by the Cloudflare pages app to deploy the new version from.

```yaml
{{#include ../../../.github/workflows/pages.yml}}
```

## Issues and their solution

### Sidebar or something else on the documentation doesn't work as expected

Chances are that the custom CSS parts need to be rebased to a newer version.
They can be found in `./docs/theme/css` and the only addition we made here is to use the Fira Sans font instead of the default one.
To rebase against a newer version comment out `dditional-css` in `./docs/book.toml` and move the `css` folder somewhere else temporarily.
After that, run `mdbook build` inside the `docs` folder. The new CSS files can now be found inside the `./docs/book/css` folder.
Copy those to the `./docs/theme/css` folder and alter the occurrences of font settings to include Fira Sans (or run a diff to find out where).
After uncommenting `additional-css` in `book.toml`, run `mdbook build` again to verify nothing got broken along the way.
