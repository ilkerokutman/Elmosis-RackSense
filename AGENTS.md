# Agent notes — Elmosis RackSense

## Deployment context (as of 2026-07-28)

The Raspberry Pi target device(s) have been **shipped and installed in a
server cabinet** (the "field" Pi, production deployment). The mac dev
machine and the Pi5 build server can no longer assume direct network/SSH
reach to the field Pi — deployment to it is now a **manual,
human-performed** process (see flow below).

A **new Pi will be connected later for testing purposes** (the "test" Pi).
`scripts/build.sh` and `scripts/deploy.sh` are **not to be modified** for
this — they remain exactly as they are and continue to be used for the test
Pi (and can be pointed at the field build server for the build-only part of
the flow, see below). Do not create new scripts for the automated part of
the field flow either: `scripts/build.sh` already does exactly what's
needed (commit/push → pull on build server → build linux arm64 → zip
bundle → copy zip to Mac `artifacts/`). `scripts/deploy.sh` is only used
against the test Pi; it is not run against the field Pi (no direct network
reach), so the field Pi's post-build steps are manual.

### Required rule: bump version on every build

**Every build must bump the version** in `RackSense/pubspec.yaml`
(`version: X.Y.Z+N`, increment at least the build number `+N`) *before*
running `scripts/build.sh`. `scripts/build.sh` aborts if the version code on
the Pi5 build server doesn't match the version code on the mac, so the bump
must happen locally (and be committed) before triggering a build.

### Current release flow (field Pi)

1. **Commit from Mac** — commit local changes (with the version bump) and
   push. (`scripts/build.sh` does this automatically: stage/commit/push.)
2. **Pull to build server** — the Pi5 build server (default
   `192.168.0.70`) fetches/checks out the branch. (automated by
   `scripts/build.sh`)
3. **Build for Linux arm64** — `flutter clean && flutter pub get && flutter
   build linux --release` on the build server. (automated by
   `scripts/build.sh`)
4. **Zip the bundle dir** — zips
   `build/linux/arm64/release/bundle` into
   `rack_sense_v<version>.zip`. (automated by `scripts/build.sh`)
5. **Copy the zip to the Mac `artifacts/` folder** — via `scp`. (automated
   by `scripts/build.sh`)
6. **Manual: upload to FTP server** — the user manually uploads the
   artifact zip from `artifacts/` to an FTP server. (manual, not scripted)
7. **Manual: SSH to the target Pi** — the user manually SSHes into the
   production Pi in the cabinet and downloads the zip from the FTP server.
   (manual, not scripted)
8. **Manual: kill the running process, extract the zip, fix permissions** —
   done by hand on the target Pi (roughly mirrors what `scripts/deploy.sh`
   automates for LAN-reachable Pis: `pkill -x rack_sense`, unzip into
   `/opt/rack_sense`, `chmod -R 755` + `chmod +x rack_sense`). (manual, not
   scripted)
9. **User runs the app from the desktop shortcut** on the Pi
   (`/home/pi/Desktop/rack_sense.desktop`, created by `scripts/deploy.sh`
   previously; verify it still exists on the cabinet Pi).

Steps 1–5 remain automated via `./scripts/build.sh [branch] [build-host]`
(unmodified, no new script needed). Steps 6–9 are manual and out of scope
for automation from this repo — do not assume `scripts/deploy.sh` can reach
the field Pi directly; that script is reserved for the test Pi.
