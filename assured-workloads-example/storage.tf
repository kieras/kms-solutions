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

data "google_storage_project_service_account" "gcs_account" {
  project = module.aw_workload_project.project_id
}

resource "google_kms_crypto_key_iam_binding" "gcs_service_account_binding" {
  crypto_key_id = google_kms_crypto_key.hsm_encrypt_decrypt.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

module "workload-bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 6.1"

  name       = "workload-bucket-${local.default_suffix}"
  project_id = module.aw_workload_project.project_id
  location   = var.aw_location

  encryption = {
    default_kms_key_name = google_kms_crypto_key.hsm_encrypt_decrypt.id
  }

  depends_on = [module.aw_workload_project]
}
