#!/bin/sh
set -eu

if echo "$PARAM_HELM_CHART" | grep -q '^oci://'; then
  chart="$(basename "$PARAM_HELM_CHART")-${PARAM_HELM_CHARTVERSION}.tgz"
elif [ -n "${PARAM_HELM_REPOURL:-}" ]; then
  chart="${PARAM_HELM_CHART}-${PARAM_HELM_CHARTVERSION}.tgz"
else
  chart="$PARAM_HELM_CHART"
fi

args=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '[
  (.[] | select(.name == "valueFiles") | .array // [] | .[] | ["-v", .]),
  (.[] | select(.name == "patchFiles") | .array // [] | .[] | ["-p", .]),
  (.[] | select(.name == "scopes")     | .array // [] | .[] | ["-s", .])
] | flatten | map(@sh) | join(" ")')

release="${PARAM_HELM_RELEASENAME:-$ARGOCD_APP_NAME}"
namespace="${ARGOCD_APP_NAMESPACE:-default}"
args="$args -s '$(jq -n --arg r "$release" --arg ns "$namespace" '{helm:{release:$r,namespace:$ns}}')'"

[ -n "${PARAM_CUE_MODULEROOT:-}" ] && args="$args --cue-module-root '$PARAM_CUE_MODULEROOT'"
[ -n "${PARAM_CUE_BASEDIR:-}" ] && args="$args --cue-base-dir '$PARAM_CUE_BASEDIR'"

eval "exec konduit '$PARAM_EVALUATOR' $args -- \
  template '$release' '$chart' \
  --namespace '$namespace' \
  --include-crds"
