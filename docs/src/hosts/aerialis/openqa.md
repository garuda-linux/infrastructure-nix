# openqa (aerialis)

## General

[openQA](https://open.qa) at [openqa.garudalinux.org](https://openqa.garudalinux.org) tests the ISOs of [image-builder](https://gitlab.com/garuda-linux/tools/image-builder). 
The `openqa:<edition>` job of its ISO pipeline is the gate before `publish:<edition>`, see `docs/ci.md` of image-builder.

### Container explanations

- **webui**: the openQA web UI, scheduler, websockets, gru and livehandler with Apache in one container (`openqa_webui` image without `MODE`). The database is `openqa` in the [postgres](postgres.md) container.
- **worker**: a single openQA worker, so one test VM runs at a time. The image `openqa-worker:latest` is built by image-builder (`ci/openqa.Containerfile` on the upstream `openqa_worker` image), with `Inline::Python` for the Python tests and the OVMF files under `/usr/share/garuda-openqa/`.

## Resource limits

The web services of aerialis come first. The nspawn container caps web UI, worker and QEMU together:

| Setting      | Value     |
| ------------ | --------- |
| `CPUQuota`   | 8 threads |
| `MemoryHigh` | 18 GiB    |
| `MemoryMax`  | 20 GiB    |
| `CPUWeight`  | 10        |
| `IOWeight`   | 10        |

The `install` scenario uses a VM with 6 GB and 4 vCPUs, `live-modes` one with 12 GB.

## Data

`/data_2/containers/openqa` on the host (`/var/lib/openqa-data` in the container): `factory` (ISOs and disk images), `testresults`, `images`, `tests` and the worker `pool`. Not backed up. The database is in the borgmatic dumps of postgres.

openQA cleans up after each job (`[minion_task_triggers]`): results after 90 days, untracked assets after 7 days, assets of a job group above 60 GiB.

## Authentication

openQA accepts any GitLab account. web-front therefore puts `/login` behind [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/), which only lets members of the GitLab group `garuda-linux` through (the same GitLab application, which also needs the scopes `openid` and `email` and the callback `https://openqa.garudalinux.org/oauth2/callback`). Everything else, including `/api`, stays public.

The worker and the image-builder pipeline use API keys, created under _Manage API keys_.

## Restarting containers

```bash
sudo systemctl restart compose-runner-openqa
```

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/openqa.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/openqa/compose.yml}}
```
