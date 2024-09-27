/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "storage_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 16.0"

  project_id                  = "${var.aw_base_id}-storage-${local.default_suffix}"
  disable_services_on_destroy = true
  org_id                      = var.organization_id
  folder_id                   = var.aw_root_folder_id
  name                        = "${var.aw_base_id} Storage"
  billing_account             = var.billing_account_id
  activate_apis = [
    "storage-api.googleapis.com"
  ]
}
data "google_storage_project_service_account" "gcs_account" {
  project = module.storage_project.project_id

  depends_on = [module.storage_project]
}

resource "google_kms_crypto_key_iam_binding" "gcs_service_account_binding" {
  crypto_key_id = google_kms_crypto_key.hsm_encrypt_decrypt.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]

  depends_on = [module.storage_project]
}

module "workload-bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 6.0.0"

  name       = "workload-bucket-${local.default_suffix}"
  project_id = module.storage_project.project_id
  location   = var.aw_location

  encryption = {
    default_kms_key_name = google_kms_crypto_key.hsm_encrypt_decrypt.id
  }

  depends_on = [
    module.storage_project,
    google_kms_crypto_key_iam_binding.gcs_service_account_binding
  ]
}
