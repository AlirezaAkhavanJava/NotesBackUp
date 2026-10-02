

Maven **scopes** control **where a dependency is available** in your project: compile time, runtime, tests, etc.

Think of a scope as:

> **“When should Maven put this dependency on my classpath?”**

## The main Maven scopes

|Scope|Compile|Runtime|Tests|Packaged?|
|---|--:|--:|--:|--:|
|`compile`|✓|✓|✓|✓|
|`provided`|✓|✓*|✓|✗|
|`runtime`|✗|✓|✓|✓|
|`test`|✗|✗|✓|✗|
|`system`|✓|✓|✓|✗|
|`import`|—|—|—|—|

`compile` is the **default**.

---

# 1. `compile`

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>...</version>
</dependency>
```

Same as:

```xml
<scope>compile</scope>
```

It means:

> I need this dependency everywhere.

Available when:

```text
src/main/java
     ↓
compile ✓
     ↓
runtime ✓
     ↓
tests ✓
     ↓
package ✓
```

Most normal dependencies use this.

---

# 2. `test`

```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>...</version>
    <scope>test</scope>
</dependency>
```

Means:

> I only need this dependency for testing.

So:

```text
src/main/java       ❌
src/main/resources  ❌

src/test/java       ✓
src/test/resources  ✓
```

For example:

```java
import org.junit.jupiter.api.Test;
```

works inside:

```text
src/test/java
```

but not:

```text
src/main/java
```

This is why JUnit is normally `test`.

---

# 3. `runtime`

This one is particularly important.

```xml
<dependency>
    <groupId>org.xerial</groupId>
    <artifactId>sqlite-jdbc</artifactId>
    <version>...</version>
    <scope>runtime</scope>
</dependency>
```

Means:

> My application doesn't need this dependency to **compile**, but it needs it when **running**.

Classic example:

```text
JDBC API
   ↓
compile
   ↓
SQLite JDBC driver
   ↓
runtime
```

Your Java code might use:

```java
Connection connection = DriverManager.getConnection(...);
```

You compile against the JDBC API, while the actual database driver is needed at runtime.

---

# 4. `provided`

Means:

> I need this dependency to compile, but **something else will provide it when the application runs**.

Classic example: Servlet API in a traditional web container.

```xml
<dependency>
    <groupId>jakarta.servlet</groupId>
    <artifactId>jakarta.servlet-api</artifactId>
    <version>...</version>
    <scope>provided</scope>
</dependency>
```

Your application compiles against it:

```text
compile ✓
```

But Maven doesn't package it into your application:

```text
package ✗
```

because the server/container is expected to provide it.

### Mental model

```text
compile:
    "I need you to build my code."

runtime:
    "I need you to run my code."

provided:
    "I need you to build my code,
     but the environment will provide you."

test:
    "I only need you for tests."
```

---

# 5. `system`

This is a special/legacy scope.

It lets you point Maven directly at a JAR on your filesystem:

```xml
<scope>system</scope>
<systemPath>/some/path/library.jar</systemPath>
```

For example:

```text
/home/ethan/libs/something.jar
```

Generally **avoid this**.

Maven's whole dependency system is designed around repositories, so hardcoding local paths makes your project difficult to reproduce on another machine.

---

# 6. `import`

`import` is different from the others.

You normally see it with a **BOM**:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-dependencies</artifactId>
    <version>...</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

It doesn't mean:

> "Make this library available to my Java code."

Instead it means:

> **"Import the dependency-management rules from this POM."**

This lets Maven inherit a set of dependency versions.

---

# The important concept: transitive dependencies

Scopes also affect dependencies that come **through another dependency**.

Imagine:

```text
Your application
      │
      ▼
Library A
      │
      ▼
Library B
```

If Library A depends on Library B, Maven can automatically bring B into your project.

That's called a **transitive dependency**.

But scopes determine whether that dependency propagates.

For example, roughly:

```text
Your project
    │
    ├── compile → A
    │              │
    │              └── compile → B ✓
    │
    └── test → A
                   │
                   └── compile → B ✓
```

This is why Maven scopes aren't simply "when to download the JAR."

They're primarily about **classpath and dependency propagation**.

---

## The mental model I'd use

Think about your project as four environments:

```text
                    Maven
                      │
        ┌─────────────┼─────────────┐
        │             │             │
     COMPILE       RUNTIME         TEST
        │             │             │
   javac needs    JVM needs     test code needs
        │             │             │
        └─────────────┴─────────────┘
                      │
                   PACKAGE
```

Then remember:

```text
compile  = everywhere
test     = tests only
runtime  = runtime + tests, not compilation
provided = compilation + runtime environment, but don't package
```

For a **Spring Boot project**, you'll mostly encounter **`compile`**, **`runtime`**, and **`test`**. `provided` appears occasionally, while `system` should almost never be necessary.


[[Spring Framework]]
[[Maven]]