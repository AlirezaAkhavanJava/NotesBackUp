#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CREATED=0
SKIPPED=0
FAILED=0

create_pack() {
  local pack="$1"
  shift

  local directory="$ROOT/$pack"

  mkdir -p -- "$directory"

  local index=0
  local note
  local filename
  local filepath

  echo
  echo "=========================================="
  echo "$pack"
  echo "=========================================="

  for note in "$@"; do

    # Make titles safe for Linux filenames.
    note="${note//\// - }"
    note="${note//:/ - }"
    note="${note//\\/-}"

    printf -v filename "%02d - %s.md" "$index" "$note"

    filepath="$directory/$filename"

    if [[ -e "$filepath" ]]; then
      echo "[SKIPPED] $filename"
      ((SKIPPED += 1))
    else
      if printf '%s\n' \
        '[[IntelliJ IDEA]]' \
        '[[Java]]' \
        '[[Spring Boot]]' \
        >"$filepath"; then

        echo "[CREATED] $filename"
        ((CREATED += 1))
      else
        echo "[FAILED] $filepath"
        ((FAILED += 1))
      fi
    fi

    ((index += 1))
  done
}

# ==================================================
# PACK 1 - INTELLIJ IDEA FUNDAMENTALS
# ==================================================

create_pack "Pack 1 - IntelliJ IDEA Fundamentals" \
  "What is IntelliJ IDEA Ultimate" \
  "IntelliJ IDEA Architecture" \
  "IntelliJ IDEA vs Community Edition" \
  "IntelliJ IDEA vs VS Code" \
  "IDE vs Text Editor" \
  "Understanding IDE Projects" \
  "Project Window" \
  "Editor Window" \
  "Navigation Bar" \
  "Tool Windows" \
  "Actions and Search Everywhere" \
  "Find Action" \
  "Command Search" \
  "Project Structure" \
  "Project SDK" \
  "Project Language Level" \
  "Module Structure" \
  "Content Roots and Source Roots" \
  "Resource Directories" \
  "Marking Directories" \
  "File Templates" \
  "Editor Tabs" \
  "Multiple Editors" \
  "Split Editor" \
  "Navigation Shortcuts" \
  "Recent Files" \
  "Recent Locations" \
  "Search Everywhere" \
  "Find in Files" \
  "Replace in Files" \
  "Structural Search and Replace" \
  "IntelliJ IDEA Settings and Preferences" \
  "IntelliJ IDEA Documentation"

# ==================================================
# PACK 2 - PROJECT AND BUILD MANAGEMENT
# ==================================================

create_pack "Pack 2 - Project and Build Management" \
  "Creating Java Projects" \
  "Creating Projects with Spring Initializr" \
  "Importing Existing Projects" \
  "Project SDK Configuration" \
  "Installing and Configuring JDKs" \
  "Multiple JDK Management" \
  "Project Language Level Configuration" \
  "Maven Project Integration" \
  "Maven Lifecycle Integration" \
  "Maven Goals and Run Configurations" \
  "Maven Dependency Management" \
  "Maven Dependency Analyzer" \
  "Maven Repository Configuration" \
  "Maven Local Repository Configuration" \
  "Maven Offline Mode" \
  "Maven Profiles" \
  "Maven Multi-Module Projects" \
  "Maven Wrapper" \
  "Maven Import and Synchronization" \
  "Maven Dependency Resolution Problems" \
  "Gradle Project Integration" \
  "Gradle Tasks and Run Configurations" \
  "Gradle Dependency Management" \
  "Gradle Wrapper" \
  "Gradle Sync and Refresh" \
  "Gradle Multi-Project Builds" \
  "Maven vs Gradle in IntelliJ" \
  "Build Tool Window" \
  "Build Output and Error Navigation" \
  "Compiler Configuration" \
  "Annotation Processing" \
  "Lombok Configuration" \
  "Build Cache and Incremental Compilation" \
  "Common Build Problems and Fixes"

# ==================================================
# PACK 3 - JAVA DEVELOPMENT
# ==================================================

create_pack "Pack 3 - Java Development" \
  "Java Development Environment" \
  "Java SDK Configuration in IntelliJ" \
  "Java Project Structure" \
  "Java Source Navigation" \
  "Java Code Completion" \
  "Smart Completion" \
  "Import Optimization" \
  "Code Formatting" \
  "Code Reformatting" \
  "Code Generation" \
  "Generate Constructors and Getters" \
  "Generate equals and hashCode" \
  "Generate toString" \
  "Java Refactoring" \
  "Rename Refactoring" \
  "Extract Method" \
  "Extract Variable" \
  "Extract Field" \
  "Extract Interface" \
  "Inline Refactoring" \
  "Change Signature" \
  "Move Refactoring" \
  "Safe Delete" \
  "Java Code Inspections" \
  "Inspection Severity Levels" \
  "Quick Fixes and Intentions" \
  "Suppressing Inspections" \
  "Unused Code Detection" \
  "Nullability Analysis" \
  "Java Stream Debugging" \
  "Java Records Support" \
  "Modern Java Language Features" \
  "Java 25 Support" \
  "Java Documentation and Javadocs" \
  "External Libraries Navigation" \
  "Java Code Style Configuration"

# ==================================================
# PACK 4 - SPRING BOOT DEVELOPMENT
# ==================================================

create_pack "Pack 4 - Spring Boot Development" \
  "Spring Boot Support in IntelliJ Ultimate" \
  "Spring Initializr Integration" \
  "Creating Spring Boot Applications" \
  "Spring Boot Project Navigation" \
  "Spring Tool Window" \
  "Spring Beans Navigation" \
  "Spring Bean Dependencies Visualization" \
  "Dependency Injection Navigation" \
  "Navigating Between Interfaces and Implementations" \
  "Spring Configuration Metadata" \
  "application.properties Support" \
  "application.yml Support" \
  "Spring Profiles" \
  "Spring Boot Run Configurations" \
  "Spring Boot Debug Configurations" \
  "Spring Boot Dashboard" \
  "Spring Boot Application Startup" \
  "Spring Boot Actuator Integration" \
  "Spring MVC Navigation" \
  "REST Controller Navigation" \
  "Request Mapping Navigation" \
  "DTO and Entity Navigation" \
  "Spring Data JPA Support" \
  "Spring Repository Navigation" \
  "Spring Security Navigation" \
  "Spring Configuration Properties" \
  "Spring Boot DevTools Integration" \
  "Spring Boot Hot Swap and Reload" \
  "Spring Boot Application Logs" \
  "Spring Boot Environment Variables" \
  "Spring Boot Profile Activation" \
  "Spring Boot Configuration Problems and Fixes" \
  "Spring Boot IDE Limitations"

# ==================================================
# PACK 5 - DATABASE AND SQL DEVELOPMENT
# ==================================================

create_pack "Pack 5 - Database and SQL Development" \
  "Database Tools in IntelliJ Ultimate" \
  "Database Tool Window" \
  "Creating Database Connections" \
  "PostgreSQL Connection Configuration" \
  "PostgreSQL JDBC Driver" \
  "Database Authentication" \
  "SSL Database Connections" \
  "Testing Database Connections" \
  "Database Schemas" \
  "Database Tables and Columns" \
  "Database Introspection" \
  "SQL Console" \
  "SQL Query Execution" \
  "SQL Code Completion" \
  "SQL Formatting" \
  "SQL Dialects" \
  "PostgreSQL SQL Dialect" \
  "SQL Execution Plans" \
  "EXPLAIN and EXPLAIN ANALYZE" \
  "Database Data Editor" \
  "Editing Database Records" \
  "Database Import and Export" \
  "Database Dumps and Restores" \
  "Database Diagrams" \
  "Database Navigation" \
  "PostgreSQL Transaction Management" \
  "SQL History" \
  "Database Connection Problems and Fixes" \
  "Database Tools vs External Database Clients"

# ==================================================
# PACK 6 - HIBERNATE AND JPA
# ==================================================

create_pack "Pack 6 - Hibernate and JPA" \
  "Hibernate Support in IntelliJ" \
  "JPA Support in IntelliJ" \
  "JPA Entity Navigation" \
  "Entity Relationship Navigation" \
  "Hibernate Configuration" \
  "Persistence Unit Configuration" \
  "Entity Mapping Inspection" \
  "JPQL Language Support" \
  "JPQL Query Console" \
  "Hibernate HQL Support" \
  "Named Queries" \
  "JPA Repository Navigation" \
  "Spring Data Derived Query Navigation" \
  "SQL and JPQL Comparison" \
  "Hibernate SQL Logging" \
  "Inspecting Generated SQL" \
  "N Plus One Query Investigation" \
  "Database Schema Validation" \
  "Flyway Integration" \
  "Liquibase Integration" \
  "JPA and Hibernate Troubleshooting"

# ==================================================
# PACK 7 - DEBUGGING AND TROUBLESHOOTING
# ==================================================

create_pack "Pack 7 - Debugging and Troubleshooting" \
  "Debugger Fundamentals" \
  "Starting Debug Sessions" \
  "Debug Tool Window" \
  "Line Breakpoints" \
  "Conditional Breakpoints" \
  "Exception Breakpoints" \
  "Method Breakpoints" \
  "Field Watchpoints" \
  "Inline Breakpoints" \
  "Stepping Over and Into" \
  "Step Out and Run to Cursor" \
  "Evaluate Expression" \
  "Watches" \
  "Variable Inspection" \
  "Object Inspection" \
  "Thread Inspection" \
  "Thread and Stack Frames" \
  "Async Stack Traces" \
  "Stream Debugging" \
  "HotSwap Classes" \
  "Remote JVM Debugging" \
  "Debugging Spring Boot Applications" \
  "Debugging Spring Security Filters" \
  "Debugging Hibernate Queries" \
  "Debugging Database Transactions" \
  "Debugging Maven and Gradle Tasks" \
  "Debugging Memory Problems" \
  "Debugging Deadlocks" \
  "Common Debugger Problems and Fixes"

# ==================================================
# PACK 8 - TESTING
# ==================================================

create_pack "Pack 8 - Testing" \
  "Testing Support in IntelliJ" \
  "JUnit 5 Integration" \
  "Creating Test Classes" \
  "Test Source Roots" \
  "Running Individual Tests" \
  "Running Test Classes" \
  "Running Test Packages" \
  "Run Configurations for Tests" \
  "JUnit Assertions" \
  "JUnit Parameterized Tests" \
  "JUnit Nested Tests" \
  "Mockito Integration" \
  "Mockito Test Navigation" \
  "Spring Boot Test Integration" \
  "Spring Boot Integration Tests" \
  "MockMvc Testing" \
  "Testcontainers Integration" \
  "Database Integration Testing" \
  "Test Profiles" \
  "Test Debugging" \
  "Code Coverage" \
  "Coverage Reports" \
  "Test Results Navigation" \
  "Test Execution Problems and Fixes"

# ==================================================
# PACK 9 - GIT AND VERSION CONTROL
# ==================================================

create_pack "Pack 9 - Git and Version Control" \
  "Version Control Integration" \
  "Configuring Git in IntelliJ" \
  "Git Root Configuration" \
  "Git Repository Integration" \
  "Git Tool Window" \
  "Commit Window" \
  "Local Changes" \
  "Git Diff Viewer" \
  "Git History" \
  "Git Log Navigation" \
  "Branch Management" \
  "Creating and Switching Branches" \
  "Merging Branches" \
  "Rebasing Branches" \
  "Interactive Rebase" \
  "Cherry Picking" \
  "Stashing Changes" \
  "Resolving Merge Conflicts" \
  "Git Blame" \
  "Annotate and Code History" \
  "GitHub Integration" \
  "Pull Requests" \
  "Commit Templates" \
  "Git Hooks" \
  "Git Problems and Fixes"

# ==================================================
# PACK 10 - FRONTEND AND RELATED LANGUAGES
# ==================================================

create_pack "Pack 10 - Frontend and Related Languages" \
  "JavaScript Support in IntelliJ" \
  "JavaScript Language Service" \
  "JavaScript Code Completion" \
  "JavaScript Refactoring" \
  "TypeScript Support" \
  "TypeScript Language Service" \
  "TypeScript Configuration" \
  "Node.js Integration" \
  "npm Integration" \
  "package.json Support" \
  "Vite Integration" \
  "Angular Integration" \
  "Angular CLI Integration" \
  "Angular Project Navigation" \
  "Angular Debugging" \
  "HTML Support" \
  "CSS and SCSS Support" \
  "Tailwind CSS Support" \
  "JSON Support" \
  "YAML Support" \
  "XML Support" \
  "REST Client and HTTP Requests" \
  "HTTP Client Environment Files" \
  "Testing REST APIs with HTTP Client" \
  "Spring Boot API Testing from IntelliJ" \
  "Frontend Backend Integration Debugging"

# ==================================================
# PACK 11 - DOCKER AND INFRASTRUCTURE
# ==================================================

create_pack "Pack 11 - Docker and Infrastructure" \
  "Docker Integration in IntelliJ" \
  "Docker Connection Configuration" \
  "Docker Tool Window" \
  "Dockerfile Support" \
  "Docker Compose Support" \
  "Container Management" \
  "Container Logs" \
  "Container Terminal" \
  "Docker Image Management" \
  "Docker Volumes" \
  "Docker Networks" \
  "Docker Compose Services" \
  "Running Spring Boot in Docker" \
  "Debugging Dockerized Java Applications" \
  "Docker and PostgreSQL Integration" \
  "Environment Variables in Containers" \
  "Remote Development" \
  "SSH Configuration" \
  "Remote JVM Debugging" \
  "Kubernetes Integration" \
  "Docker Integration Problems and Fixes"

# ==================================================
# PACK 12 - PERSONALIZATION AND PRODUCTIVITY
# ==================================================

create_pack "Pack 12 - Personalization and Productivity" \
  "IntelliJ Appearance Customization" \
  "Themes and Color Schemes" \
  "Editor Color Schemes" \
  "Font and Font Size" \
  "Ligatures" \
  "Editor Rendering Settings" \
  "Keymap Configuration" \
  "Custom Keyboard Shortcuts" \
  "Creating Personal Keymaps" \
  "Vim Emulation with IdeaVim" \
  "IdeaVim Configuration" \
  "IdeaVim and IntelliJ Keymap Conflicts" \
  "Personal Workflow Customization" \
  "Code Style Configuration" \
  "Java Code Style" \
  "XML and SQL Code Style" \
  "Live Templates" \
  "Custom Live Templates" \
  "Postfix Completion" \
  "File Templates" \
  "Custom File Templates" \
  "Custom Inspections" \
  "Inspection Profiles" \
  "Scopes and Favorites" \
  "Tool Window Customization" \
  "Plugin Management" \
  "Useful Plugins for Java Developers" \
  "Plugin Conflicts and Troubleshooting" \
  "Settings Sync" \
  "Exporting and Importing Settings" \
  "Personal IntelliJ Configuration Backup"

# ==================================================
# PACK 13 - ADVANCED INTELLIJ FEATURES
# ==================================================

create_pack "Pack 13 - Advanced IntelliJ Features" \
  "JVM Profiler Integration" \
  "CPU Profiling" \
  "Memory Profiling" \
  "Java Flight Recorder Integration" \
  "JFR Analysis" \
  "Heap Dump Analysis" \
  "Thread Dump Analysis" \
  "Memory Leak Investigation" \
  "Performance Profiling" \
  "Profiler Flame Graphs" \
  "Code With Me" \
  "HTTP Client Advanced Features" \
  "HTTP Client Scripts" \
  "Database Diagram Advanced Features" \
  "Structural Search" \
  "Structural Replace" \
  "Advanced Code Inspections" \
  "Dependency Analysis" \
  "Call Hierarchy" \
  "Type Hierarchy" \
  "Data Flow Analysis" \
  "Dependency Diagrams" \
  "Bytecode Viewer" \
  "Decompiling Java Classes" \
  "Terminal Integration" \
  "External Tools Configuration" \
  "Command Line Launcher" \
  "Headless IDE Operations"

# ==================================================
# PACK 14 - PROBLEMS, FIXES AND RECOVERY
# ==================================================

create_pack "Pack 14 - Problems, Fixes and Recovery" \
  "IntelliJ Troubleshooting Methodology" \
  "IDE Indexing Problems" \
  "Slow Indexing and Performance" \
  "Invalidating Caches" \
  "Safe Cache Recovery" \
  "IDE Startup Problems" \
  "IDE Crashes and Logs" \
  "IDE Memory Configuration" \
  "Increasing IDE Heap Size" \
  "Out of Memory Errors" \
  "IDE Freezing and Unresponsiveness" \
  "Java SDK Not Detected" \
  "Incorrect Project SDK" \
  "Incorrect Language Level" \
  "Maven Dependencies Not Resolving" \
  "Maven Import Failures" \
  "Gradle Sync Failures" \
  "Gradle Daemon Problems" \
  "Lombok Not Working" \
  "Annotation Processing Disabled" \
  "Spring Beans Not Detected" \
  "Spring Boot Run Configuration Problems" \
  "JPA Navigation Not Working" \
  "Database Connection Failures" \
  "PostgreSQL Driver Problems" \
  "Debugger Not Attaching" \
  "Breakpoints Not Working" \
  "Git Changes Not Detected" \
  "Git Credentials Problems" \
  "Plugin Conflicts" \
  "Corrupted Project Metadata" \
  "Corrupted IDE Configuration" \
  "Recovering Lost Changes" \
  "Safe Mode and Plugin Isolation" \
  "IDE Logs and Diagnostic Reports" \
  "When to Reimport a Project" \
  "When to Rebuild a Project" \
  "When to Reset IDE Configuration"

# ==================================================
# PACK 15 - DEBIAN 13 INTEGRATION
# ==================================================

create_pack "Pack 15 - Debian 13 Integration" \
  "Installing IntelliJ IDEA on Debian 13" \
  "IntelliJ Installation Methods" \
  "JetBrains Toolbox Integration" \
  "IntelliJ Installation Directories" \
  "Desktop Entry Integration" \
  "GNOME Integration" \
  "Application Launcher Configuration" \
  "JDK Installation on Debian 13" \
  "Multiple Java Versions on Debian" \
  "JAVA_HOME Configuration" \
  "PATH Configuration" \
  "Environment Variables" \
  "Maven Installation on Debian" \
  "Gradle Installation on Debian" \
  "Git Installation and Configuration" \
  "PostgreSQL Integration on Debian" \
  "Docker Integration on Debian" \
  "File Permissions and Ownership" \
  "Filesystem Performance" \
  "Working with Applications on HDD" \
  "IntelliJ System Directory Configuration" \
  "IntelliJ Configuration Directory" \
  "IntelliJ Plugin Directory" \
  "Moving IDE Data to Another Disk" \
  "Linux Clipboard Integration" \
  "GNOME Fonts and Rendering" \
  "HiDPI and Display Scaling" \
  "Linux Terminal Integration" \
  "Debian Application Troubleshooting" \
  "IntelliJ Backup and Recovery on Linux"

# ==================================================
# SUMMARY
# ==================================================

echo
echo "=============================================="
echo " INTELLIJ IDEA CURRICULUM COMPLETE"
echo "=============================================="
echo
echo "Created : $CREATED"
echo "Skipped : $SKIPPED"
echo "Failed  : $FAILED"
echo
echo "Packs   : 15"
echo "Files   : $(find "$ROOT" -type f -name '*.md' | wc -l)"
echo "Path    : $ROOT"
echo

if ((FAILED > 0)); then
  echo "WARNING: Some files could not be created."
  exit 1
fi

echo "All operations completed successfully."
