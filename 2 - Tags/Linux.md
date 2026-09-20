Linux is a free and open-source Unix-like operating system kernel first released by Linus Torvalds in 1991. It powers everything from smartphones (via Android) and servers to supercomputers and embedded devices. The full "Linux" experience typically refers to **GNU/Linux distributions** (distros), which combine the kernel with GNU tools, desktop environments, and package managers.

### Key Concepts
- **Kernel**: The core that manages hardware, memory, processes, and system calls.
- **Distributions**: Pre-packaged systems like:
  - **Ubuntu** (beginner-friendly, Debian-based)
  - **Fedora** (cutting-edge, Red Hat-sponsored)
  - **Arch Linux** (minimal, rolling-release for advanced users)
  - **Debian** (stable, vast repositories)
  - **Linux Mint** (Ubuntu-based with Cinnamon/MATE desktop)
- **Package Managers**:
  - `apt` (Debian/Ubuntu)
  - `dnf` (Fedora)
  - `pacman` (Arch)
  - `zypper` (openSUSE)

### Common Commands (Terminal)
```bash
# Update system (Ubuntu/Debian)
sudo apt update && sudo apt upgrade

# List files
ls -la

# Navigate directories
cd /path/to/dir
pwd  # print working directory

# File operations
cp source.txt dest.txt
mv file.txt /new/location/
rm -rf directory/  # careful!

# Process management
ps aux | grep process_name
kill PID
top  # or htop (interactive monitor)

# Permissions
chmod 755 script.sh
chown user:group file.txt
```

### Why Use Linux?
- **Free & Open Source**: Modify, distribute, audit code.
- **Stability**: Servers run for years without reboot.
- **Security**: Granular permissions, active patching.
- **Customization**: Choose desktop (GNOME, KDE, XFCE) or go CLI-only.
- **Performance**: Lightweight (e.g., Alpine Linux < 5MB).

### Getting Started
1. **Try without installing**:
   - Use **Windows Subsystem for Linux (WSL)**: `wsl --install` in PowerShell.
   - Boot from **Live USB** (e.g., Ubuntu ISO via Rufus).
2. **Dual-boot**: Install alongside Windows (backup first!).
3. **Virtual Machine**: Test in VirtualBox/VMware.

### Resources
- [linuxjourney.com](https://linuxjourney.com) – Interactive beginner tutorials
- [Arch Wiki](https://wiki.archlinux.org) – Gold standard documentation
- `man command` – Built-in manual (e.g., `man ls`)



##### [[Computer & Programming & Networking & CyberSecurity]] [[1 - Docker 🧋]]