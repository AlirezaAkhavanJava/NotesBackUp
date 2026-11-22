
#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s nullglob

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

CREATED=0
SKIPPED=0

add_notes() {
    local folder="$1"
    shift

    local dir="$ROOT/$folder"
    local max_index=-1
    local file filename prefix concept index

    # Find the highest existing note number.
    for file in "$dir"/*.md; do
        [[ -f "$file" ]] || continue

        filename="${file##*/}"

        if [[ "$filename" =~ ^([0-9]+)\ -\  ]]; then
            prefix="${BASH_REMATCH[1]}"
            (( 10#$prefix > max_index )) && max_index=$((10#$prefix))
        fi
    done

    local next_index=$((max_index + 1))

    if [[ ! -d "$dir" ]]; then
        echo "[DIR] $folder"
        [[ "$DRY_RUN" == true ]] || mkdir -p "$dir"
    fi

    for concept in "$@"; do

        # Prevent duplicate concepts, even if their numbering differs.
        local exists=false

        for file in "$dir"/*.md; do
            [[ -f "$file" ]] || continue

            filename="${file##*/}"

            if [[ "$filename" == *" - $concept.md" ]]; then
                exists=true
                break
            fi
        done

        if [[ "$exists" == true ]]; then
            echo "[SKIP] $concept"
            ((SKIPPED += 1))
            continue
        fi

        printf -v index "%02d" "$next_index"
        local target="$dir/$index - $concept.md"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[PREVIEW] $folder/$index - $concept.md"
        else
            printf '%s\n' '[[Computer Science]]' > "$target"
            echo "[CREATED] $folder/$index - $concept.md"
        fi

        ((CREATED += 1))
        ((next_index += 1))
    done
}

echo "======================================"
echo " BACK-END CURRICULUM EXPANSION"
echo "======================================"

# 00 - Back-end Fundamentals
add_notes "00 - Back-end Fundamentals" \
    "Client Server Architecture" \
    "Backend Responsibilities" \
    "Frontend vs Backend" \
    "Backend Request Response Model" \
    "Stateless and Stateful Applications" \
    "Synchronous and Asynchronous Processing" \
    "Backend Application Lifecycle" \
    "Backend Development Workflow" \
    "Backend Application Components" \
    "Backend System Requirements"

# 01 - Server Architecture
add_notes "01 - Server Architecture" \
    "Physical Servers" \
    "Dedicated and Shared Servers" \
    "Virtual Servers" \
    "Virtual Machines" \
    "Server Operating Systems" \
    "Server Processes" \
    "Process Management" \
    "Threads and Multithreading" \
    "Thread Pools" \
    "CPU Bound and IO Bound Tasks" \
    "Server Resource Management" \
    "Server Resource Limits" \
    "Environment Variables" \
    "Runtime Dependencies" \
    "JVM as a Server Runtime"

# 02 - Web Server
add_notes "02 - Web Server" \
    "Web Server Architecture" \
    "Static and Dynamic Content" \
    "Web Server Request Handling" \
    "Reverse Proxy" \
    "Forward Proxy" \
    "Nginx Architecture" \
    "Apache HTTP Server Architecture" \
    "Web Server Virtual Hosts" \
    "TLS Termination" \
    "Web Server Load Balancing" \
    "Web Server Connection Management" \
    "Web Server Caching" \
    "Web Server Logging"

# 03 - Web Applications
add_notes "03 - Web Applications" \
    "Web Application Architecture" \
    "Web Application Components" \
    "Multi Tier Architecture" \
    "Presentation Layer" \
    "Business Logic Layer" \
    "Data Access Layer" \
    "Application Deployment Models" \
    "Monolithic Web Applications" \
    "Modular Monolithic Applications" \
    "Microservices Overview" \
    "Web Application Configuration" \
    "Application Context and Environment"

# 04 - HTTP and Communication
add_notes "04 - HTTP and Communication" \
    "HTTP Protocol Fundamentals" \
    "HTTP Request Structure" \
    "HTTP Response Structure" \
    "HTTP Methods" \
    "HTTP Safe and Idempotent Methods" \
    "HTTP Status Code Classes" \
    "HTTP Request Headers" \
    "HTTP Response Headers" \
    "HTTP Content Negotiation" \
    "HTTP Content Types" \
    "HTTP Cookies" \
    "HTTP Sessions" \
    "HTTP Authentication" \
    "HTTP Caching Headers" \
    "HTTP Conditional Requests" \
    "HTTP Persistent Connections" \
    "HTTP 1.1" \
    "HTTP 2" \
    "HTTP 3" \
    "TLS and HTTPS" \
    "WebSocket Protocol" \
    "Server Sent Events"

# 05 - Request Lifecycle and Servlet Architecture
add_notes "05 - Request Lifecycle and Servlet Architecture" \
    "Web Request Lifecycle" \
    "DNS Resolution During a Web Request" \
    "TCP Connection Establishment" \
    "TLS Handshake During HTTPS" \
    "Request Routing" \
    "Application Server Request Processing" \
    "Servlet Architecture" \
    "Servlet Lifecycle" \
    "Servlet Container" \
    "Servlet API" \
    "HttpServlet" \
    "HttpServletRequest" \
    "HttpServletResponse" \
    "Servlet Filters" \
    "Filter Chain" \
    "DispatcherServlet" \
    "Request Dispatching" \
    "Servlet Thread Model" \
    "Tomcat Architecture" \
    "Tomcat Connector and Protocol Handler" \
    "Tomcat Request Processing Pipeline" \
    "Embedded Tomcat"

# 06 - API Design and Communication
add_notes "06 - API Design and Communication" \
    "Application Programming Interfaces" \
    "API Design Fundamentals" \
    "REST Architectural Constraints" \
    "REST Resource Modeling" \
    "REST Endpoint Design" \
    "Resource Naming Conventions" \
    "API Versioning" \
    "API Pagination" \
    "API Filtering and Sorting" \
    "API Error Handling" \
    "API Documentation" \
    "OpenAPI Specification" \
    "Swagger" \
    "JSON Serialization" \
    "DTO and API Contracts" \
    "RPC Fundamentals" \
    "gRPC Fundamentals" \
    "GraphQL Fundamentals" \
    "API Compatibility" \
    "Backward Compatible API Changes"

# 07 - Backend Architecture and Design
add_notes "07 - Backend Architecture and Design" \
    "Backend Architecture Fundamentals" \
    "Layered Architecture" \
    "Controller Service Repository Architecture" \
    "Separation of Concerns" \
    "Dependency Injection" \
    "Inversion of Control" \
    "Hexagonal Architecture" \
    "Clean Architecture" \
    "Domain Driven Design" \
    "Domain Model" \
    "Bounded Contexts" \
    "Modular Monolith Architecture" \
    "Microservices Architecture" \
    "Service Communication" \
    "Service Discovery" \
    "API Gateway Pattern" \
    "Backend Integration Patterns" \
    "Event Driven Architecture" \
    "Message Driven Architecture"

# 08 - Backend Security
add_notes "08 - Backend Security" \
    "Backend Security Fundamentals" \
    "Authentication vs Authorization" \
    "Identity and Access Management" \
    "Session Based Authentication" \
    "Token Based Authentication" \
    "JWT Fundamentals" \
    "OAuth 2.0 Fundamentals" \
    "OpenID Connect" \
    "Role Based Access Control" \
    "Access Control Models" \
    "Password Storage and Hashing" \
    "Secure Password Reset" \
    "Input Validation" \
    "SQL Injection Prevention" \
    "Cross Site Scripting Prevention" \
    "Cross Site Request Forgery Prevention" \
    "CORS Configuration" \
    "HTTPS and Transport Security" \
    "API Rate Limiting" \
    "Secrets Management" \
    "OWASP Top 10"

# 09 - Performance and Scalability
add_notes "09 - Performance and Scalability" \
    "Backend Performance Fundamentals" \
    "Latency and Throughput" \
    "Concurrency and Parallelism" \
    "Vertical Scaling" \
    "Horizontal Scaling" \
    "Stateless Backend Design" \
    "Load Balancing Algorithms" \
    "Connection Pooling" \
    "Database Connection Management" \
    "Caching Fundamentals" \
    "Application Level Caching" \
    "Distributed Caching" \
    "Cache Invalidation" \
    "Cache Eviction Policies" \
    "Redis Architecture" \
    "Asynchronous Processing" \
    "Background Jobs" \
    "Message Queues" \
    "Backpressure" \
    "Rate Limiting Strategies" \
    "Performance Profiling" \
    "Load Testing"

# 10 - Reliability and Observability
add_notes "10 - Reliability and Observability" \
    "Backend Reliability Fundamentals" \
    "Fault Tolerance" \
    "High Availability" \
    "Failure Handling" \
    "Timeouts" \
    "Retries and Exponential Backoff" \
    "Circuit Breaker Pattern" \
    "Bulkhead Pattern" \
    "Idempotent Request Processing" \
    "Graceful Degradation" \
    "Health Checks" \
    "Application Logging" \
    "Structured Logging" \
    "Application Metrics" \
    "Distributed Tracing" \
    "Observability Fundamentals" \
    "SLI SLO and SLA" \
    "Incident Management" \
    "Graceful Shutdown"

# 11 - Deployment and Infrastructure
add_notes "11 - Deployment and Infrastructure" \
    "Backend Deployment Fundamentals" \
    "Linux Server Deployment" \
    "Linux Services and systemd" \
    "Reverse Proxy Deployment" \
    "Nginx and Application Server Integration" \
    "Application Configuration Management" \
    "Docker Fundamentals" \
    "Docker Images and Containers" \
    "Docker Networking" \
    "Docker Volumes" \
    "Docker Compose" \
    "Containerization vs Virtualization" \
    "CI CD Fundamentals" \
    "Build and Deployment Pipelines" \
    "Environment Separation" \
    "Production Configuration" \
    "Zero Downtime Deployment" \
    "Application Backup and Recovery"

echo
echo "======================================"
echo " SUMMARY"
echo "======================================"
echo "Root:           $ROOT"
echo "Created/Planned: $CREATED"
echo "Skipped:         $SKIPPED"
echo "Dry run:         $DRY_RUN"
echo "======================================"

if [[ "$DRY_RUN" == false ]]; then
    echo
    echo "Final directory structure:"
    tree "$ROOT"
fi
