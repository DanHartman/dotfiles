#!/usr/bin/env bash
set -euo pipefail
DIR="$( cd "$( dirname "${0}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_NAME=$(basename "$0")

rsync -avzP \
  --exclude .git \
  --exclude .idea \
  --exclude images \
  --exclude notes \
  ${DIR}/.[^.]* ~/