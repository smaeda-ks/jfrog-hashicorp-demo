job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    service {
      provider = "nomad"
      name     = "nginx"
      port     = "http"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      # NOTE: If you're not using Docker Desktop,
      # replace "host.docker.internal" with "{{ .Address }}" below
      template {
        data = <<EOF
upstream production {
  {{- range nomadService "production" }}
  server host.docker.internal:{{ .Port }};{{- end }}
}

{{ range nomadServices -}}
{{ if .Name | regexMatch "^staging-.*$" }}
upstream {{ .Name | toLower | replaceAll "/" "-" }} {
  {{- range nomadService .Name }}
  server host.docker.internal:{{ .Port }};{{- end }}
}
{{ end }}
{{- end }}

server {
  listen 8080;

{{ range nomadServices -}}
{{ if .Name | regexMatch "^staging-.*$" }}
  location /{{ .Name | toLower | replaceAll "/" "-" }}/ {
    proxy_pass http://{{ .Name | toLower | replaceAll "/" "-" }}/;
  }
{{ end }}
{{- end }}

  location / {
    proxy_pass http://production;
  }
}
EOF

        destination   = "local/nginx.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
