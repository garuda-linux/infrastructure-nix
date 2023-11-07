# repo

## General

This is another package builder, that builds packages for our `[garuda]` repository.
This builder is accessed by the [PKGBUILD repos](https://gitlab.com/garuda-linux/pkgbuilds) CI pipelines via SSH to trigger package deployments.

## How to request a build via CI

To lock down any possible action, access has been restricted to a command wrapper. Allowed actions for the `gitlab` user are:

1. Building a specific package
2. Building a full routine

In order to trigger these actions, one needs to do the following:

1. `ssh -p 223 gitlab@builds.garudalinux.org chaotictrigger $pkgname`
2. `ssh -p 223 gitlab@builds.garudalinux.org chaotictrigger routine`

For our PKGBUILD repo, it has been implemented via this [pipeline](https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/.gitlab-ci.yml?ref_type=heads#L69).

## How packages get built

We switched to a CI-driven workflow for deploying new packages of the `garuda` repository, more details on how to operate the process can be found in the [repository section](../repositories/general.md).
The GitLab runner used to build the packages is located in the untrusted [github-runner](./github-runner.md) container.

## Nix expression

```nix
{{#include ../../../nixos/hosts/repo.nix}}
```
