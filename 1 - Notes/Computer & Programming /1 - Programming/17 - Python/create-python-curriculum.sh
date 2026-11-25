
#!/usr/bin/env bash
set -euo pipefail

# Python Obsidian Curriculum
# Run from: 17 - Python
#
# Features:
# - Creates all curriculum folders
# - Continues numbering from existing notes
# - Never overwrites existing Markdown files
# - Sanitizes filename characters
# - Every new note contains [[Python]]
# - Safe with Bash set -e

ROOT="."

add_notes() {
    local folder="$1"
    shift

    mkdir -p "$folder"

    local max_number=-1
    local next
    local file
    local filename
    local title
    local safe_title
    local number
    local created=0
    local skipped=0

    # Find the highest existing numbered Markdown note.
    for file in "$folder"/*.md; do
        [[ -e "$file" ]] || continue

        filename="${file##*/}"

        if [[ "$filename" =~ ^([0-9]+)\ -\ .*\.md$ ]]; then
            number=$((10#${BASH_REMATCH[1]}))

            if (( number > max_number )); then
                max_number="$number"
            fi
        fi
    done

    next=$((max_number + 1))

    for title in "$@"; do
        # Replace filename-unsafe characters.
        safe_title="${title//\// - }"
        safe_title="${safe_title//:/ - }"
        safe_title="${safe_title//\?}"

        printf -v filename "%02d - %s.md" "$next" "$safe_title"

        if [[ -e "$folder/$filename" ]]; then
            printf 'SKIP: %s\n' "$folder/$filename"
            skipped=$((skipped + 1))
        else
            printf '[[Python]]\n' > "$folder/$filename"
            printf 'CREATED: %s\n' "$folder/$filename"
            created=$((created + 1))
        fi

        next=$((next + 1))
    done

    printf '\nFolder: %s\nCreated: %d | Skipped: %d\n\n' \
        "$folder" "$created" "$skipped"
}

# ============================================================
# 00 - Python Fundamentals
# ============================================================

add_notes "$ROOT/00 - Python Fundamentals" \
    "What Is Python" \
    "Python Installation on Debian" \
    "Python Interpreter and Execution" \
    "Python Syntax and Indentation" \
    "Variables and Naming" \
    "Primitive and Built-in Types" \
    "Numbers and Numeric Operations" \
    "Strings and String Methods" \
    "String Formatting and f-Strings" \
    "Boolean Values and Truthiness" \
    "None and NoneType" \
    "Type Conversion" \
    "Operators and Operator Precedence" \
    "Conditional Statements" \
    "Loops: for and while" \
    "break, continue, and pass" \
    "Range and Enumerate" \
    "Lists" \
    "Tuples" \
    "Sets" \
    "Dictionaries" \
    "List Comprehensions" \
    "Dictionary and Set Comprehensions" \
    "Functions and Parameters" \
    "Positional and Keyword Arguments" \
    "Default Arguments" \
    "Variable-Length Arguments: args and kwargs" \
    "Scope and LEGB Rule" \
    "Lambda Functions" \
    "Recursion" \
    "Modules and Imports" \
    "Packages and init.py" \
    "Python Standard Library" \
    "Virtual Environments with venv" \
    "pip and Dependency Management" \
    "requirements.txt" \
    "pyproject.toml" \
    "Python Type Hints" \
    "mypy and Static Type Checking" \
    "Docstrings and Documentation" \
    "PEP 8 and Python Style" \
    "Python Errors and Tracebacks"

# ============================================================
# 01 - Python OOP and Advanced Language
# ============================================================

add_notes "$ROOT/01 - Python OOP and Advanced Language" \
    "Classes and Objects" \
    "Instance Attributes and Methods" \
    "Class Attributes and Methods" \
    "Static Methods" \
    "Constructors and init" \
    "Inheritance" \
    "Multiple Inheritance" \
    "Method Resolution Order and MRO" \
    "super() Internals" \
    "Encapsulation and Properties" \
    "Polymorphism and Duck Typing" \
    "Abstract Base Classes" \
    "Protocols and Structural Typing" \
    "Dataclasses" \
    "Enums" \
    "Special Methods and Dunder Methods" \
    "str and repr" \
    "Equality and Hashing" \
    "Iterators and Iterables" \
    "Generators and yield" \
    "Generator Expressions" \
    "Decorators" \
    "Decorator Arguments" \
    "Closures" \
    "Context Managers" \
    "with Statement and enter exit" \
    "Exception Handling" \
    "Custom Exceptions" \
    "Exception Chaining" \
    "File Handling" \
    "Pathlib" \
    "JSON Serialization" \
    "Pickle and Serialization Risks" \
    "Regular Expressions" \
    "Functional Programming in Python" \
    "map, filter, and reduce" \
    "functools and itertools" \
    "Descriptors" \
    "Metaclasses" \
    "Python Object Model" \
    "Garbage Collection and Reference Counting" \
    "Memory Management in Python" \
    "Python Concurrency Model" \
    "Threading" \
    "Multiprocessing" \
    "Global Interpreter Lock" \
    "Async and Await" \
    "asyncio Fundamentals" \
    "Async Context Managers" \
    "Async Iterators and Generators"

# ============================================================
# 02 - Python Scripting
# ============================================================

add_notes "$ROOT/02 - Python Scripting" \
    "Python Scripting Overview" \
    "Writing Executable Python Scripts" \
    "Shebang and Script Permissions" \
    "Command-Line Arguments with argparse" \
    "Command-Line Interfaces with click" \
    "Environment Variables with os.environ" \
    "Working with Files and Directories" \
    "Automating File Organization" \
    "Bulk File Renaming" \
    "Searching Files with pathlib" \
    "Reading and Writing CSV Files" \
    "Working with JSON Files" \
    "YAML Configuration Files" \
    "Configuration with dotenv" \
    "Subprocess and External Commands" \
    "Running Linux Commands from Python" \
    "Capturing stdout and stderr" \
    "Process Exit Codes" \
    "Automating APT and System Tasks" \
    "Linux Log File Analysis" \
    "Disk and System Monitoring Scripts" \
    "Scheduling Python Scripts with cron" \
    "Systemd Services for Python Scripts" \
    "Python Script Logging" \
    "Rotating Log Files" \
    "Retries and Backoff" \
    "Script Configuration and Secrets" \
    "Building Reusable CLI Tools" \
    "Packaging Python Scripts" \
    "Testing Automation Scripts" \
    "Python Automation Project: Backup Tool" \
    "Python Automation Project: Log Analyzer" \
    "Python Automation Project: System Report"

# ============================================================
# 03 - Black Hat Python
# ============================================================

add_notes "$ROOT/03 - Black Hat Python" \
    "Black Hat Python Overview" \
    "Ethical Hacking and Legal Boundaries" \
    "Building an Isolated Security Lab" \
    "Python for Security Research" \
    "Network Socket Fundamentals" \
    "TCP Client and Server" \
    "UDP Client and Server" \
    "Socket Programming Patterns" \
    "Network Connection Diagnostics" \
    "Banner Grabbing in an Authorized Lab" \
    "Building a Simple Port Checker" \
    "DNS Queries with Python" \
    "HTTP Requests for Security Testing" \
    "HTTP Headers and Security Analysis" \
    "Working with TLS Certificates" \
    "Packet Capture Fundamentals" \
    "Packet Analysis with Scapy" \
    "ARP and Ethernet Fundamentals" \
    "Analyzing Network Traffic" \
    "SSH Automation with Paramiko" \
    "Secure Remote Administration" \
    "Parsing PCAP Files" \
    "Analyzing Suspicious Network Connections" \
    "Python for Log-Based Threat Detection" \
    "File Hashing and Integrity Checks" \
    "YARA Rules and Python Integration" \
    "Safe Malware Analysis Fundamentals" \
    "Static Analysis of Suspicious Files" \
    "Extracting Indicators of Compromise" \
    "Building a Defensive Network Monitor" \
    "Security Tool Error Handling" \
    "Security Tool Logging and Reporting"

# ============================================================
# 04 - Python Networking
# ============================================================

add_notes "$ROOT/04 - Python Networking" \
    "Computer Networking Fundamentals" \
    "OSI and TCP IP Models" \
    "Ethernet and MAC Addresses" \
    "IP Addressing and Subnets" \
    "IPv4 and IPv6" \
    "TCP and UDP" \
    "Ports and Sockets" \
    "DNS Resolution" \
    "DHCP Fundamentals" \
    "HTTP and HTTPS" \
    "TLS Handshake Fundamentals" \
    "Routing and Gateways" \
    "Firewalls and NAT" \
    "Network Latency and Timeouts" \
    "Python socket Module" \
    "TCP Socket Programming" \
    "UDP Socket Programming" \
    "Client Server Architecture" \
    "Concurrent Network Servers" \
    "Network Programming with Threading" \
    "Network Programming with asyncio" \
    "Asyncio Streams" \
    "HTTP Clients with requests" \
    "HTTP Clients with httpx" \
    "Building HTTP Clients" \
    "WebSockets with Python" \
    "REST API Clients" \
    "Retrying Failed Network Requests" \
    "Connection Pooling" \
    "Network Data Serialization" \
    "Network Programming Error Handling" \
    "Building a TCP Echo Server" \
    "Building a DNS Lookup Tool" \
    "Building a Network Health Checker" \
    "Building a REST API Monitoring Script"

# ============================================================
# 05 - Python Web and Backend
# ============================================================

add_notes "$ROOT/05 - Python Web and Backend" \
    "Python Backend Development Overview" \
    "Choosing a Python Backend Framework" \
    "WSGI and ASGI" \
    "FastAPI Fundamentals" \
    "Flask Fundamentals" \
    "Django Fundamentals" \
    "Django REST Framework" \
    "Routing and Request Handling" \
    "Request and Response Models" \
    "Pydantic Validation" \
    "Dependency Injection in FastAPI" \
    "Middleware in Python Web Frameworks" \
    "Exception Handling in FastAPI" \
    "Exception Handling in Django" \
    "Authentication and Authorization" \
    "Password Hashing and Storage" \
    "JWT Authentication in Python" \
    "OAuth2 Fundamentals" \
    "Role-Based Access Control" \
    "API Documentation with OpenAPI" \
    "REST API Design in Python" \
    "API Versioning" \
    "Pagination, Filtering, and Sorting" \
    "File Uploads and Downloads" \
    "Background Tasks" \
    "Task Queues and Worker Processes" \
    "WebSockets in Python" \
    "Server-Sent Events" \
    "Application Configuration" \
    "Environment Variables and Secrets" \
    "Backend Testing with pytest" \
    "Testing Python APIs" \
    "Integration Testing" \
    "Mocking External Services" \
    "Backend Project Structure" \
    "Service Layer and Repository Pattern" \
    "Separation of Concerns in Python Backend" \
    "Clean Architecture in Python" \
    "Modular Monoliths in Python" \
    "Microservices with Python" \
    "Python Backend Project: Task Management API"

# ============================================================
# 06 - Python Databases and Persistence
# ============================================================

add_notes "$ROOT/06 - Python Databases and Persistence" \
    "Database Fundamentals for Python Backend" \
    "PostgreSQL with Python" \
    "psycopg and PostgreSQL Connections" \
    "SQLAlchemy Fundamentals" \
    "SQLAlchemy ORM and Core" \
    "SQLAlchemy Models" \
    "SQLAlchemy Relationships" \
    "SQLAlchemy Session Lifecycle" \
    "Transactions and Unit of Work" \
    "Repository Pattern with SQLAlchemy" \
    "Database Connection Pooling" \
    "Database Transactions and Isolation" \
    "Handling Database Exceptions" \
    "Preventing SQL Injection" \
    "Parameterized Queries" \
    "Alembic Database Migrations" \
    "Schema Migration Workflows" \
    "Database Indexes and Query Performance" \
    "EXPLAIN and Query Analysis" \
    "N+1 Query Problem" \
    "Lazy Loading and Eager Loading" \
    "Optimizing ORM Queries" \
    "Redis Fundamentals" \
    "Caching with Redis" \
    "Cache Invalidation Strategies" \
    "Database-backed Sessions" \
    "MongoDB with Python" \
    "Relational vs Document Databases" \
    "Data Access Layer Testing" \
    "PostgreSQL Integration Testing"

# ============================================================
# 07 - Python Backend Production and Deployment
# ============================================================

add_notes "$ROOT/07 - Python Backend Production and Deployment" \
    "Production Python Backend Architecture" \
    "Linux Deployment for Python APIs" \
    "Dockerizing a Python Backend" \
    "Docker Compose for Backend Development" \
    "Environment-Specific Configuration" \
    "Running FastAPI with Uvicorn" \
    "Running Django with Gunicorn" \
    "Reverse Proxy with Nginx" \
    "HTTPS and TLS Deployment" \
    "Process Management with systemd" \
    "Database Deployment and Backups" \
    "Database Connection Limits" \
    "Health Checks and Readiness Checks" \
    "Structured Logging in Python" \
    "Logging Request IDs" \
    "Metrics and Prometheus" \
    "Distributed Tracing Fundamentals" \
    "OpenTelemetry in Python" \
    "Monitoring Python Applications" \
    "Application Performance Profiling" \
    "Memory Profiling" \
    "Async Performance and Bottlenecks" \
    "Workers and Horizontal Scaling" \
    "Load Balancing" \
    "Graceful Shutdown" \
    "Configuration and Secret Management" \
    "Dependency and Vulnerability Scanning" \
    "CI CD for Python Backend Projects" \
    "Deploying Python APIs" \
    "Production Incident Debugging" \
    "Python Backend Project: Production REST API"

# ============================================================
# 08 - Python and Spring Boot
# ============================================================

add_notes "$ROOT/08 - Python and Spring Boot" \
    "Python and Spring Boot: When to Use Both" \
    "Python as a Separate Microservice" \
    "Spring Boot Calling a Python REST API" \
    "Python Calling a Spring Boot REST API" \
    "HTTP Communication Between Java and Python" \
    "API Contracts Between Java and Python" \
    "JSON Compatibility Between Jackson and Python" \
    "DTOs and Pydantic Models Across Services" \
    "Validation Across Java and Python APIs" \
    "Error Response Contracts Between Services" \
    "Authentication Between Spring Boot and Python" \
    "Service-to-Service JWT Authentication" \
    "Python Scripts Invoked by Spring Boot" \
    "Running Python with ProcessBuilder" \
    "Managing Python Processes from Java" \
    "Timeouts and Exit Codes in ProcessBuilder" \
    "When Not to Use ProcessBuilder for Python" \
    "Python Batch Jobs for Spring Boot Systems" \
    "Python Data Processing with Spring Boot" \
    "Python for Reports and Data Exports" \
    "Python and PostgreSQL Integration" \
    "Sharing a PostgreSQL Database Between Services" \
    "Database Ownership in Microservices" \
    "Python and Spring Boot with Redis" \
    "Python and Spring Boot with Kafka" \
    "Java and Python Event-Driven Architecture" \
    "Spring Boot and Python with Docker Compose" \
    "Deploying Java and Python Services" \
    "Observability Across Java and Python" \
    "Logging and Correlation IDs Across Services" \
    "Integration Testing Java and Python Services" \
    "A Spring Boot API with a Python Worker"

# ============================================================
# 09 - Python Projects and Engineering Practices
# ============================================================

add_notes "$ROOT/09 - Python Projects and Engineering Practices" \
    "Python Project Structure and Conventions" \
    "Application Entry Points" \
    "Configuration Management Patterns" \
    "Dependency Injection Patterns" \
    "Design Patterns in Python" \
    "SOLID Principles in Python" \
    "Code Quality with Ruff" \
    "Formatting with Black" \
    "Import Sorting with isort" \
    "Pre-commit Hooks" \
    "Testing with pytest" \
    "Unit Tests and Integration Tests" \
    "Test Coverage with coverage.py" \
    "Continuous Integration for Python" \
    "Building and Publishing Python Packages" \
    "Semantic Versioning for Python Packages" \
    "Python Project Documentation" \
    "Python Project: CLI Application" \
    "Python Project: Network Monitoring Service" \
    "Python Project: FastAPI and PostgreSQL Backend" \
    "Python Project: Django REST API" \
    "Python Project: Async Job Worker" \
    "Python Project: Security Log Analyzer"

# ============================================================
# Final summary
# ============================================================

printf '\n========================================\n'
printf 'Python curriculum generation completed.\n'
printf 'Existing notes were not overwritten.\n'
printf 'New notes contain [[Python]].\n'
printf '========================================\n'
