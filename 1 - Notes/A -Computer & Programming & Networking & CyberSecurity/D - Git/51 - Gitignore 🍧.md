

### **What is `.gitignore`?**

A `.gitignore` file tells Git **which files or directories to ignore**—meaning Git will **not track** them, so they won’t show up in commits. This is useful for files that are:

- Automatically generated (build files, logs)
    
- Environment-specific (IDE configs, OS files)
    
- Sensitive (passwords, API keys)
    

---

### **Where is it placed?**

- `.gitignore` usually lives in the **root of your repository**.
    
- You can also place **nested `.gitignore` files** in subdirectories to apply rules locally.
    

---

### **Syntax Rules**

1. **Ignore a file:**
    

```
secret.txt
```

Ignores a file named `secret.txt` in the same directory.

2. **Ignore a directory:**
    

```
logs/
```

Ignores the `logs` directory and all its content.

3. **Ignore by pattern:**
    

```
*.log
```

Ignores all files ending with `.log` anywhere in the repo.

4. **Ignore all files except one:**
    

```
*.txt
!important.txt
```

Ignores all `.txt` files but still tracks `important.txt`.

5. **Ignore files in a specific folder:**
    

```
/build/*.class
```

Ignores all `.class` files in the `/build` folder **only**, not elsewhere.

6. **Comments:**
    

```
# This is a comment
```

7. **Wildcards:**
    

- `*` → matches any number of characters except `/`
    
- `?` → matches a single character
    
- `**` → matches directories recursively
    

```
**/temp/*.tmp
```

Ignores `.tmp` files in any `temp` folder, anywhere in the repo.

---

### **Important Notes**

- `.gitignore` **only affects untracked files**. Files already tracked by Git will **still be tracked**, even if they now match `.gitignore`. To stop tracking, you must remove them:
    

```bash
git rm --cached file.txt
```

- There are **global `.gitignore` files** to ignore patterns for all repos on a system (like IDE settings).
    

---

### **Common Examples**

**Java Project**

```
# Compiled class files
*.class

# Logs
*.log

# Build directory
/build/

# IDE files
.idea/
*.iml
```

**Node.js Project**

```
# Node modules
node_modules/

# Logs
*.log

# Environment variables
.env
```

---

In short: `.gitignore` is Git’s **filter sheet**—it tells Git:

> “Hey, don’t bother tracking these files, they’re temporary, local, or sensitive.”


---

# **Ultimate .gitignore Cheat Sheet**


## **1. General Rules**

|Pattern|Meaning|
|---|---|
|`*`|Matches any number of characters except `/`|
|`?`|Matches a single character|
|`**`|Matches directories recursively|
|`/folder/`|Ignore folder only at root|
|`folder/`|Ignore folder at any depth|
|`!file.txt`|Exclude this file from being ignored|
|`# comment`|Add a comment|
|`*.ext`|Ignore all files with extension `.ext`|

---

## **2. Operating System Files**

**Windows**

```
Thumbs.db
Desktop.ini
$RECYCLE.BIN/
```

**macOS**

```
.DS_Store
.AppleDouble
.LSOverride
```

**Linux**

```
*~
.nfs*
```

---

## **3. IDE / Editor Files**

**VS Code**

```
.vscode/
*.code-workspace
```

**IntelliJ / JetBrains**

```
.idea/
*.iml
*.iws
out/
```

**Eclipse**

```
.project
.classpath
.settings/
bin/
```

**NetBeans**

```
nbproject/private/
build/
```

---

## **4. Programming Languages**

### **Java**

```
*.class
*.jar
*.war
*.ear
*.log
target/
build/
out/
```

### **Python**

```
*.pyc
*.pyo
*.pyd
__pycache__/
*.egg
*.egg-info/
dist/
build/
.env
```

### **JavaScript / Node.js**

```
node_modules/
npm-debug.log*
yarn-error.log*
dist/
.env
```

### **C / C++**

```
*.o
*.obj
*.exe
*.dll
*.so
*.dylib
*.out
```

### **Go**

```
*.exe
*.test
*.out
bin/
pkg/
```

### **Ruby**

```
*.gem
*.rbc
.bundle/
vendor/bundle/
log/
tmp/
```

### **PHP**

```
vendor/
*.log
*.cache
.env
```

### **.NET / C#**

```
bin/
obj/
*.user
*.suo
*.dll
*.exe
*.pdb
```

---

## **5. Build Tools / Package Managers**

```
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup

# Gradle
.gradle/
build/
!gradle-wrapper.jar

# npm / Yarn
node_modules/
dist/
package-lock.json
yarn.lock

# Composer (PHP)
vendor/
composer.lock
```

---

## **6. Logs, Temp Files**

```
*.log
*.tmp
*.swp
*.bak
*.old
*.orig
```

---

## **7. Secrets / Environment Files**

```
.env
.env.local
*.key
*.pem
credentials.json
```

---

## **8. Git Tricks**

- **Stop tracking a file already in Git**
    

```bash
git rm --cached filename
```

- **Global ignore** (for files like OS stuff everywhere)
    

```bash
git config --global core.excludesfile ~/.gitignore_global
```

- **Nested ignores**: place `.gitignore` in subfolders to apply only there.
    

---

## **9. Advanced Patterns**

```
# Ignore everything in folder except one file
logs/*
!logs/keep.log

# Ignore all txt except in /docs
*.txt
!/docs/*.txt

# Ignore recursively
**/temp/
**/*.bak
```

---

💡 **Tip:** You can generate ready-made `.gitignore` files for your language/project via [gitignore.io](https://www.toptal.com/developers/gitignore).

---




## ✅ Summary of “Learn Git: Gitignore” (Boot.dev)

- The lesson is part of Boot.dev’s full Git course which aims to teach not just the basic Git commands but also the inner workings (“plumbing”) of Git. ([Boot.dev](https://www.boot.dev/courses/learn-git?utm_source=chatgpt.com "Learn Git [Full Course]"))
    
- In this specific lesson, the focus is on the `.gitignore` file: how it works, when and how to use it, and its role in version control. ([Boot.dev](https://www.boot.dev/courses/learn-git?promo=PRIME&utm_source=chatgpt.com "Learn Git [Full Course]"))
    
- It explains that `.gitignore` is a text file where you list **patterns** for files or directories you want Git to _ignore_ — meaning Git will not treat them as untracked or track changes in them. ([Boot.dev](https://www.boot.dev/lessons/65e6780d-fdde-447a-9898-b30b73793a3a?utm_source=chatgpt.com "Learn Git"))
    
- It also likely covers nuances like:
    
    - `.gitignore` only affects files **not yet tracked** by Git.
        
    - If you already committed a file and later add it to `.gitignore`, Git will still track it unless you remove it from tracking (e.g. using `git rm --cached`).
        
    - Using wildcard patterns (`*`, `**`), directory ignores, exceptions (`!pattern`), etc.
        



##### Tags : [[0 - Git 🍋‍🟩]]