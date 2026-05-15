terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "repo_name" {
  type    = string
  default = "helix"
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "ghcr_user" {
  type      = string
  sensitive = false
}

variable "ansible_vault_password" {
  type      = string
  sensitive = true
}

provider "github" {
  token = var.github_token
}

resource "github_repository" "helix_core" {
  name        = var.repo_name
  description = "Helix - robotics infrastructure hub"
  visibility  = "public"

  has_issues             = true
  has_projects           = false
  has_wiki               = false
  delete_branch_on_merge = true
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.helix_core.node_id
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = [
      "Publish images / build-and-push",
      "Handle infrastructure / terraform",
      "Handle infrastructure / ansible-lint",
      "Handle infrastructure / telemetry-server",
      "Handle infrastructure / firmware",
    ]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  allows_force_pushes = false
}

resource "github_actions_secret" "tailscale_auth_key" {
  repository  = github_repository.helix_core.name
  secret_name = "TAILSCALE_AUTH_KEY"
  value       = var.tailscale_auth_key
}

resource "github_actions_secret" "ansible_vault_password" {
  repository  = github_repository.helix_core.name
  secret_name = "ANSIBLE_VAULT_PASSWORD"
  value       = var.ansible_vault_password
}

resource "github_actions_variable" "ghcr_user" {
  repository    = github_repository.helix_core.name
  variable_name = "GHCR_USER"
  value         = var.ghcr_user
}

output "repo_full_name" {
  value = github_repository.helix_core.full_name
}
