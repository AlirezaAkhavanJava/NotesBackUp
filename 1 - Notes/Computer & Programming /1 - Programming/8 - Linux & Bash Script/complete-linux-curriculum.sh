
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
    local next_index

    for file in "$dir"/*.md; do
        [[ -f "$file" ]] || continue
        filename="${file##*/}"

        if [[ "$filename" =~ ^([0-9]+)[[:space:]]*-[[:space:]] ]]; then
            prefix="${BASH_REMATCH[1]}"
            (( 10#$prefix > max_index )) && max_index=$((10#$prefix))
        fi
    done

    next_index=$((max_index + 1))

    if [[ ! -d "$dir" ]]; then
        echo "[DIR] $folder"
        [[ "$DRY_RUN" == true ]] || mkdir -p -- "$dir"
    fi

    for concept in "$@"; do
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
            echo "[SKIP] $folder/$concept"
            ((SKIPPED += 1))
            continue
        fi

        printf -v index "%02d" "$next_index"

        local target="$dir/$index - $concept.md"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[PREVIEW] $folder/$index - $concept.md"
        else
            printf '%s\n' '[[Linux]]' > "$target"
            echo "[CREATED] $folder/$index - $concept.md"
        fi

        ((CREATED += 1))
        ((next_index += 1))
    done
}

echo "========================================"
echo " LINUX AND BASH CURRICULUM GENERATOR"
echo "========================================"

# ==================================================
# PACK 1 - BASIC LINUX COMMANDS
# ==================================================

add_notes "Pack 1 (Basic Linux Commands)" \
    "pwd command" \
    "mkdir command" \
    "rmdir command" \
    "file command" \
    "stat command" \
    "readlink command" \
    "realpath command" \
    "basename command" \
    "dirname command" \
    "du command" \
    "df command" \
    "tree command" \
    "file globbing" \
    "Wildcards" \
    "Brace Expansion" \
    "Command Substitution" \
    "Quoting and Escaping" \
    "Command Chaining" \
    "Logical Operators in Shell" \
    "sort command" \
    "uniq command" \
    "cut command" \
    "paste command" \
    "tr command" \
    "sed command" \
    "awk command" \
    "xargs command" \
    "which command" \
    "type command" \
    "whereis command" \
    "command command" \
    "printf command" \
    "date command" \
    "cal command" \
    "seq command" \
    "basename and dirname" \
    "diff and cmp" \
    "patch command" \
    "tar command" \
    "gzip and gunzip" \
    "bzip2 and xz" \
    "zip and unzip" \
    "file compression formats" \
    "sha256sum command" \
    "md5sum command" \
    "tee command advanced usage" \
    "watch command" \
    "timeout command" \
    "yes command" \
    "xclip and clipboard utilities" \
    "reset command" \
    "clear command" \
    "stty command" \
    "tput command" \
    "printf formatting"

# ==================================================
# PACK 2 - BASH SCRIPT
# ==================================================

add_notes "Pack 2 (Bash Script)/00 - Bash Fundamentals" \
    "What Is Bash" \
    "Bash vs Shell" \
    "Bash Architecture" \
    "Bash Execution Modes" \
    "Interactive and Non Interactive Shells" \
    "Login and Non Login Shells" \
    "Bash Startup Files" \
    "Bash Configuration Files" \
    "Bash Script Structure" \
    "Shebang in Bash" \
    "Script Execution" \
    "Executable Permissions for Scripts" \
    "Running Bash Scripts" \
    "Bash Comments" \
    "Bash Syntax Rules"

add_notes "Pack 2 (Bash Script)/01 - Variables and Data Types" \
    "Variable Declaration" \
    "Variable Assignment" \
    "Variable Expansion" \
    "Environment Variables" \
    "Local Variables" \
    "Exported Variables" \
    "Readonly Variables" \
    "Unset Variables" \
    "Variable Scope" \
    "Special Shell Variables" \
    "Bash Data Types" \
    "Integer Variables" \
    "String Variables" \
    "Variable Defaults" \
    "Parameter Expansion" \
    "Indirect Expansion" \
    "Declare and Typeset"

add_notes "Pack 2 (Bash Script)/02 - Input and Output" \
    "Reading User Input" \
    "read builtin" \
    "printf builtin" \
    "echo builtin" \
    "Standard Input in Bash" \
    "Standard Output in Bash" \
    "Standard Error in Bash" \
    "File Descriptors" \
    "Input Redirection" \
    "Output Redirection" \
    "Append Redirection" \
    "Here Documents" \
    "Here Strings" \
    "Process Substitution" \
    "Redirection Order" \
    "Pipelines in Bash" \
    "Named Pipes in Bash"

add_notes "Pack 2 (Bash Script)/03 - Operators and Expressions" \
    "Arithmetic Expansion" \
    "Arithmetic Evaluation" \
    "Arithmetic Operators" \
    "Comparison Operators" \
    "String Comparison" \
    "File Test Operators" \
    "Logical Operators" \
    "Bitwise Operators" \
    "Conditional Expressions" \
    "The test Command" \
    "The Double Bracket Expression" \
    "The Double Parentheses Expression" \
    "Pattern Matching" \
    "Regular Expressions in Bash"

add_notes "Pack 2 (Bash Script)/04 - Conditional Statements" \
    "if Statement" \
    "if else Statement" \
    "if elif else Statement" \
    "Nested Conditions" \
    "case Statement" \
    "select Statement" \
    "Conditional Command Execution" \
    "Short Circuit Evaluation" \
    "Pattern Matching in case"

add_notes "Pack 2 (Bash Script)/05 - Loops and Iteration" \
    "for Loop" \
    "C Style for Loop" \
    "while Loop" \
    "until Loop" \
    "select Loop" \
    "Nested Loops" \
    "break Statement" \
    "continue Statement" \
    "Loop Control" \
    "Iterating Over Files" \
    "Iterating Over Command Output" \
    "Looping Over Arrays" \
    "Infinite Loops"

add_notes "Pack 2 (Bash Script)/06 - Functions" \
    "Bash Functions" \
    "Function Declaration" \
    "Function Arguments" \
    "Function Return Status" \
    "Returning Values from Functions" \
    "Local Variables in Functions" \
    "Global Variables in Functions" \
    "Function Scope" \
    "Recursive Functions" \
    "Function Libraries" \
    "Sourcing External Scripts" \
    "Function Traps"

add_notes "Pack 2 (Bash Script)/07 - Arrays and Strings" \
    "Indexed Arrays" \
    "Associative Arrays" \
    "Array Declaration" \
    "Array Initialization" \
    "Array Access" \
    "Array Iteration" \
    "Array Length" \
    "Array Slicing" \
    "Array Expansion" \
    "Array Operations" \
    "String Manipulation" \
    "String Length" \
    "String Replacement" \
    "Substring Extraction" \
    "String Splitting" \
    "IFS Variable"

add_notes "Pack 2 (Bash Script)/08 - File and Text Processing" \
    "Reading Files Line by Line" \
    "Writing Files from Bash" \
    "Appending to Files" \
    "Checking File Existence" \
    "Checking File Types" \
    "Checking File Permissions" \
    "Temporary Files" \
    "mktemp command" \
    "Text Processing with grep" \
    "Text Processing with sed" \
    "Text Processing with awk" \
    "Parsing Configuration Files" \
    "CSV Processing in Bash" \
    "JSON Processing with jq" \
    "Safe File Handling"

add_notes "Pack 2 (Bash Script)/09 - Processes and Signals" \
    "Background Jobs" \
    "Foreground Jobs" \
    "Job Control" \
    "Process IDs in Bash" \
    "Subshells" \
    "Command Execution" \
    "wait builtin" \
    "jobs builtin" \
    "Process Substitution" \
    "Signals in Bash" \
    "trap builtin" \
    "Signal Handling" \
    "Process Cleanup" \
    "Parallel Execution" \
    "Background Process Management"

add_notes "Pack 2 (Bash Script)/10 - Error Handling and Debugging" \
    "Exit Status in Bash" \
    "exit builtin" \
    "return builtin" \
    "set builtin" \
    "set -e Behavior" \
    "set -u Behavior" \
    "set -o pipefail" \
    "Strict Mode in Bash" \
    "Error Handling Strategies" \
    "Bash Debugging" \
    "bash -x" \
    "bash -n" \
    "trap ERR" \
    "Error Messages" \
    "Input Validation" \
    "Defensive Bash Programming"

add_notes "Pack 2 (Bash Script)/11 - Advanced Bash" \
    "Bash Parameter Expansion Advanced" \
    "Bash Process Model" \
    "Subshell vs Current Shell" \
    "Command Grouping" \
    "Brace Groups" \
    "Subshell Groups" \
    "Bash Builtins" \
    "Shell Options" \
    "shopt" \
    "Bash Completion" \
    "Programmable Completion" \
    "Dynamic Command Generation" \
    "Bash Traps Advanced" \
    "Bash Portability" \
    "POSIX Shell Compatibility" \
    "ShellCheck" \
    "Bash Best Practices"

add_notes "Pack 2 (Bash Script)/12 - Practical Automation" \
    "Backup Automation Script" \
    "Log Rotation Script" \
    "System Health Check Script" \
    "Disk Usage Monitoring Script" \
    "User Management Script" \
    "Automated Package Update Script" \
    "Service Monitoring Script" \
    "Database Backup Script" \
    "PostgreSQL Backup with Bash" \
    "Scheduled Jobs with Cron" \
    "Bash Automation with systemd Timers" \
    "Script Configuration Management" \
    "Reusable Bash Libraries" \
    "Command Line Argument Parsing" \
    "getopts" \
    "Long Options with getopt" \
    "Building a CLI Tool in Bash" \
    "Production Bash Script Design"

# ==================================================
# PACK 3 - LINUX ARCHITECTURE AND INTERNALS
# ==================================================

add_notes "Pack 3 (Linux Architecture and Internals)" \
    "Linux Architecture Overview" \
    "Linux Kernel Architecture" \
    "Kernel Space and User Space" \
    "Linux System Calls" \
    "System Call Interface" \
    "Linux Kernel Modules" \
    "Loadable Kernel Modules" \
    "Kernel Module Management" \
    "Linux Device Drivers" \
    "Character Devices" \
    "Block Devices" \
    "Device Files" \
    "udev and Device Management" \
    "Virtual Filesystems" \
    "proc Filesystem" \
    "sysfs Filesystem" \
    "devtmpfs Filesystem" \
    "Linux Boot Architecture" \
    "Linux ABI" \
    "glibc and System Libraries" \
    "Dynamic Linking" \
    "Static Linking" \
    "ELF Binary Format" \
    "Linux Hardware Discovery"

# ==================================================
# PACK 4 - FILESYSTEMS AND STORAGE
# ==================================================

add_notes "Pack 4 (Linux Filesystems and Storage)" \
    "Linux Filesystem Hierarchy Standard" \
    "Filesystem Types" \
    "ext4 Filesystem" \
    "XFS Filesystem" \
    "Btrfs Filesystem" \
    "Filesystem Mounting" \
    "mount and umount" \
    "fstab Configuration" \
    "UUID and Filesystem Labels" \
    "Filesystem Metadata" \
    "Inodes in Linux" \
    "Superblocks" \
    "Filesystem Journaling" \
    "Filesystem Permissions" \
    "Extended Attributes" \
    "Access Control Lists" \
    "Disk Partitions" \
    "MBR and GPT" \
    "Partitioning with fdisk" \
    "Partitioning with parted" \
    "lsblk and blkid" \
    "LVM Fundamentals" \
    "Physical Volumes" \
    "Volume Groups" \
    "Logical Volumes" \
    "LVM Snapshots" \
    "Swap Space" \
    "Disk Quotas" \
    "Disk Health and SMART" \
    "Disk Recovery Fundamentals" \
    "Filesystem Repair with fsck" \
    "Linux Storage Performance"

# ==================================================
# PACK 5 - PROCESSES AND RESOURCE MANAGEMENT
# ==================================================

add_notes "Pack 5 (Linux Processes and Resource Management)" \
    "Linux Process Architecture" \
    "Process States" \
    "Process Creation" \
    "fork and exec" \
    "Process Termination" \
    "Process Scheduling" \
    "Linux Scheduler" \
    "CPU Scheduling Classes" \
    "Process Priorities" \
    "nice and renice" \
    "CPU Affinity" \
    "Signals and Signal Handling" \
    "Linux Threads" \
    "Kernel Threads" \
    "Lightweight Processes" \
    "Process Groups and Sessions" \
    "Orphan Processes" \
    "Zombie Processes" \
    "Memory Management in Linux" \
    "Virtual Memory in Linux" \
    "Page Tables" \
    "Page Cache" \
    "Memory Pressure" \
    "OOM Killer" \
    "Linux Memory Overcommit" \
    "Resource Limits with ulimit" \
    "PAM Limits" \
    "cgroups Fundamentals" \
    "Linux Control Groups v2" \
    "CPU Resource Control" \
    "Memory Resource Control" \
    "IO Resource Control"

# ==================================================
# PACK 6 - USERS AND SECURITY
# ==================================================

add_notes "Pack 6 (Linux Users and Security)" \
    "Linux User Management" \
    "Linux Groups" \
    "Primary and Supplementary Groups" \
    "UID and GID" \
    "Root User" \
    "Superuser Privileges" \
    "sudo Architecture" \
    "sudoers Configuration" \
    "PAM Architecture" \
    "User Authentication" \
    "Password Management" \
    "passwd and shadow Files" \
    "Linux Permission Model" \
    "Special Permission Bits" \
    "SUID" \
    "SGID" \
    "Sticky Bit" \
    "Linux ACL" \
    "Linux Capabilities" \
    "Linux Security Modules" \
    "AppArmor" \
    "SELinux Fundamentals" \
    "Linux Firewall Fundamentals" \
    "nftables" \
    "iptables" \
    "SSH Security" \
    "SSH Key Authentication" \
    "SSH Server Configuration" \
    "Fail2ban" \
    "Security Auditing" \
    "File Integrity Monitoring" \
    "Linux Hardening"

# ==================================================
# PACK 7 - NETWORKING
# ==================================================

add_notes "Pack 7 (Linux Networking)" \
    "Linux Networking Architecture" \
    "Network Interfaces" \
    "ip command" \
    "Network Interface Configuration" \
    "NetworkManager" \
    "systemd-networkd" \
    "Linux Routing" \
    "Routing Tables" \
    "Default Routes" \
    "IP Address Configuration" \
    "Subnet Masks and CIDR" \
    "ARP and Neighbor Tables" \
    "DNS Configuration in Linux" \
    "resolv.conf" \
    "systemd-resolved" \
    "Hosts File" \
    "DHCP Client Configuration" \
    "Linux Network Namespaces" \
    "Veth Pairs" \
    "Linux Bridges" \
    "VLANs" \
    "Bonding and Teaming" \
    "TUN and TAP Devices" \
    "Linux Socket Interface" \
    "ss Command" \
    "Network Traffic Analysis" \
    "tcpdump" \
    "Wireshark" \
    "Netfilter Architecture" \
    "Linux NAT" \
    "Port Forwarding" \
    "Firewall Configuration" \
    "Network Troubleshooting"

# ==================================================
# PACK 8 - BOOT AND SYSTEMD
# ==================================================

add_notes "Pack 8 (Linux Boot and Systemd)" \
    "Linux Boot Process" \
    "BIOS and UEFI" \
    "GRUB Bootloader" \
    "GRUB Configuration" \
    "Linux Initramfs" \
    "Kernel Initialization" \
    "PID 1" \
    "Init Systems" \
    "systemd Architecture" \
    "systemd Targets" \
    "systemd Units" \
    "Service Units" \
    "Socket Units" \
    "Timer Units" \
    "Mount Units" \
    "Automount Units" \
    "systemctl" \
    "journalctl" \
    "Systemd Dependencies" \
    "Unit Dependencies and Ordering" \
    "Service Restart Policies" \
    "Systemd Environment Configuration" \
    "Systemd Resource Control" \
    "System Shutdown and Reboot" \
    "Rescue and Emergency Targets" \
    "Boot Troubleshooting"

# ==================================================
# PACK 9 - SOFTWARE AND PACKAGE MANAGEMENT
# ==================================================

add_notes "Pack 9 (Linux Package Management and Software)" \
    "Linux Package Management Fundamentals" \
    "Debian Package Management" \
    "APT Architecture" \
    "dpkg" \
    "APT Repositories" \
    "sources.list Configuration" \
    "Debian Repository Components" \
    "APT Package Priorities" \
    "APT Pinning" \
    "Package Dependencies" \
    "Package Installation" \
    "Package Removal and Purging" \
    "Package Holds" \
    "Package Verification" \
    "Debian Package Files" \
    "Building Debian Packages" \
    "Compiling Software from Source" \
    "GNU Make" \
    "CMake Fundamentals" \
    "Shared Library Management" \
    "ldconfig" \
    "ldd" \
    "Debian Alternatives System" \
    "APT Troubleshooting" \
    "Unattended Upgrades"

# ==================================================
# PACK 10 - SYSTEM ADMINISTRATION
# ==================================================

add_notes "Pack 10 (Linux System Administration)" \
    "Linux System Administration Fundamentals" \
    "Hostname Management" \
    "Time and Date Configuration" \
    "Timezone Configuration" \
    "NTP and Time Synchronization" \
    "Locale Configuration" \
    "Log Management" \
    "Linux Logging Architecture" \
    "rsyslog" \
    "systemd Journal" \
    "logrotate" \
    "Cron Architecture" \
    "crontab" \
    "at and batch Commands" \
    "Scheduled System Maintenance" \
    "User Administration" \
    "SSH Administration" \
    "Remote Administration" \
    "Backup and Restore" \
    "Rsync" \
    "Linux Configuration Management" \
    "Ansible Fundamentals" \
    "Server Provisioning" \
    "Linux Administration Best Practices"

# ==================================================
# PACK 11 - MONITORING AND TROUBLESHOOTING
# ==================================================

add_notes "Pack 11 (Linux Monitoring and Troubleshooting)" \
    "Linux Monitoring Fundamentals" \
    "CPU Monitoring" \
    "Memory Monitoring" \
    "Disk Monitoring" \
    "I O Monitoring" \
    "Network Monitoring" \
    "Load Average" \
    "uptime" \
    "free" \
    "vmstat" \
    "iostat" \
    "iotop" \
    "mpstat" \
    "pidstat" \
    "sar and sysstat" \
    "lsof" \
    "strace" \
    "ltrace" \
    "dmesg" \
    "journalctl Troubleshooting" \
    "Kernel Log Analysis" \
    "Core Dumps" \
    "coredumpctl" \
    "Linux Performance Analysis" \
    "Performance Bottleneck Identification" \
    "Linux System Diagnostics" \
    "Network Diagnostics" \
    "Disk Diagnostics" \
    "Boot Failure Troubleshooting" \
    "Service Failure Troubleshooting"

# ==================================================
# PACK 12 - VIRTUALIZATION AND CONTAINERS
# ==================================================

add_notes "Pack 12 (Linux Virtualization and Containers)" \
    "Virtualization Fundamentals" \
    "Hypervisors" \
    "KVM Architecture" \
    "QEMU" \
    "libvirt" \
    "Virtual Machine Networking" \
    "Virtual Machine Storage" \
    "Container Fundamentals" \
    "Linux Namespaces" \
    "Control Groups" \
    "Container Isolation" \
    "Overlay Filesystems" \
    "Docker Architecture" \
    "Docker Engine" \
    "Docker Images" \
    "Docker Containers" \
    "Docker Volumes" \
    "Docker Networking" \
    "Docker Compose" \
    "Container Security" \
    "Container Resource Limits" \
    "Rootless Containers" \
    "Podman Fundamentals" \
    "OCI Container Standards"

# ==================================================
# PACK 13 - SERVER AND PRODUCTION OPERATIONS
# ==================================================

add_notes "Pack 13 (Linux Server and Production Operations)" \
    "Linux Server Architecture" \
    "Production Server Fundamentals" \
    "Headless Linux Servers" \
    "Remote Server Management" \
    "Nginx on Debian" \
    "Reverse Proxy Configuration" \
    "TLS Certificates with Let's Encrypt" \
    "Certbot" \
    "Production SSH Configuration" \
    "Production Firewall Configuration" \
    "Application Service Deployment" \
    "Java Application Deployment on Linux" \
    "Spring Boot Deployment on Debian" \
    "JAR Service with systemd" \
    "PostgreSQL Server Administration" \
    "PostgreSQL Backup on Linux" \
    "Database Service Management" \
    "Environment Secrets on Linux" \
    "Production Log Management" \
    "Server Monitoring Stack" \
    "Server Backup Strategy" \
    "Disaster Recovery" \
    "Production Security Hardening" \
    "Zero Downtime Deployment" \
    "Linux Server Maintenance"

echo
echo "========================================"
echo " GENERATION SUMMARY"
echo "========================================"
echo "Root:    $ROOT"
echo "Created: $CREATED"
echo "Skipped: $SKIPPED"
echo "Dry run: $DRY_RUN"
echo "========================================"

if [[ "$DRY_RUN" == false ]]; then
    echo
    echo "Curriculum tree:"
    tree "$ROOT"
fi
