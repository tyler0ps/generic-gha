locals {
  environment = "staging"
  project     = "generic-gha"
  region      = "ap-southeast-1"
  azs         = ["ap-southeast-1a", "ap-southeast-1b"]

  # Service definitions
  services = {
    api-golang = {
      port              = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/ping"
      path_pattern      = ["/api/golang/*"]
      priority          = 100
      needs_database    = true
    }
    api-node = {
      port              = 3000
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/health"
      path_pattern      = ["/api/node/*"]
      priority          = 200
      needs_database    = true
    }
    load-generator-python = {
      port              = 8000
      cpu               = 256
      memory            = 512
      desired_count     = 0 # Scale up when needed
      health_check_path = "/health"
      path_pattern      = ["/load/*"]
      priority          = 300
      needs_database    = false
    }
    client-react = {
      port              = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      health_check_path = "/"
      path_pattern      = ["/*"]
      priority          = 999 # Catch-all, lowest priority
      needs_database    = false
    }
  }
}
