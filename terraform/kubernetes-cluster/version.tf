terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    shell = {
      source =  "scottwinkler/shell"
      version = "~> 1.7.10"
    }
    tls = {
      source =  "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }

  required_version = ">= 1.3.9"
}
