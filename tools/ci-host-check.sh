#!/usr/bin/env bash
# Fail fast if the self-hosted runner can't build. Nothing here installs
# anything; the host is set up once by hand.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
[ -n "${GITHUB_PATH:-}" ] && echo "$HOME/.local/bin" >> "$GITHUB_PATH"

command -v kas >/dev/null || { echo "::error::kas not found on runner host"; exit 1; }
python3 -c "import pexpect" || { echo "::error::python3-pexpect missing on runner host"; exit 1; }
if [ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" != "0" ]; then
  echo "::error::kernel.apparmor_restrict_unprivileged_userns must be 0 (bitbake needs unprivileged user namespaces)"
  exit 1
fi
# set in the runner's .env so actions/checkout doesn't wipe the cache
for v in DL_DIR SSTATE_DIR; do
  [ -n "${!v:-}" ] || { echo "::error::$v not set in the runner's .env"; exit 1; }
  mkdir -p "${!v}"
  echo "$v=${!v}"
done
df -h "$SSTATE_DIR" | tail -1
