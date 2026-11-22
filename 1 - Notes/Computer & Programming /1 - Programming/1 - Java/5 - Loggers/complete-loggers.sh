
#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR="$(pwd)/Log4J2"

if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: Log4J2 directory not found."
    echo "Run this script from your 5 - Loggers directory."
    exit 1
fi

if [[ ! -f "$BASE_DIR/00 - Complete Mastery Roadmap.md" ]]; then
    echo "Error: Existing roadmap not found. Aborting."
    exit 1
fi

created=0
skipped=0

create_note() {
    local filename="$1"
    local destination="$BASE_DIR/$filename"

    if [[ -e "$destination" ]]; then
        echo "[SKIP] $filename"
        ((skipped+=1))
        return
    fi

    {
        echo "[[Logger]]"
        echo
    } > "$destination"

    echo "[CREATED] $filename"
    ((created+=1))
}

notes=(

# --------------------------------------------------
# 10. Java Logging Fundamentals
# --------------------------------------------------

"10 - Java Logging Architecture.md"
"11 - System.out and System.err.md"
"12 - java.util.logging (JUL).md"
"13 - Logging Facade vs Logging Implementation.md"
"14 - Logging API vs Logging Provider.md"
"15 - Logging Levels.md"
"16 - TRACE DEBUG INFO WARN ERROR FATAL.md"
"17 - Logging Hierarchy.md"
"18 - Logger Naming Conventions.md"
"19 - Logger Categories.md"
"20 - Logger Inheritance and Additivity.md"

# --------------------------------------------------
# 11. SLF4J
# --------------------------------------------------

"21 - SLF4J.md"
"22 - Why SLF4J Exists.md"
"23 - SLF4J Architecture.md"
"24 - LoggerFactory.md"
"25 - Logger Interface.md"
"26 - Parameterized Logging.md"
"27 - Logging Placeholders.md"
"28 - SLF4J Providers.md"
"29 - SLF4J Bindings and Provider Discovery.md"
"30 - SLF4J and Log4j2 Integration.md"
"31 - SLF4J and Spring Boot.md"
"32 - Logging Bridges and Adapters.md"
"33 - Log4j to SLF4J Bridge.md"
"34 - JUL to SLF4J Bridge.md"
"35 - Avoiding Multiple Logging Providers.md"

# --------------------------------------------------
# 12. Log4j2 Architecture
# --------------------------------------------------

"36 - Log4j2 Architecture.md"
"37 - Log4j2 Components.md"
"38 - LogManager.md"
"39 - LoggerContext.md"
"40 - Configuration Object.md"
"41 - LoggerConfig.md"
"42 - LogEvent.md"
"43 - Message Object.md"
"44 - Log4j2 Lifecycle.md"
"45 - Log4j2 Plugin System.md"
"46 - Log4j2 Plugin Discovery.md"
"47 - Log4j2 Configuration Factory.md"
"48 - Log4j2 Configuration Reloading.md"

# --------------------------------------------------
# 13. Log4j2 Configuration
# --------------------------------------------------

"49 - Log4j2 Configuration Files.md"
"50 - XML Configuration.md"
"51 - JSON Configuration.md"
"52 - YAML Configuration.md"
"53 - Properties Configuration.md"
"54 - Configuration Properties.md"
"55 - Configuration Status Logger.md"
"56 - Configuration Substitution.md"
"57 - Environment Variables in Logging Configuration.md"
"58 - System Properties in Logging Configuration.md"
"59 - Configuration Profiles and Environments.md"
"60 - Programmatic Configuration.md"
"61 - Configuration Validation and Troubleshooting.md"

# --------------------------------------------------
# 14. Appenders
# --------------------------------------------------

"62 - Appenders.md"
"63 - Console Appender.md"
"64 - File Appender.md"
"65 - Rolling File Appender.md"
"66 - Random Access File Appender.md"
"67 - Async Appender.md"
"68 - Routing Appender.md"
"69 - Failover Appender.md"
"70 - Rewrite Appender.md"
"71 - JDBC Appender.md"
"72 - Socket Appender.md"
"73 - HTTP Appender.md"
"74 - Appender References.md"
"75 - Appender Lifecycle.md"

# --------------------------------------------------
# 15. Layouts and Formatting
# --------------------------------------------------

"76 - Layouts.md"
"77 - Pattern Layout.md"
"78 - Pattern Conversion Specifiers.md"
"79 - JSON Template Layout.md"
"80 - JsonLayout.md"
"81 - Message Layouts.md"
"82 - Custom Layouts.md"
"83 - Timestamp Formatting.md"
"84 - Exception Formatting.md"
"85 - Stack Trace Formatting.md"
"86 - Log Message Formatting.md"

# --------------------------------------------------
# 16. Filters
# --------------------------------------------------

"87 - Filters.md"
"88 - Threshold Filter.md"
"89 - Level Range Filter.md"
"90 - Regex Filter.md"
"91 - Marker Filter.md"
"92 - Thread Context Map Filter.md"
"93 - Burst Filter.md"
"94 - Composite Filters.md"
"95 - Filter Evaluation Order.md"

# --------------------------------------------------
# 17. Rolling Policies and Retention
# --------------------------------------------------

"96 - Log File Rotation.md"
"97 - Time Based Triggering Policy.md"
"98 - Size Based Triggering Policy.md"
"99 - Cron Triggering Policy.md"
"100 - Composite Triggering Policy.md"
"101 - Default Rollover Strategy.md"
"102 - Fixed Window Rollover Strategy.md"
"103 - Direct Write Rollover Strategy.md"
"104 - Log File Retention.md"
"105 - Log Compression.md"
"106 - Archive Management.md"
"107 - Disk Space Management.md"

# --------------------------------------------------
# 18. Asynchronous Logging and Performance
# --------------------------------------------------

"108 - Synchronous vs Asynchronous Logging.md"
"109 - Async Appender vs Async Logger.md"
"110 - Async Logger.md"
"111 - Disruptor and Ring Buffer.md"
"112 - Log Event Queue.md"
"113 - Queue Full Policies.md"
"114 - Blocking vs Non Blocking Logging.md"
"115 - Garbage Free Logging.md"
"116 - Logging Performance.md"
"117 - Logging Overhead.md"
"118 - Benchmarking Logging Performance.md"
"119 - Log Backpressure.md"
"120 - Shutdown and Log Event Flushing.md"

# --------------------------------------------------
# 19. Thread Context and Correlation
# --------------------------------------------------

"121 - Thread Context.md"
"122 - Thread Context Map.md"
"123 - Thread Context Stack.md"
"124 - MDC (Mapped Diagnostic Context).md"
"125 - NDC (Nested Diagnostic Context).md"
"126 - Correlation IDs.md"
"127 - Request ID Logging.md"
"128 - Trace ID and Span ID.md"
"129 - Context Propagation.md"
"130 - Thread Pool Context Propagation.md"
"131 - Executor Service Context Propagation.md"
"132 - Context Cleanup and Memory Leaks.md"

# --------------------------------------------------
# 20. Spring Boot Logging Integration
# --------------------------------------------------

"133 - Spring Boot Logging Architecture.md"
"134 - Spring Boot LoggingSystem.md"
"135 - Spring Boot Logging Initialization.md"
"136 - Spring Boot Logging Dependencies.md"
"137 - Default Logback Configuration.md"
"138 - Replacing Logback with Log4j2.md"
"139 - Spring Boot Log4j2 Starter.md"
"140 - Excluding Default Logging Dependencies.md"
"141 - Spring Boot Logging Properties.md"
"142 - logging.level Property.md"
"143 - logging.file.name and logging.file.path.md"
"144 - logging.config Property.md"
"145 - Logging Profiles in Spring Boot.md"
"146 - Logging During Application Startup.md"
"147 - ApplicationContext and Logging.md"
"148 - Logging in Controllers.md"
"149 - Logging in Services.md"
"150 - Logging in Repositories.md"
"151 - Logging in Filters and Interceptors.md"
"152 - Logging Exceptions in Spring Boot.md"

# --------------------------------------------------
# 21. Web and Distributed Application Logging
# --------------------------------------------------

"153 - HTTP Request Logging.md"
"154 - HTTP Response Logging.md"
"155 - Servlet Filter Logging.md"
"156 - Spring MVC Interceptor Logging.md"
"157 - Request and Response Correlation.md"
"158 - Logging REST API Errors.md"
"159 - Distributed Logging.md"
"160 - Centralized Logging.md"
"161 - Log Aggregation.md"
"162 - Structured Logging.md"
"163 - JSON Logging in Spring Boot.md"
"164 - Microservices Log Correlation.md"
"165 - Logging Across Service Boundaries.md"

# --------------------------------------------------
# 22. Observability and Monitoring
# --------------------------------------------------

"166 - Observability Fundamentals.md"
"167 - Logs Metrics and Traces.md"
"168 - Distributed Tracing.md"
"169 - OpenTelemetry.md"
"170 - OpenTelemetry Java Instrumentation.md"
"171 - Spring Boot Actuator and Logging.md"
"172 - Micrometer and Logging Context.md"
"173 - Log Correlation with Traces.md"
"174 - Log Collection Pipelines.md"
"175 - Elasticsearch and Log Aggregation.md"
"176 - Grafana Loki.md"
"177 - Fluent Bit and Log Shipping.md"
"178 - Logstash.md"
"179 - Kibana.md"

# --------------------------------------------------
# 23. Security and Reliability
# --------------------------------------------------

"180 - Secure Logging.md"
"181 - Sensitive Data in Logs.md"
"182 - Password and Token Redaction.md"
"183 - PII Masking.md"
"184 - Log Injection.md"
"185 - CRLF Injection in Logs.md"
"186 - Log Forging.md"
"187 - Log File Permissions.md"
"188 - Audit Logging.md"
"189 - Tamper Resistant Logging.md"
"190 - Logging Failure Handling.md"
"191 - Disk Exhaustion and Logging.md"
"192 - Production Logging Best Practices.md"

# --------------------------------------------------
# 24. Testing and Troubleshooting
# --------------------------------------------------

"193 - Testing Log Output.md"
"194 - Capturing Logs in Unit Tests.md"
"195 - Log4j2 Test Dependencies.md"
"196 - Verifying Log Levels.md"
"197 - Testing Structured Log Output.md"
"198 - Troubleshooting Missing Log Messages.md"
"199 - Duplicate Log Messages.md"
"200 - Multiple Logging Implementations.md"
"201 - Classpath Logging Conflicts.md"
"202 - Log4j2 Configuration Errors.md"
"203 - Logging Dependency Conflicts.md"
"204 - Diagnosing Logging Performance Issues.md"

# --------------------------------------------------
# 25. Advanced Topics and Practical Applications
# --------------------------------------------------

"205 - Custom Log4j2 Plugins.md"
"206 - Custom Appenders.md"
"207 - Custom Filters.md"
"208 - Custom Message Implementations.md"
"209 - Custom Log Levels.md"
"210 - Markers and Marker Based Logging.md"
"211 - Logging in Multithreaded Applications.md"
"212 - Logging in Virtual Threads.md"
"213 - Logging in Asynchronous Workflows.md"
"214 - Logging in Scheduled Tasks.md"
"215 - Logging in Docker Containers.md"
"216 - Logging in Kubernetes.md"
"217 - Container Log Management.md"
"218 - Production Logging Architecture.md"
"219 - Designing a Logging Strategy.md"
"220 - Logging Architecture for Spring Boot Projects.md"

)

echo
echo "Starting Logger curriculum completion..."
echo "Target: $BASE_DIR"
echo

for note in "${notes[@]}"; do
    create_note "$note"
done

echo
echo "========================================"
echo "Logger curriculum completion finished."
echo "Created: $created"
echo "Skipped: $skipped"
echo "========================================"
