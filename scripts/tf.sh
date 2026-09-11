#!/usr/bin/env bash
# Wrapper around terraform that always loads secrets.tfvars.
# Usage: ./scripts/tf.sh plan | apply | destroy | output ...
set -euo pipefail
cd "$(dirname "$0")/../Terraform"

cmd="${1:-plan}"
shift || true

case "$cmd" in
  plan|apply|destroy|refresh)
    terraform init -input=false >/dev/null
    terraform "$cmd" -var-file=secrets.tfvars "$@"
    ;;
  *)
    terraform "$cmd" "$@"
    ;;
esac
