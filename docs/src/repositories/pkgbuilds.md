# PKGBUILDs

## Types of PKGBUILDs

There are 2 types of repos packaging-wise:

1. The ones that have all required files in the new pkgbuilds repo and don't reference any external repo in PKGBUILDs `source()`
2. The ones requiring external repositories as source. These are listed in the SOURCES files below, packages _not_ listed here are automatically packages of the first category:

[This file](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/SOURCES) provides the needed information to check for the new version with the scheme `$repourl $pkgbuildPathInPkgbuildsRepo $GitlabProjectId`

## Releasing a new version

This means executing the following for doing changes and releasing a new version:

1. Would be modified directly in the new pkgbuilds repo, along with their source.
   Versions are bumped in the PKGBUILD itself and deployments need to happen by increasing `pkgver` + supplying a fitting commit message (append _[deploy pkgname ]_ to it)
2. In case of modifying these, one would make the changes to the source files repo (not the new PKGBUILDs one).
   Then, if a new version should be built, one would push the corresponding tag to that repo (omitting "v", adding v breaks the PKGBUILD!).
   That's everything needed in case no packaging changes (adding new dependencies for example) that require changing the PKGBUILD occur.
   The [half-hourly pipeline](https://gitlab.com/garuda-linux/pkgbuilds/-/pipeline_schedules) of the [PKGBUILD repo](https://gitlab.com/garuda-linux/pkgbuilds) then checks for the existence of a new tag.
   Once a new one gets detected, the PKGBUILD gets updated and deployment occurs via `[deploy *]` in the commit message.
   _If PKGBUILD changes need to be implemented, this would of course indicate doing it as described in 1. This would increase pkgrel only and not the actual version._

There are currently three bash scripts responsible for CI/CD:

- [Checking PKGBUILDs/code style](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.ci/lint.sh?ref_type=heads)
- [Updating the package versions automatically](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.ci/version-bump.sh?ref_type=heads)
- [Triggering automated deployments via commit message](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.ci/what-to-deploy.sh?ref_type=heads)

Past pipeline runs may be reviewed by visiting the [pipelines](https://gitlab.com/garuda-linux/pkgbuilds/-/pipelines) page.
