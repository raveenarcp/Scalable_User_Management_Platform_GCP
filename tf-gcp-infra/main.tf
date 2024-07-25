terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.16.0"
    }
  }
}

#Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_project" "project" {}

resource "google_compute_network" "vpcnetwork" {
  name                            = var.vpc_name
  auto_create_subnetworks         = var.auto_create_subnets
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes
}

resource "google_compute_subnetwork" "webapp" {
  name                     = var.web_subnet_name
  ip_cidr_range            = var.web_app_cidr
  network                  = google_compute_network.vpcnetwork.id
  private_ip_google_access = var.private_ip_google_access
}

resource "google_compute_subnetwork" "db" {
  name                     = var.db_subnet_name
  ip_cidr_range            = var.db_cidr
  network                  = google_compute_network.vpcnetwork.id
  private_ip_google_access = var.private_ip_google_access
}

resource "google_compute_subnetwork" "serverless_subnet" {
  name          = var.serverless_subnet_name
  ip_cidr_range = var.serverless_ip_cidr_range
  network       = google_compute_network.vpcnetwork.id
}

resource "google_compute_global_address" "private_ip_block" {
  name          = var.private_service_access_name
  purpose       = var.psa_purpose
  address_type  = var.address_type
  ip_version    = var.ip_version
  prefix_length = var.prefix_length
  network       = google_compute_network.vpcnetwork.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpcnetwork.id
  service                 = var.service_network
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_compute_route" "webapp_route" {
  name             = var.web_app_route_name
  network          = google_compute_network.vpcnetwork.self_link
  dest_range       = var.web_app_route_cidr
  priority         = var.webapp_route_priority
  next_hop_gateway = var.next_hop_gateway
  tags             = [var.tag_name]
}

resource "google_vpc_access_connector" "serverless-connector" {
  name = var.vpc_connector_name
  subnet {
    name = google_compute_subnetwork.serverless_subnet.name
  }
  machine_type  = var.vpc_connector_machine_type
  min_instances = 2
  max_instances = 7

}

resource "google_service_account" "service_account" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_project_iam_binding" "bind_logging_admin_role" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "bind_monitoring_metric_writer_role" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_pubsub_schema" "schema" {
  name       = var.pubsub_schema_name
  type       = var.pubsub_schema_type
  definition = "{\n  \"type\" : \"record\",\n  \"name\" : \"User\",\n  \"fields\" : [\n    {\n      \"name\" : \"email_id\",\n      \"type\" : \"string\"\n    },\n    {\n      \"name\" : \"first_name\",\n      \"type\" : \"string\"\n    }\n, {\n      \"name\" : \"unique_id\",\n      \"type\" : \"string\"\n    }\n  ]\n}\n"
}

resource "google_pubsub_topic" "verify_email" {
  name                       = var.google_pubsub_topic_name
  message_retention_duration = var.google_pubsub_topic_rtn
  depends_on                 = [google_pubsub_schema.schema]
  schema_settings {
    schema   = google_pubsub_schema.schema.id
    encoding = "JSON"
  }
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = google_pubsub_topic.verify_email.project
  topic   = google_pubsub_topic.verify_email.name
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_pubsub_topic_iam_binding" "publisher_role" {
  project = var.project_id
  topic   = google_pubsub_topic.verify_email.name
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_service_identity" "cloudsql_sa" {
  provider = google-beta

  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_kms_key_ring" "webapp-keyring" {
  name     = var.webapp_keyring
  location = var.region
}


resource "google_kms_crypto_key" "vm_instance_key" {
  name            = var.vm_instance_key
  key_ring        = google_kms_key_ring.webapp-keyring.id
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = false
  }
}


resource "google_kms_crypto_key" "bucket_instance_key" {
  name            = var.bucket_instance_key
  key_ring        = google_kms_key_ring.webapp-keyring.id
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "cloudsql_instance_key" {
  name            = var.cloudsql_instance_key
  key_ring        = google_kms_key_ring.webapp-keyring.id
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_iam_binding" "vm_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.vm_instance_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",
  ]
}

resource "google_kms_crypto_key_iam_binding" "bucket_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.bucket_instance_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com",
  ]
}

resource "google_kms_crypto_key_iam_binding" "cloudsql_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.cloudsql_instance_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
  ]
}

resource "google_sql_database_instance" "mysql_instance" {
  name                = var.mysql_instance_name
  database_version    = var.mysql_version
  region              = var.region
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.private_vpc_connection]
  encryption_key_name = google_kms_crypto_key.cloudsql_instance_key.id
  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.vpcnetwork.self_link
    }

    disk_size         = var.sql_instance_disk_size
    disk_type         = var.sql_instance_disk_type
    availability_type = var.sql_instance_availability_type
    backup_configuration {
      enabled            = var.backup_conf_enabled
      binary_log_enabled = var.binary_log_enabled
    }
  }
}


resource "random_password" "mysql_password" {
  length           = var.mysql_password_length
  special          = var.mysql_password_special_character
  override_special = var.special_characters
}

resource "google_sql_user" "users" {
  name     = var.mysql_username
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.mysql_password.result
}

resource "google_sql_database" "mysql_database" {
  name     = var.mysql_database_name
  instance = google_sql_database_instance.mysql_instance.name
}

resource "google_cloudfunctions2_function" "gcp_function" {
  name     = var.google_func_name
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    environment_variables = {
      BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = var.cloudfunc_bucket_name
        object = var.cloudfunc_arch_name
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    vpc_connector      = google_vpc_access_connector.serverless-connector.id
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
      DB_USER             = google_sql_user.users.name
      DB_PASSWORD         = random_password.mysql_password.result
      DB_URL              = google_sql_database_instance.mysql_instance.private_ip_address
      APPLICATION_PORT    = var.application_port
      DB_PORT             = var.db_port
      DOMAIN_NAME         = var.domain_name
    }
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = var.all_traffic_on_latest_revision_value
    service_account_email          = google_service_account.service_account.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = "RETRY_POLICY_RETRY"

  }
  depends_on = [google_storage_bucket.cloudfunc_bucket_name,google_pubsub_topic.verify_email, google_vpc_access_connector.serverless-connector, google_sql_user.users, google_service_account.service_account, google_sql_database_instance.mysql_instance]
}

resource "google_cloudfunctions2_function_iam_binding" "binding" {
  project        = google_cloudfunctions2_function.gcp_function.project
  cloud_function = google_cloudfunctions2_function.gcp_function.name
  role           = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

data "template_file" "default" {
  template = file("startup-script.sh")
  vars = {
    DB_USER     = google_sql_user.users.name
    DB_PASSWORD = random_password.mysql_password.result
    DB_URL      = "${google_sql_database_instance.mysql_instance.private_ip_address}:3306"
    PROJECT_ID  = var.project_id
    TOPIC_ID    = google_pubsub_topic.verify_email.name
  }
}

#This output is added to fetch db user name and password without ssh in vm
output "file_data" {
  value = data.template_file.default.rendered

  
}
resource "google_storage_bucket" "cloudfunc_bucket_name" {
  name          = var.cloudfunc_bucket_name
  location      = var.region
  force_destroy = true
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_instance_key.id
  }
}

resource "google_storage_bucket_object" "cloudfunc_arch_name" {
  name   = "serverless-fork.zip"
  bucket = google_storage_bucket.cloudfunc_bucket_name.name
  source = "serverless-fork.zip" 

  
}

resource "google_compute_region_instance_template" "webapp_instance_template" {
  name         = var.webapp_instance_template_name
  machine_type = var.machine_type
  tags         = [var.tag_name, var.health_check_tag]

  disk {
    source_image = var.image_name
    disk_size_gb = var.disk_size
    disk_type    = var.disk_type
    auto_delete  = var.auto_delete_val
    boot         = var.boot_val
    

    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_instance_key.id
     
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.webapp.name
    access_config {}
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.service_account_scopes
  }

  metadata_startup_script = data.template_file.default.rendered
}

resource "google_compute_managed_ssl_certificate" "webapp_ssl_cert" {
  #provider = google-beta
  name    = var.webapp_ssl_cert
  project = var.project_id
  managed {
    domains = [var.domain_name]
  }
}

resource "google_project_iam_binding" "instance_admin_binding" {

  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_compute_health_check" "webapp-health-check" {
  name                = var.health_check_name
  description         = "Webapp application health check via HTTP"
  timeout_sec         = var.health_check_timeout
  check_interval_sec  = var.health_check_interval
  healthy_threshold   = var.health_check_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  http_health_check {
    port               = var.application_port
    port_specification = var.port_specification_val
    request_path       = var.healthz_endpoint

  }
  log_config {
    enable = var.log_config_health_check
  }

}


resource "google_compute_region_instance_group_manager" "webapp_igm" {
  name = var.igm_name

  base_instance_name        = var.vm_instance_name
  region                    = var.region
  distribution_policy_zones = var.distribution_policy_zone

  version {
    instance_template = google_compute_region_instance_template.webapp_instance_template.self_link
    name              = "primary"
  }
  named_port {
    name = var.named_port
    port = var.application_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.webapp-health-check.self_link
    initial_delay_sec = var.initial_delay_val
  }
}

resource "google_compute_global_address" "external_ip" {
  name       = var.external_ip_name
  ip_version = var.external_ip_version
  purpose    = var.external_ip_purpose
}


resource "google_compute_firewall" "health_check_firewall" {
  name          = var.fw_health_check_allow
  direction     = var.fw_health_check_direction
  network       = google_compute_network.vpcnetwork.self_link
  priority      = 100
  source_ranges = var.fw_health_check_source_ranges
  target_tags   = [var.health_check_tag]
  allow {
    ports    = var.fw_health_check_ports
    protocol = "tcp"
  }
}


resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = var.webapp_autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_igm.self_link

  autoscaling_policy {
    max_replicas    = var.auto_scaling_max_replicas
    min_replicas    = var.auto_scaling_min_replicas
    cooldown_period = var.auto_scaling_cooldown_time

    cpu_utilization {
      target = 0.05
    }
  }
}

resource "google_compute_backend_service" "webapp_backend_service" {
  name                            = var.backend_service_name
  connection_draining_timeout_sec = var.connection_drain_timeout
  health_checks                   = [google_compute_health_check.webapp-health-check.self_link]
  load_balancing_scheme           = var.lb_scheme
  port_name                       = var.named_port
  protocol                        = var.backend_protocol
  timeout_sec                     = var.backend_timeout
  backend {
    group          = google_compute_region_instance_group_manager.webapp_igm.instance_group
    balancing_mode = var.lb_balancing_mode
    # capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "webapp_url_map" {
  name            = var.webapp_url_map_name
  default_service = google_compute_backend_service.webapp_backend_service.self_link
}

resource "google_compute_target_https_proxy" "webapp_https_proxy" {
  #provider = google-beta
  name    = var.https_proxy_name
  project = var.project_id
  url_map = google_compute_url_map.webapp_url_map.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.webapp_ssl_cert.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.webapp_ssl_cert
  ]
}

resource "google_compute_global_forwarding_rule" "webapp_lb" {
  name = var.webapp_lb_name
  #ip_protocol           = "TCP"
  #load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range = var.ssl_port
  target     = google_compute_target_https_proxy.webapp_https_proxy.id
  ip_address = google_compute_global_address.external_ip.id
}

resource "google_dns_record_set" "default" {
  managed_zone = var.zone_name
  name         = var.dns_record_set_name
  type         = var.dns_type
  rrdatas      = [google_compute_global_address.external_ip.address]
  ttl          = var.ttl

}

#Create a firewall rule to block traffic to the SSH port
resource "google_compute_firewall" "block_ssh_port" {
  name    = var.block_ssh_firewall_name
  network = google_compute_network.vpcnetwork.name

  deny {
    protocol = "tcp"
    ports    = ["22"] # SSH port
  }
  source_ranges = ["0.0.0.0/0"] 
}

resource "google_compute_firewall" "allow_application_port" {
  name    = var.allow_application_port_firewall_name
  network = google_compute_network.vpcnetwork.self_link

  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }

  source_ranges = ["${google_compute_global_address.external_ip.address}/32", var.source_range_ip1, var.source_range_ip2]
  target_tags   = [var.tag_name]
}

