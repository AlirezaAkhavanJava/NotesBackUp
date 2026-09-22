
## `pom.xml` — The Maven Project Object Model

`pom.xml` (**P**roject **O**bject **M**odel) is the heart of any Maven-based Spring Boot project. It declares:
- What your project **is** (name, version, packaging)
- What it **depends on** (libraries)
- How it **builds** (plugins, Java version)
- Where it **gets dependencies from** (repositories)

Think of it as: **`package.json` for Java**, but far more powerful and structured.

---

## 1. Minimal Valid `pom.xml`

Every POM must have these four elements:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0.0</version>
</project>
```

### The coordinates (GAV)

| Element | Meaning | Example |
|---|---|---|
| `groupId` | Organization / package namespace | `com.example` |
| `artifactId` | Project name (the JAR name) | `my-app` |
| `version` | Project version | `1.0.0`, `1.0.0-SNAPSHOT` |
| `packaging` | Build output type | `jar` (default), `war`, `pom` |

These three (`groupId:artifactId:version`) uniquely identify your project — called **GAV coordinates**.

---

## 2. Full Spring Boot `pom.xml` (Annotated)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <!-- ① POM model version — always 4.0.0 -->
    <modelVersion>4.0.0</modelVersion>

    <!-- ② Parent POM: inherits defaults + dependency management -->
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
        <relativePath/> <!-- look up in repo, not locally -->
    </parent>

    <!-- ③ Project coordinates -->
    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>my-app</name>
    <description>Demo Spring Boot application</description>

    <!-- ④ Properties: reusable variables -->
    <properties>
        <java.version>21</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <mybatis.version>3.0.3</mybatis.version>
    </properties>

    <!-- ⑤ Dependencies: what your app needs -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <!-- ⑥ Build configuration: plugins -->
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```

---

## 3. Part-by-Part Breakdown

### ① `<modelVersion>`
Always `4.0.0`. Never change it.

### ② `<parent>` — Inheritance

Spring Boot's **`spring-boot-starter-parent`** is a special POM that gives you:

| Benefit | What it does |
|---|---|
| **Dependency management** | Pre-defines versions for 1000+ libraries — you omit `<version>` in children |
| **Plugin management** | Pre-configures `maven-compiler-plugin`, `maven-surefire-plugin`, etc. |
| **Property defaults** | Sets `java.version`, encoding, resource filtering |
| **Sensible configs** | JAR packaging, plugin versions pinned |

Because of the parent, you can write:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- no <version> needed! -->
</dependency>
```

**Alternative (when you can't use the parent):** import a BOM instead:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>3.3.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### ③ Coordinates
Covered above. Note: `version` ending in `-SNAPSHOT` means "in development."

### ④ `<properties>` — Variables

Define once, reuse with `${...}` anywhere:

```xml
<properties>
    <java.version>21</java.version>
    <lombok.version>1.18.32</lombok.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
    </dependency>
</dependencies>
```

Built-in variables:
| Variable | Meaning |
|---|---|
| `${project.version}` | This project's version |
| `${project.artifactId}` | This project's artifactId |
| `${java.version}` | Java version (recognized by parent) |
| `${project.basedir}` | Project root directory |
| `${env.HOME}` | Environment variable |

### ⑤ `<dependencies>` — The Core

Each `<dependency>` has four key parts:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>   <!-- who makes it -->
    <artifactId>spring-boot-starter-web</artifactId> <!-- what it is -->
    <version>3.3.0</version>                       <!-- optional if managed -->
    <scope>compile</scope>                         <!-- when it's available -->
</dependency>
```

#### Dependency Scopes

| Scope | Available at compile | At runtime | In tests | Packaged in JAR |
|---|---|---|---|---|
| `compile` (default) | ✅ | ✅ | ✅ | ✅ |
| `provided` | ✅ | ✅ | ✅ | ❌ (e.g. servlet API) |
| `runtime` | ❌ | ✅ | ✅ | ✅ (e.g. JDBC drivers) |
| `test` | ❌ | ❌ | ✅ | ❌ (e.g. JUnit) |
| `system` | ✅ | ✅ | ✅ | ❌ (avoid — use local repo) |
| `import` | — | — | — | Only for BOMs in `<dependencyManagement>` |

#### Optional dependencies

```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>my-lib</artifactId>
    <version>1.0.0</version>
    <optional>true</optional>   <!-- consumers must add it themselves -->
</dependency>
```

#### Exclusions — remove transitive deps

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<!-- Now you can add spring-boot-starter-jetty instead -->
```

### ⑥ `<dependencyManagement>` — Centralized Version Control

Declares versions **without adding** the dependency. Children inherit the version when they declare the dependency.

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.17.0</version>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <!-- version comes from dependencyManagement -->
    </dependency>
</dependencies>
```

**This is the #1 way to fix version conflicts** in multi-module projects.

### ⑦ `<build>` — Plugins & Resources

```xml
<build>
    <!-- Output JAR name -->
    <finalName>my-app</finalName>

    <!-- Where source/resources live (defaults shown) -->
    <sourceDirectory>src/main/java</sourceDirectory>
    <resources>
        <resource>
            <directory>src/main/resources</directory>
            <filtering>true</filtering>  <!-- replace ${...} in files -->
        </resource>
    </resources>

    <plugins>
        <!-- Spring Boot fat JAR / executable JAR -->
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <mainClass>com.example.MyApp</mainClass>
            </configuration>
        </plugin>

        <!-- Java compiler -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <configuration>
                <source>21</source>
                <target>21</target>
            </configuration>
        </plugin>
    </plugins>
</build>
```

---

## 4. Common Spring Boot Starters (Copy-Paste Reference)

```xml
<!-- Web / REST -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<!-- JPA + Hibernate -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- MongoDB -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>

<!-- Security -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- Validation (Jakarta Bean Validation) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>

<!-- Thymeleaf -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>

<!-- Actuator -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<!-- WebFlux (reactive) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>

<!-- Testing -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- DevTools (hot reload) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>

<!-- Lombok -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

**Databases:**
```xml
<!-- MySQL -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- PostgreSQL -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- H2 (in-memory) -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

---

## 5. How Maven Resolves Dependencies

1. Reads your `pom.xml`.
2. Downloads the parent POM → inherits versions.
3. Downloads each dependency and its **transitive** dependencies.
4. Stores them in your **local repo** (`~/.m2/repository`).
5. Builds a dependency tree.

**Conflict resolution:** Maven uses **"nearest wins"** — the shortest path to a version in the dependency tree takes priority. When in doubt:

```bash
mvn dependency:tree
```

Output:
```
com.example:my-app:jar:1.0.0
├─ org.springframework.boot:spring-boot-starter-web:jar:3.3.0
│  ├─ org.springframework.boot:spring-boot-starter:jar:3.3.0
│  └─ ...
└─ com.fasterxml.jackson.core:jackson-databind:jar:2.17.0
```

Force a version explicitly:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.17.0</version>  <!-- wins over transitive -->
        </dependency>
    </dependencies>
</dependencyManagement>
```

---

## 6. Multi-Module POMs (Brief)

**Parent POM** (`packaging=pom`):
```xml
<packaging>pom</packaging>
<modules>
    <module>common</module>
    <module>api</module>
    <module>web</module>
</modules>
```

**Child module:**
```xml
<parent>
    <groupId>com.example</groupId>
    <artifactId>my-parent</artifactId>
    <version>1.0.0</version>
</parent>
<artifactId>api</artifactId>
```

Child inherits dependencies, plugin config, and properties from parent. Shared deps go in the parent's `<dependencies>`; version-only declarations go in `<dependencyManagement>`.

---

## 7. Useful Lifecycle & Commands

| Command | What it does |
|---|---|
| `mvn clean` | Delete `target/` |
| `mvn compile` | Compile sources |
| `mvn test` | Run tests |
| `mvn package` | Build JAR/WAR into `target/` |
| `mvn install` | Install into local repo (`~/.m2`) |
| `mvn verify` | Run integration tests + package |
| `mvn spring-boot:run` | Run app via Boot plugin |
| `mvn dependency:tree` | Show full dep tree |
| `mvn dependency:analyze` | Find unused/undeclared deps |
| `mvn versions:display-dependency-updates` | Show newer versions |
| `mvn clean package -DskipTests` | Build without running tests |
| `mvn help:effective-pom` | See fully merged POM |

Maven lifecycle order: **validate → compile → test → package → verify → install → deploy**

---

## 8. Complete Realistic Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>bookstore</artifactId>
    <version>1.0.0</version>
    <name>bookstore</name>
    <description>Bookstore REST API</description>

    <properties>
        <java.version>21</java.version>
        <jjwt.version>0.12.5</jjwt.version>
    </properties>

    <dependencies>
        <!-- Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- JPA + MySQL -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Security + JWT -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>${jjwt.version}</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

---

## Key Takeaways

1. **`pom.xml` = project identity + dependencies + build config.**
2. **Always use `spring-boot-starter-parent`** — you get managed versions for free.
3. **Omit `<version>`** for Spring-managed dependencies; specify it only for third-party libs.
4. **Use `<properties>`** to centralize versions.
5. **Use `<dependencyManagement>`** to pin versions across modules.
6. **Understand scopes** — `test`, `runtime`, `provided`, `compile` matter.
7. **Exclusions** break unwanted transitive deps.
8. **`mvn dependency:tree`** is your debugging best friend for version conflicts.
9. **Never edit `~/.m2` manually** — let Maven manage it.

Master this file and you control everything about how your Spring Boot app builds, runs, and ships.

[[Java]]
[[0 - Spring Framework]]
[[1 - Maven 👻]]