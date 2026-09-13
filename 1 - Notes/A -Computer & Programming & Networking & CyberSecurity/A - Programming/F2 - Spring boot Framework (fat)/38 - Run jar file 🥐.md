
# How to Run a JAR File – Super Simple Guide  
**For:** `UltimateArcadeBoot-0.0.1-SNAPSHOT.jar`  
**Time:** November 11, 2025 – 04:51 PM (+04, Azerbaijan)

---

## Step-by-Step: Run Your JAR File

### 1. **Build the JAR** (One time)

```bash
./mvnw clean package
```

→ Output:  
`target/UltimateArcadeBoot-0.0.1-SNAPSHOT.jar`

---

### 2. **Go to the `target` folder**

```bash
cd target
```

---

### 3. **Run the JAR with a Profile**

| Profile | Command |
|--------|--------|
| **Development** | `java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev` |
| **QA** | `java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=qa` |
| **Production** | `java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod` |

**Example (dev):**
```bash
java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
```

You’ll see:
```
Tomcat started on port(s): 8080 (http)
Started UltimateArcadeBootApplication in 3.2 seconds
```

---

### 4. **Open in Browser**

Go to:  
http://localhost:8080

---

### 5. **Stop the App**

In the **same terminal**, press:

```
Ctrl + C
```

→ Clean shutdown.

---

## One-Line Command (Copy-Paste)

```bash
cd target && java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
```

---

## Requirements

- **Java 17+** installed  
  Check with:
  ```bash
  java -version
  ```
  → Should show: `openjdk 17` or higher

---

## Save This File

Create: `RUN_JAR.md`

```markdown
# How to Run JAR

1. Build:
   ./mvnw clean package

2. Run (dev):
   cd target
   java -jar UltimateArcadeBoot-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev

3. Stop:
   Ctrl + C
```

---

**Done!**  
You now know how to run **any** Spring Boot JAR file.

##### Tags : [[0 - Spring Framework]]