locals {
  environment = "staging"
  project     = "generic-gha"
  region      = "ap-southeast-1"

  # Service definitions
  services = {
    api-golang = {
      port              = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/api/golang/ping"
      path_pattern      = ["/api/golang/*"]
      priority          = 100
      needs_database    = true
    }
    api-node = {
      port              = 3000
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/api/node/health"
      path_pattern      = ["/api/node/*"]
      priority          = 200
      needs_database    = true
    }
    load-generator-python = {
      cpu            = 256
      memory         = 512
      desired_count  = 1 # Enable to generate load
      needs_database = false
    }
    client-react = {
      port              = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/ping"
      path_pattern      = ["/*"]
      priority          = 999 # Catch-all, lowest priority
      needs_database    = false
    }
  }
}
