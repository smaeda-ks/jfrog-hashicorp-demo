variable "jfrog_user_name" {
  type = string
}

variable "jfrog_api_key" {
  type = string
}

variable "docker_image_path" {
  type = string
}

job "production" {
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
        name     = "production"
        provider = "nomad"
        port     = "http"
      }

      env {
        PORT = "${NOMAD_PORT_http}"
      }

      config {
        image = var.docker_image_path
        ports = [
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
