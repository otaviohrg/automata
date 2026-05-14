terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.15"
    }
  }
}

variable "tailscale_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "tailscale_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "tailnet" {
  type        = string
  description = "Your tailnet name, e.g. your-tailnet.ts.net"
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
  tailnet             = var.tailnet
}

resource "tailscale_acl" "name" {
  acl = jsonencode(
    {
      tagOwners = {
        "tag:monitoring"  = [],
        "tag:robot"       = [],
        "tag:workstation" = [],
      }

      acls = [
        {
          action = "accept"
          src    = ["tag:workstation"]
          dst    = ["*:*"]
        },
        {
          action = "accept"
          src    = ["tag:robot"]
          dst    = ["tag:monitoring:50051"]
        },
        {
          action = "accept"
          src    = ["tag:monitoring"]
          dst    = ["tag:robot:9090"]
        },
      ]

      ssh = [
        {
          action = "accept"
          src    = ["tag:workstation"]
          dst    = ["tag:monitoring", "tag:robot"]
          users  = ["autogroup:nonroot"]
        },
      ]
    }
  )
}

resource "tailscale_dns_nameservers" "automata" {
  nameservers = ["100.100.100.100", "1.1.1.1"]
}
