locals {
  image = "ghcr.io/jace-ys/argocd-cmp-konduit:latest"
}

resource "kind_cluster" "cluster" {
  name           = "kind"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
  }
}

resource "terraform_data" "local_image" {
  count = var.use_local_image ? 1 : 0

  triggers_replace = [
    filemd5("${path.module}/../../../Dockerfile"),
    filemd5("${path.module}/../../../plugin.yaml"),
    filemd5("${path.module}/../../../scripts/init.sh"),
    filemd5("${path.module}/../../../scripts/generate.sh"),
  ]

  provisioner "local-exec" {
    command = "docker build -t ${local.image} ${path.module}/../../../"
  }

  provisioner "local-exec" {
    command = "kind load docker-image ${local.image} --name ${kind_cluster.cluster.name}"
  }

  depends_on = [kind_cluster.cluster]
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "39.0.0"

  values = [yamlencode({
    service = {
      type = "ClusterIP"
    }

    ports = {
      web = {
        hostPort = 80
      }
      websecure = {
        hostPort = 443
      }
    }

    nodeSelector = {
      "kubernetes.io/hostname" = "kind-control-plane"
    }

    providers = {
      kubernetesIngress = {
        publishedService = {
          enabled = false
        }
      }
    }

    additionalArguments = [
      "--providers.kubernetesingress.ingressendpoint.ip=127.0.0.1",
    ]
  })]

  depends_on = [kind_cluster.cluster]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.4.1"

  values = [yamlencode({
    configs = {
      params = {
        "server.insecure" = true
      }
      cm = {
        "url" = "http://argocd.kind.localhost"
      }
      secret = {
        # Password: admin
        argocdServerAdminPassword = "$2a$10$45bjbFvhuLBw8IaTt6Z24O6388henAmbnE4nLqBjOHdTvxNNICx5a"
      }
    }

    server = {
      ingress = {
        enabled          = true
        ingressClassName = "traefik"
        hostname         = "argocd.kind.localhost"
      }
    }

    repoServer = {
      extraContainers = [
        {
          name            = "konduit"
          image           = local.image
          imagePullPolicy = "IfNotPresent"
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 999
          }
          env = [
            { name = "HELM_CACHE_HOME", value = "/tmp/helm/cache" },
            { name = "HELM_CONFIG_HOME", value = "/tmp/helm/config" },
            { name = "HELM_DATA_HOME", value = "/tmp/helm/data" },
            { name = "CUE_CACHE_DIR", value = "/tmp/cue/cache" },
            { name = "CUE_CONFIG_DIR", value = "/tmp/cue/config" },
          ]
          volumeMounts = [
            { name = "var-files", mountPath = "/var/run/argocd" },
            { name = "plugins", mountPath = "/home/argocd/cmp-server/plugins" },
            { name = "cmp-tmp", mountPath = "/tmp" },
          ]
        },
      ]
      volumes = [
        {
          name     = "cmp-tmp"
          emptyDir = {}
        },
      ]
    }
  })]

  depends_on = [kind_cluster.cluster]
}

resource "terraform_data" "argocd_app_of_apps" {
  triggers_replace = [filemd5("${path.module}/../apps/app-of-apps.yaml")]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/../apps/app-of-apps.yaml"
  }

  depends_on = [helm_release.argocd]
}
