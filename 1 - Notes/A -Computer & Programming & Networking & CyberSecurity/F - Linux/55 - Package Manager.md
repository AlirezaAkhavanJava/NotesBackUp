
A **package manager** is a tool that helps you **install, update, remove, and manage software** on your system. It automates downloading packages, resolving dependencies, and keeping software up-to-date.

---

### 🧠 Key Concepts

- **Package:** A bundle of software (program + metadata + dependencies).
    
- **Repository:** A server hosting packages.
    
- **Dependency:** Other packages your software needs to run.
    

---

### 🔀 Popular Linux Package Managers

|Distro Family|Package Manager|Commands Example|
|---|---|---|
|Debian / Ubuntu|`apt` / `dpkg`|`sudo apt update`, `sudo apt install git`|
|RedHat / CentOS / Fedora|`yum` / `dnf` / `rpm`|`sudo dnf install vim`, `sudo rpm -ivh package.rpm`|
|Arch Linux|`pacman`|`sudo pacman -Syu`, `sudo pacman -S firefox`|
|OpenSUSE|`zypper`|`sudo zypper install htop`|
|Universal|`snap`, `flatpak`|`sudo snap install code`, `flatpak install flathub org.gimp.GIMP`|

---

### 🧩 Common Package Manager Operations

|Task|Debian/Ubuntu Example|
|---|---|
|Update package list|`sudo apt update`|
|Upgrade installed packages|`sudo apt upgrade`|
|Install package|`sudo apt install package_name`|
|Remove package|`sudo apt remove package_name`|
|Search package|`apt search package_name`|
|Show info about package|`apt show package_name`|

---

### ⚙️ Notes

- Most package managers **resolve dependencies automatically**.
    
- Some (`dpkg`, `rpm`) handle **individual packages only**, no automatic dependency resolution.
    
- `apt`, `yum`, `dnf`, `pacman`, etc., are higher-level tools built on top of these lower-level managers.
    

---

# Package Managers

A package manager is a software tool that helps you install other software. Its primary functions include:

- Downloading software from official sources
- Installing software
- Updating software
- Removing software
- Managing dependencies

As a developer, you'll frequently use package managers to get access to the software you need to get your work done.

## APT (Ubuntu)

APT, or "Advanced Package Tool", is the primary package manager for Ubuntu. To be fair, you can use other package managers on Ubuntu, but APT is the default and most common.

If you're on WSL and Ubuntu, you'll be using APT. If you're on another Linux setup, I pray you already know what package manager you're using. If you're on WSL or Ubuntu, check to make sure you have APT installed by running the following command:

```bash
apt --version
```

## Brew (macOS)

There isn't a "default" package manager for macOS. The most popular (but unofficial) package manager is [Homebrew](https://brew.sh/).

If you're on macOS, and you don't have Homebrew installed, you can install it by running the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

See the [Homebrew](https://brew.sh/) site for more information if needed.



##### Tags : [[2 - Core-concepts/Linux|Linux]]