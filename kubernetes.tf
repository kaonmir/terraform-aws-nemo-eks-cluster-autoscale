locals {
  serviceaccount_name      = "cluster-autoscaler"
  serviceaccount_namespace = "kube-system"
}

resource "kubernetes_service_account" "cluster-autoscaler" {
  metadata {
    name      = local.serviceaccount_name
    namespace = local.serviceaccount_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.k8s_asg_policy.arn}"
    }
    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }
  secret {
    name = kubernetes_secret.cluster-autoscaler.metadata.0.name
  }
}

resource "kubernetes_secret" "cluster-autoscaler" {
  metadata {
    name      = local.serviceaccount_name
    namespace = local.serviceaccount_namespace
  }
}

