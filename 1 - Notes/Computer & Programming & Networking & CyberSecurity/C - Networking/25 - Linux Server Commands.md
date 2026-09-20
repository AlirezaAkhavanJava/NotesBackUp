
# Complete Linux Server Commands Tutorial

A comprehensive guide to understanding and using essential Linux commands for server management, with detailed output explanations.

---

## Table of Contents

1. [Network & Port Management](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#network--port-management)
2. [Process Management](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#process-management)
3. [Log Monitoring](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#log-monitoring)
4. [Connection Testing](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#connection-testing)
5. [Server Performance & Resources](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#server-performance--resources)
6. [Firewall & Security](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#firewall--security)
7. [File & Directory Management](https://claude.ai/chat/0b182425-4b88-47ce-8fd4-c587afe4bbd3#file--directory-management)

---

## Network & Port Management

### 1. **netstat** (Network Statistics)

**Definition:** Displays network statistics including open ports, established connections, and network protocols in use.

**Syntax:**

```bash
netstat [OPTIONS]
```

**Common Options:**

- `-t` : TCP connections
- `-u` : UDP connections
- `-n` : Show numerical addresses (IPs instead of hostnames)
- `-l` : Show only listening sockets
- `-p` : Show process name/PID
- `-a` : Show all connections (both listening and established)

**Usage Examples:**

```bash
# Show all listening TCP connections with port numbers
netstat -tuln

# Show TCP connections with process information
netstat -tulnp

# Show all connections (listening + established)
netstat -an

# Show only established connections
netstat -an | grep ESTABLISHED

# Show connections for a specific port
netstat -tuln | grep :8080

# Count total connections
netstat -an | wc -l
```

**Output Explanation:**

```
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1234/sshd
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      5678/nginx
tcp        0      0 127.0.0.1:3306          0.0.0.0:*               LISTEN      9012/mysqld
tcp        0      0 192.168.1.100:22        192.168.1.50:54321      ESTABLISHED 1234/sshd
tcp        0      0 192.168.1.100:80        10.0.0.5:45678          ESTABLISHED 5678/nginx
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`Proto`|Protocol type|tcp, udp|
|`Recv-Q`|Data received but not read|0 (usually 0)|
|`Send-Q`|Data sent but not acknowledged|0 (usually 0)|
|`Local Address`|Your server's IP:Port|0.0.0.0:22 (listening on all IPs)|
|`Foreign Address`|Remote IP:Port|192.168.1.50:54321|
|`State`|Connection status|LISTEN, ESTABLISHED, TIME_WAIT|
|`PID/Program name`|Process ID and name|1234/sshd|

**Common States:**

- `LISTEN`: Waiting for incoming connections
- `ESTABLISHED`: Active connection
- `TIME_WAIT`: Waiting before closing connection
- `SYN_SENT`: Initiating connection
- `CLOSE_WAIT`: Waiting to close after remote closed

---

### 2. **ss** (Socket Statistics)

**Definition:** Modern replacement for netstat. Shows socket statistics more efficiently and with better performance.

**Syntax:**

```bash
ss [OPTIONS]
```

**Common Options:**

- `-t` : TCP sockets
- `-u` : UDP sockets
- `-l` : Listening sockets only
- `-a` : All sockets
- `-n` : Numerical format (don't resolve hostnames)
- `-p` : Show process info
- `-s` : Summary statistics

**Usage Examples:**

```bash
# Show all listening sockets with port numbers
ss -tuln

# Show listening TCP sockets with process info
ss -tulnp

# Show all established connections
ss -tan | grep ESTAB

# Summary of socket statistics
ss -s

# Show connections to specific port
ss -tuln | grep :3306

# Show UDP connections
ss -uln

# Monitor connections in real-time (requires watch)
watch -n 1 'ss -tuln'
```

**Output Explanation:**

```
Netid  State      Recv-Q Send-Q       Local Address:Port        Peer Address:Port  Process
tcp    LISTEN     0      128          0.0.0.0:22               0.0.0.0:*          users:(("sshd",pid=1234,fd=3))
tcp    LISTEN     0      511          0.0.0.0:80               0.0.0.0:*          users:(("nginx",pid=5678,fd=6))
tcp    LISTEN     0      70           127.0.0.1:3306           0.0.0.0:*          users:(("mysqld",pid=9012,fd=14))
tcp    ESTAB      0      0            192.168.1.100:22         192.168.1.50:54321
tcp    ESTAB      0      0            192.168.1.100:80         10.0.0.5:45678
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`Netid`|Type of socket|tcp, udp|
|`State`|Connection state|LISTEN, ESTAB, TIME-WAIT|
|`Recv-Q`|Bytes received not read by app|0|
|`Send-Q`|Bytes sent not acknowledged|128|
|`Local Address:Port`|Your server listening address|0.0.0.0:22|
|`Peer Address:Port`|Remote connection address|192.168.1.50:54321|
|`Process`|Process info|users:(("sshd",pid=1234,fd=3))|

**Advantages over netstat:**

- Faster and more efficient
- Better formatted output
- Shows more detailed process information
- More modern command

---

### 3. **lsof** (List Open Files)

**Definition:** Lists all open files and network connections. In Unix/Linux, everything is a file, so this shows network sockets too.

**Syntax:**

```bash
lsof [OPTIONS]
```

**Common Options:**

- `-i` : Show network connections
- `-i :PORT` : Show connections on specific port
- `-p PID` : Show files opened by process ID
- `-u USER` : Show files opened by user
- `-n` : Numerical format
- `-P` : Show port numbers instead of names

**Usage Examples:**

```bash
# Show all open network connections
lsof -i

# Show connections on specific port
lsof -i :8080

# Show connections for specific process
lsof -p 1234

# Show files opened by Apache
lsof -c apache2

# Show connections from specific user
lsof -u www-data

# Show combined network info
lsof -i -n -P

# Find what's using a specific port
lsof -i :80
```

**Output Explanation:**

```
COMMAND     PID   USER   FD   TYPE            DEVICE  SIZE/OFF NODE NAME
nginx      5678   root    6u  IPv4          11111111      0t0  TCP *:http (LISTEN)
nginx      5680   www-d   7u  IPv4          11111112      0t0  TCP 192.168.1.100:http->10.0.0.5:45678 (ESTABLISHED)
sshd       1234   root    3u  IPv4          11111113      0t0  TCP *:ssh (LISTEN)
mysql      9012   mysql  14u  IPv4          11111114      0t0  TCP 127.0.0.1:mysql (LISTEN)
redis      4567   redis   5u  IPv4          11111115      0t0  TCP 127.0.0.1:6379 (LISTEN)
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`COMMAND`|Process name|nginx, sshd, mysql|
|`PID`|Process ID|5678|
|`USER`|Process owner|root, www-data, mysql|
|`FD`|File descriptor|6u (u=read/write)|
|`TYPE`|File type|IPv4, IPv6, unix|
|`DEVICE`|Device number|Internal ID|
|`SIZE/OFF`|File size or offset|0t0 (not applicable for sockets)|
|`NODE`|Inode number|Network node|
|`NAME`|File/connection details|TCP *:http (LISTEN)|

**FD Types:**

- `r` : Read
- `w` : Write
- `u` : Read + Write (read/write)

---

### 4. **netstat -an** vs **ss -an** (All Connections)

**Definition:** Shows all network connections both listening and established.

```bash
# Using netstat
netstat -an | head -20

# Using ss (recommended)
ss -an | head -20
```

**Output Example:**

```
Proto Recv-Q Send-Q Local Address     Foreign Address   State
tcp        0      0 0.0.0.0:22        0.0.0.0:*         LISTEN
tcp        0      0 0.0.0.0:80        0.0.0.0:*         LISTEN
tcp        0      0 0.0.0.0:443       0.0.0.0:*         LISTEN
tcp        0      0 192.168.1.1:22    192.168.1.50:1234 ESTABLISHED
tcp        0      0 192.168.1.1:80    10.0.0.5:5678     ESTABLISHED
tcp        0      0 192.168.1.1:80    10.0.0.5:5679     ESTABLISHED
tcp        0      0 192.168.1.1:443   10.0.0.6:9012     TIME_WAIT
udp        0      0 0.0.0.0:53        0.0.0.0:*
```

**How to Read:**

- **0.0.0.0** means listening on all network interfaces
- **127.0.0.1** means listening only on localhost
- **192.168.1.1** means listening on that specific IP
- Each line represents one socket/connection

---

## Process Management

### 1. **ps** (Process Status)

**Definition:** Shows snapshot of current running processes.

**Syntax:**

```bash
ps [OPTIONS]
```

**Common Options:**

- `aux` : Show all processes with detailed info (ASCII output)
- `ef` : Show all processes in forest format
- `u` : User-oriented format

**Usage Examples:**

```bash
# Show all running processes with details
ps aux

# Show all processes in tree format
ps -ef

# Show processes for current user
ps u

# Show specific process
ps aux | grep nginx

# Show process hierarchy (tree view)
ps -ef --forest

# Show only running processes (exclude sleeping)
ps aux | grep -E "^\S+\s+[0-9]+\s+[0-9.]+\s+[0-9.]+\s+[0-9]+"
```

**Output Explanation:**

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1  19232  1608 ?        Ss   Sep16   0:01 /sbin/init
root       567  0.0  0.3  24560  3256 ?        Ss   Sep16   0:02 /lib/systemd/systemd-journald
www-data  5678  0.2  1.5 456789 15360 ?        S    10:23   0:45 /usr/sbin/nginx
mysql     9012  0.5  4.2 987654 42000 ?        Sl   10:24   1:23 /usr/sbin/mysqld
redis     4567  0.1  0.8 234567  8192 ?        Sl   10:25   0:34 /usr/bin/redis-server
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`USER`|Process owner|root, www-data|
|`PID`|Process ID|5678|
|`%CPU`|CPU usage percentage|0.2 (0.2%)|
|`%MEM`|Memory usage percentage|1.5 (1.5% of total RAM)|
|`VSZ`|Virtual memory size (KB)|456789|
|`RSS`|Resident set size - actual RAM (KB)|15360|
|`TTY`|Terminal|? (no terminal) or pts/0|
|`STAT`|Process state|Ss, S, Sl, etc.|
|`START`|When process started|Sep16, 10:23|
|`TIME`|CPU time used|0:45|
|`COMMAND`|Full command|/usr/sbin/nginx|

**STAT Code Explanation:**

|Code|Meaning|
|---|---|
|`S`|Sleeping (waiting for event)|
|`R`|Running (using CPU)|
|`Z`|Zombie (terminated but parent hasn't cleaned up)|
|`T`|Stopped/Traced|
|`<`|High priority (negative nice value)|
|`N`|Low priority (positive nice value)|
|`s`|Session leader|
|`l`|Multi-threaded|
|`+`|Foreground process group|

**Memory Analysis:**

- `VSZ` (Virtual Size): Total virtual memory (including swapped and shared)
- `RSS` (Resident Set Size): Actual physical RAM being used
- If RSS is much smaller than VSZ, process has lots of unused allocated memory

---

### 2. **top** (Table of Processes)

**Definition:** Real-time display of system resources and processes. Interactive command that updates continuously.

**Syntax:**

```bash
top [OPTIONS]
```

**Common Options:**

- `-u USER` : Show only processes from user
- `-p PID` : Monitor specific process
- `-n NUM` : Number of iterations before exiting
- `-d SEC` : Refresh interval in seconds
- `-b` : Batch mode (non-interactive)

**Usage Examples:**

```bash
# Launch top (interactive)
top

# Monitor specific process
top -p 5678

# Show only Apache processes
top -u www-data

# Run for 5 iterations then exit
top -n 5

# Run with 2-second refresh
top -d 2

# Batch mode output
top -b -n 3 > top_output.txt
```

**Output Explanation:**

```
top - 14:35:22 up 23:10,  2 users,  load average: 0.85, 0.92, 0.88
Tasks: 245 total,   2 running, 243 sleeping,   0 stopped,   0 zombie
%Cpu(s):  8.3 us,  2.1 sy,  0.0 ni, 89.2 id,  0.3 wa,  0.1 hi,  0.0 si,  0.0 st
MiB Mem :   7902.8 total,   2445.2 free,   3124.6 used,   2332.9 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   4245.3 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 5678 www-data  20   0  456789  15360   4500 S  15.3   0.2   0:45.23 nginx
 9012 mysql     20   0  987654  42000   8900 S  12.5   0.5   1:23.45 mysqld
 4567 redis     20   0  234567   8192   3200 S   2.1   0.1   0:34.12 redis-server
 1234 root      20   0   34567   2345   1200 S   0.3   0.0   0:01.23 sshd
```

**Header Breakdown:**

```
top - 14:35:22              = Current time
up 23:10                    = System uptime (23 hours 10 minutes)
2 users                     = Number of logged-in users
load average: 0.85, 0.92, 0.88 = Load average for 1, 5, 15 minutes
                              (lower = less busy, value of 1 = 1 CPU fully used)
```

**CPU Stats:**

```
%Cpu(s):  8.3 us,  2.1 sy,  0.0 ni, 89.2 id,  0.3 wa, 0.1 hi, 0.0 si, 0.0 st

us (user)     = 8.3%  (time running user processes)
sy (system)   = 2.1%  (time running kernel processes)
ni (nice)     = 0.0%  (time running niced user processes)
id (idle)     = 89.2% (idle time - CPU doing nothing)
wa (wait)     = 0.3%  (time waiting for I/O completion)
hi (hard irq) = 0.1%  (time serving hardware interrupts)
si (soft irq) = 0.0%  (time serving software interrupts)
st (steal)    = 0.0%  (time stolen by hypervisor for other guests)
```

**Memory Stats:**

```
MiB Mem :   7902.8 total = Total RAM installed
            2445.2 free  = Available RAM not in use
            3124.6 used  = RAM currently in use
            2332.9 buff/cache = RAM used for buffers/cache

MiB Swap:   2048.0 total = Total swap space
            2048.0 free  = Available swap
            0.0 used     = Currently using swap
            4245.3 avail Mem = Available memory for new processes
```

**Process Column Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`PR`|Priority|20 (default)|
|`NI`|Nice value|0 (0=normal)|
|`VIRT`|Virtual memory size|456789|
|`RES`|Resident memory|15360|
|`SHR`|Shared memory|4500|
|`S`|State|S (sleeping), R (running)|
|`%CPU`|CPU percentage|15.3|
|`%MEM`|Memory percentage|0.2|
|`TIME+`|CPU time used|0:45.23|
|`COMMAND`|Process name|nginx|

**Interactive Commands in top:**

```
q     = Quit
h     = Help
P     = Sort by CPU
M     = Sort by Memory
T     = Sort by Time
u     = Filter by user
k     = Kill process (enter PID)
r     = Renice process (change priority)
```

---

### 3. **htop** (Enhanced top)

**Definition:** More user-friendly, colorized version of top with better visualization and interactive features.

**Syntax:**

```bash
htop [OPTIONS]
```

**Usage Examples:**

```bash
# Launch htop
htop

# Monitor specific process
htop -p 5678

# Show only specific user's processes
htop -u www-data

# Sort by CPU usage
htop (press P while running)

# Search for process
htop (press F to find)
```

**Output Explanation:**

Similar to top but with:

- Color-coded CPU, memory bars
- Better visual formatting
- Process tree view
- Easier navigation

**Interactive Commands:**

```
F1/h  = Help
F3    = Search
F4    = Filter
F5    = Tree view
F6    = Sort by
F7    = Decrease priority
F8    = Increase priority
F9    = Kill process
F10/q = Quit
```

---

### 4. **kill** (Terminate Process)

**Definition:** Sends a signal to a process to terminate it or change its behavior.

**Syntax:**

```bash
kill [SIGNAL] PID
```

**Common Signals:**

|Signal|Number|Meaning|
|---|---|---|
|SIGTERM|15|Terminate gracefully (default)|
|SIGKILL|9|Force kill (cannot be caught)|
|SIGSTOP|19|Pause process|
|SIGCONT|18|Resume stopped process|
|SIGHUP|1|Hangup (reload config)|
|SIGUSR1|10|User defined|

**Usage Examples:**

```bash
# Graceful termination (default)
kill 5678

# Force kill process
kill -9 5678
kill -KILL 5678

# Send SIGTERM explicitly
kill -TERM 5678

# Pause a process
kill -STOP 5678

# Resume a stopped process
kill -CONT 5678

# Kill all processes named nginx
killall nginx

# Kill all processes from user
killall -u www-data

# Kill process tree
kill -TERM -5678  # Negative PID = process group
```

**How to Use:**

1. Find PID using `ps aux | grep processname` or `lsof -i :port`
2. Send signal: `kill -SIGNAL PID`
3. Verify with `ps aux | grep PID`

---

### 5. **systemctl** (Systemd Service Manager)

**Definition:** Controls systemd services and units. Modern replacement for service command.

**Syntax:**

```bash
systemctl [COMMAND] [SERVICE]
```

**Common Commands:**

|Command|Purpose|
|---|---|
|start|Start service|
|stop|Stop service|
|restart|Restart service|
|reload|Reload configuration|
|status|Show service status|
|enable|Start at boot|
|disable|Don't start at boot|
|is-active|Check if running|
|is-enabled|Check if enabled at boot|

**Usage Examples:**

```bash
# Start a service
sudo systemctl start nginx

# Stop a service
sudo systemctl stop apache2

# Restart a service
sudo systemctl restart mysql

# Reload configuration (without stopping)
sudo systemctl reload postgresql

# Check service status
sudo systemctl status nginx

# Enable service to start at boot
sudo systemctl enable redis-server

# Disable service from auto-starting
sudo systemctl disable mongodb

# Check if service is running
sudo systemctl is-active nginx
# Output: active or inactive

# Check if service enabled at boot
sudo systemctl is-enabled sshd
# Output: enabled or disabled

# View all services
sudo systemctl list-units --type=service

# View running services only
sudo systemctl list-units --type=service --state=running

# Restart all services matching pattern
sudo systemctl restart apache* mysql*
```

**Status Output Explanation:**

```
● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/etc/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2024-09-16 10:23:45 UTC; 4h 12min ago
     Docs: man:nginx(8)
   Main PID: 5678 (nginx)
    Tasks: 5 (limit: 2345)
   Memory: 15.3M
   CGroup: /system.slice/nginx.service
           ├─5678 nginx: master process /usr/sbin/nginx -g daemon on;
           ├─5679 nginx: worker process
           ├─5680 nginx: worker process
           ├─5681 nginx: worker process
           └─5682 nginx: worker process

Sep 16 10:23:45 server1 systemd[1]: Started A high performance web server...
```

**Status Breakdown:**

|Field|Meaning|Example|
|---|---|---|
|`Loaded`|Config file loaded|loaded (/etc/systemd/...)|
|`Active`|Current state|active (running)|
|`since`|When it started|Wed 2024-09-16 10:23:45|
|`Docs`|Documentation reference|man:nginx(8)|
|`Main PID`|Process ID|5678|
|`Tasks`|Number of threads|5|
|`Memory`|RAM usage|15.3M|
|`CGroup`|Process group|/system.slice/nginx.service|

**Enabled/Disabled Meanings:**

- `enabled` = Service starts automatically at boot
- `disabled` = Service must be started manually
- `enabled; vendor preset: enabled` = Both system and vendor enable it
- `active (running)` = Service is currently running
- `inactive (dead)` = Service is stopped

---

## Log Monitoring

### 1. **tail** (View End of File)

**Definition:** Shows the end of a file, useful for viewing log files. With `-f` flag, follows new additions in real-time.

**Syntax:**

```bash
tail [OPTIONS] FILE
```

**Common Options:**

- `-f` : Follow mode (real-time updates)
- `-n NUM` : Show last NUM lines (default 10)
- `-c NUM` : Show last NUM bytes
- `-F` : Follow even if file is rotated

**Usage Examples:**

```bash
# Show last 10 lines (default)
tail /var/log/nginx/access.log

# Show last 50 lines
tail -n 50 /var/log/apache2/error.log

# Follow log file in real-time
tail -f /var/log/syslog

# Follow multiple files
tail -f /var/log/nginx/access.log /var/log/nginx/error.log

# Follow with timestamp
tail -f /var/log/auth.log | while IFS= read -r line; do echo "[$(date '+%H:%M:%S')] $line"; done

# Show last 100 bytes
tail -c 100 /var/log/mysql/error.log

# Real-time with 2-second refresh
tail -f -s 2 /var/log/application.log

# Exit after printing initial content (non-follow)
tail -n 100 --max-unchanged-stats=5 /var/log/syslog
```

**Output Example:**

```
192.168.1.50 - - [16/Sep/2024:14:35:22 +0000] "GET / HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
192.168.1.51 - - [16/Sep/2024:14:35:23 +0000] "POST /api/users HTTP/1.1" 201 456 "-" "curl/7.68"
192.168.1.52 - - [16/Sep/2024:14:35:24 +0000] "GET /admin HTTP/1.1" 403 0 "-" "Firefox/91.0"
```

**When to Use:**

- `tail file` : Check recent activity
- `tail -f file` : Monitor log file live (Press Ctrl+C to stop)
- `tail -n 50` : Review more history

---

### 2. **journalctl** (Systemd Journal)

**Definition:** Views logs from systemd journal. Centralized logging system for all services managed by systemd.

**Syntax:**

```bash
journalctl [OPTIONS]
```

**Common Options:**

- `-u UNIT` : Show logs for specific service
- `-f` : Follow mode (real-time)
- `-n NUM` : Show last NUM lines
- `-b` : Show logs since last boot
- `--since` : Show logs since date/time
- `--until` : Show logs until date/time
- `-p PRIORITY` : Filter by priority level
- `-o FORMAT` : Output format (short, json, verbose)

**Usage Examples:**

```bash
# Show logs for specific service
journalctl -u nginx

# Follow nginx logs in real-time
journalctl -u nginx -f

# Show last 50 lines of MySQL logs
journalctl -u mysql -n 50

# Show logs since last boot
journalctl -b

# Show logs from last 2 hours
journalctl --since "2 hours ago"

# Show logs from specific date
journalctl --since "2024-09-16 10:00:00" --until "2024-09-16 15:00:00"

# Show only errors and above
journalctl -u apache2 -p err

# Show logs in JSON format (for parsing)
journalctl -u postgresql -o json

# Show logs with full details
journalctl -u sshd -o verbose

# Show last boot logs
journalctl -b -1  # -1 = previous boot, -0 = current

# Follow multiple services
journalctl -u nginx -u mysql -f

# Show boot messages
journalctl -b -o short-monotonic

# Disk usage of journal
journalctl --disk-usage
```

**Output Explanation (short format):**

```
Sep 16 14:35:22 server1 nginx[5678]: 192.168.1.50 - - "GET / HTTP/1.1" 200 1234
Sep 16 14:35:23 server1 nginx[5679]: 192.168.1.51 - - "POST /api HTTP/1.1" 201
Sep 16 14:35:24 server1 mysql[9012]: InnoDB: Buffer pool size = 1GB
Sep 16 14:35:25 server1 sshd[1234]: Accepted publickey for user from 192.168.1.100
```

**Output Format (verbose):**

```
Sat 2024-09-16 14:35:22.123456 UTC [s=abc123def456...]
    PRIORITY=6
    SYSLOG_FACILITY=16
    _SYSTEMD_UNIT=nginx.service
    _SYSTEMD_INVOCATION_ID=abc123...
    _COMM=nginx
    _EXE=/usr/sbin/nginx
    _UID=33
    _GID=33
    MESSAGE=192.168.1.50 - - "GET / HTTP/1.1" 200 1234
```

**Priority Levels (highest to lowest):**

|Level|Number|Name|
|---|---|---|
|0|emerg|System unusable|
|1|alert|Action must be taken immediately|
|2|crit|Critical condition|
|3|err|Error condition|
|4|warning|Warning condition|
|5|notice|Normal but significant|
|6|info|Informational|
|7|debug|Debug-level messages|

**Output Formats:**

- `short` : Timestamp, hostname, process, message
- `short-monotonic` : Monotonic timestamp instead of wall clock
- `verbose` : All fields shown
- `json` : JSON format for parsing
- `json-pretty` : Formatted JSON
- `cat` : Only message text

---

### 3. **grep** (Search Text)

**Definition:** Searches for text patterns in files. Used to filter log entries.

**Syntax:**

```bash
grep [OPTIONS] PATTERN [FILE]
```

**Common Options:**

- `-i` : Ignore case
- `-v` : Invert match (show lines NOT matching)
- `-c` : Count matching lines
- `-n` : Show line numbers
- `-A NUM` : Show NUM lines after match (context)
- `-B NUM` : Show NUM lines before match
- `-C NUM` : Show NUM lines before and after
- `-E` : Use regex patterns
- `-l` : Show only filenames

**Usage Examples:**

```bash
# Search for errors in log
grep ERROR /var/log/application.log

# Case-insensitive search
grep -i "error" /var/log/syslog

# Search and show line numbers
grep -n "Failed" /var/log/auth.log

# Count matching lines
grep -c "200" /var/log/nginx/access.log

# Show lines NOT containing pattern
grep -v "200" /var/log/nginx/access.log

# Show context around match
grep -A 5 "Error" /var/log/syslog  # Show 5 lines after
grep -B 5 "Error" /var/log/syslog  # Show 5 lines before
grep -C 3 "Error" /var/log/syslog  # Show 3 lines before and after

# Use with pipes to filter other commands
ps aux | grep nginx
tail -f /var/log/syslog | grep "ERROR"

# Search in multiple files
grep "connection" /var/log/mysql/*.log

# Show only filenames containing pattern
grep -l "500" /var/log/nginx/*

# Case-insensitive with context
grep -i -A 2 "timeout" /var/log/apache2/error.log

# Search with regex (extended grep)
grep -E "^[0-9]+\.[0-9]+\.[0-9]+" /var/log/syslog

# Count errors vs warnings
echo "Errors: $(grep -c 'ERROR' log.txt), Warnings: $(grep -c 'WARNING' log.txt)"
```

**Output Example:**

```
grep -n "ERROR" /var/log/app.log

45: 2024-09-16 14:35:22 ERROR Connection timeout
67: 2024-09-16 14:36:15 ERROR Database unavailable
89: 2024-09-16 14:37:03 ERROR File not found
```

**With Context:**

```
grep -A 2 -B 1 "ERROR" /var/log/app.log

44: 2024-09-16 14:35:21 INFO Starting database sync
45: 2024-09-16 14:35:22 ERROR Connection timeout
46: 2024-09-16 14:35:23 INFO Retrying connection
47: 2024-09-16 14:35:24 INFO Connected successfully
--
66: 2024-09-16 14:36:14 INFO Attempting reconnection
67: 2024-09-16 14:36:15 ERROR Database unavailable
68: 2024-09-16 14:36:16 INFO Waiting 5 seconds
69: 2024-09-16 14:36:21 INFO Reconnected
```

---

## Connection Testing

### 1. **curl** (Command Line URL Retrieval)

**Definition:** Downloads or tests web pages and APIs. Sends HTTP requests and displays responses.

**Syntax:**

```bash
curl [OPTIONS] URL
```

**Common Options:**

- `-I` : Headers only (no body)
- `-i` : Headers and body
- `-X METHOD` : HTTP method (GET, POST, PUT, DELETE)
- `-d DATA` : Send POST data
- `-H HEADER` : Add header
- `-u USER:PASS` : Basic auth
- `-L` : Follow redirects
- `-v` : Verbose (show request/response details)
- `-w "format"` : Output specific information
- `-o FILE` : Save to file
- `-O` : Save with original filename
- `--connect-timeout` : Connection timeout
- `--max-time` : Total timeout

**Usage Examples:**

```bash
# Simple GET request
curl http://localhost:8080

# Show headers only
curl -I http://example.com

# Show headers and body
curl -i http://example.com

# Follow redirects
curl -L http://example.com

# Verbose output (see request/response)
curl -v http://localhost:80

# Test with specific HTTP method
curl -X POST http://api.example.com/users

# Send JSON data
curl -X POST http://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":30}'

# Basic authentication
curl -u username:password http://example.com/admin

# Add custom headers
curl -H "Authorization: Bearer TOKEN123" \
  -H "User-Agent: MyApp/1.0" \
  http://api.example.com/data

# Save response to file
curl http://example.com -o page.html

# Test connection timeout
curl --connect-timeout 5 http://slowserver.com

# Get response time and other statistics
curl -w "HTTP Status: %{http_code}\nTime Total: %{time_total}s\n" \
  http://example.com

# Test API endpoint with all details
curl -v -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' \
  -w "\nHTTP Status: %{http_code}\n"
```

**Output Example (verbose):**

```
*   Trying 93.184.216.34:80...
* Connected to example.com (93.184.216.34) port 80 (#0)
> GET / HTTP/1.1
> Host: example.com
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Age: 357479
< Cache-Control: max-age=604800
< Content-Type: text/html; charset=UTF-8
< Date: Wed, 16 Sep 2024 14:35:22 GMT
< Etag: "3147526947"
< Expires: Wed, 23 Sep 2024 14:35:22 GMT
< Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
< Server: ECS (dcb/7F83)
< Vary: Accept-Encoding
< X-Cache: HIT
< Content-Length: 1256
<
<!DOCTYPE html>
<html>
...
```

**Output Breakdown:**

```
*   Trying IP:PORT              = Attempting connection
* Connected                    = Connection successful
> GET / HTTP/1.1               = Request line sent
> Host: example.com            = Request headers
> 
< HTTP/1.1 200 OK              = Response status line
< Content-Type: text/html      = Response headers
<
<!DOCTYPE html>                = Response body
```

**Common HTTP Status Codes:**

|Code|Meaning|
|---|---|
|200|OK - Success|
|301/302|Redirect|
|400|Bad Request|
|401|Unauthorized|
|403|Forbidden|
|404|Not Found|
|500|Internal Server Error|
|502|Bad Gateway|
|503|Service Unavailable|

---

### 2. **nc** (Netcat - Network Cat)

**Definition:** Tests if ports are open and responsive. Can also be used for network communication.

**Syntax:**

```bash
nc [OPTIONS] HOST PORT
```

**Common Options:**

- `-z` : Just check if port is open (don't send data)
- `-v` : Verbose output
- `-w TIMEOUT` : Connection timeout in seconds
- `-u` : UDP instead of TCP
- `-l` : Listen mode (server)
- `-p PORT` : Specify local port

**Usage Examples:**

```bash
# Check if port is open (TCP)
nc -zv localhost 8080

# Check if port is open with timeout
nc -zv -w 5 example.com 80

# Check multiple ports
nc -zv localhost 80 443 3306 5432

# Test UDP port
nc -zuv localhost 53

# Listen on port (server mode)
nc -l -p 9999

# Connect and send data
echo "Hello Server" | nc localhost 8080

# Scan range of ports
for port in 80 443 3306 5432 8080; do
  nc -zv -w 2 localhost $port
done

# Check all common web server ports
nc -zv localhost 80 443 8080 8443 8000 8888
```

**Output Example:**

```
# Successful connection
nc -zv localhost 8080
Connection to localhost 8080 port [tcp/http-alt] succeeded!

# Failed connection
nc -zv -w 3 192.168.1.100 9999
nc: connect to 192.168.1.100 port 9999 (tcp) timed out
```

**Port Scanning Output:**

```
nc -zv localhost 80 443 3306 8080

Connection to localhost 80 port [tcp/http] succeeded!
nc: connect to localhost 443 port [tcp/https] timed out
nc: connect to localhost 3306 port [tcp/mysql] failed: Connection refused
Connection to localhost 8080 port [tcp/8080-http-alt] succeeded!
```

---

### 3. **telnet** (Teletype Network)

**Definition:** Connects to a server on a specific port. Shows connection status and allows interactive testing.

**Syntax:**

```bash
telnet HOST PORT
```

**Usage Examples:**

```bash
# Test SSH connection
telnet localhost 22

# Test HTTP port
telnet example.com 80

# Test SMTP
telnet mail.example.com 25

# Test custom port
telnet localhost 3000
```

**Output Example (successful):**

```
telnet localhost 22
Trying ::1...
Connected to localhost.
Escape character is '^]'.
SSH-2.0-OpenSSH_7.4
```

**Output Explanation:**

```
Connected to localhost           = Connection established
Escape character is '^]'         = Press Ctrl+] to exit
SSH-2.0-OpenSSH_7.4             = Server response (SSH banner)
```

**Output Example (failed):**

```
telnet localhost 9999
Trying ::1...
telnet: connect to address ::1: Connection refused
Trying 127.0.0.1...
telnet: connect to address 127.0.0.1: Connection refused
telnet: Unable to connect to remote host: Connection refused
```

**Interactive Commands:**

```
telnet> ?                  = Help
telnet> open host port     = Connect to different server
telnet> quit               = Exit (or Ctrl+])
```

---

### 4. **ping** (Packet Internet Groper)

**Definition:** Tests reachability of a host and measures round-trip time to it.

**Syntax:**

```bash
ping [OPTIONS] HOST
```

**Common Options:**

- `-c NUM` : Send NUM packets (Linux/Mac)
- `-n NUM` : Send NUM packets (Windows)
- `-i INTERVAL` : Wait INTERVAL seconds between packets
- `-W TIMEOUT` : Wait timeout seconds for reply
- `-s SIZE` : Packet size

**Usage Examples:**

```bash
# Ping host (stop with Ctrl+C)
ping example.com

# Send 5 packets then stop
ping -c 5 example.com

# Ping with 2-second interval
ping -i 2 example.com

# Ping with custom packet size
ping -c 5 -s 1024 example.com

# Ping with timeout
ping -c 5 -W 3 example.com
```

**Output Example:**

```
PING example.com (93.184.216.34) 56(84) bytes of data.
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=1 ttl=56 time=45.2 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=2 ttl=56 time=44.8 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=3 ttl=56 time=45.5 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=4 ttl=56 time=44.9 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=5 ttl=56 time=45.1 ms

--- example.com statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4005ms
rtt min/avg/max/stddev = 44.8/45.1/45.5/0.3 ms
```

**Output Breakdown:**

```
56(84) bytes of data          = Data size (56 + 28 header bytes = 84 total)
icmp_seq=1                    = Sequence number
ttl=56                        = Time To Live (hops remaining)
time=45.2 ms                  = Round-trip time

--- Statistics ---
5 packets transmitted         = Sent 5
5 received                    = Received 5
0% packet loss                = None lost
rtt min/avg/max/stddev        = Min, average, max, standard deviation times
```

---

### 5. **dig** (Domain Information Groper)

**Definition:** Queries DNS servers to resolve domain names and check DNS records.

**Syntax:**

```bash
dig [OPTIONS] DOMAIN [RECORD_TYPE]
```

**Common Record Types:**

- `A` : IPv4 address
- `AAAA` : IPv6 address
- `CNAME` : Canonical name
- `MX` : Mail exchange
- `NS` : Nameserver
- `TXT` : Text record
- `SOA` : Start of authority

**Usage Examples:**

```bash
# Lookup A record (IPv4)
dig example.com

# Lookup specific record type
dig example.com MX    # Mail servers
dig example.com NS    # Nameservers
dig example.com TXT   # Text records
dig example.com AAAA  # IPv6 addresses

# Query specific DNS server
dig @8.8.8.8 example.com

# Short output (answer section only)
dig +short example.com

# Trace DNS resolution path
dig +trace example.com

# Reverse DNS lookup
dig -x 93.184.216.34

# Do NOT recurse (authoritative only)
dig +norec example.com

# Show all DNSSEC info
dig +dnssec example.com
```

**Output Example:**

```
; <<>> DiG 9.16.1-Ubuntu <<>> example.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; QUESTION SECTION:
;example.com.                   IN      A

;; ANSWER SECTION:
example.com.            3599    IN      A       93.184.216.34

;; ADDITIONAL SECTION:
;; Got validating NSEC3 RRset for example.com. from 199.43.135.53 in 45 ms

;; Query time: 45 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Wed Sep 16 14:35:22 UTC 2024
;; MSG SIZE  rcvd: 96
```

**Output Breakdown:**

```
QUERY SECTION:
;example.com.     IN     A   = Query: example.com A record

ANSWER SECTION:
example.com.  3599  IN  A  93.184.216.34
              ^^^^              = TTL (time to live in seconds)
                 ^^              = Class (IN = Internet)
                    ^            = Type (A record)
                       ^^^^^^^^^^= Answer (IP address)

Query time: 45 msec          = How long query took
SERVER: 127.0.0.53#53        = Which DNS server
```

**Short Output:**

```
dig +short example.com
93.184.216.34
```

---

## Server Performance & Resources

### 1. **free** (Memory Usage)

**Definition:** Shows RAM and swap memory usage.

**Syntax:**

```bash
free [OPTIONS]
```

**Common Options:**

- `-h` : Human-readable (show with M, G, T suffixes)
- `-b` : Show in bytes
- `-k` : Show in kilobytes
- `-m` : Show in megabytes
- `-g` : Show in gigabytes
- `-s INTERVAL` : Refresh every INTERVAL seconds

**Usage Examples:**

```bash
# Show memory in human-readable format
free -h

# Show in megabytes
free -m

# Show in gigabytes
free -g

# Refresh every 2 seconds
free -h -s 2

# One-time output (non-interactive)
free -h

# With timestamps
watch -n 1 'echo "=== $(date) ===" && free -h'
```

**Output Example:**

```
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       3.1Gi       2.4Gi       245Mi       2.3Gi       4.2Gi
Swap:          2.0Gi          0B       2.0Gi
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`total`|Total installed RAM|7.6Gi|
|`used`|RAM in use|3.1Gi|
|`free`|Unused RAM|2.4Gi|
|`shared`|Shared memory|245Mi|
|`buff/cache`|Buffers + Cache|2.3Gi|
|`available`|Available for apps|4.2Gi|

**Understanding Memory:**

```
Total = Used + Free (not quite true due to buffers/cache)

used     = Memory actively used by processes
free     = Completely unused
buff/cache = Buffers and cache (can be freed if needed)
available  = Free + cache (realistically available for new processes)
```

**Memory in Bytes:**

```
free -b

               total        used        free      shared  buff/cache   available
Mem:     8370253824  3354894336  2580602880  256901120  2434756608  4527890432
Swap:    2147483648           0  2147483648
```

---

### 2. **df** (Disk Free Space)

**Definition:** Shows disk space usage of mounted filesystems.

**Syntax:**

```bash
df [OPTIONS] [FILESYSTEM]
```

**Common Options:**

- `-h` : Human-readable format
- `-i` : Show inode usage instead
- `-k` : Show in kilobytes
- `-m` : Show in megabytes
- `-g` : Show in gigabytes
- `-T` : Show filesystem type

**Usage Examples:**

```bash
# Show all mounted filesystems in human format
df -h

# Show with filesystem type
df -hT

# Show inode usage
df -i

# Show specific filesystem
df -h /home

# Show in gigabytes
df -g

# Exclude certain filesystems
df -h -x tmpfs -x devtmpfs

# Show total in last line
df -h --total
```

**Output Example:**

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  48% /
/dev/sda2       200G  150G   40G  79% /home
/dev/sdb1       500G  250G  225G  52% /data
tmpfs           3.8G     0  3.8G   0% /dev/shm
tmpfs           1.6G  8.2M  1.5G   1% /run
```

**Output Breakdown:**

|Column|Meaning|Example|
|---|---|---|
|`Filesystem`|Device or mount|/dev/sda1|
|`Size`|Total partition size|100G|
|`Used`|Space used|45G|
|`Avail`|Space available|50G|
|`Use%`|Percentage used|48%|
|`Mounted on`|Where mounted|/|

**Interpreting Usage:**

- **0-50%** : Plenty of space, no concerns
- **50-80%** : Getting full, monitor
- **80-90%** : Getting critical, consider cleanup
- **>90%** : Critical, cleanup urgently

**With Inode Info:**

```
df -i /

Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/sda1    6553600  1234 6552366    1% /
```

---

### 3. **du** (Disk Usage)

**Definition:** Shows disk space used by files and directories.

**Syntax:**

```bash
du [OPTIONS] [PATH]
```

**Common Options:**

- `-h` : Human-readable
- `-s` : Summary only (not subdirectories)
- `-a` : Show all files (not just directories)
- `-c` : Total sum
- `-d DEPTH` : Limit depth
- `--max-depth=N` : Maximum depth to traverse
- `-x` : Don't cross filesystem boundaries

**Usage Examples:**

```bash
# Show size of directory
du -sh /home

# Show size of all subdirectories
du -h /var

# Show top 10 largest directories
du -sh /home/* | sort -rh | head -10

# Show total size
du -sh /data

# Show detailed breakdown
du -h --max-depth=2 /var

# Show all files (not just dirs)
du -ah /home | sort -rh | head -10

# Show with count of files
du -sh /* | sort -rh

# Find large files in current directory
find . -type f -exec du -h {} + | sort -rh | head -10
```

**Output Example:**

```
du -h /var

12M     /var/backups
234M    /var/log
45M     /var/cache
8.5G    /var/lib
9.0G    total
```

**Output Breakdown:**

```
12M     = Size of directory
/var/backups = Path

First column = Disk usage
Second column = Directory/file path
```

**Finding Large Directories:**

```
du -sh /home/* | sort -rh

15G     /home/user1
8.5G    /home/user2
3.2G    /home/user3
1.1G    /home/user4
```

---

### 4. **top** (Already Covered Above)

See Process Management section for detailed explanation.

---

### 5. **htop** (Already Covered Above)

See Process Management section for detailed explanation.

---

### 6. **iotop** (IO Top - Disk I/O)

**Definition:** Shows which processes are using most disk I/O.

**Syntax:**

```bash
iotop [OPTIONS]
```

**Common Options:**

- `-o` : Show only processes doing I/O
- `-a` : Accumulated I/O
- `-b` : Batch mode
- `-n NUM` : Show NUM updates

**Usage Examples:**

```bash
# Launch iotop (requires sudo)
sudo iotop

# Show only processes doing I/O
sudo iotop -o

# Batch mode (5 updates)
sudo iotop -b -n 5

# With accumulated I/O
sudo iotop -a

# For specific time period
sudo iotop -b -n 10 -o > io_report.txt
```

**Output Example:**

```
Total DISK READ :       0.00 B/s | Total DISK WRITE :      10.34 M/s
Actual DISK READ:       0.00 B/s | Actual DISK WRITE :      10.34 M/s
   TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN  IO%   COMMAND
  5678  be/4  mysql       0.00 B    10.34 M    0.00%  85%   mysqld
  1234  be/4  www-data    0.00 B     2.15 M    0.00%  15%   apache2
  9012  be/4  root        0.00 B     0.00 B    0.00%   0%   sshd
```

---

### 7. **vmstat** (Virtual Memory Statistics)

**Definition:** Shows system performance including CPU, memory, and I/O statistics.

**Syntax:**

```bash
vmstat [DELAY] [COUNT]
```

**Usage Examples:**

```bash
# Single snapshot
vmstat

# Update every 2 seconds, 10 times
vmstat 2 10

# Show disk I/O every 5 seconds
vmstat -d 5

# Show memory statistics
vmstat -s

# Real-time monitoring
vmstat 1  # Updates every 1 second (stop with Ctrl+C)
```

**Output Example:**

```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0 2540960 123456 2345678   0    0   100  200  1234 5678 15  3 78  4  0
 1  0      0 2234567 123456 2345678   0    0   150  250  1456 6234 25  5 68  2  0
```

**Output Breakdown:**

**procs:**

- `r`: Processes running
- `b`: Processes blocked

**memory:**

- `swpd`: Virtual memory used
- `free`: Free memory
- `buff`: Buffers
- `cache`: Cache

**swap:**

- `si`: Swap in (from disk)
- `so`: Swap out (to disk)

**io:**

- `bi`: Blocks in (read from disk)
- `bo`: Blocks out (write to disk)

**system:**

- `in`: Interrupts/second
- `cs`: Context switches/second

**cpu:**

- `us`: User CPU%
- `sy`: System CPU%
- `id`: Idle%
- `wa`: Wait for I/O%
- `st`: Stolen%

---

## Firewall & Security

### 1. **ufw** (Uncomplicated Firewall)

**Definition:** User-friendly frontend to iptables. Controls incoming/outgoing traffic rules.

**Syntax:**

```bash
sudo ufw [COMMAND] [RULE]
```

**Common Commands:**

|Command|Purpose|
|---|---|
|enable|Turn on firewall|
|disable|Turn off firewall|
|status|Show firewall status|
|allow PORT|Allow port|
|deny PORT|Block port|
|delete allow PORT|Remove allow rule|
|reset|Reset all rules|
|reload|Reload rules|

**Usage Examples:**

```bash
# Check firewall status
sudo ufw status

# Enable firewall
sudo ufw enable

# Disable firewall
sudo ufw disable

# Allow specific port
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3306/tcp # MySQL
sudo ufw allow 5432/tcp # PostgreSQL

# Allow for all protocols
sudo ufw allow 8080

# Deny port
sudo ufw deny 23        # Deny Telnet

# Allow from specific IP
sudo ufw allow from 192.168.1.50 to any port 22

# Show rule numbers
sudo ufw status numbered

# Delete rule by number
sudo ufw delete 5

# Delete rule by name
sudo ufw delete allow 22/tcp

# Reset all rules
sudo ufw reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow range of ports
sudo ufw allow 1000:2000/tcp

# List all rules
sudo ufw show added
```

**Status Output Explanation:**

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
3306/tcp                   ALLOW       192.168.1.50
22/tcp (v6)                ALLOW       Anywhere (v6)
```

**Output Breakdown:**

|Column|Meaning|
|---|---|
|`To`|Destination port/service|
|`Action`|ALLOW or DENY|
|`From`|Source (Anywhere or specific IP)|

---

### 2. **iptables** (Advanced Firewall)

**Definition:** Direct kernel firewall rule management. More complex but more powerful than ufw.

**Syntax:**

```bash
sudo iptables [COMMAND] [OPTIONS]
```

**Common Commands:**

|Command|Purpose|
|---|---|
|-A CHAIN|Append rule|
|-D CHAIN|Delete rule|
|-L|List rules|
|-n|Numeric output|
|-v|Verbose|
|-F|Flush (delete all)|
|-X|Delete chains|

**Chains:**

- `INPUT`: Incoming traffic
- `OUTPUT`: Outgoing traffic
- `FORWARD`: Forwarded traffic

**Actions:**

- `ACCEPT`: Allow packet
- `DROP`: Drop packet silently
- `REJECT`: Reject with error message

**Usage Examples:**

```bash
# List all rules
sudo iptables -L

# List with line numbers
sudo iptables -L --line-numbers

# List specific chain
sudo iptables -L INPUT -n -v

# Add rule to allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow from specific IP
sudo iptables -A INPUT -p tcp -s 192.168.1.50 --dport 3306 -j ACCEPT

# Delete rule by line number
sudo iptables -D INPUT 5

# Allow all established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all other incoming
sudo iptables -A INPUT -j DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

**Output Example:**

```
sudo iptables -L -n -v

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 1234 95678 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
 5678 456789 ACCEPT    tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
   12  1024 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:23
```

---

## File & Directory Management

### 1. **ls** (List Files)

**Definition:** Lists files and directories with details.

**Syntax:**

```bash
ls [OPTIONS] [PATH]
```

**Common Options:**

- `-l` : Long format (detailed)
- `-a` : Show hidden files
- `-h` : Human-readable sizes
- `-t` : Sort by time
- `-r` : Reverse sort
- `-R` : Recursive
- `-S` : Sort by size

**Usage Examples:**

```bash
# Simple listing
ls /var/log

# Detailed listing
ls -lh /var/log

# Include hidden files
ls -la /home/user

# Sort by modification time (newest first)
ls -lt /var/log

# Reverse sort (oldest first)
ls -ltr /var/log

# Recursive (show subdirectories)
ls -lR /etc/nginx

# Sort by file size
ls -lhS /var/log
```

**Output Example:**

```
ls -lh /var/log

drwxr-xr-x  5 root     root     4.0K Sep 16 14:00 apache2
-rw-r--r--  1 syslog   adm      2.3M Sep 16 14:35 syslog
-rw-r--r--  1 syslog   adm      1.2M Sep 16 14:35 auth.log
drwxr-xr-x  2 mysql    mysql    4.0K Sep 16 10:00 mysql
-rw-r--r--  1 www-data www-data 567K Sep 16 14:30 nginx_access.log
```

**Output Breakdown:**

```
drwxr-xr-x              = Permissions
     (d = directory, r = read, w = write, x = execute)
5                       = Number of hard links
root                    = Owner
root                    = Group
4.0K                    = Size
Sep 16 14:00            = Last modified date/time
apache2                 = Filename

Permissions:
First character: d (directory) or - (file)
Next 9 characters: rwxrwxrwx (owner, group, others)
  r = read (4), w = write (2), x = execute (1)
```

---

### 2. **find** (Search Files)

**Definition:** Searches for files based on various criteria.

**Syntax:**

```bash
find [PATH] [OPTIONS] [EXPRESSION]
```

**Common Options:**

|Option|Purpose|
|---|---|
|`-name PATTERN`|Match filename|
|`-type f/d`|File or directory|
|`-size +100M`|Larger than 100MB|
|`-mtime -7`|Modified in last 7 days|
|`-user USERNAME`|Owned by user|
|`-perm /mode`|With permissions|
|`-exec COMMAND {}`|Execute command on results|

**Usage Examples:**

```bash
# Find all .log files
find / -name "*.log"

# Find all files larger than 1GB
find / -size +1G

# Find recently modified files (last 24 hours)
find / -mtime -1

# Find files owned by www-data
find / -user www-data

# Find and delete old log files
find /var/log -name "*.log" -mtime +30 -delete

# Find and list large files
find / -type f -size +100M -exec ls -lh {} \;

# Find empty directories
find / -type d -empty

# Find files modified in last 7 days
find /home -mtime -7

# Find and compress old files
find /var/log -name "*.log" -mtime +30 -exec gzip {} \;

# Find executable files
find /usr/bin -type f -executable

# Find with multiple criteria
find /var -type f -name "*.log" -size +10M -mtime -7
```

**Output Example:**

```
find /var/log -name "*.log" -type f

/var/log/apache2/access.log
/var/log/apache2/error.log
/var/log/mysql/error.log
/var/log/nginx/access.log
/var/log/syslog
```

---

### 3. **chmod** (Change Permissions)

**Definition:** Changes file and directory permissions.

**Syntax:**

```bash
chmod [OPTIONS] MODE FILE
```

**Mode Format:**

- **Numeric**: `rwx` = 4+2+1 = 7
    
    - `4` = read
    - `2` = write
    - `1` = execute
    - First digit = owner, second = group, third = others
- **Symbolic**: `u/g/o` ± `r/w/x`
    
    - `u` = user (owner)
    - `g` = group
    - `o` = others
    - `a` = all
    - `+` = add, `-` = remove, `=` = set

**Usage Examples:**

```bash
# Make file readable/writable by owner only
chmod 600 file.txt

# Make file executable for owner
chmod 755 script.sh

# Make directory and contents executable for everyone
chmod -R 755 /var/www

# Add execute permission
chmod +x script.sh

# Remove write permission from group
chmod g-w file.txt

# Make readable by all
chmod a+r file.txt

# Set specific permissions
chmod u=rwx,g=rx,o=rx script.sh
```

**Permission Breakdown:**

```
chmod 755 file
      7 = owner: read(4) + write(2) + execute(1) = 7
      5 = group: read(4) + execute(1) = 5
      5 = others: read(4) + execute(1) = 5
```

---

### 4. **chown** (Change Owner)

**Definition:** Changes file owner and group ownership.

**Syntax:**

```bash
chown [OPTIONS] OWNER:GROUP FILE
```

**Usage Examples:**

```bash
# Change owner
sudo chown www-data file.txt

# Change owner and group
sudo chown www-data:www-data file.txt

# Change group only
sudo chown :www-data file.txt

# Recursive (directory and contents)
sudo chown -R www-data:www-data /var/www

# Change to match another file
sudo chown --reference=ref.txt target.txt
```

---

## Conclusion

This tutorial covers the most essential Linux server commands. Key takeaways:

1. **Network Management**: Use `ss` or `netstat` to monitor connections
2. **Process Control**: Use `systemctl` for managing services, `ps/top` for monitoring
3. **Log Analysis**: Use `tail -f`, `journalctl`, and `grep` to troubleshoot
4. **Performance**: Monitor with `top`, `free`, and `df`
5. **Security**: Use `ufw` for simple firewall rules, `iptables` for advanced

Always run with `sudo` when needed, and remember to check man pages: `man command` for detailed help.


[[Networking]]
[[2 - Tags/Linux|Linux]]