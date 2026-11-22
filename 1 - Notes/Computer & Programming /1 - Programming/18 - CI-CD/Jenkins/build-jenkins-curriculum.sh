
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"

if [[ "$(basename "$ROOT")" != "Jenkins" ]]; then
    echo "ERROR: Run this script inside the Jenkins directory."
    exit 1
fi

if [[ ! -f "$ROOT/00 - What is CI CD ?.md" ]]; then
    echo "ERROR: Jenkins package marker not found. Aborting."
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

        printf '[[Jenkins]]\n' > "$file"
        echo "CREATE: $folder/$note.md"
        ((created+=1))
    done
}

# --------------------------------------------------
# 06 - Jenkins Fundamentals
# --------------------------------------------------

create_notes "06 - Jenkins Fundamentals" \
"00 - Jenkins Architecture" \
"01 - Jenkins Controller and Agents" \
"02 - Executors and Build Queues" \
"03 - Jenkins Home Directory" \
"04 - Jenkins Workspace" \
"05 - Jenkins Plugins Architecture" \
"06 - Jenkins Job Build and Run Lifecycle" \
"07 - Jenkins Build Status and Results" \
"08 - Jenkins Environment Variables" \
"09 - Jenkins Parameters" \
"10 - Jenkins System Configuration" \
"11 - Jenkins Global Tools Configuration" \
"12 - Jenkins CLI" \
"13 - Jenkins REST API" \
"14 - Jenkins Script Console" \
"15 - Jenkins Configuration as Code"

# --------------------------------------------------
# 07 - Jenkins Jobs and Build Management
# --------------------------------------------------

create_notes "07 - Jenkins Jobs and Build Management" \
"00 - Jenkins Job Types" \
"01 - Freestyle Projects" \
"02 - Pipeline Jobs" \
"03 - Multibranch Pipeline Jobs" \
"04 - Organization Folders" \
"05 - Build Triggers" \
"06 - Poll SCM vs Webhooks" \
"07 - Scheduled Builds with Cron" \
"08 - Build Parameters" \
"09 - Build Artifacts" \
"10 - Artifact Archiving" \
"11 - Build Retention and Log Rotation" \
"12 - Build History and Console Output" \
"13 - Build Dependencies" \
"14 - Upstream and Downstream Jobs" \
"15 - Build Fingerprints" \
"16 - Jenkins Build Notifications"

# --------------------------------------------------
# 08 - Jenkins Pipeline Fundamentals
# --------------------------------------------------

create_notes "08 - Jenkins Pipeline Fundamentals" \
"00 - What Is Pipeline as Code" \
"01 - Jenkinsfile" \
"02 - Declarative Pipeline" \
"03 - Scripted Pipeline" \
"04 - Declarative vs Scripted Pipeline" \
"05 - Pipeline Syntax" \
"06 - Pipeline Structure" \
"07 - pipeline and agent Directives" \
"08 - stages and stage" \
"09 - steps" \
"10 - post Conditions" \
"11 - environment Directive" \
"12 - parameters Directive" \
"13 - options Directive" \
"14 - tools Directive" \
"15 - when Directive" \
"16 - input Directive" \
"17 - timeout and retry" \
"18 - Parallel Stages" \
"19 - Matrix Builds" \
"20 - Error Handling" \
"21 - Pipeline Status and Result" \
"22 - Workspace and Directory Operations" \
"23 - Stashing and Unstashing Files" \
"24 - Pipeline Shared Libraries" \
"25 - Reusable Pipeline Functions" \
"26 - Pipeline Debugging"

# --------------------------------------------------
# 09 - Jenkins Pipeline Groovy
# --------------------------------------------------

create_notes "09 - Jenkins Pipeline Groovy" \
"00 - Groovy Fundamentals for Jenkins" \
"01 - Groovy Variables and Types" \
"02 - Groovy Collections" \
"03 - Groovy Closures" \
"04 - Groovy Methods and Functions" \
"05 - String Interpolation" \
"06 - GStrings vs Strings" \
"07 - Jenkins Pipeline DSL" \
"08 - Script Blocks" \
"09 - CPS Transformation" \
"10 - Serialization and Pipeline Durability" \
"11 - @NonCPS and Its Limitations" \
"12 - Groovy Sandbox" \
"13 - Trusted and Untrusted Libraries" \
"14 - Common Groovy Pipeline Mistakes"

# --------------------------------------------------
# 10 - Git and GitHub Integration
# --------------------------------------------------

create_notes "10 - Git and GitHub Integration" \
"00 - Jenkins Git Integration" \
"01 - Git Plugin" \
"02 - GitHub Plugin" \
"03 - Source Code Management Configuration" \
"04 - Repository Checkout" \
"05 - Branch Discovery" \
"06 - Multibranch Pipeline with GitHub" \
"07 - GitHub Webhooks" \
"08 - GitHub Branch Source Plugin" \
"09 - Pull Request Validation" \
"10 - Branch Based Pipelines" \
"11 - Commit Status Checks" \
"12 - Git Tags and Release Builds" \
"13 - Git Credentials" \
"14 - Shallow Clones and Checkout Performance" \
"15 - Monorepo Pipeline Strategies"

# --------------------------------------------------
# 11 - Java and Maven Build Automation
# --------------------------------------------------

create_notes "11 - Java and Maven Build Automation" \
"00 - Configuring Java in Jenkins" \
"01 - JDK Tool Installation and Selection" \
"02 - Maven Installation and Configuration" \
"03 - Maven Wrapper in Jenkins" \
"04 - Building Java Projects" \
"05 - Maven Lifecycle in CI" \
"06 - Dependency Caching" \
"07 - Maven Repository Configuration" \
"08 - Running Unit Tests" \
"09 - Running Integration Tests" \
"10 - Test Reports and JUnit Plugin" \
"11 - JaCoCo Code Coverage" \
"12 - Checkstyle and SpotBugs" \
"13 - Static Analysis Quality Gates" \
"14 - Packaging JAR and WAR Files" \
"15 - Build Artifact Versioning" \
"16 - Reproducible Java Builds" \
"17 - Java Build Failure Troubleshooting"

# --------------------------------------------------
# 12 - Spring Boot CI Pipelines
# --------------------------------------------------

create_notes "12 - Spring Boot CI Pipelines" \
"00 - Spring Boot CI Architecture" \
"01 - Spring Boot Pipeline Structure" \
"02 - Building Spring Boot with Maven" \
"03 - Running Spring Boot Tests in Jenkins" \
"04 - Test Profiles and CI Configuration" \
"05 - Externalized Configuration in CI" \
"06 - Spring Boot Integration Tests" \
"07 - PostgreSQL Integration Testing" \
"08 - Testcontainers in Jenkins" \
"09 - Database Test Isolation" \
"10 - Flyway Migration Validation" \
"11 - Build and Package Spring Boot JAR" \
"12 - Spring Boot Docker Image Creation" \
"13 - Build Metadata and Application Versioning" \
"14 - Spring Boot Artifact Promotion" \
"15 - Pipeline for Pull Requests" \
"16 - Pipeline for Main Branch" \
"17 - Release Pipeline for Spring Boot"

# --------------------------------------------------
# 13 - Docker and Jenkins
# --------------------------------------------------

create_notes "13 - Docker and Jenkins" \
"00 - Docker Integration Architecture" \
"01 - Jenkins Docker Plugin" \
"02 - Docker CLI from Jenkins" \
"03 - Docker Socket and Permissions" \
"04 - Docker Build in Pipeline" \
"05 - Dockerfile Best Practices" \
"06 - Multi Stage Docker Builds" \
"07 - Docker Image Tagging" \
"08 - Container Registry Authentication" \
"09 - Pushing Images to a Registry" \
"10 - Pulling Images for Deployment" \
"11 - Docker Compose in CI" \
"12 - Docker Based Jenkins Agents" \
"13 - Ephemeral Build Environments" \
"14 - Docker in Docker vs Docker Socket" \
"15 - Container Image Scanning" \
"16 - Docker Build Cache" \
"17 - Production Container Pipeline"

# --------------------------------------------------
# 14 - Jenkins Agents and Distributed Builds
# --------------------------------------------------

create_notes "14 - Jenkins Agents and Distributed Builds" \
"00 - Why Jenkins Agents Exist" \
"01 - Controller Agent Architecture" \
"02 - Permanent Agents" \
"03 - SSH Agents" \
"04 - Inbound Agents" \
"05 - WebSocket Agents" \
"06 - Agent Labels" \
"07 - Agent Executors" \
"08 - Agent Workspaces" \
"09 - Agent Tool Configuration" \
"10 - Docker Agents" \
"11 - Kubernetes Agents" \
"12 - Ephemeral Agents" \
"13 - Agent Isolation" \
"14 - Distributed Build Scheduling" \
"15 - Agent Failure and Reconnection" \
"16 - Scaling Jenkins Agents"

# --------------------------------------------------
# 15 - Credentials and Security
# --------------------------------------------------

create_notes "15 - Credentials and Security" \
"00 - Jenkins Security Architecture" \
"01 - Authentication and Authorization" \
"02 - Security Realms" \
"03 - Authorization Strategies" \
"04 - Matrix Based Security" \
"05 - Role Based Authorization" \
"06 - Jenkins Credentials Store" \
"07 - Credentials Types" \
"08 - Secret Text and Username Password" \
"09 - SSH Private Key Credentials" \
"10 - Credentials Binding Plugin" \
"11 - Using Credentials in Jenkinsfile" \
"12 - Secret Masking Limitations" \
"13 - Credential Scope" \
"14 - Folder Scoped Credentials" \
"15 - Avoiding Secret Exposure in Logs" \
"16 - CSRF Protection and API Tokens" \
"17 - Agent Security Boundaries" \
"18 - Pipeline Script Security" \
"19 - Plugin Security and Updates" \
"20 - Jenkins Hardening Checklist"

# --------------------------------------------------
# 16 - Linux and Jenkins Operations
# --------------------------------------------------

create_notes "16 - Linux and Jenkins Operations" \
"00 - Jenkins on Linux Architecture" \
"01 - Jenkins systemd Service" \
"02 - Jenkins Service User" \
"03 - Linux File Permissions for Jenkins" \
"04 - Jenkins Home Directory Permissions" \
"05 - Jenkins Workspace Permissions" \
"06 - Environment Variables in systemd" \
"07 - Jenkins Configuration Files" \
"08 - Jenkins Logs on Linux" \
"09 - Journalctl for Jenkins" \
"10 - Jenkins Port and Network Binding" \
"11 - Reverse Proxy with Nginx" \
"12 - HTTPS and TLS Termination" \
"13 - Firewall Rules for Jenkins" \
"14 - SSH Access from Jenkins" \
"15 - Disk Space and Workspace Cleanup" \
"16 - Jenkins Restart and Shutdown" \
"17 - Jenkins Backup and Restore" \
"18 - Jenkins Upgrade Strategy" \
"19 - Linux Troubleshooting Checklist"

# --------------------------------------------------
# 17 - Deployment Pipelines
# --------------------------------------------------

create_notes "17 - Deployment Pipelines" \
"00 - Continuous Delivery vs Continuous Deployment" \
"01 - Deployment Pipeline Architecture" \
"02 - Build Once Deploy Many" \
"03 - Artifact Promotion" \
"04 - Development Staging Production Environments" \
"05 - Environment Approval Gates" \
"06 - Manual Approval in Jenkins" \
"07 - Deployment over SSH" \
"08 - Deploying Spring Boot JAR on Linux" \
"09 - Running Spring Boot with systemd" \
"10 - Spring Boot Environment Configuration" \
"11 - Externalized Secrets on Production Servers" \
"12 - Database Migration During Deployment" \
"13 - Flyway Migration Deployment Strategy" \
"14 - Backward Compatible Database Changes" \
"15 - Zero Downtime Deployment" \
"16 - Rolling Deployment" \
"17 - Blue Green Deployment" \
"18 - Canary Deployment" \
"19 - Rollback Strategies" \
"20 - Health Checks After Deployment" \
"21 - Deployment Verification" \
"22 - Production Release Checklist"

# --------------------------------------------------
# 18 - Advanced CI/CD Practices
# --------------------------------------------------

create_notes "18 - Advanced CI-CD Practices" \
"00 - CI CD Pipeline Design Principles" \
"01 - Pipeline as a Product" \
"02 - Pipeline Reusability" \
"03 - Shared Libraries Architecture" \
"04 - Jenkins Shared Library Structure" \
"05 - Versioning Shared Libraries" \
"06 - Pipeline Templates" \
"07 - Dynamic Pipeline Generation" \
"08 - Conditional Pipeline Execution" \
"09 - Parallel Build Optimization" \
"10 - Build Caching Strategies" \
"11 - Artifact Repository Integration" \
"12 - Nexus and Artifactory Integration" \
"13 - Software Bill of Materials" \
"14 - Supply Chain Security" \
"15 - Software Provenance and Attestations" \
"16 - Dependency Vulnerability Scanning" \
"17 - Container Vulnerability Scanning" \
"18 - Quality Gates and Release Policies" \
"19 - GitOps and Jenkins" \
"20 - Jenkins vs GitHub Actions"

# --------------------------------------------------
# 19 - Monitoring and Troubleshooting
# --------------------------------------------------

create_notes "19 - Monitoring and Troubleshooting" \
"00 - Jenkins Monitoring Fundamentals" \
"01 - Jenkins Metrics" \
"02 - Monitoring Controller Health" \
"03 - Monitoring Agent Health" \
"04 - Queue Length and Build Duration" \
"05 - Disk and Memory Monitoring" \
"06 - Jenkins Metrics Plugin" \
"07 - Prometheus Integration" \
"08 - Grafana Dashboards" \
"09 - Build Failure Diagnosis" \
"10 - Pipeline Failure Diagnosis" \
"11 - Agent Connection Problems" \
"12 - Out of Memory Errors" \
"13 - Disk Space Problems" \
"14 - Plugin Compatibility Problems" \
"15 - Thread Dumps and Heap Dumps" \
"16 - Jenkins Support Bundles" \
"17 - Operational Alerts and Incident Response"

# --------------------------------------------------
# 20 - Production Projects
# --------------------------------------------------

create_notes "20 - Production Projects" \
"00 - Project 1: Java Maven CI Pipeline" \
"01 - Project 2: Spring Boot Test Pipeline" \
"02 - Project 3: Spring Boot PostgreSQL Integration Pipeline" \
"03 - Project 4: Docker Image Build and Push" \
"04 - Project 5: Deploy Spring Boot on Debian with systemd" \
"05 - Project 6: Pull Request Validation Pipeline" \
"06 - Project 7: Multi Environment Deployment Pipeline" \
"07 - Project 8: Automated Flyway Migration Pipeline" \
"08 - Project 9: Jenkins Shared Library" \
"09 - Project 10: Distributed Jenkins Agents" \
"10 - Project 11: Secure Production Pipeline" \
"11 - Project 12: Full Production CI CD Platform" \
"12 - Production Readiness Review"

# --------------------------------------------------
# Summary
# --------------------------------------------------

echo
echo "======================================"
echo "Jenkins curriculum generation complete"
echo "Created: $created"
echo "Skipped: $skipped"
echo "======================================"
