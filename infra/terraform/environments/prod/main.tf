terraform {
  required_version = ">= 1.7"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "ansible_vault_password" {
  type      = string
  sensitive = true
}

variable "ghcr_user" {
  type      = string
  sensitive = false
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
  type = string
}

module "github_repos" {
  source = "../../modules/github-repos"

  github_token           = var.github_token
  repo_name              = "automata"
  tailscale_auth_key     = var.tailscale_auth_key
  ansible_vault_password = var.ansible_vault_password
  ghcr_user              = var.ghcr_user
}

module "tailscale_acl" {
  source = "../../modules/tailscale-acl"

  tailscale_oauth_client_id     = var.tailscale_oauth_client_id
  tailscale_oauth_client_secret = var.tailscale_oauth_client_secret
  tailnet                       = var.tailnet
}
