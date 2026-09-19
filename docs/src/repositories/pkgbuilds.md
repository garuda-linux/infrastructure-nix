# PKGBUILDs

## Types of PKGBUILDs

There are two types of repo packaging-wise:

1. The ones that have all required files in the new pkgbuilds repo and don't reference any external repo in PKGBUILDs `source()`
2. The ones requiring external repositories as a source. These are listed in the SOURCES files below, packages _not_ listed here are automatically packages of the first category:

[This file](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/SOURCES) provides the needed information to check for the new version with the scheme `$repourl $pkgbuildPathInPkgbuildsRepo $GitlabProjectId`

## Releasing a new version

Releasing only needs a new tag or a push - the pipelines (in particular the chaotic-repository-template) take care of the rest.

1. Packages that have all required files in the pkgbuilds repo: bump `pkgver` in the PKGBUILD and push. The pipeline
   picks the change up and deploys the package.
2. Packages that build from an external repository (listed in the SOURCES file above): push the corresponding tag to
   that repository (omitting "v", adding v breaks the PKGBUILD!). Nothing else is needed as long as no packaging
   changes are required. The [half-hourly pipeline](https://gitlab.com/garuda-linux/pkgbuilds/-/pipeline_schedules) of
   the [PKGBUILD repo](https://gitlab.com/garuda-linux/pkgbuilds) then detects the new tag, updates the PKGBUILD and
   deploys the package.
   _If PKGBUILD changes need to be implemented as well, this would of course indicate doing it as described in 1. This
   would increase pkgrel only and not the actual version._

There are currently two bash scripts responsible for CI/CD:

- [Checking PKGBUILDs/code style](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.ci/lint.sh?ref_type=heads)
- [Updating the package versions automatically](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.ci/version-bump.sh?ref_type=heads)

Past pipeline runs may be reviewed by visiting the [pipelines](https://gitlab.com/garuda-linux/pkgbuilds/-/pipelines) page.
