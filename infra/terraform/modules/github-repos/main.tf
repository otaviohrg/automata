terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "github_token" {
  type = string
  sensitive = true
}

variable "repo_name" {
  type = string
  default = "automata"
}

variable "tailscale_auth_key" {
  type = string
  sensitive = true
}

variable "ghcr_user" {
    type = string
    sensitive = false
}

provider "github" {
  token = var.github_token
}

resource "github_repository" "automata" {
  name          = var.repo_name
  description   = "Robotics & AI portfolio monorepo"
  visibility    = "public"

  has_issues                = true
  has_projects              = false
  has_wiki                  = false
  delete_branch_on_merge    = true 
  allow_squash_merge        = true
  allow_merge_commit        = false
  allow_rebase_merge        = false
}

resource "github_branch_protection" "main" {
  repository_id     = github_repository.automata.node_id
  pattern           = "main"

  required_status_checks {
    strict = true
    contexts = [
        "CI — container images",
        "CI — Rust firmware",
        "CI — Go telemetry server",
        "CI — Python projects",
        "CI — IaC validation",
    ]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  allows_force_pushes = false
}

resource "github_actions_secret" "tailscale_auth_key" {
  repository      = github_repository.automata.name
  secret_name     = "TAILSCALE_AUTH_KEY"
  value           = var.tailscale_auth_key
}

resource "github_actions_variable" "ghcr_user" {
  repository    = github_repository.automata.name
  variable_name = "GHCR_USER"
  value         = var.ghcr_user
}

output "repo_full_name" {
  value = github_repository.automata.full_name
}
