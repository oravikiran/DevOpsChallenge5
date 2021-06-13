terraform {
  required_version = ">= 0.12.0"
  backend "remote" {
    organization = "datapunks"
    workspaces {
      name = "orcl_kubernetes_app"
    }
  }
}