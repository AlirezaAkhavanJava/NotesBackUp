

## Part 1: What Are Environment Variables (Generally)?

An **environment variable** is a **named value stored outside your program** that the operating system keeps for every running process. Think of it as a small key-value pair that lives in the OS and gets passed down to programs when they start.

### The Mental Model

```
Operating System
├── PATH=/usr/bin:/bin:/usr/local/bin
├── HOME=/Users/alice
├── JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home
├── USER=alice
└── ...

        │ (inherited when a process starts)
        ▼
   Your Java Program
   (can read: PATH, HOME, JAVA_HOME, USER, ...)
```

### Key Properties

| Property | Explanation |
|---|---|
| **Key-value pairs** | Both key and value are strings (e.g., `HOME=/Users/alice`) |
| **Inherited** | A child process inherits the parent's environment by default |
| **Global-ish** | Set once, visible to many programs — not tied to one program |
| **Platform-specific** | `PATH` separator is `:` on Linux/macOS but `;` on Windows |
| **Case-sensitive (usually)** | On Linux/macOS yes; on Windows mostly no |

### Why They Exist

1. **Configuration without recompiling** — change a value without touching code.
2. **Secrets** — store API keys outside source control (e.g., `OPENAI_API_KEY`).
3. **Portability** — same code runs on different machines with different values.
4. **System-wide settings** — e.g., where to find executables (`PATH`).

### Common Examples

| Variable | Purpose |
|---|---|
| `PATH` | Directories the shell searches for commands |
| `HOME` / `USERPROFILE` | User's home directory |
| `JAVA_HOME` | Where the JDK is installed |
| `TEMP` / `TMP` | Temp directory location |
| `LANG` | Locale/language settings |
| `DATABASE_URL` | Often used by web apps |

### How You Set Them

**Linux/macOS (bash/zsh):**
```bash
export MY_VAR="hello"
java MyApp
```

**Windows (cmd):**
```cmd
set MY_VAR=hello
java MyApp
```

**Windows (PowerShell):**
```powershell
$env:MY_VAR = "hello"
java MyApp
```

**One-off for a single command:**
```bash
MY_VAR=hello java MyApp
```

---

## Part 2: Environment Variables in Java

Java gives you two main ways to read them.

### 2.1 `System.getenv()` — Read Environment Variables

```java
public class EnvDemo {
    public static void main(String[] args) {

        // Get a single variable (returns null if not set)
        String home = System.getenv("HOME");
        System.out.println("HOME = " + home);

        // Get with a default fallback
        String dbUrl = System.getenv().getOrDefault(
            "DATABASE_URL", "jdbc:h2:mem:test"
        );
        System.out.println("DB = " + dbUrl);

        // Get ALL environment variables
        System.getenv().forEach((k, v) ->
            System.out.println(k + " = " + v)
        );
    }
}
```

**Signature:**
```java
public static String getenv(String name)        // single value or null
public static Map<String,String> getenv()       // entire environment
```

### 2.2 `System.getProperty()` — System Properties (Different Thing!)

This is a **common point of confusion**. Java has *two* separate mechanisms:

| | Environment Variables | System Properties |
|---|---|---|
| Set via | OS (`export FOO=bar`) | JVM flag (`-DFOO=bar`) |
| Read via | `System.getenv("FOO")` | `System.getProperty("FOO")` |
| Where stored | OS process environment | Inside the JVM |
| Portable | Platform quirks | Always the same |

```bash
java -Dmy.property=hello MyApp
```

```java
String v = System.getProperty("my.property");   // "hello"
```

**Rule of thumb:**
- **Environment variables** → external config, secrets, deployment settings.
- **System properties** → JVM-level tuning, Java-specific flags.

### 2.3 Important Java Quirks

1. **You cannot set environment variables from pure Java.**
   `System.getenv()` is read-only. There is no `System.setenv()`.
   To *set* one, you must:
   - Set it before launching the JVM, **or**
   - Use `ProcessBuilder.environment()` to control a **child** process.

2. **`ProcessBuilder` — passing env vars to a child process:**
   ```java
   ProcessBuilder pb = new ProcessBuilder("my-tool");
   pb.environment().put("MY_VAR", "hello");
   pb.start();
   ```

3. **Environment variables are captured at JVM startup** — changes made later by the OS don't affect a running JVM.

4. **Reflection hack (avoid!):** People have used reflection to modify the internal map. It's fragile and blocked by modern JVM module restrictions.

---

## Part 3: A Realistic Example

```java
package com.gex.cli;

public class Config {

    public static String getApiKey() {
        String key = System.getenv("GEX_API_KEY");
        if (key == null || key.isBlank()) {
            throw new IllegalStateException(
                "GEX_API_KEY environment variable is not set"
            );
        }
        return key;
    }

    public static String getEnv() {
        return System.getenv().getOrDefault("GEX_ENV", "development");
    }

    public static void main(String[] args) {
        System.out.println("Environment: " + getEnv());
        System.out.println("API Key present: " + (getApiKey() != null));
    }
}
```

**Run:**
```bash
export GEX_API_KEY=abc123
export GEX_ENV=production
java com.gex.cli.Config
```

**Output:**
```
Environment: production
API Key present: true
```

---

## Part 4: Best Practices

1. **Never hardcode secrets** — read them from env vars.
2. **Always provide defaults or fail fast** — don't silently proceed with `null`.
3. **Document required variables** — a `.env.example` or README section.
4. **Validate at startup** — fail early, not deep inside business logic.
5. **Don't log secrets** — sanitize before printing.
6. **Prefer libraries for large apps:**
   - Small: plain `System.getenv()`.
   - Medium: [dotenv-java](https://github.com/cdimascio/dotenv-java) for `.env` files.
   - Spring: `@Value("${MY_VAR}")` or `application.properties` with env overrides.
   - Micronaut/Quarkus: built-in config systems.

7. **Distinguish env vars from system properties** — pick one convention and stick to it.

---

## Summary

| Concept | One-liner |
|---|---|
| Environment variable | OS-level key/value passed to every process |
| Inherited? | Yes, parent → child |
| Java read API | `System.getenv("NAME")` |
| Java write API | None — set it outside the JVM, or use `ProcessBuilder` for children |
| Related concept | `System.getProperty("name")` for `-Dname=value` JVM flags |
| Typical use | Secrets, deployment config, `PATH`, `JAVA_HOME` |





[[Java]]