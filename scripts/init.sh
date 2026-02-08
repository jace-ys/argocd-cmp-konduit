#!/bin/sh
set -eu

if echo "$PARAM_HELM_CHART" | grep -q '^oci://'; then
  helm pull "$PARAM_HELM_CHART" \
    --version "$PARAM_HELM_CHARTVERSION"
elif [ -n "${PARAM_HELM_REPOURL:-}" ]; then
  helm pull "$PARAM_HELM_CHART" \
    --repo "$PARAM_HELM_REPOURL" \
    --version "$PARAM_HELM_CHARTVERSION"
fi
