
**Gradle** is a build automation and dependency management tool, like Maven (the first lesson), but its build file is **code** (Groovy or Kotlin) instead of XML. It does the same job: download libraries, compile, test, and package your project into a `.jar`.

**Analogy:** Maven is a **printed recipe card**: a fixed format where you fill in the blanks (`pom.xml`). Gradle is a **recipe you can program**: same dishes, but you can write logic, loops, and custom steps in the recipe itself. More flexible, but more ways to make a mess.

## Same job, different file

Maven (`pom.xml`):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

Gradle (`build.gradle`, Groovy DSL):

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

Or in Kotlin DSL (`build.gradle.kts`), which is the newer default:

```kotlin
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
}
```

Same library, one line instead of five. The coordinates are identical (`group:artifact:version`), and both tools download from the same repositories (Maven Central), so libraries don't care which tool you use.

## A typical Spring Boot `build.gradle.kts`

```kotlin
plugins {
    java
    id("org.springframework.boot") version "3.4.0"
    id("io.spring.dependency-management") version "1.1.6"
}

group = "com.example"
version = "0.0.1"

java {
    toolchain { languageVersion = JavaLanguageVersion.of(21) }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.test {
    useJUnitPlatform()
}
```

(Version numbers here are examples; Spring Initializr generates current ones for you.)

## Core idea: tasks

Gradle's building block is the **task** (compile, test, jar), and tasks form a **graph** of dependencies: `build` needs `test`, which needs `compileTestJava`, which needs `compileJava`. Gradle runs only what is needed and in the right order. Maven instead has a fixed **lifecycle** of phases (`compile`, `test`, `package`).

## The Gradle Wrapper

Projects include `gradlew`, a small script that downloads the **exact Gradle version** the project needs. You don't install Gradle globally:

```bash
./gradlew build          # compile + test + package -> build/libs/app.jar
./gradlew test           # run tests
./gradlew bootRun        # start the Spring Boot app
./gradlew clean          # delete the build/ folder
./gradlew dependencies   # show the dependency tree
```

The wrapper solves "works on my machine" for build tools, so everyone, including CI servers, uses the same version. (Maven has the same idea: `mvnw`.) On Debian 13 you only need a JDK installed (`sudo apt install openjdk-21-jdk`, or whichever version Debian offers).

## Dependency scopes (called configurations)

|Gradle|Meaning|Maven equivalent|
|---|---|---|
|`implementation`|Needed to compile and run; not exposed to consumers|`compile`|
|`api`|Same, but exposed to consumers (libraries only)|`compile`|
|`runtimeOnly`|Needed only when running (JDBC drivers)|`runtime`|
|`compileOnly`|Needed only to compile (Lombok)|`provided`|
|`testImplementation`|Only for tests|`test`|

## Why Gradle is fast

- **Incremental builds:** it skips tasks whose inputs haven't changed (`UP-TO-DATE`).
- **Build cache:** reuses outputs from earlier runs, even from other machines.
- **Daemon:** a background process stays warm between builds, so you skip JVM startup.

## Maven vs Gradle

||Maven|Gradle|
|---|---|---|
|**Config**|XML (`pom.xml`), declarative|Groovy/Kotlin code|
|**Flexibility**|Rigid, conventional|Very flexible|
|**Speed**|Slower on big projects|Faster (incremental, cache, daemon)|
|**Learning curve**|Gentle, predictable|Steeper|
|**Readability**|Verbose but uniform|Concise, but can become complex|
|**Typical home**|Enterprise Java, Spring|Android (the standard), big multi-module projects, Kotlin|

Both work perfectly with Spring Boot. Many Java companies use Maven, so since you started with it, there is no need to switch. Learn Gradle well enough to read it, because you will meet it in other projects.

## Gotchas

- **Two DSLs:** `build.gradle` (Groovy) and `build.gradle.kts` (Kotlin) look similar but differ in quotes and parentheses, so copying from tutorials needs care.
- **Always use `./gradlew`, not `gradle`,** so you get the project's pinned version.
- **`compile` is gone:** old tutorials use `compile` and `testCompile`, which were removed. Use `implementation` and `testImplementation`.
- **Flexibility is a trap:** custom logic in build files can turn into unreadable "build code." Keep it simple.
- **Output folders differ:** Maven builds into `target/`, Gradle into `build/`. A Dockerfile that copies `target/app.jar` must change to `build/libs/app.jar`.
- **Gradle versions and JDK versions must be compatible:** an old Gradle can't run on a new JDK, which causes confusing errors. The wrapper helps.
- **Don't mix both** in one project; pick one.
- **Dependency conflicts:** if two libraries need different versions of a third, Gradle picks the highest by default. Inspect with `./gradlew dependencies`.




[[Java]]
[[Spring Framework]]