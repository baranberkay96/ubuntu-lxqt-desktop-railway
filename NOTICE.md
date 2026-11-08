# NOTICE: Ubuntu 26.04 LXQt Desktop in Your Browser template

## Base image and its components

The service is built `FROM lscr.io/linuxserver/webtop:ubuntu-lxqt-8eee505a-ls6@sha256:ba4ccfec4e4a24c3279de24090a004143bf2bea92f8c6e1cff355dd2378586f8` (built 2026-11-03). The image is used as published by linuxserver.io. This repository contains no copy of its source files.

| Component | Source | License | How it is used |
|---|---|---|---|
| linuxserver.io `webtop`, release `ubuntu-lxqt-8eee505a-ls6` | https://github.com/linuxserver/docker-webtop/tree/ubuntu-lxqt (git revision `3d6a5c4db2fd2841d559097691a6abb8c8d041d1`) | GPL-3.0 | Base image (`FROM`), unmodified except for the build-time edits listed below |
| linuxserver.io baseimage-selkies (`baseimage-selkies:ubunturesolute`) | https://github.com/linuxserver/docker-baseimage-selkies | GPL-3.0 | Layers of the base image: the s6 service definitions, `init-nginx`, `/defaults/default.conf` |
| Selkies | https://github.com/selkies-project/selkies | MPL-2.0 | Streaming server and web client, in the base image |
| s6-overlay 3.2.1.0 | https://github.com/just-containers/s6-overlay, https://skarnet.org/software/ | ISC | Process supervision. `railway-start` calls `s6-svscan`, `s6-rc-compile`, `s6-rc-init` and `s6-rc` from the image |
| catatonit | https://github.com/openSUSE/catatonit (distribution package in the base image) | GPL-2.0-or-later | Container init and subreaper (`ENTRYPOINT`) |
| Ubuntu 26.04 packages: LXQt, labwc, PCManFM-Qt, QTerminal, nginx, PulseAudio, Mesa and others; Chromium from the xtradeb/apps PPA | https://launchpad.net/ubuntu and https://launchpad.net/~xtradeb/+archive/ubuntu/apps | Each package's own license (`/usr/share/doc/*/copyright` in the image) | In the base image |

### GPL notes

- The GPL parts of the base image stay under their licenses. Their complete corresponding source is published by their authors at the repositories above, at the git revision named in the image label.
- **Modified files:** at build time, `services/desktop/patch-image.sh` edits `/defaults/default.conf` (GPL-3.0, from docker-baseimage-selkies: basic auth switched on, an Origin check, anti-framing headers and a `/healthz` location) and `/etc/nginx/nginx.conf` (2 worker processes, error log on stderr). The script and the inserted snippets (`nginx-origin-map.conf`, `nginx-server-hardening.conf`) are the complete record of these changes. Anyone who distributes a built image of this template should keep them available with it.
- The files written for this template (`Dockerfile`, `railway-start.sh`, `pkg-restore.sh`, `patch-image.sh`, the two nginx snippets and the documentation) are offered under GPL-3.0-or-later.
- No source file of linuxserver.io, Selkies or s6-overlay was copied into this repository. `railway-start` re-implements, in its own code, the order of steps that s6-overlay's `preinit`, `stage0` and `rc.init` perform, and then calls the image's own s6 tools and service definitions.

## Market templates reviewed

`linux-desktop-lxqt` "Linux Desktop | Ubuntu LXQt in the Cloud" (two-workspaces/webtop-lxqt, no license): read for ideas only. Nothing copied.

Product names belong to their owners. This is a community template, not affiliated with linuxserver.io, the Selkies project, the distribution's publishers or Railway. Ubuntu is a registered trademark of Canonical Ltd.
