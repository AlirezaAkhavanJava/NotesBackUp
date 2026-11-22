
#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR="$(pwd)"

if [[ "$(basename "$BASE_DIR")" != "7 - System Design" ]]; then
    echo "Error: Run this script inside the '7 - System Design' directory."
    exit 1
fi

created=0
skipped=0

create_package() {
    local package="$1"
    shift

    local package_dir="$BASE_DIR/$package"

    mkdir -p "$package_dir"

    echo
    echo "=== $package ==="

    for note in "$@"; do
        local destination="$package_dir/$note"

        if [[ -e "$destination" ]]; then
            echo "[SKIP] $note"
            ((skipped+=1))
            continue
        fi

        {
            echo "[[System Design]]"
            echo
        } > "$destination"

        echo "[CREATED] $note"
        ((created+=1))
    done
}

# ==================================================
# 00 - SYSTEM DESIGN FUNDAMENTALS
# ==================================================

create_package "00 - System Design Fundamentals" \
"00 - What Is System Design.md" \
"01 - System Design vs Software Architecture.md" \
"02 - Functional Requirements.md" \
"03 - Non Functional Requirements.md" \
"04 - Production Requirements.md" \
"05 - System Constraints.md" \
"06 - Tradeoffs in System Design.md" \
"07 - Availability.md" \
"08 - Reliability.md" \
"09 - Scalability.md" \
"10 - Maintainability.md" \
"11 - Fault Tolerance.md" \
"12 - Performance.md" \
"13 - Latency and Throughput.md" \
"14 - Capacity Planning.md" \
"15 - Cost Efficiency.md" \
"16 - Single Point of Failure.md" \
"17 - Bottleneck Analysis.md" \
"18 - Back of the Envelope Estimation.md" \
"19 - Production Readiness Criteria.md"

# ==================================================
# 01 - REQUIREMENTS AND ARCHITECTURE
# ==================================================

create_package "01 - Requirements and Architecture" \
"00 - Requirements Gathering.md" \
"01 - Functional Requirement Analysis.md" \
"02 - Non Functional Requirement Analysis.md" \
"03 - Workload Estimation.md" \
"04 - Traffic Estimation.md" \
"05 - Storage Estimation.md" \
"06 - Bandwidth Estimation.md" \
"07 - Architecture Diagrams.md" \
"08 - C4 Model.md" \
"09 - Context Diagram.md" \
"10 - Container Diagram.md" \
"11 - Component Diagram.md" \
"12 - Deployment Diagram.md" \
"13 - Monolithic Architecture.md" \
"14 - Modular Monolith.md" \
"15 - Microservices Architecture.md" \
"16 - Service Oriented Architecture.md" \
"17 - Modular Architecture.md" \
"18 - Layered Architecture.md" \
"19 - Hexagonal Architecture.md" \
"20 - Clean Architecture.md" \
"21 - Architecture Decision Records.md" \
"22 - Architecture Tradeoff Analysis.md" \
"23 - Technical Debt.md" \
"24 - Evolutionary Architecture.md"

# ==================================================
# 02 - NETWORKING AND COMMUNICATION
# ==================================================

create_package "02 - Networking and Communication" \
"00 - Networking Fundamentals for Backend Systems.md" \
"01 - OSI and TCP IP Models.md" \
"02 - IP Addressing.md" \
"03 - DNS.md" \
"04 - DNS Resolution.md" \
"05 - TCP.md" \
"06 - UDP.md" \
"07 - TCP Handshake.md" \
"08 - Connection Termination.md" \
"09 - HTTP.md" \
"10 - HTTP Request and Response.md" \
"11 - HTTP Headers.md" \
"12 - HTTP Methods.md" \
"13 - HTTP Status Codes.md" \
"14 - HTTP Keep Alive.md" \
"15 - HTTP Persistent Connections.md" \
"16 - HTTP 1.1 vs HTTP 2 vs HTTP 3.md" \
"17 - TLS and HTTPS.md" \
"18 - TLS Handshake.md" \
"19 - Certificates and Certificate Authorities.md" \
"20 - Reverse Proxy.md" \
"21 - Forward Proxy.md" \
"22 - Load Balancer.md" \
"23 - Layer 4 vs Layer 7 Load Balancing.md" \
"24 - WebSockets.md" \
"25 - Server Sent Events.md" \
"26 - Long Polling.md" \
"27 - Network Timeouts.md" \
"28 - Connection Pooling.md" \
"29 - Network Partitions.md" \
"30 - NAT and Firewalls.md"

# ==================================================
# 03 - API DESIGN
# ==================================================

create_package "03 - API Design" \
"00 - API Design Fundamentals.md" \
"01 - REST Architecture.md" \
"02 - RESTful Resource Modeling.md" \
"03 - Resource Naming Conventions.md" \
"04 - HTTP Method Semantics.md" \
"05 - HTTP Status Code Design.md" \
"06 - API Versioning.md" \
"07 - URI Versioning.md" \
"08 - Header Based Versioning.md" \
"09 - Request and Response Contracts.md" \
"10 - DTO Design.md" \
"11 - Pagination.md" \
"12 - Offset Pagination.md" \
"13 - Cursor Based Pagination.md" \
"14 - Filtering and Sorting.md" \
"15 - API Idempotency.md" \
"16 - Idempotency Keys.md" \
"17 - API Rate Limiting.md" \
"18 - API Throttling.md" \
"19 - API Validation.md" \
"20 - API Error Handling.md" \
"21 - Problem Details RFC 9457.md" \
"22 - API Documentation.md" \
"23 - OpenAPI Specification.md" \
"24 - Swagger UI.md" \
"25 - API Backward Compatibility.md" \
"26 - API Deprecation.md" \
"27 - Bulk API Operations.md" \
"28 - Webhook Design.md" \
"29 - API Gateway.md" \
"30 - BFF Pattern.md" \
"31 - GraphQL.md" \
"32 - gRPC.md" \
"33 - API Contract Testing.md"

# ==================================================
# 04 - DATABASES AND DATA MODELING
# ==================================================

create_package "04 - Databases and Data Modeling" \
"00 - Database Architecture.md" \
"01 - Relational vs NoSQL Databases.md" \
"02 - Database Selection.md" \
"03 - Relational Data Modeling.md" \
"04 - Entity Relationship Diagrams.md" \
"05 - Database Normalization.md" \
"06 - Database Denormalization.md" \
"07 - Primary Keys.md" \
"08 - Foreign Keys.md" \
"09 - Unique Constraints.md" \
"10 - Check Constraints.md" \
"11 - Database Indexing.md" \
"12 - B Tree Indexes.md" \
"13 - Composite Indexes.md" \
"14 - Covering Indexes.md" \
"15 - Partial Indexes.md" \
"16 - Index Selectivity.md" \
"17 - Index Maintenance.md" \
"18 - PostgreSQL Architecture.md" \
"19 - PostgreSQL MVCC.md" \
"20 - PostgreSQL Vacuum and Autovacuum.md" \
"21 - PostgreSQL WAL.md" \
"22 - PostgreSQL Query Planner.md" \
"23 - EXPLAIN and EXPLAIN ANALYZE.md" \
"24 - PostgreSQL Connection Management.md" \
"25 - PgBouncer.md" \
"26 - Database Connection Pooling.md" \
"27 - HikariCP.md" \
"28 - Database Partitioning.md" \
"29 - Horizontal Partitioning.md" \
"30 - Vertical Partitioning.md" \
"31 - PostgreSQL Table Partitioning.md" \
"32 - Read Replicas.md" \
"33 - Database Replication.md" \
"34 - Synchronous vs Asynchronous Replication.md" \
"35 - Database Sharding.md" \
"36 - Database Schema Evolution.md" \
"37 - Database Migrations.md" \
"38 - Flyway Production Strategy.md" \
"39 - Database Backup.md" \
"40 - Point In Time Recovery.md" \
"41 - Database Restore Testing.md" \
"42 - Database Disaster Recovery.md"

# ==================================================
# 05 - CACHING
# ==================================================

create_package "05 - Caching" \
"00 - Caching Fundamentals.md" \
"01 - Why Caching Matters.md" \
"02 - Cache Architecture.md" \
"03 - Cache Hierarchy.md" \
"04 - Client Side Caching.md" \
"05 - Application Level Caching.md" \
"06 - Distributed Caching.md" \
"07 - Database Caching.md" \
"08 - Cache Aside.md" \
"09 - Read Through Cache.md" \
"10 - Write Through Cache.md" \
"11 - Write Behind Cache.md" \
"12 - Write Around Cache.md" \
"13 - Cache Invalidation.md" \
"14 - Cache Expiration and TTL.md" \
"15 - Cache Eviction Policies.md" \
"16 - LRU Cache.md" \
"17 - LFU Cache.md" \
"18 - Cache Stampede.md" \
"19 - Cache Penetration.md" \
"20 - Cache Avalanche.md" \
"21 - Cache Warming.md" \
"22 - Cache Consistency.md" \
"23 - Redis Architecture.md" \
"24 - Redis Data Structures.md" \
"25 - Redis Persistence.md" \
"26 - Redis Replication.md" \
"27 - Redis Sentinel.md" \
"28 - Redis Cluster.md" \
"29 - Redis High Availability.md" \
"30 - Spring Cache Abstraction.md" \
"31 - Spring Data Redis.md" \
"32 - Cache Monitoring.md" \
"33 - Production Caching Strategy.md"

# ==================================================
# 06 - MESSAGING AND EVENT DRIVEN ARCHITECTURE
# ==================================================

create_package "06 - Messaging and Event Driven Architecture" \
"00 - Messaging Fundamentals.md" \
"01 - Synchronous vs Asynchronous Communication.md" \
"02 - Message Queues.md" \
"03 - Message Brokers.md" \
"04 - Point to Point Messaging.md" \
"05 - Publish Subscribe Pattern.md" \
"06 - Event Driven Architecture.md" \
"07 - Domain Events.md" \
"08 - Event Notification.md" \
"09 - Event Carried State Transfer.md" \
"10 - Event Sourcing.md" \
"11 - Apache Kafka Architecture.md" \
"12 - Kafka Brokers.md" \
"13 - Kafka Topics.md" \
"14 - Kafka Partitions.md" \
"15 - Kafka Producers.md" \
"16 - Kafka Consumers.md" \
"17 - Consumer Groups.md" \
"18 - Consumer Offsets.md" \
"19 - Offset Commit Strategies.md" \
"20 - Kafka Replication.md" \
"21 - Kafka ISR.md" \
"22 - Kafka Retention.md" \
"23 - Kafka Delivery Semantics.md" \
"24 - At Most Once Delivery.md" \
"25 - At Least Once Delivery.md" \
"26 - Exactly Once Semantics.md" \
"27 - Idempotent Consumers.md" \
"28 - Message Ordering.md" \
"29 - Dead Letter Queues.md" \
"30 - Retry Queues.md" \
"31 - Delayed Messages.md" \
"32 - Message Deduplication.md" \
"33 - Schema Registry.md" \
"34 - Avro and Protobuf.md" \
"35 - Transactional Outbox Pattern.md" \
"36 - CDC (Change Data Capture).md" \
"37 - Debezium.md" \
"38 - Spring Kafka.md" \
"39 - Kafka Consumer Failure Handling.md" \
"40 - Messaging Observability.md"

# ==================================================
# 07 - DISTRIBUTED SYSTEMS
# ==================================================

create_package "07 - Distributed Systems" \
"00 - Distributed Systems Fundamentals.md" \
"01 - Distributed System Characteristics.md" \
"02 - Distributed System Challenges.md" \
"03 - CAP Theorem.md" \
"04 - PACELC Theorem.md" \
"05 - Consistency Models.md" \
"06 - Strong Consistency.md" \
"07 - Eventual Consistency.md" \
"08 - Causal Consistency.md" \
"09 - Read Your Writes Consistency.md" \
"10 - Distributed Transactions.md" \
"11 - Two Phase Commit.md" \
"12 - Three Phase Commit.md" \
"13 - Saga Pattern.md" \
"14 - Choreography vs Orchestration.md" \
"15 - Distributed Locks.md" \
"16 - Lease Based Locks.md" \
"17 - Fencing Tokens.md" \
"18 - Leader Election.md" \
"19 - Distributed Coordination.md" \
"20 - Consensus Algorithms.md" \
"21 - Raft.md" \
"22 - Paxos.md" \
"23 - Quorum.md" \
"24 - Split Brain.md" \
"25 - Network Partitions and Failure Detection.md" \
"26 - Heartbeats.md" \
"27 - Gossip Protocol.md" \
"28 - Service Discovery.md" \
"29 - Distributed Configuration.md" \
"30 - Clock Synchronization.md" \
"31 - Logical Clocks.md" \
"32 - Vector Clocks.md" \
"33 - Idempotency in Distributed Systems.md" \
"34 - Retry and Duplicate Execution.md"

# ==================================================
# 08 - SCALABILITY AND PERFORMANCE
# ==================================================

create_package "08 - Scalability and Performance" \
"00 - Scalability Fundamentals.md" \
"01 - Vertical Scaling.md" \
"02 - Horizontal Scaling.md" \
"03 - Stateless Application Design.md" \
"04 - Stateful Application Design.md" \
"05 - Session Management at Scale.md" \
"06 - Load Balancing Strategies.md" \
"07 - Round Robin.md" \
"08 - Least Connections.md" \
"09 - Consistent Hashing.md" \
"10 - Request Routing.md" \
"11 - Database Read Write Splitting.md" \
"12 - Database Sharding Strategies.md" \
"13 - Hot Partitions.md" \
"14 - Hot Keys.md" \
"15 - Backpressure.md" \
"16 - Queue Based Load Leveling.md" \
"17 - Bulkhead Isolation.md" \
"18 - Resource Pooling.md" \
"19 - Connection Pool Sizing.md" \
"20 - JVM Performance Fundamentals.md" \
"21 - JVM Heap and Memory Pressure.md" \
"22 - Garbage Collection Impact.md" \
"23 - Thread Pool Sizing.md" \
"24 - Virtual Threads in Production.md" \
"25 - CPU Bound vs IO Bound Workloads.md" \
"26 - Profiling Production Applications.md" \
"27 - Load Testing.md" \
"28 - Stress Testing.md" \
"29 - Spike Testing.md" \
"30 - Soak Testing.md" \
"31 - Capacity Testing.md" \
"32 - Performance Budgets.md" \
"33 - Tail Latency.md" \
"34 - Percentiles and P95 P99.md" \
"35 - Performance Optimization Workflow.md"

# ==================================================
# 09 - RELIABILITY AND RESILIENCE
# ==================================================

create_package "09 - Reliability and Resilience" \
"00 - Reliability Engineering.md" \
"01 - Fault Tolerance.md" \
"02 - High Availability.md" \
"03 - Redundancy.md" \
"04 - Failover Strategies.md" \
"05 - Active Active Architecture.md" \
"06 - Active Passive Architecture.md" \
"07 - Health Checks.md" \
"08 - Liveness and Readiness Probes.md" \
"09 - Startup Probes.md" \
"10 - Graceful Shutdown.md" \
"11 - Graceful Degradation.md" \
"12 - Circuit Breaker Pattern.md" \
"13 - Retry Pattern.md" \
"14 - Exponential Backoff.md" \
"15 - Jitter.md" \
"16 - Timeout Pattern.md" \
"17 - Bulkhead Pattern.md" \
"18 - Rate Limiting.md" \
"19 - Load Shedding.md" \
"20 - Fallback Strategies.md" \
"21 - Resilience4j.md" \
"22 - Failure Injection Testing.md" \
"23 - Chaos Engineering.md" \
"24 - Fault Isolation.md" \
"25 - Disaster Recovery.md" \
"26 - RTO and RPO.md" \
"27 - Business Continuity.md" \
"28 - Availability Calculations.md" \
"29 - SLA SLO and SLI.md" \
"30 - Error Budgets.md" \
"31 - Production Incident Management.md"

# ==================================================
# 10 - SECURITY
# ==================================================

create_package "10 - Security" \
"00 - Production Security Architecture.md" \
"01 - Security by Design.md" \
"02 - Defense in Depth.md" \
"03 - Authentication vs Authorization.md" \
"04 - OAuth 2.0.md" \
"05 - OpenID Connect.md" \
"06 - JWT Architecture.md" \
"07 - Access and Refresh Tokens.md" \
"08 - Token Rotation.md" \
"09 - Session Based Authentication.md" \
"10 - Spring Security Architecture.md" \
"11 - API Security.md" \
"12 - Rate Limiting and Abuse Prevention.md" \
"13 - TLS Everywhere.md" \
"14 - Service to Service Authentication.md" \
"15 - Mutual TLS.md" \
"16 - Secrets Management.md" \
"17 - Environment Variables and Secrets.md" \
"18 - Vault and Secret Managers.md" \
"19 - Database Security.md" \
"20 - Least Privilege Principle.md" \
"21 - Network Segmentation.md" \
"22 - OWASP Top 10.md" \
"23 - SQL Injection.md" \
"24 - SSRF.md" \
"25 - CSRF.md" \
"26 - CORS.md" \
"27 - Secure Headers.md" \
"28 - Audit Trails.md" \
"29 - Data Encryption at Rest.md" \
"30 - Data Encryption in Transit.md" \
"31 - PII Protection.md" \
"32 - Dependency and Supply Chain Security.md" \
"33 - Security Incident Response.md"

# ==================================================
# 11 - OBSERVABILITY AND OPERATIONS
# ==================================================

create_package "11 - Observability and Operations" \
"00 - Production Observability.md" \
"01 - Logs Metrics and Traces.md" \
"02 - Observability vs Monitoring.md" \
"03 - Structured Logging.md" \
"04 - Correlation IDs.md" \
"05 - MDC and Distributed Context.md" \
"06 - Spring Boot Actuator.md" \
"07 - Micrometer.md" \
"08 - Prometheus.md" \
"09 - Grafana.md" \
"10 - Alertmanager.md" \
"11 - Alert Design.md" \
"12 - Alert Fatigue.md" \
"13 - OpenTelemetry.md" \
"14 - Distributed Tracing.md" \
"15 - Trace Context Propagation.md" \
"16 - Jaeger.md" \
"17 - Tempo.md" \
"18 - Centralized Logging.md" \
"19 - ELK Stack.md" \
"20 - Grafana Loki.md" \
"21 - Log Retention.md" \
"22 - Log Sampling.md" \
"23 - RED Metrics.md" \
"24 - USE Method.md" \
"25 - Golden Signals.md" \
"26 - Production Dashboards.md" \
"27 - SLI SLO and SLA Monitoring.md" \
"28 - Incident Response.md" \
"29 - On Call Engineering.md" \
"30 - Runbooks.md" \
"31 - Postmortem Analysis.md" \
"32 - Root Cause Analysis.md" \
"33 - Production Debugging.md" \
"34 - JVM Monitoring.md" \
"35 - Database Monitoring.md" \
"36 - Infrastructure Monitoring.md"

# ==================================================
# 12 - DEPLOYMENT AND INFRASTRUCTURE
# ==================================================

create_package "12 - Deployment and Infrastructure" \
"00 - Production Deployment Architecture.md" \
"01 - Linux Production Fundamentals.md" \
"02 - Process Management.md" \
"03 - Systemd Services.md" \
"04 - Reverse Proxy Deployment.md" \
"05 - Nginx.md" \
"06 - TLS Termination.md" \
"07 - Docker Architecture.md" \
"08 - Docker Images and Layers.md" \
"09 - Multi Stage Docker Builds.md" \
"10 - Docker Networking.md" \
"11 - Docker Volumes.md" \
"12 - Container Resource Limits.md" \
"13 - Container Health Checks.md" \
"14 - Docker Compose.md" \
"15 - Kubernetes Architecture.md" \
"16 - Pods and Deployments.md" \
"17 - Services and Ingress.md" \
"18 - ConfigMaps and Secrets.md" \
"19 - Resource Requests and Limits.md" \
"20 - Horizontal Pod Autoscaler.md" \
"21 - Kubernetes Probes.md" \
"22 - Persistent Volumes.md" \
"23 - Kubernetes Rolling Updates.md" \
"24 - Helm.md" \
"25 - Infrastructure as Code.md" \
"26 - Terraform.md" \
"27 - Cloud Computing Fundamentals.md" \
"28 - AWS Production Architecture.md" \
"29 - Load Balancers in Cloud.md" \
"30 - Cloud Managed Databases.md" \
"31 - Object Storage.md" \
"32 - CDN.md" \
"33 - DNS and Domain Management.md" \
"34 - Environment Separation.md" \
"35 - Infrastructure Cost Management.md"

# ==================================================
# 13 - DATA CONSISTENCY AND TRANSACTIONS
# ==================================================

create_package "13 - Data Consistency and Transactions" \
"00 - Transaction Fundamentals.md" \
"01 - ACID Properties.md" \
"02 - Transaction Isolation Levels.md" \
"03 - Dirty Reads.md" \
"04 - Non Repeatable Reads.md" \
"05 - Phantom Reads.md" \
"06 - Lost Updates.md" \
"07 - Write Skew.md" \
"08 - Optimistic Locking.md" \
"09 - Pessimistic Locking.md" \
"10 - MVCC.md" \
"11 - PostgreSQL Row Level Locks.md" \
"12 - Deadlocks.md" \
"13 - Deadlock Detection and Prevention.md" \
"14 - Spring Transaction Management.md" \
"15 - Transaction Propagation.md" \
"16 - Transaction Rollback Rules.md" \
"17 - Transaction Boundaries.md" \
"18 - Long Running Transactions.md" \
"19 - Distributed Transaction Problems.md" \
"20 - Eventual Consistency Patterns.md" \
"21 - Saga Transactions.md" \
"22 - Transactional Outbox.md" \
"23 - Inbox Pattern.md" \
"24 - Idempotent Transaction Processing.md" \
"25 - Reconciliation Jobs.md" \
"26 - Data Consistency Testing.md"

# ==================================================
# 14 - PRODUCTION DESIGN PATTERNS
# ==================================================

create_package "14 - Production Design Patterns" \
"00 - Production Architecture Patterns.md" \
"01 - Layered Architecture.md" \
"02 - Modular Monolith Pattern.md" \
"03 - Microservices Pattern.md" \
"04 - Strangler Fig Pattern.md" \
"05 - Anti Corruption Layer.md" \
"06 - API Gateway Pattern.md" \
"07 - Backend for Frontend Pattern.md" \
"08 - Service Discovery Pattern.md" \
"09 - Database per Service.md" \
"10 - CQRS.md" \
"11 - Event Sourcing.md" \
"12 - Saga Pattern.md" \
"13 - Transactional Outbox Pattern.md" \
"14 - Inbox Pattern.md" \
"15 - Circuit Breaker Pattern.md" \
"16 - Bulkhead Pattern.md" \
"17 - Retry Pattern.md" \
"18 - Rate Limiter Pattern.md" \
"19 - Cache Aside Pattern.md" \
"20 - Sidecar Pattern.md" \
"21 - Ambassador Pattern.md" \
"22 - Adapter Pattern in Integration.md" \
"23 - Anti Corruption Boundaries.md" \
"24 - Hexagonal Architecture in Spring Boot.md" \
"25 - Database Per Tenant.md" \
"26 - Multi Tenancy.md" \
"27 - Feature Flags.md" \
"28 - Blue Green Deployment.md" \
"29 - Canary Deployment.md" \
"30 - Rolling Deployment.md" \
"31 - Zero Downtime Deployment.md" \
"32 - Expand and Contract Migrations.md" \
"33 - Production Architecture Tradeoffs.md"

# ==================================================
# 15 - PRODUCTION CASE STUDIES
# ==================================================

create_package "15 - Production Case Studies" \
"00 - How to Approach a System Design Interview.md" \
"01 - Production Design Document.md" \
"02 - Design a URL Shortener.md" \
"03 - Design a Pastebin Service.md" \
"04 - Design a File Storage Service.md" \
"05 - Design an Image Processing Service.md" \
"06 - Design a Notification System.md" \
"07 - Design an Email Delivery System.md" \
"08 - Design a Chat Application.md" \
"09 - Design a Real Time Messaging System.md" \
"10 - Design a News Feed.md" \
"11 - Design a Social Media Backend.md" \
"12 - Design an Authentication Service.md" \
"13 - Design an Authorization Service.md" \
"14 - Design an E Commerce Backend.md" \
"15 - Design an Inventory Management System.md" \
"16 - Design an Order Processing System.md" \
"17 - Design a Payment Processing System.md" \
"18 - Design a Booking and Reservation System.md" \
"19 - Design a Rate Limiting Service.md" \
"20 - Design a Distributed Cache.md" \
"21 - Design a Job Scheduling System.md" \
"22 - Design a Background Processing System.md" \
"23 - Design a Webhook Delivery Platform.md" \
"24 - Design an Audit Logging Platform.md" \
"25 - Design a Log Aggregation Platform.md" \
"26 - Design a Metrics Monitoring Platform.md" \
"27 - Design a Search Service.md" \
"28 - Design a Recommendation System.md" \
"29 - Design a Multi Tenant SaaS Backend.md" \
"30 - Design a Payment Ledger.md" \
"31 - Design a Distributed Task Queue.md" \
"32 - Design a URL Based File Sharing System.md" \
"33 - Production Design Review and Failure Analysis.md"

# ==================================================
# 16 - PRODUCTION ENGINEERING CHECKLISTS
# ==================================================

create_package "16 - Production Engineering Checklists" \
"00 - Production Readiness Checklist.md" \
"01 - Application Security Checklist.md" \
"02 - API Production Checklist.md" \
"03 - Database Production Checklist.md" \
"04 - PostgreSQL Backup Checklist.md" \
"05 - Database Migration Checklist.md" \
"06 - Caching Production Checklist.md" \
"07 - Messaging Production Checklist.md" \
"08 - Observability Checklist.md" \
"09 - Logging Checklist.md" \
"10 - Monitoring and Alerting Checklist.md" \
"11 - Deployment Checklist.md" \
"12 - Docker Production Checklist.md" \
"13 - Kubernetes Production Checklist.md" \
"14 - Disaster Recovery Checklist.md" \
"15 - Incident Response Checklist.md" \
"16 - Performance Testing Checklist.md" \
"17 - Load Testing Checklist.md" \
"18 - Capacity Planning Checklist.md" \
"19 - High Availability Checklist.md" \
"20 - Zero Downtime Release Checklist.md" \
"21 - Rollback Checklist.md" \
"22 - Cost Optimization Checklist.md" \
"23 - Production Review Template.md" \
"24 - System Design Review Checklist.md"

# ==================================================
# SUMMARY
# ==================================================

echo
echo "============================================"
echo "System Design curriculum generation complete"
echo "============================================"
echo "Target:  $BASE_DIR"
echo "Created: $created"
echo "Skipped: $skipped"
echo "Packages: 17"
echo "============================================"
