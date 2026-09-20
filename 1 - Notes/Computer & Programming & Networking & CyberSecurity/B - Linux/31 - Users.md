
## Linux User Management

![[Pasted image 20251106125842.png]]
### 1. User Concepts in Linux

#### Types of Users
- **Root User**: Superuser with UID 0, has complete system access
- **System Users**: Service accounts (UID 1-999 on most systems)
- **Regular Users**: Human users (UID 1000+)

#### Important Files
- `/etc/passwd` - User account information
- `/etc/shadow` - Encrypted passwords and aging info
- `/etc/group` - Group definitions
- `/etc/sudoers` - Sudo privileges configuration

---

### 2. Viewing User Information

#### Current User
```bash
# Who am I?
whoami

# Current user with more details
id

# Detailed user information
id username
```

#### Logged-in Users
```bash
# See who's logged in
who

# More detailed login information
w

# Last logins
last

# Check if a specific user is logged in
who | grep username
```

#### User Configuration Files
```bash
# View all users
cat /etc/passwd

# View user passwords (shadowed)
sudo cat /etc/shadow

# View groups
cat /etc/group

# Search for a specific user
grep "username" /etc/passwd
```

#### Understanding `/etc/passwd` Format
```
username:x:UID:GID:Full Name:/home/username:/bin/bash
```
- **username**: Login name
- **x**: Password placeholder (actual password in `/etc/shadow`)
- **UID**: User ID
- **GID**: Primary Group ID
- **Full Name**: GECOS field (comment)
- **/home/username**: Home directory
- **/bin/bash**: Login shell

---

### 3. User Management Commands

#### Creating Users
```bash
# Create a new user with default settings
sudo useradd john

# Create user with specific home directory
sudo useradd -m -d /home/john john

# Create user with specific UID
sudo useradd -u 1500 john

# Create user with specific group as primary
sudo useradd -g developers john

# Create user with comment/description
sudo useradd -c "John Doe - Developer" john

# useradd vs adduser (more interactive)
sudo adduser john  # Asks for password and details
```

#### Setting Passwords
```bash
# Set password for a user
sudo passwd john

# Change your own password
passwd

# Lock a user account
sudo passwd -l john

# Unlock a user account
sudo passwd -u john

# Force password change on next login
sudo passwd -e john
```

#### Modifying Users
```bash
# Change user's full name
sudo usermod -c "John Smith" john

# Change user's home directory
sudo usermod -d /new/home/john -m john

# Change user's shell
sudo usermod -s /bin/bash john

# Change user's primary group
sudo usermod -g developers john

# Add user to supplementary groups
sudo usermod -aG sudo,adm john

# Lock/disable account
sudo usermod -L john

# Unlock account
sudo usermod -U john
```

#### Deleting Users
```bash
# Delete user but keep home directory
sudo userdel john

# Delete user and home directory
sudo userdel -r john

# Delete user with home directory and mail spool
sudo userdel -r -f john
```

---

### 4. Group Management

#### Creating Groups
```bash
# Create a new group
sudo groupadd developers

# Create group with specific GID
sudo groupadd -g 2000 developers
```

#### Modifying Groups
```bash
# Add user to group
sudo usermod -aG developers john

# OR use gpasswd
sudo gpasswd -a john developers

# Remove user from group
sudo gpasswd -d john developers

# Change group name
sudo groupmod -n devteam developers

# Change group GID
sudo groupmod -g 2001 developers
```

#### Viewing Group Information
```bash
# See groups a user belongs to
groups john
id john

# See all groups
getent group

# See members of a specific group
getent group developers
```

#### Deleting Groups
```bash
# Delete a group
sudo groupdel developers
```

---

### 5. Practical User Management Examples

#### Create a Developer User
```bash
# Create user with home directory, specific shell, and add to groups
sudo useradd -m -s /bin/bash -c "Developer Account" -G developers,sudo devuser
sudo passwd devuser
```

#### Create a Service Account
```bash
# System account without login capability
sudo useradd -r -s /bin/false -d /opt/serviceapp serviceuser
```

#### Bulk User Operations
```bash
# Create multiple users from a list
for user in alice bob charlie; do
    sudo useradd -m $user
    echo "User $user created"
done

# Reset passwords for multiple users
for user in alice bob charlie; do
    echo "Setting password for $user"
    echo "${user}:newpassword" | sudo chpasswd
done
```

#### Check User Account Status
```bash
# Check if account is locked
sudo passwd -S username

# Check account expiration
sudo chage -l username

# View password aging policies
sudo grep username /etc/shadow
```

---

### 6. Sudo and Privileges

#### Granting Sudo Access
```bash
# Add user to sudo group (Ubuntu/Debian)
sudo usermod -aG sudo username

# Add user to wheel group (CentOS/RHEL)
sudo usermod -aG wheel username

# Edit sudoers file safely
sudo visudo

# Add specific user to sudoers
# Add this line to /etc/sudoers via visudo:
# username ALL=(ALL) ALL
```

#### Sudoers File Examples
```
# User can run all commands as any user
john ALL=(ALL) ALL

# User can run specific commands without password
john ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx

# Group-based sudo access
%developers ALL=(ALL) ALL
```

---

### 7. User Environment and Defaults

#### User Default Configuration
```bash
# View default user settings
useradd -D

# Change default settings
sudo useradd -D -s /bin/bash -b /home
```

#### Home Directory Setup
```bash
# Copy skeleton files to new user's home
sudo cp -r /etc/skel/. /home/newuser/
sudo chown -R newuser:newuser /home/newuser/
```

---

### 8. Security and Monitoring

#### Account Security
```bash
# Check for users with no password
sudo awk -F: '($2 == "") {print $1}' /etc/shadow

# Check for users with UID 0 (besides root)
sudo awk -F: '($3 == 0) {print $1}' /etc/passwd

# Find all users with sudo access
getent group sudo
getent group wheel
```

#### Login Monitoring
```bash
# See failed login attempts
sudo lastb

# See successful logins
last

# Current login sessions
who

# Check when user last logged in
last username
```

#### Password Policy Enforcement
```bash
# Set password expiration
sudo chage -M 90 username      # Max days
sudo chage -W 7 username       # Warning days
sudo chage -I 30 username      # Inactive days

# View current policy
sudo chage -l username
```

---

### 9. Common Troubleshooting

#### Permission Issues
```bash
# Fix home directory permissions
sudo chmod 755 /home/username
sudo chown username:username /home/username

# Fix user file ownership recursively
sudo chown -R username:username /home/username/
```

#### Login Problems
```bash
# Check if account is locked
sudo passwd -S username

# Check valid shells
cat /etc/shells

# Check if home directory exists
ls -ld /home/username
```

#### User Session Management
```bash
# See all processes by a user
ps -u username

# Kill all processes by a user
sudo pkill -u username

# Force logout user (except your own session)
sudo skill -KILL -u username
```

---

### Summary

Key user management commands:
- **View users**: `who`, `w`, `id`, `last`
- **Create users**: `useradd`, `adduser`
- **Modify users**: `usermod`, `passwd`, `chage`
- **Delete users**: `userdel`
- **Groups**: `groupadd`, `groupmod`, `groupdel`, `usermod -aG`
- **Privileges**: `visudo`, group membership

Always remember:
- Use `sudo` for user management commands
- Be careful with `-r` (remove home directory) and `-f` (force) options
- Use `visudo` instead of directly editing `/etc/sudoers`
- Test new accounts before deploying in production

---
# Users

[Unix-like](https://en.wikipedia.org/wiki/Unix-like) systems (like the one you're using) support multiple users. Each user has their own home directory, their own files, and their own permissions.

If you're like most people these days, you're the only user on your machine. It used to be more common for multiple people to share a single computer, or for multiple people to do their work on the same computer over a network.

![[Pasted image 20251106125935.png]]

## Sudo

The `sudo` keyword lets you run a command as a "superuser". It's short for ["superuser do"](https://www.linux.com/training-tutorials/linux-101-introduction-sudo/). To use it, you'll need a password with superuser privileges, which you should already have if you're the only user of your machine.

##### Tags : [[2 - Tags/Linux|Linux]]