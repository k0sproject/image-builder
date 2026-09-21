#!/usr/bin/env bash

# Helper script to build the GitHub Actions runner from source for Alpine, using
# as much of upstream's tooling as possible. Relies on some small patches to be
# applied to the sources before building.

set -euo pipefail

# Docker's TARGETARCH in .NET's terms.
case "$TARGETARCH" in
amd64) dotNetArch=x64 ;;
*) dotNetArch="$TARGETARCH" ;;
esac

# The .NET runtime identifier to build for, and the configuration in dev.sh's terms.
devTargetRuntime=linux-musl-$dotNetArch
devConfig=Release

do_restore() {
  # MSBuild imports a Directory.Build.targets at the end of every project below
  # it, so properties set here override the projects' own.
  [ ! -e Directory.Build.targets ] || {
    echo "Directory.Build.targets exists, refusing to overwrite it" >&2
    exit 1
  }
  cat >Directory.Build.targets <<TARGETS
<Project>
  <PropertyGroup>
    <!--
      The projects list all of upstream's targets, and a self-contained restore
      downloads the runtime packs for each of them. Narrow that to the one RID we
      build for, which also makes restore aware of a musl RID in the first place.
    -->
    <RuntimeIdentifiers>$devTargetRuntime</RuntimeIdentifiers>
    <!--
      The projects treat warnings as errors, so an advisory published after
      the pinned revision would otherwise break the build.
    -->
    <NuGetAudit>false</NuGetAudit>
  </PropertyGroup>
</Project>
TARGETS

  dotnet restore ActionsRunner.sln
}

for command in "$@"; do
  case "$command" in
  restore) do_restore ;;
  *) ./dev.sh "$command" "$devConfig" "$devTargetRuntime" ;;
  esac
done
