
#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PACK_NAME="Pack 15 (CI-CD and Production Operations)"
PACK="$SCRIPT_DIR/$PACK_NAME"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ ! -d "$PACK" ]]; then
    echo "ERROR: Directory not found:"
    printf '  %q\n' "$PACK"
    exit 1
fi

CONCEPTS=(
    "Docker in CI/CD Pipelines"
    "Building Images in CI Pipelines"
    "Automated Image Testing"
    "Image Tagging Strategies"
    "Semantic Versioning for Images"
    "Immutable Image Tags"
    "Automated Image Publishing"
    "Container Registry Authentication in CI"
    "GitHub Actions with Docker"
    "GitLab CI with Docker"
    "Jenkins with Docker"
    "Multi-Stage CI/CD Pipelines"
    "Build Caching in CI/CD"
    "BuildKit in CI/CD"
    "Multi-Architecture Builds in CI/CD"
    "Docker Image Vulnerability Scanning"
    "Software Bill of Materials (SBOM)"
    "Image Signing and Verification"
    "Supply Chain Security"
    "Deployment with Docker Compose"
    "Zero-Downtime Container Deployment"
    "Rolling Updates with Containers"
    "Blue-Green Deployment with Containers"
    "Canary Deployment with Containers"
    "Environment Configuration in Production"
    "Secrets Management in Production"
    "Container Health Checks in Deployment"
    "Rollback Strategies"
    "Container Resource Limits in Production"
    "Production Logging Strategies"
    "Production Monitoring and Alerting"
    "Container Backup and Recovery"
    "Docker Deployment Troubleshooting"
    "Production Docker Checklist"
)

max_index=-1
created=0
skipped=0

for file in "$PACK"/*.md; do
    filename="${file##*/}"

    if [[ "$filename" =~ ^([0-9]+)[[:space:]]+- ]]; then
        index=$((10#${BASH_REMATCH[1]}))

        if (( index > max_index )); then
            max_index=$index
        fi
    fi
done

next_index=$((max_index + 1))

for concept in "${CONCEPTS[@]}"; do

    exists=false

    for file in "$PACK"/*.md; do
        filename="${file##*/}"

        if [[ "$filename" == *" - $concept.md" ]]; then
            exists=true
            break
        fi
    done

    if [[ "$exists" == true ]]; then
        echo "[SKIP] $concept"
        ((skipped+=1))
        continue
    fi

    printf -v filename "%02d - %s.md" "$next_index" "$concept"
    filepath="$PACK/$filename"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] $filename"
    else
        printf '[[Docker]]\n' > "$filepath"
        echo "[CREATED] $filename"
    fi

    ((created+=1))
    ((next_index+=1))

done

echo
echo "Finished."
echo "Created/planned: $created"
echo "Skipped: $skipped"
echo "Directory: $PACK"
