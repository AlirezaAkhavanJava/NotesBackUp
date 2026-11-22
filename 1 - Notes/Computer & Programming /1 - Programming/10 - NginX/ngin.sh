
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"

if [[ "$(basename "$ROOT")" != "10 - NginX" ]]; then
    echo "ERROR: Run inside the '10 - NginX' directory."
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

        printf '[[Nginx]]\n' > "$file"
        echo "CREATE: $folder/$note.md"
        ((created+=1))
    done
}

# --------------------------------------------------
# 0 - Web Server Fundamentals
# --------------------------------------------------

create_notes "0 - Web Server Fundamentals" \
"00 - What Is a Web Server" \
"01 - How the Web Works" \
"02 - Client Server Architecture" \
"03 - HTTP Fundamentals" \
"04 - HTTP Request and Response Lifecycle" \
"05 - HTTP Methods and Status Codes" \
"06 - HTTP Headers" \
"07 - HTTP Keep Alive Connections" \
"08 - HTTP Persistent Connections" \
"09 - HTTP 1.1 vs HTTP 2 vs HTTP 3" \
"10 - TCP and UDP Fundamentals" \
"11 - DNS Resolution" \
"12 - Ports and Network Sockets" \
"13 - Web Server vs Application Server" \
"14 - Reverse Proxy vs Forward Proxy" \
"15 - What Is a Load Balancer" \
"16 - Nginx vs Apache" \
"17 - When to Use Nginx"

# --------------------------------------------------
# 1 - Nginx Fundamentals and Architecture
# --------------------------------------------------

create_notes "1 - Nginx Fundamentals and Architecture" \
"00 - What Is Nginx" \
"01 - Nginx Architecture" \
"02 - Master and Worker Processes" \
"03 - Event Driven Architecture" \
"04 - Non Blocking I O" \
"05 - Worker Connections" \
"06 - Nginx Modules" \
"07 - Static and Dynamic Modules" \
"08 - Nginx Installation on Debian" \
"09 - Nginx Directory Structure on Debian" \
"10 - Nginx Configuration Files" \
"11 - nginx.conf Anatomy" \
"12 - Main Events and HTTP Contexts" \
"13 - Server and Location Contexts" \
"14 - Configuration Inheritance" \
"15 - Directive Context and Scope" \
"16 - Nginx Configuration Reloading" \
"17 - nginx -t Configuration Testing" \
"18 - Nginx Process Lifecycle"

# --------------------------------------------------
# 2 - Nginx Configuration Language
# --------------------------------------------------

create_notes "2 - Nginx Configuration Language" \
"00 - Nginx Configuration Syntax" \
"01 - Directives and Contexts" \
"02 - Configuration Includes" \
"03 - Variables in Nginx" \
"04 - Built In Variables" \
"05 - Custom Variables" \
"06 - Conditional Configuration" \
"07 - if Directive Limitations" \
"08 - map Directive" \
"09 - geo Directive" \
"10 - Regular Expressions" \
"11 - Location Matching Rules" \
"12 - Exact Match Location" \
"13 - Prefix Location" \
"14 - Regex Location" \
"15 - Location Priority and Precedence" \
"16 - try_files Directive" \
"17 - Named Locations" \
"18 - Configuration Organization Best Practices"

# --------------------------------------------------
# 3 - Virtual Hosts and Static Files
# --------------------------------------------------

create_notes "3 - Virtual Hosts and Static Files" \
"00 - Server Blocks" \
"01 - Virtual Hosting" \
"02 - listen Directive" \
"03 - server_name Directive" \
"04 - Default Server" \
"05 - Root vs Alias" \
"06 - Serving Static Files" \
"07 - Directory Index" \
"08 - Autoindex and Directory Listing" \
"09 - MIME Types" \
"10 - Custom Error Pages" \
"11 - File Permissions and Ownership" \
"12 - Symbolic Links and Web Root" \
"13 - Handling 404 and 403 Errors" \
"14 - SPA Frontend Routing with try_files" \
"15 - Serving React and Vite Builds" \
"16 - Multiple Websites on One Server"

# --------------------------------------------------
# 4 - Reverse Proxy and Spring Boot
# --------------------------------------------------

create_notes "4 - Reverse Proxy and Spring Boot" \
"00 - Reverse Proxy Fundamentals" \
"01 - proxy_pass Directive" \
"02 - Proxy Request Lifecycle" \
"03 - Proxy Request Headers" \
"04 - Host and X Forwarded Headers" \
"05 - X Forwarded For" \
"06 - X Forwarded Proto" \
"07 - X Real IP" \
"08 - proxy_set_header" \
"09 - Proxy HTTP Version" \
"10 - Proxy Buffering" \
"11 - Proxy Request Buffering" \
"12 - Proxy Response Buffering" \
"13 - Proxy Timeouts" \
"14 - Proxy Connection Handling" \
"15 - Reverse Proxy to Spring Boot" \
"16 - Spring Boot on Localhost Port 8080" \
"17 - Running Multiple Spring Boot Instances" \
"18 - Spring Boot Forwarded Headers Configuration" \
"19 - ForwardedHeaderFilter and Framework Support" \
"20 - Spring Boot HTTPS Awareness" \
"21 - CORS Behind Nginx" \
"22 - API Routing with Nginx" \
"23 - Reverse Proxy Troubleshooting"

# --------------------------------------------------
# 5 - Load Balancing
# --------------------------------------------------

create_notes "5 - Load Balancing" \
"00 - Load Balancing Fundamentals" \
"01 - Upstream Context" \
"02 - Upstream Servers" \
"03 - Round Robin" \
"04 - Least Connections" \
"05 - IP Hash" \
"06 - Generic Hash" \
"07 - Consistent Hashing" \
"08 - Weighted Load Balancing" \
"09 - Backup Servers" \
"10 - Passive Health Checks" \
"11 - Active Health Checks" \
"12 - Server Failure Handling" \
"13 - max_fails and fail_timeout" \
"14 - Connection Draining" \
"15 - Session Persistence" \
"16 - Sticky Sessions Limitations" \
"17 - Stateless Spring Boot Services" \
"18 - Load Balancing Multiple Backend Instances" \
"19 - Capacity Planning and Load Distribution"

# --------------------------------------------------
# 6 - HTTPS and TLS
# --------------------------------------------------

create_notes "6 - HTTPS and TLS" \
"00 - HTTPS Fundamentals" \
"01 - TLS Handshake" \
"02 - Certificates and Certificate Authorities" \
"03 - Public and Private Keys" \
"04 - Certificate Chains" \
"05 - Certificate Formats PEM CRT KEY" \
"06 - TLS Versions and Cipher Suites" \
"07 - Configuring HTTPS in Nginx" \
"08 - ssl_certificate Directive" \
"09 - ssl_certificate_key Directive" \
"10 - HTTP to HTTPS Redirect" \
"11 - TLS Termination" \
"12 - TLS Between Nginx and Spring Boot" \
"13 - Let's Encrypt" \
"14 - Certbot on Debian" \
"15 - Automatic Certificate Renewal" \
"16 - Certificate Renewal Hooks" \
"17 - OCSP Stapling" \
"18 - HSTS" \
"19 - TLS Security Hardening" \
"20 - SSL Labs and TLS Testing" \
"21 - Troubleshooting Certificate Errors"

# --------------------------------------------------
# 7 - Caching and Performance
# --------------------------------------------------

create_notes "7 - Caching and Performance" \
"00 - HTTP Caching Fundamentals" \
"01 - Browser Caching" \
"02 - Cache Control Headers" \
"03 - Expires Header" \
"04 - ETag and Last Modified" \
"05 - Nginx Static File Caching" \
"06 - Proxy Cache Fundamentals" \
"07 - proxy_cache_path" \
"08 - proxy_cache Configuration" \
"09 - Cache Keys" \
"10 - Cache Validity" \
"11 - Cache Bypass and No Cache" \
"12 - Cache Invalidation" \
"13 - Cache Locking" \
"14 - Stale Cache Responses" \
"15 - Microcaching" \
"16 - Gzip Compression" \
"17 - Brotli Compression" \
"18 - Sendfile and TCP Optimization" \
"19 - Worker Process Tuning" \
"20 - Worker Connections Tuning" \
"21 - File Descriptor Limits" \
"22 - Kernel Network Tuning" \
"23 - Nginx Performance Benchmarking"

# --------------------------------------------------
# 8 - Security and Access Control
# --------------------------------------------------

create_notes "8 - Security and Access Control" \
"00 - Nginx Security Fundamentals" \
"01 - Server Information Disclosure" \
"02 - Hiding Server Tokens" \
"03 - Restricting Access by IP" \
"04 - allow and deny Directives" \
"05 - Basic Authentication" \
"06 - Password File Management" \
"07 - Request Rate Limiting" \
"08 - limit_req Module" \
"09 - Connection Limiting" \
"10 - limit_conn Module" \
"11 - Request Size Limits" \
"12 - Request Timeout Protection" \
"13 - Blocking Unwanted HTTP Methods" \
"14 - Restricting Sensitive Paths" \
"15 - Preventing Directory Traversal" \
"16 - Security Headers" \
"17 - Content Security Policy" \
"18 - X Content Type Options" \
"19 - X Frame Options" \
"20 - Referrer Policy" \
"21 - CORS Security Considerations" \
"22 - WAF Fundamentals" \
"23 - ModSecurity and Nginx" \
"24 - Production Security Checklist"

# --------------------------------------------------
# 9 - WebSockets and Advanced HTTP
# --------------------------------------------------

create_notes "9 - WebSockets and Advanced HTTP" \
"00 - WebSocket Fundamentals" \
"01 - HTTP Upgrade Mechanism" \
"02 - WebSocket Proxy Configuration" \
"03 - Connection Upgrade Headers" \
"04 - WebSocket Timeouts" \
"05 - Spring Boot WebSocket Behind Nginx" \
"06 - Server Sent Events" \
"07 - SSE Proxy Buffering" \
"08 - Long Polling" \
"09 - Streaming Responses" \
"10 - Large File Uploads" \
"11 - Client Body Buffering" \
"12 - Chunked Transfer Encoding" \
"13 - HTTP Range Requests" \
"14 - gRPC Proxying" \
"15 - HTTP 2 and gRPC Configuration"

# --------------------------------------------------
# 10 - Docker and Nginx
# --------------------------------------------------

create_notes "10 - Docker and Nginx" \
"00 - Nginx in Docker" \
"01 - Official Nginx Docker Image" \
"02 - Dockerfile for Nginx" \
"03 - Nginx Configuration Mounts" \
"04 - Static Files in Containers" \
"05 - Reverse Proxy to Docker Services" \
"06 - Docker DNS and Service Discovery" \
"07 - Docker Compose Reverse Proxy" \
"08 - Spring Boot and Nginx with Compose" \
"09 - Container Networking" \
"10 - Container Health Checks" \
"11 - Read Only Container Filesystems" \
"12 - Container Logs" \
"13 - Docker Secrets and TLS Certificates" \
"14 - Multi Container Production Architecture" \
"15 - Nginx Container Deployment Checklist"

# --------------------------------------------------
# 11 - Linux and Nginx Operations
# --------------------------------------------------

create_notes "11 - Linux and Nginx Operations" \
"00 - Nginx on Debian Architecture" \
"01 - systemd and Nginx" \
"02 - Nginx Service Management" \
"03 - systemctl start stop restart reload" \
"04 - Nginx Configuration Test" \
"05 - Nginx Logs on Linux" \
"06 - Access Logs" \
"07 - Error Logs" \
"08 - Log Formats" \
"09 - Log Rotation with logrotate" \
"10 - File Permissions and Security" \
"11 - Linux Capabilities and Port Binding" \
"12 - Firewall Configuration with UFW" \
"13 - Firewall Configuration with nftables" \
"14 - Listening Ports with ss" \
"15 - Network Diagnostics with curl" \
"16 - DNS Diagnostics with dig" \
"17 - Process Inspection with ps" \
"18 - Open File Descriptors" \
"19 - Disk and Memory Monitoring" \
"20 - Graceful Reload and Shutdown" \
"21 - Nginx Upgrade on Debian" \
"22 - Nginx Backup and Restore"

# --------------------------------------------------
# 12 - Observability and Troubleshooting
# --------------------------------------------------

create_notes "12 - Observability and Troubleshooting" \
"00 - Nginx Observability Fundamentals" \
"01 - Access Log Analysis" \
"02 - Error Log Analysis" \
"03 - Custom Log Formats" \
"04 - Request IDs" \
"05 - Correlation IDs Across Services" \
"06 - Upstream Response Time" \
"07 - Request Processing Time" \
"08 - Nginx Stub Status Module" \
"09 - Prometheus Nginx Exporter" \
"10 - Grafana Nginx Dashboards" \
"11 - Centralized Logging" \
"12 - OpenTelemetry and Nginx" \
"13 - Monitoring HTTP Error Rates" \
"14 - Monitoring Latency" \
"15 - Monitoring Active Connections" \
"16 - Troubleshooting 502 Bad Gateway" \
"17 - Troubleshooting 503 Service Unavailable" \
"18 - Troubleshooting 504 Gateway Timeout" \
"19 - Troubleshooting 403 Forbidden" \
"20 - Troubleshooting 404 Not Found" \
"21 - Troubleshooting TLS Errors" \
"22 - Troubleshooting DNS and Upstream Failures" \
"23 - Production Incident Checklist"

# --------------------------------------------------
# 13 - High Availability and Infrastructure
# --------------------------------------------------

create_notes "13 - High Availability and Infrastructure" \
"00 - High Availability Fundamentals" \
"01 - Nginx as an Edge Proxy" \
"02 - Nginx as a Load Balancer" \
"03 - Multiple Nginx Instances" \
"04 - Keepalived and Virtual IPs" \
"05 - Failover Architecture" \
"06 - DNS Based Failover" \
"07 - Cloud Load Balancers and Nginx" \
"08 - Nginx in Kubernetes" \
"09 - Ingress Controller Fundamentals" \
"10 - Nginx Ingress Architecture" \
"11 - Nginx Configuration in Infrastructure as Code" \
"12 - Configuration Management" \
"13 - Ansible and Nginx" \
"14 - Infrastructure Deployment Strategy" \
"15 - Disaster Recovery Planning"

# --------------------------------------------------
# 14 - Production Architecture and Projects
# --------------------------------------------------

create_notes "14 - Production Architecture and Projects" \
"00 - Production Nginx Architecture" \
"01 - Nginx and Spring Boot Production Architecture" \
"02 - Nginx Spring Boot PostgreSQL Deployment" \
"03 - Nginx with Multiple Spring Boot Instances" \
"04 - Nginx and React Frontend Deployment" \
"05 - Single Server Full Stack Deployment" \
"06 - Separate Frontend and Backend Domains" \
"07 - API Reverse Proxy Architecture" \
"08 - Nginx as an API Gateway" \
"09 - Multi Tenant Virtual Hosting" \
"10 - Production HTTPS Architecture" \
"11 - Zero Downtime Configuration Deployment" \
"12 - Production Capacity Planning" \
"13 - Production Readiness Checklist" \
"14 - Project 1: Deploy Spring Boot Behind Nginx" \
"15 - Project 2: HTTPS with Let's Encrypt" \
"16 - Project 3: React and Spring Boot Reverse Proxy" \
"17 - Project 4: Load Balance Spring Boot Instances" \
"18 - Project 5: Docker Compose Production Stack" \
"19 - Project 6: Secure Public API" \
"20 - Project 7: Monitoring and Troubleshooting Stack"

echo
echo "======================================"
echo "Nginx curriculum generation complete"
echo "Created: $created"
echo "Skipped: $skipped"
echo "======================================"
