FROM ghcr.io/jace-ys/konduit:v0.2.3

USER root
RUN apk add --no-cache jq

COPY plugin.yaml /home/argocd/cmp-server/config/plugin.yaml
COPY scripts/ /home/argocd/scripts/

USER 999

ENTRYPOINT ["/var/run/argocd/argocd-cmp-server"]