

## 1. The Users: `root` vs Regular Users

### root User (Superuser)
- **The Administrator**: The `root` user has absolute power over the entire system
- **Unrestricted Access**: Can read, modify, or delete any file, install software, change system settings, and manage user accounts
- **UID 0**: Has User ID 0 (the first and most powerful user)
- **Dangerous**: A single typo as root can destroy the entire system
- **Usage**: Should only be used for system administration tasks

### Regular User (Home User)
- **Limited Privileges**: Can only modify files they own or have permission to access
- **Restricted Access**: Cannot modify system files or other users' files without permission
- **Safe**: Mistakes are generally contained within their own home directory
- **Daily Use**: Meant for everyday computing tasks

## 2. The Directories: `/root` vs `/home`

### /root (root's Home Directory)
- **Path**: `/root`
- **Owner**: The `root` user
- **Purpose**: Personal workspace for the system administrator
- **Permissions**: Only accessible by root (other users cannot view its contents)
- **Contents**: root's personal files, scripts, and configuration files
- **Location**: At the filesystem root level

### /home (Users' Home Directories)
- **Path**: `/home`
- **Purpose**: Contains personal directories for all regular users
- **Structure**: `/home/username/` for each user (e.g., `/home/alice`, `/home/bob`)
- **Permissions**: Each user has full control over their own home directory
- **Contents**: User documents, downloads, personal configurations
- **Location**: A subdirectory under filesystem root

## Visual Comparison

| Aspect | root User | Regular User (e.g., alice) |
|--------|-----------|----------------------------|
| **Username** | `root` | `alice`, `bob`, etc. |
| **User ID** | 0 | 1000, 1001, etc. |
| **Privileges** | Full system control | Limited to own files |
| **Home Directory** | `/root` | `/home/alice` |
| **Access to others** | Can access all user directories | Cannot access `/root` or other users' homes |

| Aspect | `/root` Directory | `/home` Directory |
|--------|-------------------|-------------------|
| **Path** | `/root` | `/home` |
| **Purpose** | root user's personal space | Container for user home directories |
| **Access** | root only | Each user accesses their own |
| **Typical Contents** | Admin scripts, root's configs | User documents, media, personal configs |

## Practical Examples

### Accessing Home Directories
```bash
# As regular user 'alice'
$ cd ~              # Goes to /home/alice
$ cd /home/alice    # Same as above
$ pwd
/home/alice

# As root user
# cd ~              # Goes to /root
# cd /root          # Same as above
# pwd
/root
```

### Permission Differences
```bash
# Regular user trying to access /root
$ ls /root
ls: cannot open directory '/root': Permission denied

# Regular user trying to access another user's home
$ ls /home/bob
ls: cannot open directory '/home/bob': Permission denied

# Root user can access everything
# ls /home/alice
# ls /home/bob  
# ls /root
```

## Security Principle: "Don't use root for everyday tasks"

This is the golden rule of Linux security:
- **Use a regular user account** for browsing web, editing documents, programming
- **Use root privileges temporarily** only when needed (using `sudo`)

### How to Temporarily Gain Root Privileges
```bash
# Use sudo for single commands
$ sudo apt update
$ sudo systemctl restart nginx

# Switch to root user temporarily
$ sudo -i
# [now you are root, be careful!]
# exit

# Run a shell as root
$ sudo bash
```

## Key Takeaways

1. **root** is the **superuser account** with `/root` as its home
2. **Regular users** have limited privileges with homes in `/home/username`
3. **/root** is the administrator's personal workspace
4. **/home** is where regular users store their personal files
5. **Always use a regular user account** and elevate privileges only when necessary

This separation is fundamental to Linux's multi-user design and security model, preventing everyday users from accidentally damaging the system.


##### Tags : [[2 - Core-concepts/Linux|Linux]]