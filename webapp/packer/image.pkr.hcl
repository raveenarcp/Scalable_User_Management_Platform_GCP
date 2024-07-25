variable "project_id" {
  type    = string
  default = "dev-gcp-project-414721"
}

variable "source_image_family" {
  type    = string
  default = "centos-stream-8"
}

variable "zone" {
  type    = string
  default = "us-east4-c"
}
variable "WEBAPP_FILE_PATH" {
  type = string
  #default = "/home/runner/work/webapp/webapp/webapp.zip"
  default = "./webapp.zip"
}

variable "GCP_CREDENTIALS_JSON" {
  type    = string
  default = "./packer-svc.json"

}


packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "centos-stream-8" {
  project_id              = var.project_id
  source_image_project_id = ["centos-cloud"]
  image_name              = "centos-8-packer-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  source_image_family     = var.source_image_family
  machine_type            = "n1-standard-1"
  zone                    = var.zone
  disk_size               = 50
  disk_type               = "pd-balanced"
  network                 = "default"
  image_description       = "Custom image with Python 3.9 & MySQL"
  image_labels = {
    environment = "dev"
  }
  ssh_username     = "packer"
  credentials_file = var.GCP_CREDENTIALS_JSON
}

build {
  sources = ["source.googlecompute.centos-stream-8"]

  provisioner "shell" {
    scripts = [
      "python.sh"
    ]
  }
  provisioner "shell" {
    script = "create_user.sh"
  }

  provisioner "file" {
    source      = var.WEBAPP_FILE_PATH
    destination = "/tmp/"
  }

  provisioner "shell" {
    script = "install_dependencies.sh"
  }

  provisioner "shell" {
    script = "user.sh"
  }

  provisioner "file" {
    source      = "webapp.service"
    destination = "/tmp/webapp.service"
  }

  provisioner "file" {
    source      = "config.yaml"
    destination = "/tmp/config.yaml"
  }

  provisioner "shell" {
    script = "ops_agent.sh"
  }

  provisioner "shell" {
    script = "start_service.sh"
  }

}
