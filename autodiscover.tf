# Cluster Autoscaler Autodiscover
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Service Account "cluster-autoscaler" is created by Terraform

resource "kubernetes_cluster_role" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }

  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events", "endpoints"]
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["pods/eviction"]
  }

  rule {
    verbs      = ["update"]
    api_groups = [""]
    resources  = ["pods/status"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
  }

  rule {
    verbs      = ["watch", "list", "get", "update"]
    api_groups = [""]
    resources  = ["nodes"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = [""]
    resources  = ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
  }

  rule {
    verbs      = ["watch", "list"]
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
  }

  rule {
    verbs      = ["get", "list", "watch", "patch"]
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
  }

  rule {
    verbs      = ["create"]
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["cluster-autoscaler"]
  }
}

resource "kubernetes_role" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"

      k8s-app = "cluster-autoscaler"
    }
  }

  rule {
    verbs      = ["create", "list", "watch"]
    api_groups = [""]
    resources  = ["configmaps"]
  }

  rule {
    verbs          = ["delete", "get", "update", "watch"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"

      k8s-app = "cluster-autoscaler"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-autoscaler"
  }
}

resource "kubernetes_role_binding" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"

      k8s-app = "cluster-autoscaler"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cluster-autoscaler"
  }
}

resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      app = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "cluster-autoscaler" }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
        annotations = {
          "prometheus.io/port"   = "8085"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }

        container {
          name  = "cluster-autoscaler"
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.1"
          command = ["./cluster-autoscaler", "--v=4", "--stderrthreshold=info", "--cloud-provider=aws", "--skip-nodes-with-local-storage=false", "--expander=least-waste",
          "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}"]

          resources {
            limits = {
              cpu    = "100m"
              memory = "600Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "600Mi"
            }
          }

          volume_mount {
            name       = "ssl-certs"
            read_only  = true
            mount_path = "/etc/ssl/certs/ca-certificates.crt"
          }

          image_pull_policy = "Always"
        }

        node_selector = {
          role = "nodegroup_admin"
        }

        service_account_name = "cluster-autoscaler"

        security_context {
          run_as_user     = 65534
          run_as_non_root = true
          fs_group        = 65534
        }
        toleration {
          key      = "TAINED_BY_ADMIN"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        priority_class_name = "system-cluster-critical"
      }
    }
  }
}

