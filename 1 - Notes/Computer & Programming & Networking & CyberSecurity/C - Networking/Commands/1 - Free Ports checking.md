
**TCP/UDP network ports available on your Linux machine**, there isn't a fixed number of "free ports." Ports range from **0–65535**, and some are currently occupied/listening.

### 1. See currently listening ports

```bash
sudo ss -tulnp
```

- `-t` → TCP
    
- `-u` → UDP
    
- `-l` → listening
    
- `-n` → numeric ports
    
- `-p` → show process
    

Example:

```text
tcp   LISTEN 0  4096  0.0.0.0:8080
tcp   LISTEN 0  4096  127.0.0.1:5432
```

Here, `8080` and `5432` are being used for listening.

### 2. See only the port numbers

```bash
sudo ss -tuln
```

Or:

```bash
sudo ss -tuln | awk 'NR > 1 {print $5}' | sort -u
```

### 3. Check whether a specific port is free

For example, port `8080`:

```bash
sudo ss -ltn 'sport = :8080'
```

If **nothing is returned**, nothing is listening on TCP `8080`.

You can also use:

```bash
sudo lsof -i :8080
```

### 4. How many ports are theoretically available?

For each protocol:

**TCP:** 65,536 possible port numbers  
**UDP:** 65,536 possible port numbers

Ports `0–1023` are traditionally **well-known/privileged ports**. On Linux, binding to ports below `1024` normally requires root or the appropriate capability.

So for a normal application, you generally choose from:

```text
1024–65535
```

That's **64,512 port numbers**.

But there's an important distinction:

> **A port being unused for listening does not necessarily mean it is completely unavailable.**

A port can be temporarily occupied by an outgoing connection, and TCP also has states such as `TIME_WAIT`.

### 5. See TCP connections and their states

```bash
ss -tan
```

For example:

```text
LISTEN
ESTAB
TIME-WAIT
CLOSE-WAIT
```

For development, the most useful command is usually:

```bash
sudo ss -ltnp
```

If you're running **Spring Boot, PostgreSQL, Docker, etc.**, this is the command I'd use first to understand exactly what's occupying your ports.


[[Networking]]