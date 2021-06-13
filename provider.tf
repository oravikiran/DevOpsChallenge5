## Technical Challenge

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
  fingerprint      = var.fingerprint
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
}

provider "oci" {
  alias                = "homeregion"
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  region               = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  disable_auto_retries = "true"
}

provider "kubernetes" {

}

provider "grafana" {
  url  = "http://grafana.example.com/"
  auth = "eyJrIjoicEXAMPLEEXAMPLEEXAMPLEEXAMPLEk15T2VBbkFCdTYiLCJuIjoidGVycmFmb3JtX3R1dG9yaWFsIiwiaWQiOjF9"
}