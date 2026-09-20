
I'll explain `chmod` and `ls -l` for managing file permissions in Linux/Unix systems.

## Understanding `ls -l` Output

When you run `ls -l`, you see output like this:
```
-rwxr-xr-x 1 user group 2048 Jan 15 10:30 script.sh
drwxr-xr-x 2 user group 4096 Jan 15 10:25 documents/
-rw-r--r-- 1 user group 1024 Jan 15 10:20 file.txt
```

The first character indicates the file type:
- `-` = Regular file
- `d` = Directory
- `l` = Symbolic link

The next 9 characters represent permissions in three groups of three:

```
rwx r-x r-x
│││ │││ │││
│││ │││ │└─ Others: read, execute
│││ │││ └── Others: write (no)
│││ ││└──── Others: execute
│││ │└───── Group: read, execute
│││ └────── Group: write (no)
││└──────── Group: execute
│└───────── Owner: write
└────────── Owner: execute
```

## Understanding Permission Symbols

- **r** = Read (4)
- **w** = Write (2) 
- **x** = Execute (1)
- **-** = No permission

## Using `chmod` to Change Permissions

### Symbolic Method
```bash
# Syntax: chmod [who][operator][permissions] filename

# Add execute permission for owner
chmod u+x script.sh

# Remove write permission for group and others
chmod go-w file.txt

# Set read/write for owner, read for group and others
chmod u=rw,go=r file.txt

# Add execute for all users
chmod a+x script.sh

# Remove read permission for others
chmod o-r file.txt
```

**Operators:**
- `+` Add permission
- `-` Remove permission  
- `=` Set exact permission

**Who:**
- `u` User (owner)
- `g` Group
- `o` Others
- `a` All (equivalent to ugo)

### Numeric (Octal) Method
```bash
# Syntax: chmod [octal] filename

# 755: rwxr-xr-x
chmod 755 script.sh

# 644: rw-r--r--
chmod 644 file.txt

# 700: rwx------ (only owner)
chmod 700 secret.txt

# 777: rwxrwxrwx (everyone all permissions)
chmod 777 shared_file

# 600: rw------- (only owner read/write)
chmod 600 private.txt
```

### Common Permission Scenarios

```bash
# Make script executable
chmod +x script.sh

# Secure private file (only owner can read/write)
chmod 600 private.txt

# Shared directory (read/execute for all)
chmod 755 shared_directory/

# Collaborative directory (read/write/execute for group)
chmod 775 team_project/

# Remove execute from all files recursively
chmod -R a-x directory/

# Set default permissions for new files (umask)
umask 022  # Files: 644, Directories: 755
```

### Recursive Permission Changes
```bash
# Change permissions recursively for directory and contents
chmod -R 755 /path/to/directory

# Remove write permission for group/others recursively
chmod -R go-w /path/to/directory
```

## Special Permissions

```bash
# SetUID (s) - runs as file owner
chmod u+s program

# SetGID (s) - runs as file group  
chmod g+s program

# Sticky bit (t) - only owner can delete in directory
chmod +t /shared/directory
```

## Best Practices

1. **Be careful with 777** - it gives everyone full access
2. **Use 755 for executables** and directories
3. **Use 644 for regular files**
4. **Avoid using `chmod -R 777`** on important directories
5. **Test permissions** before applying recursively

This covers the essentials of file permissions using `chmod` and `ls -l`!
##### Tags : [[2 - Tags/Linux|Linux]]