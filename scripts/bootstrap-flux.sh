#!/usr/bin/env bash
# Installs Flux on the cluster and points it at kubernetes/clusters/nyx in this repo.
# Requires: flux CLI, kubectl with a working context, GITHUB_TOKEN with repo scope.
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-shiferaxa}"
GITHUB_REPO="${GITHUB_REPO:-NyxHomeLab}"
CLUSTER_PATH="${CLUSTER_PATH:-kubernetes/clusters/nyx}"
BRANCH="${BRANCH:-main}"

: "${GITHUB_TOKEN:?set GITHUB_TOKEN with repo scope}"

flux check --pre

flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$GITHUB_REPO" \
  --branch="$BRANCH" \
  --path="$CLUSTER_PATH" \
  --personal
