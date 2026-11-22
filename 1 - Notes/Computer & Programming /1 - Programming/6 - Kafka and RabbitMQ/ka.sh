
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"

if [[ "$(basename "$ROOT")" != "6 - Kafka and RabbitMQ" ]]; then
    echo "ERROR: Run this script inside '6 - Kafka and RabbitMQ'."
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

        printf '[[Kafka and RabbitMQ]]\n' > "$file"
        echo "CREATE: $folder/$note.md"
        ((created+=1))
    done
}

# --------------------------------------------------
# 00 - Messaging Fundamentals
# --------------------------------------------------

create_notes "00 - Messaging Fundamentals" \
"00 - What Is Message-Based Communication" \
"01 - Synchronous vs Asynchronous Communication" \
"02 - Message Brokers" \
"03 - Producers and Consumers" \
"04 - Messages Events and Commands" \
"05 - Queues vs Topics" \
"06 - Point-to-Point Messaging" \
"07 - Publish Subscribe Pattern" \
"08 - Request Reply Pattern" \
"09 - Event-Driven Architecture" \
"10 - Message Delivery Lifecycle" \
"11 - Delivery Semantics" \
"12 - At Most Once At Least Once Exactly Once" \
"13 - Message Ordering" \
"14 - Message Durability" \
"15 - Backpressure and Flow Control" \
"16 - Messaging vs REST APIs" \
"17 - Choosing a Message Broker"

# --------------------------------------------------
# 01 - Kafka Fundamentals and Architecture
# --------------------------------------------------

create_notes "01 - Kafka Fundamentals and Architecture" \
"00 - What Is Apache Kafka" \
"01 - Kafka Use Cases" \
"02 - Kafka Architecture Overview" \
"03 - Broker Cluster and Controller" \
"04 - KRaft Architecture" \
"05 - Topics and Partitions" \
"06 - Offsets and Logs" \
"07 - Replication Factor" \
"08 - Leader and Follower Replicas" \
"09 - ISR In Sync Replicas" \
"10 - Consumer Groups" \
"11 - Partition Assignment" \
"12 - Rebalancing" \
"13 - Retention Policies" \
"14 - Log Compaction" \
"15 - Segment Files and Indexes" \
"16 - Kafka Storage Architecture" \
"17 - Kafka Metadata and Cluster Coordination"

# --------------------------------------------------
# 02 - Kafka Producers
# --------------------------------------------------

create_notes "02 - Kafka Producers" \
"00 - Producer Architecture" \
"01 - KafkaProducer API" \
"02 - ProducerRecord" \
"03 - ProducerRecord Keys and Values" \
"04 - Serializers" \
"05 - Partitioners" \
"06 - Default Partitioner" \
"07 - Custom Partitioners" \
"08 - Producer Acknowledgements" \
"09 - Acks Configuration" \
"10 - Batching and batch.size" \
"11 - Linger.ms" \
"12 - Compression" \
"13 - Retries and Delivery Timeout" \
"14 - Idempotent Producers" \
"15 - Transactions and Transactional Producers" \
"16 - Producer Callbacks" \
"17 - Asynchronous and Synchronous Sending" \
"18 - Producer Performance Tuning"

# --------------------------------------------------
# 03 - Kafka Consumers
# --------------------------------------------------

create_notes "03 - Kafka Consumers" \
"00 - Consumer Architecture" \
"01 - KafkaConsumer API" \
"02 - Poll Loop" \
"03 - Consumer Subscriptions" \
"04 - Manual Partition Assignment" \
"05 - Automatic Offset Management" \
"06 - Manual Offset Commits" \
"07 - Synchronous and Asynchronous Commits" \
"08 - Commit Strategies" \
"09 - Consumer Rebalancing" \
"10 - Cooperative Rebalancing" \
"11 - Static Group Membership" \
"12 - Consumer Lag" \
"13 - max.poll.interval.ms" \
"14 - max.poll.records" \
"15 - Heartbeats and Session Timeout" \
"16 - Retry and Recovery" \
"17 - Poison Pill Messages" \
"18 - Dead Letter Topics" \
"19 - Consumer Performance Tuning"

# --------------------------------------------------
# 04 - Kafka Advanced Concepts
# --------------------------------------------------

create_notes "04 - Kafka Advanced Concepts" \
"00 - Kafka Delivery Guarantees" \
"01 - At Most Once Processing" \
"02 - At Least Once Processing" \
"03 - Exactly Once Semantics" \
"04 - Idempotent Message Processing" \
"05 - Kafka Transactions" \
"06 - Transactional IDs" \
"07 - Read Committed Isolation" \
"08 - Ordering Guarantees" \
"09 - Partitioning Strategies" \
"10 - Schema Evolution" \
"11 - Schema Registry" \
"12 - Avro Serialization" \
"13 - Protobuf Serialization" \
"14 - JSON Serialization" \
"15 - Kafka Streams" \
"16 - Stream Processing Fundamentals" \
"17 - KTable and KStream" \
"18 - Windowing and Stateful Processing" \
"19 - Kafka Connect" \
"20 - Source and Sink Connectors" \
"21 - Kafka MirrorMaker" \
"22 - Multi Cluster Kafka"

# --------------------------------------------------
# 05 - RabbitMQ Fundamentals and Architecture
# --------------------------------------------------

create_notes "05 - RabbitMQ Fundamentals and Architecture" \
"00 - What Is RabbitMQ" \
"01 - RabbitMQ Use Cases" \
"02 - AMQP Protocol" \
"03 - RabbitMQ Architecture" \
"04 - Connections and Channels" \
"05 - Virtual Hosts" \
"06 - Exchanges and Queues" \
"07 - Bindings and Routing Keys" \
"08 - Direct Exchange" \
"09 - Fanout Exchange" \
"10 - Topic Exchange" \
"11 - Headers Exchange" \
"12 - Default Exchange" \
"13 - Durable and Exclusive Queues" \
"14 - Persistent Messages" \
"15 - Temporary and Auto Delete Queues" \
"16 - Queue Types" \
"17 - Classic Queues" \
"18 - Quorum Queues" \
"19 - Streams in RabbitMQ"

# --------------------------------------------------
# 06 - RabbitMQ Producers and Consumers
# --------------------------------------------------

create_notes "06 - RabbitMQ Producers and Consumers" \
"00 - Publishing Messages" \
"01 - BasicPublish and BasicConsume" \
"02 - Message Properties and Headers" \
"03 - Message Routing" \
"04 - Manual Acknowledgements" \
"05 - Automatic Acknowledgements" \
"06 - BasicAck BasicNack and BasicReject" \
"07 - Prefetch Count and QoS" \
"08 - Consumer Concurrency" \
"09 - Fair Dispatch" \
"10 - Publisher Confirms" \
"11 - Publisher Returns" \
"12 - Mandatory Publishing" \
"13 - Message Persistence" \
"14 - Message TTL" \
"15 - Queue TTL" \
"16 - Dead Letter Exchanges" \
"17 - Dead Letter Queues" \
"18 - Retry Queues" \
"19 - Delayed Message Delivery" \
"20 - Priority Queues" \
"21 - Consumer Cancellation and Recovery"

# --------------------------------------------------
# 07 - RabbitMQ Advanced Concepts
# --------------------------------------------------

create_notes "07 - RabbitMQ Advanced Concepts" \
"00 - RabbitMQ Delivery Guarantees" \
"01 - Message Ordering" \
"02 - Redelivery and Duplicate Messages" \
"03 - Idempotent Consumers" \
"04 - Consumer Failure Recovery" \
"05 - Connection Recovery" \
"06 - Channel Recovery" \
"07 - Flow Control" \
"08 - Backpressure" \
"09 - Quorum Queue Replication" \
"10 - RabbitMQ Clustering" \
"11 - High Availability" \
"12 - Federation" \
"13 - Shovel Plugin" \
"14 - RabbitMQ Streams" \
"15 - Stream Consumers and Offsets" \
"16 - RabbitMQ Management API" \
"17 - RabbitMQ Plugins" \
"18 - RabbitMQ Performance Tuning"

# --------------------------------------------------
# 08 - Spring Boot Messaging Fundamentals
# --------------------------------------------------

create_notes "08 - Spring Boot Messaging Fundamentals" \
"00 - Spring Messaging Abstraction" \
"01 - Spring Boot Messaging Auto Configuration" \
"02 - Message Payloads and Headers" \
"03 - Message Conversion" \
"04 - Message Channels" \
"05 - Message Handlers" \
"06 - Messaging Configuration Properties" \
"07 - Externalized Broker Configuration" \
"08 - Connection Lifecycle" \
"09 - Message Serialization and Deserialization" \
"10 - Messaging Exception Handling" \
"11 - Testing Messaging Applications"

# --------------------------------------------------
# 09 - Spring Boot and Kafka
# --------------------------------------------------

create_notes "09 - Spring Boot and Kafka" \
"00 - Spring for Apache Kafka Overview" \
"01 - Spring Kafka Dependencies" \
"02 - Kafka Properties in application.yml" \
"03 - KafkaAdmin and Topic Creation" \
"04 - ProducerFactory and ConsumerFactory" \
"05 - KafkaTemplate" \
"06 - Sending Messages with KafkaTemplate" \
"07 - CompletableFuture and Send Results" \
"08 - @KafkaListener" \
"09 - Listener Containers" \
"10 - ConcurrentKafkaListenerContainerFactory" \
"11 - Consumer Group Configuration" \
"12 - Manual Offset Acknowledgement" \
"13 - Record and Batch Listeners" \
"14 - Message Converters" \
"15 - JSON Serialization with Spring Kafka" \
"16 - Custom Serializers and Deserializers" \
"17 - ErrorHandlingDeserializer" \
"18 - DefaultErrorHandler" \
"19 - Retryable Topics" \
"20 - Dead Letter Publishing Recoverer" \
"21 - Kafka Transactions with Spring" \
"22 - ReplyingKafkaTemplate" \
"23 - Request Reply Messaging" \
"24 - Non Blocking Retries" \
"25 - Kafka Integration Testing" \
"26 - Embedded Kafka and Testcontainers" \
"27 - Spring Kafka Observability" \
"28 - Production Kafka Configuration"

# --------------------------------------------------
# 10 - Spring Boot and RabbitMQ
# --------------------------------------------------

create_notes "10 - Spring Boot and RabbitMQ" \
"00 - Spring AMQP Overview" \
"01 - Spring Boot AMQP Dependencies" \
"02 - RabbitMQ Properties in application.yml" \
"03 - ConnectionFactory" \
"04 - CachingConnectionFactory" \
"05 - RabbitAdmin" \
"06 - Declarable Exchanges Queues and Bindings" \
"07 - RabbitTemplate" \
"08 - Sending Messages with RabbitTemplate" \
"09 - MessageBuilder and MessageProperties" \
"10 - @RabbitListener" \
"11 - SimpleMessageListenerContainer" \
"12 - DirectMessageListenerContainer" \
"13 - Listener Concurrency" \
"14 - Manual Acknowledgement Mode" \
"15 - Message Converters" \
"16 - Jackson JSON Message Conversion" \
"17 - Custom Message Converters" \
"18 - Retry Interceptors" \
"19 - Retry and Recovery Configuration" \
"20 - Dead Letter Exchange Configuration" \
"21 - Publisher Confirms with Spring AMQP" \
"22 - Publisher Returns with Spring AMQP" \
"23 - Request Reply with RabbitTemplate" \
"24 - Message Correlation" \
"25 - Spring AMQP Testing" \
"26 - Testcontainers RabbitMQ" \
"27 - Spring AMQP Observability" \
"28 - Production RabbitMQ Configuration"

# --------------------------------------------------
# 11 - Kafka RabbitMQ and PostgreSQL
# --------------------------------------------------

create_notes "11 - Kafka RabbitMQ and PostgreSQL" \
"00 - Database and Message Broker Boundaries" \
"01 - PostgreSQL as the Source of Truth" \
"02 - The Dual Write Problem" \
"03 - Database Transaction and Message Publishing" \
"04 - Why Distributed Transactions Are Difficult" \
"05 - Transactional Outbox Pattern" \
"06 - Outbox Table Design in PostgreSQL" \
"07 - Implementing Outbox with Spring Boot" \
"08 - Outbox Polling Publisher" \
"09 - Outbox Event Cleanup" \
"10 - Change Data Capture Fundamentals" \
"11 - Debezium Architecture" \
"12 - PostgreSQL WAL and Logical Replication" \
"13 - Debezium PostgreSQL Connector" \
"14 - Debezium and Kafka Connect" \
"15 - Outbox Event Router" \
"16 - Transaction Log Tailing" \
"17 - Inbox Pattern" \
"18 - Idempotent Event Consumers" \
"19 - Processed Message Tables" \
"20 - Handling Duplicate Events" \
"21 - Eventual Consistency" \
"22 - Saga Pattern with Messaging" \
"23 - Choreography vs Orchestration" \
"24 - Compensating Transactions" \
"25 - PostgreSQL and Redis with Messaging" \
"26 - Reliable Event Driven Database Architecture"

# --------------------------------------------------
# 12 - Reliability and Distributed Messaging
# --------------------------------------------------

create_notes "12 - Reliability and Distributed Messaging" \
"00 - Message Loss and Duplicate Delivery" \
"01 - At Least Once Processing in Practice" \
"02 - Idempotency Keys" \
"03 - Deduplication Strategies" \
"04 - Ordering Across Partitions and Queues" \
"05 - Retry Strategies" \
"06 - Exponential Backoff" \
"07 - Retry Storms" \
"08 - Dead Letter Handling" \
"09 - Poison Messages" \
"10 - Message Expiration" \
"11 - Circuit Breaker Around External Dependencies" \
"12 - Backpressure and Load Shedding" \
"13 - Consumer Lag and Queue Depth" \
"14 - Graceful Shutdown" \
"15 - Broker Failure Recovery" \
"16 - Network Partitions" \
"17 - Disaster Recovery" \
"18 - Replay and Reprocessing" \
"19 - Message Schema Compatibility" \
"20 - Exactly Once Processing Limitations"

# --------------------------------------------------
# 13 - Messaging Security
# --------------------------------------------------

create_notes "13 - Messaging Security" \
"00 - Messaging Security Fundamentals" \
"01 - Authentication and Authorization" \
"02 - Kafka SASL Authentication" \
"03 - Kafka ACLs" \
"04 - Kafka TLS and SSL" \
"05 - RabbitMQ Users and Permissions" \
"06 - RabbitMQ Virtual Host Permissions" \
"07 - RabbitMQ TLS" \
"08 - Credential and Secret Management" \
"09 - Spring Boot Secret Configuration" \
"10 - Message Payload Encryption" \
"11 - Sensitive Data in Messages" \
"12 - Audit Logging" \
"13 - Broker Network Isolation" \
"14 - Production Security Checklist"

# --------------------------------------------------
# 14 - Deployment and Operations
# --------------------------------------------------

create_notes "14 - Deployment and Operations" \
"00 - Running Kafka Locally" \
"01 - Running RabbitMQ Locally" \
"02 - Docker Compose for Kafka and RabbitMQ" \
"03 - Kafka KRaft Deployment" \
"04 - Kafka Cluster Sizing" \
"05 - RabbitMQ Cluster Deployment" \
"06 - Persistent Volumes and Storage" \
"07 - Broker Resource Planning" \
"08 - Kafka Configuration Management" \
"09 - RabbitMQ Configuration Management" \
"10 - Environment Specific Spring Configuration" \
"11 - Health Checks and Readiness" \
"12 - Graceful Application Shutdown" \
"13 - Broker Upgrades and Compatibility" \
"14 - Backup and Recovery" \
"15 - Disaster Recovery Planning" \
"16 - Production Deployment Checklist"

# --------------------------------------------------
# 15 - Monitoring and Observability
# --------------------------------------------------

create_notes "15 - Monitoring and Observability" \
"00 - Messaging Observability Fundamentals" \
"01 - Kafka Metrics" \
"02 - Consumer Lag Monitoring" \
"03 - Broker Disk and Network Metrics" \
"04 - Kafka JMX Metrics" \
"05 - RabbitMQ Queue Metrics" \
"06 - RabbitMQ Connection and Channel Metrics" \
"07 - RabbitMQ Prometheus Plugin" \
"08 - Spring Boot Actuator Integration" \
"09 - Micrometer Metrics" \
"10 - Distributed Tracing" \
"11 - OpenTelemetry Messaging Instrumentation" \
"12 - Correlation IDs" \
"13 - Trace Context Propagation" \
"14 - Structured Logging" \
"15 - Alerting and SLOs" \
"16 - Troubleshooting Messaging Systems"

# --------------------------------------------------
# 16 - Performance and Capacity Planning
# --------------------------------------------------

create_notes "16 - Performance and Capacity Planning" \
"00 - Messaging Performance Fundamentals" \
"01 - Throughput and Latency" \
"02 - Message Size and Serialization Cost" \
"03 - Kafka Partition Count Planning" \
"04 - Kafka Producer Tuning" \
"05 - Kafka Consumer Tuning" \
"06 - RabbitMQ Prefetch Tuning" \
"07 - RabbitMQ Queue Throughput" \
"08 - Batching and Compression Tradeoffs" \
"09 - Network and Disk Bottlenecks" \
"10 - Consumer Parallelism" \
"11 - Broker Capacity Planning" \
"12 - Load Testing Messaging Systems" \
"13 - Benchmarking Kafka and RabbitMQ" \
"14 - Performance Troubleshooting"

# --------------------------------------------------
# 17 - Architecture and Broker Selection
# --------------------------------------------------

create_notes "17 - Architecture and Broker Selection" \
"00 - Kafka vs RabbitMQ" \
"01 - Kafka Event Streaming vs RabbitMQ Task Queues" \
"02 - Choosing Based on Message Lifecycle" \
"03 - Choosing Based on Ordering Requirements" \
"04 - Choosing Based on Throughput Requirements" \
"05 - Choosing Based on Routing Requirements" \
"06 - Choosing Based on Replay Requirements" \
"07 - Using Kafka and RabbitMQ Together" \
"08 - Event Driven Microservices Architecture" \
"09 - Command and Event Separation" \
"10 - Domain Events and Integration Events" \
"11 - Event Versioning" \
"12 - Event Contract Design" \
"13 - Anti Corruption Layer for Messaging" \
"14 - Avoiding Distributed Monoliths"

# --------------------------------------------------
# 18 - Production Projects
# --------------------------------------------------

create_notes "18 - Production Projects" \
"00 - Project 1: Order Processing with RabbitMQ" \
"01 - Project 2: Notification Service with RabbitMQ" \
"02 - Project 3: Inventory Events with Kafka" \
"03 - Project 4: Payment Event Pipeline" \
"04 - Project 5: PostgreSQL Transactional Outbox" \
"05 - Project 6: Debezium CDC Pipeline" \
"06 - Project 7: Idempotent Spring Boot Consumer" \
"07 - Project 8: Retry and Dead Letter Architecture" \
"08 - Project 9: Event Driven Microservices" \
"09 - Project 10: Kafka Event Replay System" \
"10 - Project 11: Monitoring Messaging Infrastructure" \
"11 - Project 12: Production Ready Messaging Platform" \
"12 - Production Readiness Review"

# --------------------------------------------------
# Summary
# --------------------------------------------------

echo
echo "======================================"
echo "Messaging curriculum generation done"
echo "Created: $created"
echo "Skipped: $skipped"
echo "======================================"
