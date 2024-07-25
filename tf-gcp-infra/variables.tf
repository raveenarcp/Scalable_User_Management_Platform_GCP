variable "project_id" {
  description = "The unique identifier for the Google Cloud Platform (GCP) project."
  type        = string
}

variable "region" {
  description = "The geographic region where resources will be provisioned within GCP."
  type        = string
}

variable "zone" {
  description = "The specific zone within the chosen region where resources will be deployed."
  type        = string
}

variable "vpc_name" {
  description = "The name of the Virtual Private Cloud (VPC) network."
  type        = string
}

variable "web_subnet_name" {
  description = "The name of the subnet for the web application servers."
  type        = string
}

variable "db_subnet_name" {
  description = "The name of the subnet for the database servers."
  type        = string
}

variable "web_app_route_name" {
  description = "The name of the route for directing traffic to the web application subnet."
  type        = string
}

variable "web_app_cidr" {
  description = "The Classless Inter-Domain Routing (CIDR) block for the web application subnet."
  type        = string
}

variable "db_cidr" {
  description = "The CIDR block for the database subnet."
  type        = string
}

variable "web_app_route_cidr" {
  description = "The CIDR block for the route directing traffic to the web application subnet."
  type        = string
}

variable "auto_create_subnets" {
  description = "Set to true to automatically create subnets, false otherwise."
  type        = bool
}

variable "delete_default_routes" {
  description = "Set to true to delete default routes, false otherwise."
  type        = bool
}

variable "routing_mode" {
  description = "The routing mode for the VPC, e.g., 'GLOBAL' or 'REGIONAL'."
  type        = string
}

variable "private_ip_google_access" {
  description = "Enable or disable access to Google services using private IP addresses."
  type        = bool
}

variable "next_hop_gateway" {
  description = "The next hop gateway used for routing traffic."
  type        = string
}

variable "application_port" {
  description = "Application port"
  type        = string
}

variable "webapp_route_priority" {
  description = "Priority of webapp route"
  type        = number
  default     = 1000
}

variable "image_name" {

  description = "Custom image name"
  type        = string
}

variable "vm_instance_name" {
  description = "VM instance name"
  type        = string
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
}

variable "disk_size" {
  description = "Boot disk size"
  type        = string
}

variable "machine_type" {
  description = "Machine Type to use to create VM"
  type        = string
  default     = "e2-standard-2"
}

variable "tag_name" {
  description = "Tag name with which VM need to be tagged"
  type        = string
  default     = "gcp-instance"
}

variable "block_ssh_firewall_name" {
  description = "Name of the firewall that blocks SSH"
  type        = string
  default     = "block-ssh-port"
}

variable "allow_application_port_firewall_name" {
  description = "Name of the firewall that allows traffic on application port"
  type        = string
  default     = "allow-application-port"
}

variable "private_service_access_name" {
  description = "Name of Private IP Block"
  type        = string
}

variable "psa_purpose" {
  description = "Purpose of the Private IP-Block"
  type        = string
}

variable "address_type" {
  description = "Address type for the Private IP-Block"
  type        = string
}

variable "ip_version" {
  description = "IP version for the Private IP-Block"
  type        = string
}

variable "prefix_length" {
  description = "Prefix length for IP of the Private IP-Block"
  type        = number
}

variable "service_network" {
  description = "Service Networking API"
  type        = string
  default     = "servicenetworking.googleapis.com"
}

variable "mysql_instance_name" {
  description = "Name of the mysql instance"
  type        = string
  default     = "mysql-instance"
}

variable "mysql_version" {
  description = "Mysql Version to use"
  type        = string
  default     = "MYSQL_8_0"
}

variable "deletion_protection" {
  description = "Whether the instance should be protected from deletion"
  type        = bool
  default     = false
}

variable "db_tier" {
  description = "DB instance tier to use"
  type        = string
  default     = "db-f1-micro"
}

variable "ipv4_enabled" {
  description = "Whether the instance should be assigned a public IPV4 address"
  type        = bool
  default     = false
}

variable "sql_instance_disk_size" {
  description = "Disk Size of the SQL Instance"
  type        = number
  default     = 100
}

variable "sql_instance_disk_type" {
  description = "Disk Type of the SQL Instance"
  type        = string
  default     = "pd-ssd"
}

variable "sql_instance_availability_type" {
  description = "SQL Instance availaility type"
  type        = string
  default     = "REGIONAL"
}

variable "backup_conf_enabled" {
  description = "Whether backup should be configured"
  type        = bool
  default     = true
}

variable "binary_log_enabled" {
  description = "Whether binary logging enabled. Used only with MySQL"
  type        = bool
  default     = true
}

variable "mysql_password_length" {
  description = "Length of mysql password"
  type        = number
  default     = 16
}

variable "mysql_password_special_character" {
  description = "Whether special characters should be used in password"
  type        = bool
  default     = true
}

variable "special_characters" {
  description = "Special characters to use in password"
  type        = string
  default     = "()-_=+[]{}<>:?"
}

variable "mysql_username" {
  description = "Name of the MySQL user"
  type        = string
  default     = "webapp"
}

variable "mysql_database_name" {
  description = "Name of the MySQL Database"
  type        = string
  default     = "mysql-database"
}

variable "zone_name" {
  description = "Name of the zone"
  type        = string
  default     = "csye6225"
}

variable "dns_name" {
  description = "Name of the DNS"
  type        = string
  default     = "raveenarcp-cloud6225.me."
}

variable "ttl" {
  description = "Time to live"
  type        = number
  default     = 300
}

variable "dns_record_set_name" {
  description = "DNS record set name"
  type        = string
  default     = "raveenarcp-cloud6225.me."

}

variable "dns_type" {
  description = "DNS type"
  type        = string
  default     = "A"

}

variable "service_account_scopes" {
  type    = list(string)
  default = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
}

variable "google_pubsub_topic_name" {
  description = "pubsub topic name"
  type        = string
  default     = "verify_email"

}

variable "google_pubsub_topic_rtn" {
  description = "pubsub topic retention"
  type        = string
  default     = "604800s"

}

variable "google_pubsub_subscription_name" {
  description = "pubsub subscription name"
  type        = string
  default     = "gcp_subscription"

}

variable "google_func_name" {
  description = "gcp function name"
  type        = string
  default     = "gcp_function"

}

variable "cloudfunc_bucket_name" {
  description = "gcp bucket name"
  type        = string
  default     = "serverless_cloud6225"

}

variable "cloudfunc_arch_name" {
  description = "gcp archive name"
  type        = string
  default     = "serverless-fork.zip"

}

variable "runtime" {
  description = "runtime name"
  type        = string
  default     = "python39"

}

variable "entry_point" {
  description = "entry_point name"
  type        = string
  default     = "send_verification_email"

}

variable "serverless_subnet_name" {
  description = "name of the subnet used for connector"
  type        = string
  default     = "serverless-subnet"

}

variable "domain_name" {
  description = "Name of the domain"
  type        = string
  default     = "raveenarcp-cloud6225.me"
}

variable "pubsub_schema_name" {
  description = "Name of the pubsub schema name"
  type        = string
  default     = "pub-sub-schema"
}

variable "pubsub_schema_type" {
  description = "Name of the pubsub schema type"
  type        = string
  default     = "AVRO"
}


variable "db_port" {
  description = "Value of the DB port"
  type        = string
  default     = "3306"

}

variable "ingress_settings" {
  description = "ingress_settings value"
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"

}

variable "serverless_ip_cidr_range" {
  description = "serverless ip cidr range"
  type        = string
  default     = "10.10.10.0/28"

}

variable "vpc_connector_name" {
  description = "vpc connector name"
  type        = string
  default     = "cloud-serverless"

}

variable "vpc_connector_machine_type" {
  description = "vpc machine type"
  type        = string
  default     = "f1-micro"

}

variable "all_traffic_on_latest_revision_value" {
  description = "all traffic on latest revision"
  type        = bool
  default     = true
}

variable "health_check_name" {
  description = "Name of the health check resource"
  type        = string
  default     = "webapp-health-check"
}

variable "healthz_endpoint" {
  description = "Endpoint to check for webapp health"
  type        = string
  default     = "/healthz"
}


variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 3
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10
}

variable "health_check_threshold" {
  description = "Health check threshold in seconds"
  type        = number
  default     = 4
}

variable "health_check_unhealthy_threshold" {
  description = "Health check unhealthy threshold in seconds"
  type        = number
  default     = 5
}


variable "webapp_instance_template_name" {
  description = "Name of the webapp image template"
  type        = string
  default     = "webapp-instance-template"
}

variable "igm_name" {
  description = "Name of the instance group manager"
  type        = string
  default     = "webapp-igm"
}

variable "webapp_autoscaler_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "webapp-autoscaler"
}

variable "webapp_target_pool_name" {
  description = "Name of the target pool for instances"
  type        = string
  default     = "webapp-target-pool"
}


variable "webapp_ssl_cert" {
  description = "Name given for the SSL cert used for webapp"
  type        = string
  default     = "webapp-ssl-cert"
}


variable "health_check_tag" {
  description = "Tag used for allowing health check traffic"
  type        = string
  default     = "allow-health-check"
}


variable "auto_delete_val" {
  description = "Auto delete VMs"
  type        = bool
  default     = true
}

variable "boot_val" {
  description = "Whether to boot the VM"
  type        = bool
  default     = true
}

variable "port_specification_val" {
  description = "Port specification for health check"
  type        = string
  default     = "USE_FIXED_PORT"
}

variable "log_config_health_check" {
  description = "Whether to boot the VM"
  type        = bool
  default     = false
}

variable "distribution_policy_zone" {
  description = "Whether to boot the VM"
  type        = list(string)
  default     = ["us-east4-c"]
}

variable "named_port" {
  description = "Port name"
  type        = string
  default     = "http"
}

variable "initial_delay_val" {
  description = "Initial time to wait for health check to auto heal"
  type        = number
  default     = 120
}

variable "auto_healing_action" {
  description = "Action to be performed in case of health check failure"
  type        = string
  default     = "RECREATE"
}


variable "external_ip_name" {
  description = "Name of the external IP used for LB"
  type        = string
  default     = "lb-external-ip"
}

variable "external_ip_version" {
  description = "Type of the external IP used for LB"
  type        = string
  default     = "IPV4"
}

variable "external_ip_purpose" {
  description = "Purpsoe of the external IP used for LB"
  type        = string
  default     = "GLOBAL"
}

variable "fw_health_check_allow" {
  description = "Name of the firewall to allow health check traffic"
  type        = string
  default     = "fw-allow-health-check"
}

variable "fw_health_check_direction" {
  description = "Direction of the firewall to allow health check traffic"
  type        = string
  default     = "INGRESS"
}

variable "fw_health_check_source_ranges" {
  description = "Source ranges to allow health check traffic"
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

variable "fw_health_check_ports" {
  description = "Ports to allow traffic"
  type        = list(string)
  default     = ["5000", "443"]
}

variable "auto_scaling_max_replicas" {
  description = "Max replicas to create for auto scaling"
  type        = number
  default     = 6
}

variable "auto_scaling_min_replicas" {
  description = "Min replicas to create for auto scaling"
  type        = number
  default     = 3
}

variable "auto_scaling_cooldown_time" {
  description = "Cool down time for auto scaling"
  type        = number
  default     = 60
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
  default     = "webapp-backend-service"
}

variable "connection_drain_timeout" {
  description = "Connection drain timeout"
  type        = number
  default     = 300
}

variable "lb_scheme" {
  description = "load balancing scheme"
  type        = string
  default     = "EXTERNAL"
}

variable "lb_balancing_mode" {
  description = "load balancing mode"
  type        = string
  default     = "UTILIZATION"
}

variable "backend_timeout" {
  description = "backend timeout"
  type        = number
  default     = 30
}

variable "backend_protocol" {
  description = "Protocol used for backend service"
  type        = string
  default     = "HTTP"
}

variable "webapp_url_map_name" {
  description = "Name of the URL mapper"
  type        = string
  default     = "webapp-map-https"
}

variable "https_proxy_name" {
  description = "Name of the https proxy"
  type        = string
  default     = "https-lb-proxy"
}

variable "ssl_port" {
  description = "Port of the SSL"
  type        = string
  default     = "443"
}

variable "webapp_lb_name" {
  description = "Webapp LB Name"
  type        = string
  default     = "https-content-rule"
}

variable "source_range_ip1" {
  description = "IP source range to allow traffic from"
  type        = string
  default     = "130.211.0.0/22"
}

variable "source_range_ip2" {
  description = "IP source range to allow traffic from"
  type        = string
  default     = "35.191.0.0/16"
}


variable "webapp_keyring"{
  description = "Web app key ring"
  type        = string
  default     = "webapp-keyring-18"
}

variable "vm_instance_key"{
  description = "Name of CMEK for VM"
  type        = string
  default     = "vm-instance-key-18"
}

variable "bucket_instance_key"{
  description = "Name of CMEK for bucket"
  type        = string
  default     = "bucket-instance-key-18"
}

variable "cloudsql_instance_key"{
  description = "Name of CMEK for cloudsql"
  type        = string
  default     = "cloudsql-instance-key-18"
}

variable "prevent_destroy" {
  description = "Prevent destroy of CMEK"
  type        = bool
  default     = false
  
}