

We've referenced pieces of this structure across earlier tutorials (`pom.xml`, `src/main/java`, `target/`). Let's now go through **every file and folder** a Maven project generates or expects, so nothing on disk is a mystery.

---

## 1. The Full Standard Layout

This is what a freshly generated Spring Boot + Maven project (from [start.spring.io](https://start.spring.io/)) looks like:

```
library-app/
├── .mvn/
│   └── wrapper/
│       ├── maven-wrapper.properties
│       └── maven-wrapper.jar
├── mvnw
├── mvnw.cmd
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/library/
│   │   │       ├── LibraryApplication.java
│   │   │       ├── book/
│   │   │       │   ├── Book.java
│   │   │       │   ├── BookController.java
│   │   │       │   ├── BookService.java
│   │   │       │   └── BookRepository.java
│   │   │       └── shared/
│   │   │           └── config/
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── static/
│   │       └── templates/
│   └── test/
│       ├── java/
│       │   └── com/example/library/
│       │       └── book/
│       │           └── BookServiceTest.java
│       └── resources/
│           └── application-test.properties
├── target/                    (generated — never commit)
└── .gitignore
```

Let's go through every one of these, piece by piece.

---

## 2. `pom.xml` — The Root Configuration File

Already covered in depth, but here's the complete anatomy — every section, in the order Maven convention expects:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>

    <!-- Parent POM — inherits plugin/dependency version management -->
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
        <relativePath/>
    </parent>

    <!-- This project's own coordinates -->
    <groupId>com.example</groupId>
    <artifactId>library-app</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>library-app</name>
    <description>Library Management System</description>

    <!-- Reusable variables referenced elsewhere in the file -->
    <properties>
        <java.version>21</java.version>
    </properties>

    <!-- What this project needs to compile/run/test -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!-- ... -->
    </dependencies>

    <!-- Build-time tooling: compiler config, packaging plugins -->
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

### The `<build><plugins>` section — a piece we haven't detailed yet

This is where the **Spring Boot Maven Plugin** lives — it's what makes `./mvnw spring-boot:run` work, and it's _also_ what transforms a plain jar into an executable "fat jar" during `package` (bundling all dependencies inside one runnable file, instead of needing a separate classpath of 80 jars).

Without this plugin, `mvn package` would produce a jar containing only _your_ compiled classes — running it with `java -jar` would immediately fail with `ClassNotFoundException` because Spring, Tomcat, etc. wouldn't be inside it. The plugin's `repackage` goal (bound to the `package` phase automatically) is what bundles everything together.

---

## 3. `.mvn/` and `mvnw` / `mvnw.cmd` — The Maven Wrapper

We mentioned this briefly — here's the file-level detail.

```
.mvn/
└── wrapper/
    ├── maven-wrapper.properties    ← pins the exact Maven version
    └── maven-wrapper.jar            ← tiny bootstrap jar that downloads Maven itself
mvnw                                   ← shell script (Linux/macOS/Debian)
mvnw.cmd                               ← batch script (Windows)
```

`maven-wrapper.properties` contains something like:

```properties
distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.6/apache-maven-3.9.6-bin.zip
```

When you run `./mvnw` on your Debian machine for the first time, this script checks if that exact Maven version is already cached locally; if not, it downloads it automatically — before running your actual command. This is why teammates (or CI servers) never need Maven pre-installed globally, and why everyone building the same project always uses the identical Maven version, eliminating a whole class of "works on my machine" issues.

**Practical note:** always commit `.mvn/`, `mvnw`, and `mvnw.cmd` to git. Losing these means losing the guarantee of a consistent build environment.

---

## 4. `src/main/java/` — Your Application Code

This is where everything from our earlier Project Architecture tutorial actually lives on disk. One rule Maven strictly enforces: **the folder path must mirror the Java package declaration.**

```
src/main/java/com/example/library/book/Book.java
```

must contain:

```java
package com.example.library.book;

public class Book { ... }
```

Mismatch these, and the build fails immediately — this isn't a style suggestion, it's a hard compiler requirement in Java, which Maven's folder convention exists to keep consistent.

### `LibraryApplication.java` — the entry point

Sits at the **root** of your package tree (not inside any feature folder), because Spring Boot's component scanning starts from wherever this class lives and scans downward:

```java
package com.example.library;

@SpringBootApplication
public class LibraryApplication {
    public static void main(String[] args) {
        SpringApplication.run(LibraryApplication.class, args);
    }
}
```

If you put this class inside `com.example.library.book` instead of `com.example.library`, Spring would never discover your `loan` or `member` packages — component scanning only looks _downward_ from this class's package, never sideways or upward. This is a genuinely common beginner mistake worth knowing about in advance.

---

## 5. `src/main/resources/` — Configuration & Non-Code Assets

```
src/main/resources/
├── application.properties       (or application.yml)
├── static/                       ← served as-is at the web root (images, CSS, if using Thymeleaf)
└── templates/                     ← Thymeleaf HTML templates (from our UI tutorial)
```

### `application.properties`

The central config file — everything from database URLs to server port lives here:

```properties
spring.application.name=library-app

spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.datasource.username=library_user
spring.datasource.password=library_pass

spring.jpa.hibernate.ddl-auto=update
server.port=8080
```

**`application.yml` is a common alternative** — same purpose, YAML syntax instead of flat key-value pairs, often preferred once config grows large because nesting is more readable:

```yaml
spring:
  application:
    name: library-app
  datasource:
    url: jdbc:postgresql://localhost:5432/library
    username: library_user
    password: library_pass
```

Only one should exist (having both causes confusing precedence rules) — pick one convention for your project and stick with it.

### Profile-specific configuration

You'll often see `application-dev.properties`, `application-prod.properties` alongside the base file — Spring Boot merges the profile-specific file on top of the base one, activated via `spring.profiles.active=dev`. This connects directly back to the NFR we wrote in the Requirements tutorial about configuration not being hardcoded — different environments, different values, same code.

---

## 6. `src/test/` — Test Code, Mirrored Structure

```
src/test/java/com/example/library/book/BookServiceTest.java
src/test/resources/application-test.properties
```

**Critical convention:** this mirrors `src/main/java` package-for-package. A test for `book/BookService.java` belongs at `test/java/.../book/BookServiceTest.java` — same package, different source root. This lets test code access **package-private** members of the class under test (useful for testing internals without exposing them publicly), and it's how your IDE and Maven both know which tests correspond to which production code.

```java
package com.example.library.book;  // same package as Book.java

@SpringBootTest
class BookServiceTest {
    @Autowired
    private BookService bookService;

    @Test
    void shouldFindBookById() {
        // ...
    }
}
```

`src/test/resources/` holds test-only config — e.g., pointing at an in-memory H2 database instead of real PostgreSQL, so tests don't need Docker/a real DB running.

---

## 7. `target/` — Generated Output (Never Touch, Never Commit)

```
target/
├── classes/                          ← compiled src/main/java → .class files
├── test-classes/                      ← compiled src/test/java → .class files
├── generated-sources/                  ← code generated by annotation processors (e.g., Lombok, MapStruct)
├── surefire-reports/                    ← test result XML/txt reports
├── library-app-0.0.1-SNAPSHOT.jar        ← final packaged fat jar
└── maven-status/                          ← Maven's internal bookkeeping
```

Everything here is **regenerated from source on every build** — nothing in `target/` should ever be edited directly or committed to version control. This is exactly why `./mvnw clean` exists (deletes this entire folder) and why it belongs in `.gitignore`.

---

## 8. `.gitignore` — What to Exclude

A standard Spring Initializr-generated project includes this automatically:

```gitignore
target/
.idea/
*.iml
.vscode/
.DS_Store
```

`target/` is the big one — regenerated output, shouldn't be tracked. `.idea/`/`*.iml` are IntelliJ-specific project files (personal editor state, not shared project config). If you're using VS Code on Debian, `.vscode/` covers editor-specific settings too.

---

## 9. Multi-Module Projects (a preview, briefly)

As a project grows, you might split it into multiple Maven modules — each with its own `pom.xml`, coordinated by a parent:

```
library-app/                       (parent — packaging: pom)
├── pom.xml                          ← <modules> lists the children
├── library-domain/                   ← pure business logic, no Spring
│   └── pom.xml
├── library-persistence/               ← JPA entities, repositories
│   └── pom.xml
└── library-api/                        ← REST controllers, main application
    └── pom.xml
```

Parent `pom.xml`:

```xml
<packaging>pom</packaging>
<modules>
    <module>library-domain</module>
    <module>library-persistence</module>
    <module>library-api</module>
</modules>
```

This connects back to the Hexagonal Architecture idea from our Project Architecture tutorial — a multi-module setup is one concrete way to **enforce** that separation at the build level (the `library-domain` module literally cannot import Spring/JPA classes, because it has no such dependency declared in its own `pom.xml`). Not something to reach for on a learning project yet, but worth recognizing the structure when you see it in larger real-world codebases.

---

## 10. Full Annotated Tree — Everything Together

```
library-app/
├── .mvn/wrapper/                          ← Maven Wrapper internals
├── mvnw / mvnw.cmd                         ← run this, not a global `mvn`
├── pom.xml                                  ← THE config file: coordinates, deps, build plugins
├── .gitignore                                ← excludes target/, IDE files
├── src/
│   ├── main/
│   │   ├── java/com/example/library/
│   │   │   ├── LibraryApplication.java         ← entry point, must be at package root
│   │   │   ├── book/ loan/ member/               ← feature packages (package-by-feature)
│   │   │   └── shared/config/                      ← cross-cutting config classes
│   │   └── resources/
│   │       ├── application.properties               ← main config
│   │       └── application-dev.properties             ← profile-specific overrides
│   └── test/
│       ├── java/com/example/library/                  ← mirrors main/java exactly
│       └── resources/application-test.properties        ← test-only config
└── target/                                                ← generated, gitignored, never touch
```

---

## Quick Summary

1. **`pom.xml`** is the single source of truth — coordinates, dependencies, and build plugins (like the Spring Boot repackage plugin that makes your jar runnable)
2. **`src/main/java`** folder structure must exactly mirror your Java package declarations — Maven/Java enforce this strictly
3. **`LibraryApplication.java`** must sit at the top of your package tree — component scanning only looks downward from it
4. **`src/test/java`** mirrors `src/main/java` package-for-package — this is what lets test code cleanly correspond to production code
5. **`target/`** is 100% generated — always gitignored, safe to delete anytime (`./mvnw clean` does exactly that)
6. Always commit `.mvn/`, `mvnw`, `mvnw.cmd` — that's what guarantees everyone builds with the identical Maven version




[[Java]]
[[1 - Maven 👻]]
[[0 - Spring Framework]]