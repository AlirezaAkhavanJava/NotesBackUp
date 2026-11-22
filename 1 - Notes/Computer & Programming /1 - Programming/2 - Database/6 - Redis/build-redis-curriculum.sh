
#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR="$(pwd)"

if [[ "$(basename "$BASE_DIR")" != "6 - Redis" ]]; then
    echo "Error: Run this script inside the '6 - Redis' directory."
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
            echo "[[Redis]]"
            echo
        } > "$destination"

        echo "[CREATED] $note"
        ((created+=1))
    done
}

# ==================================================
# 00 - REDIS FUNDAMENTALS
# ==================================================

create_package "00 - Redis Fundamentals" \
"00 - What Is Redis.md" \
"01 - Why Redis Exists.md" \
"02 - Redis vs Traditional Databases.md" \
"03 - Redis vs PostgreSQL.md" \
"04 - Redis Use Cases in Backend Development.md" \
"05 - Redis as a Cache.md" \
"06 - Redis as a Database.md" \
"07 - Redis as a Message Broker.md" \
"08 - In Memory Data Storage.md" \
"09 - Key Value Data Model.md" \
"10 - Redis Advantages and Limitations.md" \
"11 - Redis vs Memcached.md" \
"12 - Redis Editions and Deployment Options.md" \
"13 - Redis in Production Spring Boot Applications.md"

# ==================================================
# 01 - REDIS ARCHITECTURE AND INTERNALS
# ==================================================

create_package "01 - Redis Architecture and Internals" \
"00 - Redis Architecture.md" \
"01 - Redis Server Architecture.md" \
"02 - Redis Client Server Model.md" \
"03 - Redis Event Loop.md" \
"04 - Redis Single Threaded Command Execution.md" \
"05 - Redis I O Multiplexing.md" \
"06 - Redis Network Protocol.md" \
"07 - RESP Protocol.md" \
"08 - Redis Key Space.md" \
"09 - Redis Memory Architecture.md" \
"10 - Redis Memory Allocation.md" \
"11 - Redis Object Encoding.md" \
"12 - Redis Internal Data Structures.md" \
"13 - Redis Database Selection.md" \
"14 - Redis Key Expiration.md" \
"15 - Lazy Expiration.md" \
"16 - Active Expiration.md" \
"17 - Redis Eviction Mechanism.md" \
"18 - Redis Memory Policies.md" \
"19 - Redis Configuration.md"

# ==================================================
# 02 - REDIS DATA TYPES
# ==================================================

create_package "02 - Redis Data Types" \
"00 - Redis Data Types Overview.md" \
"01 - Strings.md" \
"02 - Lists.md" \
"03 - Sets.md" \
"04 - Sorted Sets.md" \
"05 - Hashes.md" \
"06 - Streams.md" \
"07 - Bitmaps.md" \
"08 - Bitfields.md" \
"09 - HyperLogLog.md" \
"10 - Geospatial Data.md" \
"11 - Redis JSON.md" \
"12 - Redis Bloom Filters.md" \
"13 - Choosing the Right Redis Data Type.md" \
"14 - Redis Data Modeling.md" \
"15 - Redis Key Naming Conventions.md" \
"16 - Redis Key Design for Spring Boot Applications.md"

# ==================================================
# 03 - REDIS COMMANDS AND OPERATIONS
# ==================================================

create_package "03 - Redis Commands and Operations" \
"00 - Redis Command Fundamentals.md" \
"01 - Redis CLI.md" \
"02 - Connecting to Redis.md" \
"03 - GET and SET.md" \
"04 - MGET and MSET.md" \
"05 - DEL and UNLINK.md" \
"06 - EXISTS and TYPE.md" \
"07 - EXPIRE and TTL.md" \
"08 - PERSIST.md" \
"09 - INCR and DECR.md" \
"10 - HSET and HGET.md" \
"11 - LPUSH and RPUSH.md" \
"12 - SADD and SMEMBERS.md" \
"13 - ZADD and ZRANGE.md" \
"14 - SCAN vs KEYS.md" \
"15 - Transactions and MULTI EXEC.md" \
"16 - WATCH and Optimistic Locking.md" \
"17 - Lua Scripting.md" \
"18 - Redis Functions.md" \
"19 - Pipelining.md" \
"20 - Redis Command Complexity.md" \
"21 - Redis Command Monitoring.md"

# ==================================================
# 04 - PERSISTENCE AND DURABILITY
# ==================================================

create_package "04 - Redis Persistence and Durability" \
"00 - Redis Persistence.md" \
"01 - RDB Snapshots.md" \
"02 - AOF Persistence.md" \
"03 - RDB vs AOF.md" \
"04 - AOF Rewrite.md" \
"05 - Persistence Configuration.md" \
"06 - Redis Durability Guarantees.md" \
"07 - Redis Data Recovery.md" \
"08 - Redis Backup and Restore.md" \
"09 - Redis Persistence Performance.md" \
"10 - Redis Data Loss Scenarios.md" \
"11 - Redis as a Cache vs Persistent Store.md"

# ==================================================
# 05 - SPRING BOOT REDIS INTEGRATION
# ==================================================

create_package "05 - Spring Boot Redis Integration" \
"00 - Redis Integration with Spring Boot.md" \
"01 - Spring Boot Redis Starter.md" \
"02 - Spring Data Redis Dependencies.md" \
"03 - Redis Configuration in application.yml.md" \
"04 - Redis Connection Configuration.md" \
"05 - RedisConnectionFactory.md" \
"06 - Lettuce Client.md" \
"07 - Jedis Client.md" \
"08 - Lettuce vs Jedis.md" \
"09 - RedisConnection.md" \
"10 - RedisTemplate.md" \
"11 - StringRedisTemplate.md" \
"12 - RedisTemplate vs StringRedisTemplate.md" \
"13 - Redis Serialization.md" \
"14 - Redis Serializer.md" \
"15 - GenericJackson2JsonRedisSerializer.md" \
"16 - StringRedisSerializer.md" \
"17 - Jackson JSON Serialization.md" \
"18 - Redis Configuration Classes.md" \
"19 - Redis Connection Pooling.md" \
"20 - Redis Connection Timeouts.md" \
"21 - Redis Health Checks.md" \
"22 - Redis Configuration per Environment.md" \
"23 - Redis Auto Configuration.md" \
"24 - Redis Integration with Spring Boot Docker.md"

# ==================================================
# 06 - SPRING DATA REDIS
# ==================================================

create_package "06 - Spring Data Redis" \
"00 - Spring Data Redis Architecture.md" \
"01 - Redis Repositories.md" \
"02 - RedisRepository.md" \
"03 - RedisHash.md" \
"04 - RedisId.md" \
"05 - RedisKeyValueTemplate.md" \
"06 - RedisKeyValueAdapter.md" \
"07 - Redis Entity Mapping.md" \
"08 - Redis Object Mapping.md" \
"09 - Redis Repository Queries.md" \
"10 - Redis Repository TTL.md" \
"11 - Redis Repository Indexes.md" \
"12 - Redis Repository Limitations.md" \
"13 - RedisTemplate Operations.md" \
"14 - ValueOperations.md" \
"15 - HashOperations.md" \
"16 - ListOperations.md" \
"17 - SetOperations.md" \
"18 - ZSetOperations.md" \
"19 - StreamOperations.md" \
"20 - RedisCallback.md" \
"21 - SessionCallback.md" \
"22 - Reactive Redis with Spring.md" \
"23 - ReactiveRedisTemplate.md"

# ==================================================
# 07 - REDIS CACHING WITH SPRING BOOT
# ==================================================

create_package "07 - Redis Caching with Spring Boot" \
"00 - Caching Fundamentals.md" \
"01 - Spring Cache Abstraction.md" \
"02 - EnableCaching.md" \
"03 - CacheManager.md" \
"04 - RedisCacheManager.md" \
"05 - RedisCacheConfiguration.md" \
"06 - Cacheable.md" \
"07 - CachePut.md" \
"08 - CacheEvict.md" \
"09 - CacheConfig.md" \
"10 - Cache Keys.md" \
"11 - Custom Cache Key Generation.md" \
"12 - Cache TTL Configuration.md" \
"13 - Per Cache TTL Configuration.md" \
"14 - Cache Serialization.md" \
"15 - Cache Null Values.md" \
"16 - Cache Synchronization.md" \
"17 - Conditional Caching.md" \
"18 - Unless and Condition Attributes.md" \
"19 - Caching Service Layer Methods.md" \
"20 - Caching Repository Queries.md" \
"21 - Caching REST API Responses.md" \
"22 - Cache Warming on Startup.md" \
"23 - Cache Statistics.md" \
"24 - Cache Manager Configuration.md" \
"25 - Custom CacheResolver.md" \
"26 - Cache Error Handling.md" \
"27 - Cache Testing with Spring Boot.md"

# ==================================================
# 08 - REDIS AND POSTGRESQL ARCHITECTURE
# ==================================================

create_package "08 - Redis and PostgreSQL Architecture" \
"00 - Redis and PostgreSQL Together.md" \
"01 - Source of Truth.md" \
"02 - Persistent vs Ephemeral Data.md" \
"03 - Redis Cache in Front of PostgreSQL.md" \
"04 - Read Through Architecture.md" \
"05 - Cache Aside Architecture.md" \
"06 - Write Through Architecture.md" \
"07 - Write Behind Architecture.md" \
"08 - Read Write Separation.md" \
"09 - PostgreSQL Read Replicas and Redis.md" \
"10 - PostgreSQL Connection Pooling and Redis.md" \
"11 - HikariCP and Redis Connections.md" \
"12 - Database Query Caching.md" \
"13 - Caching Expensive PostgreSQL Queries.md" \
"14 - Caching JPA Entities.md" \
"15 - Caching DTOs and API Responses.md" \
"16 - Cache Data Projection.md" \
"17 - Redis Cache Key Design from Database Queries.md" \
"18 - Redis and PostgreSQL Data Ownership.md" \
"19 - Redis and PostgreSQL Failure Scenarios.md" \
"20 - Redis Cache Recovery After Database Failure.md" \
"21 - Redis Cache Warmup from PostgreSQL.md" \
"22 - PostgreSQL and Redis Data Synchronization.md" \
"23 - Dual Write Problem.md" \
"24 - Transactional Outbox with Redis.md" \
"25 - PostgreSQL CDC and Redis.md" \
"26 - Debezium Redis Cache Invalidation.md" \
"27 - Redis and PostgreSQL in Microservices.md" \
"28 - Production Redis PostgreSQL Architecture.md"

# ==================================================
# 09 - CACHE CONSISTENCY AND INVALIDATION
# ==================================================

create_package "09 - Cache Consistency and Invalidation" \
"00 - Cache Consistency.md" \
"01 - Cache Invalidation.md" \
"02 - Cache Invalidation Strategies.md" \
"03 - TTL Based Invalidation.md" \
"04 - Event Based Invalidation.md" \
"05 - Write Invalidation.md" \
"06 - Cache Update vs Cache Eviction.md" \
"07 - Stale Cache Data.md" \
"08 - Cache Stampede.md" \
"09 - Cache Penetration.md" \
"10 - Cache Avalanche.md" \
"11 - Cache Breakdown.md" \
"12 - Cache Warming.md" \
"13 - Cache Preloading.md" \
"14 - Cache Versioning.md" \
"15 - Negative Caching.md" \
"16 - Distributed Cache Invalidation.md" \
"17 - Cache Invalidation Across Application Instances.md" \
"18 - Race Conditions in Cache Updates.md" \
"19 - Concurrent Cache Refresh.md" \
"20 - Cache Consistency with PostgreSQL Transactions.md" \
"21 - Cache Invalidation with Spring Events.md" \
"22 - Cache Invalidation with Kafka Events.md" \
"23 - Cache Invalidation Testing.md"

# ==================================================
# 10 - REDIS TRANSACTIONS AND ATOMICITY
# ==================================================

create_package "10 - Redis Transactions and Atomicity" \
"00 - Redis Atomicity.md" \
"01 - Redis Command Atomicity.md" \
"02 - MULTI and EXEC.md" \
"03 - DISCARD.md" \
"04 - WATCH.md" \
"05 - Optimistic Locking in Redis.md" \
"06 - Redis Transaction Limitations.md" \
"07 - Redis Lua Scripts.md" \
"08 - Atomic Counters.md" \
"09 - Atomic Rate Limiting.md" \
"10 - Atomic Inventory Operations.md" \
"11 - Redis Transactions vs PostgreSQL Transactions.md" \
"12 - Why Redis and PostgreSQL Transactions Are Separate.md" \
"13 - Distributed Transaction Limitations.md" \
"14 - Idempotent Redis Operations.md" \
"15 - Handling Partial Failures.md"

# ==================================================
# 11 - REDIS MESSAGING AND STREAMS
# ==================================================

create_package "11 - Redis Messaging and Streams" \
"00 - Redis Messaging.md" \
"01 - Redis Pub Sub.md" \
"02 - Publish and Subscribe.md" \
"03 - Redis Pub Sub Limitations.md" \
"04 - Redis Streams.md" \
"05 - XADD and XREAD.md" \
"06 - Consumer Groups.md" \
"07 - XREADGROUP.md" \
"08 - XACK.md" \
"09 - Pending Entries List.md" \
"10 - XCLAIM and XAUTOCLAIM.md" \
"11 - Stream Retention.md" \
"12 - Stream Trimming.md" \
"13 - Redis Streams vs Kafka.md" \
"14 - Redis Streams vs RabbitMQ.md" \
"15 - Message Delivery Guarantees.md" \
"16 - Dead Letter Handling.md" \
"17 - Redis Streams with Spring Boot.md" \
"18 - Stream Consumer Recovery.md" \
"19 - Event Driven Spring Boot Applications with Redis.md"

# ==================================================
# 12 - SESSIONS AND AUTHENTICATION
# ==================================================

create_package "12 - Sessions and Authentication" \
"00 - Redis for Session Management.md" \
"01 - Stateful vs Stateless Authentication.md" \
"02 - Distributed HTTP Sessions.md" \
"03 - Spring Session.md" \
"04 - Spring Session Redis.md" \
"05 - Redis Indexed Sessions.md" \
"06 - Session Expiration.md" \
"07 - Session Invalidation.md" \
"08 - Concurrent Session Management.md" \
"09 - Session Serialization.md" \
"10 - Redis Based Login Rate Limiting.md" \
"11 - Refresh Token Storage.md" \
"12 - Token Revocation with Redis.md" \
"13 - Token Blacklisting.md" \
"14 - JWT Revocation Strategies.md" \
"15 - Spring Security Integration.md" \
"16 - Redis Session Security.md" \
"17 - Redis Authentication Failure Handling.md"

# ==================================================
# 13 - DISTRIBUTED LOCKS AND CONCURRENCY
# ==================================================

create_package "13 - Distributed Locks and Concurrency" \
"00 - Distributed Locking.md" \
"01 - Why Distributed Locks Are Needed.md" \
"02 - Redis SET NX EX.md" \
"03 - Lock Ownership.md" \
"04 - Safe Lock Release.md" \
"05 - Lock Expiration.md" \
"06 - Lock Renewal.md" \
"07 - Lease Based Locks.md" \
"08 - Fencing Tokens.md" \
"09 - Redlock Algorithm.md" \
"10 - Redis Locks and PostgreSQL Transactions.md" \
"11 - Preventing Duplicate Job Execution.md" \
"12 - Distributed Scheduled Jobs.md" \
"13 - ShedLock.md" \
"14 - Redis Locks with Spring Boot.md" \
"15 - Redis Lock Failure Scenarios.md" \
"16 - Lock Contention.md" \
"17 - When Not to Use Redis Distributed Locks.md"

# ==================================================
# 14 - PERFORMANCE AND SCALABILITY
# ==================================================

create_package "14 - Performance and Scalability" \
"00 - Redis Performance Fundamentals.md" \
"01 - Redis Latency.md" \
"02 - Redis Throughput.md" \
"03 - Redis Benchmarking.md" \
"04 - Redis Benchmark Tool.md" \
"05 - Pipeline Performance.md" \
"06 - Batch Operations.md" \
"07 - Redis Memory Optimization.md" \
"08 - Serialization Overhead.md" \
"09 - Large Key Problems.md" \
"10 - Hot Keys.md" \
"11 - Big Key Analysis.md" \
"12 - Redis Slow Log.md" \
"13 - Redis Latency Monitoring.md" \
"14 - Redis Connection Pool Sizing.md" \
"15 - Redis Client Timeouts.md" \
"16 - Redis Cluster.md" \
"17 - Redis Sharding.md" \
"18 - Redis Replication.md" \
"19 - Redis Sentinel.md" \
"20 - Redis High Availability.md" \
"21 - Redis Cluster Hash Slots.md" \
"22 - Redis Failover.md" \
"23 - Redis Read Scaling.md" \
"24 - Redis Client Side Caching.md" \
"25 - Scaling Spring Boot Redis Applications.md" \
"26 - Redis Performance Tuning in Production.md"

# ==================================================
# 15 - SECURITY AND PRODUCTION OPERATIONS
# ==================================================

create_package "15 - Security and Production Operations" \
"00 - Redis Production Security.md" \
"01 - Redis Authentication.md" \
"02 - Redis ACL.md" \
"03 - Redis Users and Permissions.md" \
"04 - Redis TLS.md" \
"05 - Redis Network Security.md" \
"06 - Redis Bind Configuration.md" \
"07 - Protected Mode.md" \
"08 - Redis Dangerous Commands.md" \
"09 - Redis Command Renaming.md" \
"10 - Redis Secret Management.md" \
"11 - Redis Data Encryption.md" \
"12 - Redis Persistence Operations.md" \
"13 - Redis Backup Strategy.md" \
"14 - Redis Restore Strategy.md" \
"15 - Redis Upgrade Strategy.md" \
"16 - Redis Configuration Management.md" \
"17 - Redis Production Deployment.md" \
"18 - Redis Docker Deployment.md" \
"19 - Redis Docker Compose.md" \
"20 - Redis Kubernetes Deployment.md" \
"21 - Redis Managed Services.md" \
"22 - Redis Operational Runbooks.md" \
"23 - Redis Disaster Recovery.md" \
"24 - Redis Production Checklist.md"

# ==================================================
# 16 - MONITORING AND TESTING
# ==================================================

create_package "16 - Monitoring and Testing" \
"00 - Redis Monitoring.md" \
"01 - Redis INFO Command.md" \
"02 - Redis MONITOR Command.md" \
"03 - Redis CLIENT LIST.md" \
"04 - Redis Memory Diagnostics.md" \
"05 - Redis Health Checks.md" \
"06 - Spring Boot Actuator Redis Health.md" \
"07 - Micrometer Redis Metrics.md" \
"08 - Prometheus Redis Exporter.md" \
"09 - Grafana Redis Dashboards.md" \
"10 - Redis Alerting.md" \
"11 - Redis Connection Monitoring.md" \
"12 - Redis Cache Hit Ratio.md" \
"13 - Redis Eviction Monitoring.md" \
"14 - Redis Slow Command Monitoring.md" \
"15 - Testing Redis with Spring Boot.md" \
"16 - Testcontainers Redis.md" \
"17 - Redis Integration Tests.md" \
"18 - Redis Serialization Tests.md" \
"19 - Cache Behavior Testing.md" \
"20 - Cache Invalidation Testing.md" \
"21 - Redis Failure Testing.md" \
"22 - Redis Mocking vs Real Redis.md" \
"23 - Testing Redis and PostgreSQL Together.md" \
"24 - Redis Load Testing.md" \
"25 - Redis Chaos Testing.md"

# ==================================================
# 17 - PRODUCTION PROJECTS AND CASE STUDIES
# ==================================================

create_package "17 - Production Projects and Case Studies" \
"00 - Redis Production Project Methodology.md" \
"01 - Spring Boot Redis Configuration Project.md" \
"02 - PostgreSQL and Redis Cache Aside Project.md" \
"03 - Product Catalog Caching System.md" \
"04 - User Profile Caching System.md" \
"05 - Redis Based API Rate Limiter.md" \
"06 - Redis Based Login Attempt Limiter.md" \
"07 - Redis Session Management System.md" \
"08 - Refresh Token Revocation System.md" \
"09 - Distributed Job Locking System.md" \
"10 - Distributed Scheduled Job System.md" \
"11 - Redis Based Leaderboard.md" \
"12 - Redis Based Notification System.md" \
"13 - Redis Streams Background Processing.md" \
"14 - PostgreSQL Outbox and Redis Events.md" \
"15 - Cache Invalidation with Spring Events.md" \
"16 - Cache Invalidation with Kafka.md" \
"17 - Multi Instance Spring Boot Cache.md" \
"18 - Redis and PostgreSQL Failure Recovery.md" \
"19 - Production Cache Monitoring Dashboard.md" \
"20 - Production Redis PostgreSQL Backend.md" \
"21 - Redis Architecture Design Review.md"

# ==================================================
# SUMMARY
# ==================================================

echo
echo "============================================"
echo "Redis curriculum generation complete"
echo "============================================"
echo "Target:  $BASE_DIR"
echo "Created: $created"
echo "Skipped: $skipped"
echo "Packages: 18"
echo "============================================"
