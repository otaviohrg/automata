#!/usr/bin/env bash
# update-images.sh — rebuild and push helix images to GHCR
# Only rebuilds images whose Dockerfile or context has changed since last push.
#
# Usage:
#   ./scripts/update-images.sh                  # auto-detect what changed
#   ./scripts/update-images.sh --all            # force rebuild both
#   ./scripts/update-images.sh --base           # force rebuild base only
#   ./scripts/update-images.sh --ml             # force rebuild ml only
#   ./scripts/update-images.sh --dry-run        # show what would be built, do nothing
#
# Requirements:
#   - GHCR_USER environment variable set (your GitHub username)
#   - Logged in to ghcr.io: echo $GITHUB_TOKEN | docker login ghcr.io -u $GHCR_USER --password-stdin
#   - docker-buildx installed (sudo pacman -S docker-buildx)

set -euo pipefail

# ─── configuration ────────────────────────────────────────────────────────────

GHCR_USER="${GHCR_USER:?GHCR_USER environment variable is not set. Add it to your shell config.}"
REGISTRY="ghcr.io/${GHCR_USER}"

BASE_IMAGE="${REGISTRY}/helix-base"
ML_IMAGE="${REGISTRY}/helix-ml"

BASE_CONTEXT="shared/images/helix-base"
ML_CONTEXT="shared/images/helix-ml"

# Tag format: latest + a dated tag for rollback
DATE_TAG=$(date +%Y%m%d)

# ─── colours ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BLUE}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ─── argument parsing ─────────────────────────────────────────────────────────

BUILD_BASE=false
BUILD_ML=false
DRY_RUN=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --all)     BUILD_BASE=true; BUILD_ML=true; FORCE=true ;;
    --base)    BUILD_BASE=true; FORCE=true ;;
    --ml)      BUILD_ML=true;   FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    *)
      error "Unknown argument: $arg"
      echo "Usage: $0 [--all|--base|--ml|--dry-run]"
      exit 1
      ;;
  esac
done

# ─── helpers ──────────────────────────────────────────────────────────────────

# Returns the git ref of the last commit that touched a path.
# Used to detect changes since the last image was pushed.
last_commit_for_path() {
  git log -1 --format="%H" -- "$1" 2>/dev/null || echo "none"
}

# Checks whether a GHCR image has a label recording the git commit it was built from.
# Returns the stored commit hash, or empty string if not found.
remote_image_commit() {
  local image="$1"
  docker manifest inspect "${image}:latest" 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
labels = {}
for item in data.get('manifests', [{}]):
    pass
# Try top-level config
config = data.get('config', {})
labels = config.get('Labels', {}) or {}
print(labels.get('org.opencontainers.image.revision', ''))
" 2>/dev/null || echo ""
}

# Detects whether a path has changed since the commit recorded in the remote image.
has_changed_since_push() {
  local context_path="$1"
  local remote_commit="$2"

  if [[ -z "$remote_commit" ]]; then
    # No remote commit recorded — treat as changed
    return 0
  fi

  # Check if any files in the context changed after the remote commit
  local changes
  changes=$(git diff --name-only "${remote_commit}..HEAD" -- "${context_path}" 2>/dev/null)

  if [[ -n "$changes" ]]; then
    return 0  # changed
  else
    return 1  # no change
  fi
}

# Builds and pushes a single image.
build_and_push() {
  local name="$1"
  local image="$2"
  local context="$3"

  local git_sha
  git_sha=$(git rev-parse HEAD)

  header "Building ${name}"
  info "Image:   ${image}"
  info "Context: ${context}"
  info "Tags:    latest, ${DATE_TAG}"
  info "Git SHA: ${git_sha}"

  if [[ "$DRY_RUN" == true ]]; then
    warn "Dry run — skipping build and push"
    return
  fi

  docker build \
    --label "org.opencontainers.image.revision=${git_sha}" \
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "org.opencontainers.image.source=https://github.com/${GHCR_USER}/helix-core" \
    --label "org.opencontainers.image.title=${name}" \
    --tag "${image}:latest" \
    --tag "${image}:${DATE_TAG}" \
    "${context}"

  info "Pushing ${image}:latest ..."
  docker push "${image}:latest"

  info "Pushing ${image}:${DATE_TAG} ..."
  docker push "${image}:${DATE_TAG}"

  success "${name} pushed successfully"
}

# ─── pre-flight checks ────────────────────────────────────────────────────────

header "helix image updater"

# Confirm we are at the repo root
if [[ ! -f "docker-compose.yml" ]]; then
  error "Run this script from the helix-core repo root (where docker-compose.yml lives)."
  exit 1
fi

# Confirm git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  error "Not inside a git repository."
  exit 1
fi

# Confirm GHCR login
if ! docker manifest inspect "${BASE_IMAGE}:latest" > /dev/null 2>&1; then
  warn "Cannot reach ${BASE_IMAGE}:latest — either not pushed yet or not logged in."
  warn "If this is first push, run:"
  warn "  echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GHCR_USER --password-stdin"
  warn "Proceeding — will attempt push anyway."
fi

# ─── change detection (when no explicit flag given) ───────────────────────────

if [[ "$FORCE" == false ]]; then
  header "Detecting changes"

  info "Fetching remote image metadata ..."

  BASE_REMOTE_COMMIT=$(remote_image_commit "${BASE_IMAGE}")
  ML_REMOTE_COMMIT=$(remote_image_commit "${ML_IMAGE}")

  if [[ -z "$BASE_REMOTE_COMMIT" ]]; then
    warn "No revision label found on ${BASE_IMAGE}:latest — will rebuild"
    BUILD_BASE=true
  elif has_changed_since_push "${BASE_CONTEXT}" "${BASE_REMOTE_COMMIT}"; then
    info "${BASE_CONTEXT} has changed since last push (${BASE_REMOTE_COMMIT:0:8})"
    BUILD_BASE=true
  else
    success "${BASE_CONTEXT} unchanged since last push — skipping"
  fi

  if [[ -z "$ML_REMOTE_COMMIT" ]]; then
    warn "No revision label found on ${ML_IMAGE}:latest — will rebuild"
    BUILD_ML=true
  elif has_changed_since_push "${ML_CONTEXT}" "${ML_REMOTE_COMMIT}"; then
    info "${ML_CONTEXT} has changed since last push (${ML_REMOTE_COMMIT:0:8})"
    BUILD_ML=true
  else
    success "${ML_CONTEXT} unchanged since last push — skipping"
  fi

  # helix-ml depends on helix-base — if base changed, ml must also rebuild
  # even if its own Dockerfile did not change, because the base layer is different
  if [[ "$BUILD_BASE" == true && "$BUILD_ML" == false ]]; then
    warn "helix-base changed — helix-ml inherits from it and must also rebuild"
    BUILD_ML=true
  fi
fi

# ─── build summary ────────────────────────────────────────────────────────────

header "Build plan"

if [[ "$BUILD_BASE" == false && "$BUILD_ML" == false ]]; then
  success "Both images are up to date — nothing to do"
  echo ""
  info "To force a rebuild: $0 --all"
  exit 0
fi

[[ "$BUILD_BASE" == true ]] && info "Will build: helix-base" || info "Skip:       helix-base (unchanged)"
[[ "$BUILD_ML"   == true ]] && info "Will build: helix-ml"   || info "Skip:       helix-ml (unchanged)"

if [[ "$DRY_RUN" == true ]]; then
  warn "Dry run mode — no images will be built or pushed"
fi

echo ""
read -r -p "Proceed? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  info "Aborted"
  exit 0
fi

# ─── build ────────────────────────────────────────────────────────────────────

# Always build base before ml — ml inherits from base
if [[ "$BUILD_BASE" == true ]]; then
  build_and_push "helix-base" "${BASE_IMAGE}" "${BASE_CONTEXT}"
fi

if [[ "$BUILD_ML" == true ]]; then
  # If we just rebuilt base, ensure docker uses the fresh local image
  # rather than a potentially cached remote layer
  if [[ "$BUILD_BASE" == true ]]; then
    info "Tagging fresh helix-base:latest for helix-ml build context"
    docker tag "${BASE_IMAGE}:latest" "helix-base:latest"
  fi
  build_and_push "helix-ml" "${ML_IMAGE}" "${ML_CONTEXT}"
fi

# ─── done ─────────────────────────────────────────────────────────────────────

header "Done"
success "Images updated and pushed to ${REGISTRY}"
echo ""
info "Pull on another machine:"
echo "  docker pull ${BASE_IMAGE}:latest"
echo "  docker pull ${ML_IMAGE}:latest"
echo ""
info "Rollback to previous build:"
echo "  docker pull ${BASE_IMAGE}:${DATE_TAG}"
echo "  docker pull ${ML_IMAGE}:${DATE_TAG}"
