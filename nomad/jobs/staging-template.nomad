# input variables are supplied by GitHub Actions on-demand
variable "jfrog_user_name" {
  type = string
}

variable "jfrog_api_key" {
  type = string
}

variable "docker_image_path" {
  type = string
}

# NOTE: this has nothing to do other than making sure that
# every new push to the PR will launch a fresh job
# even if there are no changes in the job definition.
variable "git_hash" {
  type = string
}

# GitHub Actions will replace placeholders accordingly
job "####JOB_IDENTIFIER_PLACEHOLDER####" {
  datacenters = ["dc1"]
  type        = "service"

  group "server" {
    count = 1
    network {
      # dynamic port assignment
      port "http" {
        to = -1
      }
    }
    task "app" {
      driver = "docker"

      service {
        name     = "####JOB_IDENTIFIER_PLACEHOLDER####"
        provider = "nomad"
        port     = "http"
      }

      env {
        PORT = "${NOMAD_PORT_http}"
        GIT_HASH = var.git_hash
      }

      config {
        force_pull = true
        image      = var.docker_image_path
        ports      = [
          "http",
        ]
        auth {
          username = var.jfrog_user_name
          password = var.jfrog_api_key
        }
      }
    }
  }
}
