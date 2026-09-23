

We've been writing `pom.xml` references and `./mvnw` commands throughout previous tutorials without ever formally explaining Maven itself. Let's fix that — Maven is the tool that turns your Java source files into a runnable Spring Boot app, manages every library you depend on, and runs your tests. Foundational, and worth understanding properly rather than treating as magic.

---

## 1. What Maven Is

**Maven** is a **build automation and dependency management tool** for Java projects. Before Maven (and its predecessor, Ant), Java developers manually downloaded `.jar` files, tracked versions by hand, and wrote custom scripts to compile/package/test. Maven replaced all of that with:

1. **A standard project structure** — every Maven project looks the same, so any Java developer can open any Maven project and immediately know where things live
2. **A declarative dependency system** — you _declare_ what libraries you need; Maven downloads them and their own dependencies automatically
3. **A standardized build lifecycle** — `compile`, `test`, `package` mean the same thing in every Maven project, ever

The entire configuration lives in one file at your project root: **`pom.xml`** (Project Object Model).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>library-app</artifactId>
    <version>1.0.0</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
    </parent>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <!-- declared here -->
    </dependencies>
</project>
```

### The coordinates — `groupId`, `artifactId`, `version`

Every Maven project (and every dependency you pull in) is uniquely identified by three values, often called **GAV**:

|Coordinate|Meaning|Example|
|---|---|---|
|`groupId`|Organization/namespace (usually reversed domain)|`com.example`|
|`artifactId`|The project/library's name|`library-app`|
|`version`|Which version|`1.0.0`|

This is exactly how Maven finds the _correct_ library among thousands with similar names — `org.springframework.boot:spring-boot-starter-web:3.3.0` is globally unambiguous.

---

## 2. The Standard Project Structure

Maven enforces **convention over configuration** — follow the expected folder layout, and you never have to tell Maven where anything is:

```
library-app/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/           ← your application code
    │   │   └── com/example/library/
    │   │       ├── LibraryApplication.java
    │   │       ├── book/
    │   │       └── loan/
    │   └── resources/       ← config files, templates
    │       ├── application.properties
    │       └── templates/
    └── test/
        ├── java/            ← test code, mirrors main/java structure
        │   └── com/example/library/
        │       └── book/
        │           └── BookServiceTest.java
        └── resources/        ← test-only config
            └── application-test.properties
```

Notice `src/test/java` mirrors `src/main/java`'s package structure — a test for `book/BookService.java` lives at the same package path under `test/`. This convention means Maven (and your IDE) automatically knows which tests correspond to which production code.

---

## 3. Dependency Management — What Dependencies Are

A **dependency** is an external library your project needs to compile and run — code someone else wrote that you don't want to rewrite. Spring Boot itself, the PostgreSQL driver, Lombok, JUnit — all dependencies.

### Declaring a dependency

```xml
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
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

You'll notice most Spring Boot dependencies **don't specify a `<version>`** — that's because of the `<parent>` we saw earlier (`spring-boot-starter-parent`), which pins compatible versions for the entire Spring ecosystem. This is one of Spring Boot's biggest conveniences: you never have to figure out "does Spring Web 3.3.0 work with Spring Data JPA 3.3.0?" — the parent guarantees compatibility.

### What Maven actually does with a dependency

When you run a build, Maven:

1. Reads `spring-boot-starter-web` from your `pom.xml`
2. Checks your **local repository** (`~/.m2/repository` on your Debian machine) — do I already have it?
3. If not, downloads it from a **remote repository** (Maven Central by default)
4. Downloads that library's _own_ dependencies too — this is **transitive dependency resolution**

### Transitive dependencies — the important concept

`spring-boot-starter-web` itself depends on Tomcat, Jackson, Spring MVC, and more. You never declare those explicitly — Maven pulls in the entire dependency tree automatically. This is _why_ Spring Boot "starters" exist — `spring-boot-starter-web` is a curated bundle of everything you typically need for a web app, so you write one `<dependency>` block instead of fifteen.

See the full resolved tree:

```bash
./mvnw dependency:tree
```

This prints every direct **and transitive** dependency — genuinely useful when debugging version conflicts (two libraries pulling in different versions of the same transitive dependency).

### Dependency scope — controls _when_ a dependency is available

|Scope|Available during|Example use|
|---|---|---|
|`compile` (default)|compile, test, and runtime — packaged into final jar|Most regular dependencies|
|`runtime`|test and runtime, **not** compile|JDBC drivers (you code against JPA interfaces, not the driver directly)|
|`test`|test only, never shipped in the final jar|JUnit, Mockito, `spring-boot-starter-test`|
|`provided`|compile and test, **not** packaged (assumed provided by the environment)|Servlet API in old-style WAR deployments|

Getting scope right matters for build size and correctness — shipping test libraries into your production jar is a common beginner mistake that scope prevents.

### Where dependencies are hosted — repositories

|Repository type|What it is|
|---|---|
|**Local** (`~/.m2/repository`)|Your machine's cache — checked first, always|
|**Central** (Maven Central)|The default public repository — most open-source Java libraries live here|
|**Remote/private**|Company-internal repositories (Nexus, Artifactory) for proprietary code|

You can browse Maven Central at [mvnrepository.com](https://mvnrepository.com/) to find exact `groupId`/`artifactId`/`version` coordinates to paste into your `pom.xml` — this is genuinely how most Java devs discover dependency coordinates day-to-day.

---

## 4. The Build Lifecycle, Phases, and Goals

This is the part that confuses people most, because the terminology is precise and layered. Let's build it up carefully.

### Three separate lifecycles

Maven actually has **three independent lifecycles**, though 95% of the time you're using the first one:

|Lifecycle|Purpose|
|---|---|
|`default`|The main build lifecycle — compile, test, package, install, deploy|
|`clean`|Removes previously-built files|
|`site`|Generates project documentation (rarely used day-to-day)|

### The `default` lifecycle — phases, in order

A **phase** is a named stage in the build process. Phases run **in order**, and — critically — running a later phase automatically runs every phase before it:

```
validate → compile → test → package → verify → install → deploy
```

|Phase|What happens|
|---|---|
|`validate`|Checks the project structure/`pom.xml` is correct|
|`compile`|Compiles `src/main/java` → `.class` files|
|`test`|Runs unit tests from `src/test/java` (via Surefire plugin)|
|`package`|Bundles compiled code into a `.jar` (or `.war`)|
|`verify`|Runs integration tests / checks (if configured)|
|`install`|Copies the packaged jar into your **local repository** (`~/.m2`), so other local projects can depend on it|
|`deploy`|Uploads the jar to a **remote** repository, for other people/teams to use|

### The critical rule: running a phase runs everything before it

```bash
./mvnw test
```

This doesn't _just_ run tests — it runs `validate` → `compile` → `test`, in order, automatically. You never need to run `compile` manually before `test`; Maven guarantees the correct order for you.

```bash
./mvnw package
```

Runs `validate` → `compile` → `test` → `package`. This is why `mvn package` alone gives you a fully tested, compiled `.jar` — nothing extra needed.

### Goals — the actual unit of work

Here's the layer underneath phases: a **goal** is a specific task provided by a **plugin**, and each phase is _bound_ to one or more goals. When you run a phase, Maven executes whichever goal(s) are bound to it.

```
Phase: test
  └── bound goal: surefire:test  (runs JUnit tests)

Phase: package
  └── bound goal: jar:jar  (or spring-boot:repackage for Spring Boot apps)
```

You can also invoke a goal **directly**, bypassing the phase sequence, using the `plugin:goal` syntax:

```bash
./mvnw spring-boot:run          # runs the Spring Boot app directly, skips packaging
./mvnw dependency:tree          # prints the dependency tree, not part of normal lifecycle
./mvnw surefire:test            # runs just the test goal, without compile-first guarantees
```

**The distinction that matters:** phases are the _ordered pipeline_ you normally use (`mvn test`, `mvn package`); goals are the _individual actions_ plugins actually perform, which phases trigger on your behalf. Most of the time, you think in phases; goals are what's happening underneath.

---

## 5. Maven in Action — Everyday Commands

### The Maven Wrapper — always use this, not a global `mvn` install

Notice every command example uses `./mvnw`, not `mvn`. Spring Initializr generates a **Maven Wrapper** (`mvnw` / `mvnw.cmd`) with every project — a small script that downloads the _exact_ Maven version the project expects and runs it, so you never hit "works on my machine, different Maven version" bugs. On your Debian machine:

```bash
./mvnw --version    # uses the project-pinned Maven version, no global install needed
```

You genuinely don't need to `apt install maven` at all if every project you touch includes a wrapper.

### Everyday commands

```bash
# Compile only
./mvnw compile

# Run tests
./mvnw test

# Package into a runnable jar (runs tests first)
./mvnw package

# Package, skipping tests (useful for quick local iteration)
./mvnw package -DskipTests

# Clean previous build output, then rebuild
./mvnw clean package

# Run the Spring Boot app directly (dev workflow — no need to build a jar first)
./mvnw spring-boot:run

# Install into local repo (so other local Maven projects can use this as a dependency)
./mvnw install
```

### `clean` — why you'll type this constantly

```bash
./mvnw clean package
```

`clean` isn't part of the `default` lifecycle — it's its own separate lifecycle, which deletes the `target/` folder (all previous compiled classes, jars, test reports). Running `clean` before `package` guarantees you're not accidentally shipping stale compiled code from a previous build — extremely common in real workflows, to the point most developers type `clean package` together as a habit.

### Running a single test class

```bash
./mvnw test -Dtest=BookServiceTest
```

### Where the output goes

```
target/
├── classes/                      ← compiled .class files
├── test-classes/                  ← compiled test classes
├── library-app-1.0.0.jar           ← the final packaged app
└── surefire-reports/                ← test result reports (XML + plain text)
```

`target/` is regenerated on every build — this is exactly why it should always be in your `.gitignore`, never committed.

### Running the packaged jar directly (what Docker's `ENTRYPOINT` does)

```bash
java -jar target/library-app-1.0.0.jar
```

This is literally the last line of the `Dockerfile` from our Docker Compose tutorial — Maven's `package` phase is what produces the exact `.jar` that line runs.

---

## 6. How This Connects to Everything We've Built

```
./mvnw clean package
        │
        ├── validate → compile      (your Book/Loan/Member code compiles)
        │
        ├── test                    (your BookServiceTest, LoanServiceTest run)
        │
        └── package                 (produces library-app-1.0.0.jar)
                    │
                    ▼
         COPY --from=build /app/target/*.jar app.jar     ← from our Dockerfile
                    │
                    ▼
              ENTRYPOINT ["java", "-jar", "app.jar"]
```

Every Docker build we wrote in the previous tutorial runs `./mvnw clean package` internally, in the build stage, before copying the resulting jar into the lean runtime image. Maven is the layer that turns your source code into the artifact everything else (Docker, deployment, `java -jar`) actually runs.

---

## 7. Maven vs. Gradle (context, briefly)

Worth knowing the alternative exists, since you'll see both in the wild:

||Maven|Gradle|
|---|---|---|
|Config format|XML (`pom.xml`)|Groovy or Kotlin DSL (`build.gradle`)|
|Style|Declarative, rigid lifecycle|More flexible/scriptable|
|Build speed|Slower (less caching by default)|Generally faster (incremental builds, caching)|
|Learning curve|Simpler to read/predict|More powerful, steeper learning curve|

Spring Initializr lets you pick either when generating a project. **Maven is the more common default for learning and most enterprise Java shops** — a completely reasonable place to build your foundation before optionally exploring Gradle later.

---

## Quick Summary

1. **Maven** = build tool + dependency manager, driven entirely by `pom.xml`
2. **Dependencies** are declared by `groupId:artifactId:version`; Maven resolves them (and their transitive dependencies) from your local cache or Maven Central
3. **Scope** (`compile`, `runtime`, `test`, `provided`) controls _when_ a dependency is available — get this right to avoid bloated/broken builds
4. **Lifecycle → Phases → Goals**: phases (`compile`, `test`, `package`) run in order and each triggers one or more plugin **goals**; running a phase always runs every phase before it
5. Always use the project's `./mvnw` wrapper, not a global `mvn` install
6. `./mvnw clean package` is the command you'll type constantly — wipes stale output, recompiles, tests, and produces the runnable jar

---




[[Java]]
[[1 - Maven 👻]]
[[0 - Spring Framework]]