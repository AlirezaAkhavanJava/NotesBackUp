
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"

if [[ "$(basename "$ROOT")" != "Github-Acions" ]]; then
    echo "ERROR: Run inside the Github-Acions directory."
    exit 1
fi

created=0
skipped=0

create_notes() {
    local folder="$1"
    shift

    local directory="$ROOT/$folder"
    mkdir -p "$directory"

    for note in "$@"; do
        local file="$directory/$note.md"

        if [[ -e "$file" ]]; then
            echo "SKIP: $folder/$note.md"
            ((skipped+=1))
            continue
        fi

        printf '[[CICD]]\n' > "$file"
        echo "CREATE: $folder/$note.md"
        ((created+=1))
    done
}

# --------------------------------------------------
# 0 - GitHub Actions Fundamentals
# --------------------------------------------------

create_notes "0 - GitHub Actions Fundamentals" \
"00 - What Is GitHub Actions" \
"01 - GitHub Actions Architecture" \
"02 - CI CD and GitHub Actions" \
"03 - Workflows Events and Jobs" \
"04 - Workflow Execution Lifecycle" \
"05 - GitHub Hosted vs Self Hosted Runners" \
"06 - GitHub Actions vs Jenkins" \
"07 - GitHub Actions Terminology" \
"08 - GitHub Actions Limits and Usage" \
"09 - GitHub Actions Pricing and Minutes"

# --------------------------------------------------
# 1 - YAML and Workflow Syntax
# --------------------------------------------------

create_notes "1 - YAML and Workflow Syntax" \
"00 - YAML Fundamentals" \
"01 - YAML Scalars and Data Types" \
"02 - YAML Lists and Mappings" \
"03 - YAML Indentation and Syntax" \
"04 - YAML Anchors and Aliases" \
"05 - Workflow File Structure" \
"06 - name and run-name" \
"07 - on Events" \
"08 - push and pull_request Events" \
"09 - workflow_dispatch" \
"10 - schedule and Cron Syntax" \
"11 - jobs and steps" \
"12 - uses vs run" \
"13 - with and env" \
"14 - needs and Job Dependencies" \
"15 - if Conditional Execution" \
"16 - continue-on-error" \
"17 - timeout-minutes" \
"18 - defaults and working-directory" \
"19 - Workflow Syntax Reference"

# --------------------------------------------------
# 2 - Triggers and Event Handling
# --------------------------------------------------

create_notes "2 - Triggers and Event Handling" \
"00 - Workflow Triggers" \
"01 - Push Event" \
"02 - Pull Request Event" \
"03 - Pull Request Target Event" \
"04 - Issue Events" \
"05 - Release Events" \
"06 - Workflow Dispatch Inputs" \
"07 - Repository Dispatch" \
"08 - Workflow Run Event" \
"09 - Scheduled Workflows" \
"10 - Branch Filters" \
"11 - Path Filters" \
"12 - Tag Filters" \
"13 - Event Payloads" \
"14 - GitHub Context Object" \
"15 - Event Based Pipeline Design"

# --------------------------------------------------
# 3 - Jobs Steps and Runners
# --------------------------------------------------

create_notes "3 - Jobs Steps and Runners" \
"00 - Jobs and Steps" \
"01 - Job Execution Environment" \
"02 - Ubuntu Windows and macOS Runners" \
"03 - Runner Labels" \
"04 - GitHub Hosted Runner Images" \
"05 - Self Hosted Runners" \
"06 - Installing Tools on Runners" \
"07 - Job Dependencies with needs" \
"08 - Parallel Jobs" \
"09 - Sequential Jobs" \
"10 - Job Outputs" \
"11 - Step Outputs" \
"12 - GITHUB_OUTPUT" \
"13 - GITHUB_ENV" \
"14 - GITHUB_PATH" \
"15 - Runner Temporary Directories" \
"16 - Runner Workspace" \
"17 - Runner Cleanup and Isolation" \
"18 - Self Hosted Runner Security"

# --------------------------------------------------
# 4 - Actions and Reusability
# --------------------------------------------------

create_notes "4 - Actions and Reusability" \
"00 - What Is a GitHub Action" \
"01 - Using Marketplace Actions" \
"02 - Action Versions and Tags" \
"03 - Pinning Actions by Commit SHA" \
"04 - action.yml Metadata" \
"05 - JavaScript Actions" \
"06 - Docker Container Actions" \
"07 - Composite Actions" \
"08 - Creating Custom Actions" \
"09 - Action Inputs and Outputs" \
"10 - Action Environment Variables" \
"11 - Reusable Workflows" \
"12 - Workflow Inputs and Outputs" \
"13 - workflow_call" \
"14 - Reusable Workflows vs Composite Actions" \
"15 - Centralized Workflow Templates" \
"16 - Maintaining Internal Actions"

# --------------------------------------------------
# 5 - Expressions and Contexts
# --------------------------------------------------

create_notes "5 - Expressions and Contexts" \
"00 - GitHub Actions Expressions" \
"01 - Expression Syntax" \
"02 - GitHub Context" \
"03 - github Context Properties" \
"04 - env Context" \
"05 - vars Context" \
"06 - secrets Context" \
"07 - runner Context" \
"08 - job Context" \
"09 - steps Context" \
"10 - needs Context" \
"11 - matrix Context" \
"12 - inputs Context" \
"13 - contains and startsWith" \
"14 - endsWith and format" \
"15 - join and toJSON" \
"16 - fromJSON" \
"17 - Status Check Functions" \
"18 - Expressions in if Conditions" \
"19 - Expression Evaluation Pitfalls"

# --------------------------------------------------
# 6 - Java and Maven CI
# --------------------------------------------------

create_notes "6 - Java and Maven CI" \
"00 - Java CI Pipeline Architecture" \
"01 - Setting Up Java with setup-java" \
"02 - JDK Version Selection" \
"03 - Java Toolchain Configuration" \
"04 - Maven Wrapper in GitHub Actions" \
"05 - Maven Installation and Configuration" \
"06 - Maven Dependency Caching" \
"07 - Building Java Applications" \
"08 - Running Unit Tests" \
"09 - Running Integration Tests" \
"10 - Surefire Test Reports" \
"11 - Failsafe Integration Test Reports" \
"12 - JaCoCo Code Coverage" \
"13 - Static Code Analysis" \
"14 - Checkstyle and SpotBugs" \
"15 - Maven Profiles in CI" \
"16 - Packaging JAR and WAR Files" \
"17 - Uploading Build Artifacts" \
"18 - Downloading Build Artifacts" \
"19 - Reproducible Java Builds"

# --------------------------------------------------
# 7 - Spring Boot CI Pipelines
# --------------------------------------------------

create_notes "7 - Spring Boot CI Pipelines" \
"00 - Spring Boot CI Architecture" \
"01 - Spring Boot Workflow Structure" \
"02 - Building Spring Boot with Maven" \
"03 - Running Spring Boot Tests" \
"04 - Spring Profiles in CI" \
"05 - Externalized Configuration" \
"06 - Environment Variables and application.yml" \
"07 - Spring Boot Integration Tests" \
"08 - PostgreSQL Service Containers" \
"09 - PostgreSQL Test Database Configuration" \
"10 - Testcontainers in GitHub Actions" \
"11 - Database Test Isolation" \
"12 - Flyway Migration Validation" \
"13 - Building Spring Boot JAR" \
"14 - Spring Boot Build Metadata" \
"15 - Artifact Versioning" \
"16 - Pull Request Validation" \
"17 - Main Branch Build Pipeline" \
"18 - Release Pipeline for Spring Boot"

# --------------------------------------------------
# 8 - PostgreSQL and Database CI
# --------------------------------------------------

create_notes "8 - PostgreSQL and Database CI" \
"00 - Database Integration in CI" \
"01 - PostgreSQL Service Containers" \
"02 - Service Container Networking" \
"03 - PostgreSQL Environment Variables" \
"04 - Health Checks for PostgreSQL" \
"05 - Database Initialization" \
"06 - Running SQL Scripts in CI" \
"07 - Flyway Migration Testing" \
"08 - Migration Validation" \
"09 - Migration Compatibility Checks" \
"10 - Schema Validation" \
"11 - Database Test Fixtures" \
"12 - Database Backup Before Deployment" \
"13 - Database Migration Deployment Strategy" \
"14 - Backward Compatible Schema Changes" \
"15 - Production Database Safety"

# --------------------------------------------------
# 9 - Docker and Container CI
# --------------------------------------------------

create_notes "9 - Docker and Container CI" \
"00 - Docker in GitHub Actions" \
"01 - Docker Buildx" \
"02 - Building Docker Images" \
"03 - Multi Stage Docker Builds" \
"04 - Docker Layer Caching" \
"05 - GitHub Actions Cache for Docker" \
"06 - Docker Image Tags" \
"07 - Commit SHA Image Tags" \
"08 - Semantic Version Image Tags" \
"09 - GitHub Container Registry" \
"10 - Authenticating with GHCR" \
"11 - Publishing Docker Images" \
"12 - Pulling Private Images" \
"13 - Docker Compose in CI" \
"14 - Container Image Scanning" \
"15 - SBOM Generation" \
"16 - Image Provenance" \
"17 - Container Registry Cleanup"

# --------------------------------------------------
# 10 - Artifacts and Caching
# --------------------------------------------------

create_notes "10 - Artifacts and Caching" \
"00 - Artifacts vs Cache" \
"01 - Upload Artifact Action" \
"02 - Download Artifact Action" \
"03 - Artifact Retention" \
"04 - Artifact Naming and Versioning" \
"05 - Cache Action Fundamentals" \
"06 - Cache Keys" \
"07 - Cache Restore Keys" \
"08 - Maven Dependency Cache" \
"09 - Gradle Dependency Cache" \
"10 - Docker Build Cache" \
"11 - Cache Invalidation" \
"12 - Cache Security Considerations" \
"13 - Cross Job Artifact Sharing" \
"14 - Cross Workflow Artifact Sharing"

# --------------------------------------------------
# 11 - Secrets and Security
# --------------------------------------------------

create_notes "11 - Secrets and Security" \
"00 - GitHub Actions Security Fundamentals" \
"01 - GitHub Secrets" \
"02 - Repository Secrets" \
"03 - Environment Secrets" \
"04 - Organization Secrets" \
"05 - Secret Scope and Access" \
"06 - Using Secrets in Workflows" \
"07 - Secret Masking Limitations" \
"08 - GITHUB_TOKEN" \
"09 - Token Permissions" \
"10 - Least Privilege Permissions" \
"11 - Workflow permissions" \
"12 - OpenID Connect Fundamentals" \
"13 - OIDC Authentication" \
"14 - Cloud Deployment without Long Lived Secrets" \
"15 - Pull Request Security Risks" \
"16 - Forked Repository Security" \
"17 - Script Injection Risks" \
"18 - Third Party Action Security" \
"19 - Dependency and Supply Chain Security" \
"20 - Pinning Actions Securely" \
"21 - Secure Workflow Design Checklist"

# --------------------------------------------------
# 12 - Deployment and Environments
# --------------------------------------------------

create_notes "12 - Deployment and Environments" \
"00 - Continuous Delivery with GitHub Actions" \
"01 - GitHub Environments" \
"02 - Environment Protection Rules" \
"03 - Required Reviewers" \
"04 - Environment Scoped Secrets" \
"05 - Deployment Branch Policies" \
"06 - Development Staging Production Environments" \
"07 - Build Once Deploy Many" \
"08 - Artifact Promotion" \
"09 - Deployment Approval Gates" \
"10 - Deployment Concurrency" \
"11 - Deployment Status and History" \
"12 - Rollback Strategies" \
"13 - Zero Downtime Deployment" \
"14 - Rolling Deployment" \
"15 - Blue Green Deployment" \
"16 - Canary Deployment" \
"17 - Deployment Verification" \
"18 - Release Management"

# --------------------------------------------------
# 13 - Deploying Spring Boot on Linux
# --------------------------------------------------

create_notes "13 - Deploying Spring Boot on Linux" \
"00 - Linux Deployment Architecture" \
"01 - SSH Deployment from GitHub Actions" \
"02 - SSH Keys and Secrets" \
"03 - Linux Deployment User" \
"04 - File Permissions and Ownership" \
"05 - Deploying Spring Boot JAR" \
"06 - Running Spring Boot with systemd" \
"07 - systemd Service Configuration" \
"08 - External Configuration on Production" \
"09 - Environment Variables and Secrets" \
"10 - PostgreSQL Production Connectivity" \
"11 - Flyway in Production Deployment" \
"12 - Health Checks after Deployment" \
"13 - Reverse Proxy and HTTPS" \
"14 - Deployment Failure Recovery" \
"15 - Atomic Deployment Strategies" \
"16 - Remote Deployment Troubleshooting" \
"17 - Production Linux Deployment Checklist"

# --------------------------------------------------
# 14 - Advanced Workflows and Production Operations
# --------------------------------------------------

create_notes "14 - Advanced Workflows and Production Operations" \
"00 - Matrix Builds" \
"01 - Dynamic Matrix Generation" \
"02 - Conditional Workflows" \
"03 - Workflow Concurrency" \
"04 - Canceling Redundant Workflows" \
"05 - Reusable Workflow Architecture" \
"06 - Composite Action Architecture" \
"07 - Monorepo CI Strategies" \
"08 - Path Based Workflow Execution" \
"09 - Release Automation" \
"10 - Semantic Versioning Automation" \
"11 - Automated Changelog Generation" \
"12 - GitHub Releases" \
"13 - Automated Dependency Updates" \
"14 - Dependabot Integration" \
"15 - CodeQL and Security Scanning" \
"16 - Quality Gates" \
"17 - Workflow Monitoring and Debugging" \
"18 - Workflow Logs and Diagnostics" \
"19 - Runner Capacity and Performance" \
"20 - Self Hosted Runner Operations" \
"21 - Workflow Reliability and Retry Strategies" \
"22 - CI CD Pipeline Troubleshooting" \
"23 - GitHub Actions Production Checklist"

# --------------------------------------------------
# 15 - Production Projects
# --------------------------------------------------

create_notes "15 - Production Projects" \
"00 - Project 1: Java Maven CI Workflow" \
"01 - Project 2: Spring Boot Automated Testing" \
"02 - Project 3: Spring Boot and PostgreSQL CI" \
"03 - Project 4: Testcontainers Integration Pipeline" \
"04 - Project 5: Docker Build and GHCR Publishing" \
"05 - Project 6: Pull Request Quality Gates" \
"06 - Project 7: Secure Linux SSH Deployment" \
"07 - Project 8: Spring Boot systemd Deployment" \
"08 - Project 9: Flyway Migration Pipeline" \
"09 - Project 10: Multi Environment Release Pipeline" \
"10 - Project 11: Reusable Workflow Library" \
"11 - Project 12: Self Hosted Runner" \
"12 - Project 13: Full Production CI CD Platform" \
"13 - Production Readiness Review"

echo
echo "======================================"
echo "GitHub Actions curriculum complete"
echo "Created: $created"
echo "Skipped: $skipped"
echo "======================================"
