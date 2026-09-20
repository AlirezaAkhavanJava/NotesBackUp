Date : 2025-09-04


# Gradle Full Tutorial

Gradle is an open-source build automation tool designed for flexibility and performance, widely used for Java, Kotlin, Android, and other projects. It uses a Groovy or Kotlin-based Domain Specific Language (DSL) for build scripts, offering a more concise and programmable alternative to XML-based tools like Maven. This tutorial covers Gradle from beginner to advanced levels, with practical examples and features up to Java 25 (September 2025). It includes recent updates from Gradle 8.14 and Declarative Gradle EAP (Early Access Preview).

---

## Phase 1: Getting Started with Gradle

### What is Gradle?

Gradle automates building, testing, and deploying software through build scripts. It supports multi-project builds, dependency management, and a rich plugin ecosystem. Key features include:

- **Groovy/Kotlin DSL**: Write build scripts in Groovy or Kotlin.
- **Incremental Builds**: Only rebuilds changed files for faster builds.
- **Build Cache**: Reuses task outputs to improve performance.
- **Gradle Wrapper**: Ensures consistent Gradle versions across environments.

### Installing Gradle

1. **Download Gradle**: Get the latest version (e.g., 8.14 as of Dec 2024) from [gradle.org/downloads](https://gradle.org/downloads). Choose the binary distribution (`gradle-8.14-bin.zip`).
2. **Extract**: Unzip to a folder (e.g., `C:\Gradle` or `/opt/gradle`).
3. **Set Environment Variables**:
    - Add `GRADLE_HOME` (e.g., `C:\Gradle\gradle-8.14`).
    - Add `$GRADLE_HOME/bin` to `PATH`.
4. **Verify Installation**: Run `gradle --version` in a terminal.
    
    ```
    Gradle 8.14
    JVM: 21.0.2 (OpenJDK)
    ```
    

**Alternative**: Use SDKMAN! (`sdk install gradle 8.14`) or Homebrew (`brew install gradle`) for easier installation on macOS/Linux.

### Creating a Gradle Project

Use the `gradle init` command to set up a project.

**Example: Initialize a Java Application**

```bash
mkdir my-gradle-app
cd my-gradle-app
gradle init --type java-application --dsl groovy --test-framework junit-jupiter --package com.example
```

**Generated Structure**:

```
my-gradle-app/
├── gradle/
│   ├── wrapper/
│   │   ├── gradle-wrapper.jar
│   │   └── gradle-wrapper.properties
├── gradlew
├── gradlew.bat
├── settings.gradle
└── app/
    ├── build.gradle
    └── src/
        ├── main/
        │   └── java/
        │       └── com/example/
        │           └── App.java
        └── test/
            └── java/
                └── com/example/
                    └── AppTest.java
```

**Key Files**:

- **settings.gradle**: Defines project name and subprojects (`rootProject.name = 'my-gradle-app'`).
- **build.gradle**: Configures tasks, plugins, and dependencies.
- **gradlew**: Gradle Wrapper script for consistent builds.

**Example: settings.gradle**

```groovy
rootProject.name = 'my-gradle-app'
include 'app'
```

**Example: app/build.gradle**

```groovy
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.google.guava:guava:33.3.0-jre'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
}

application {
    mainClass = 'com.example.App'
}
```

**Key Points**:

- Use `java` plugin for Java projects, `application` plugin for executable JARs.
- `mavenCentral()` adds Maven Central for dependency resolution.
- Run `./gradlew build` to compile, test, and package the app.

**Run the App**:

```bash
./gradlew run
```

**Output** (default `App.java`):

```
Hello, World!
```

---

## Phase 2: Core Concepts

### Gradle Build Lifecycle

1. **Initialization**: Reads `settings.gradle` to determine projects.
2. **Configuration**: Configures tasks and dependencies in `build.gradle`.
3. **Execution**: Runs selected tasks (e.g., `build`, `run`).

### Tasks

Tasks are units of work (e.g., compile code, run tests). Use `./gradlew tasks` to list available tasks.

**Example: Custom Task**

```groovy
task hello {
    doLast {
        println 'Hello, Gradle!'
    }
}
```

**Run**:

```bash
./gradlew hello
```

**Output**:

```
Hello, Gradle!
```

### Dependencies

Dependencies are managed in the `dependencies` block. Common configurations:

- `implementation`: For runtime and compile-time dependencies.
- `testImplementation`: For test dependencies.

**Example: Add OkHttp Dependency**

```groovy
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
```

### Plugins

Plugins extend Gradle’s functionality. Apply them in `build.gradle`.

**Example: Apply Checkstyle Plugin**

```groovy
plugins {
    id 'checkstyle'
}
```

**Key Points**:

- Use `plugins { id 'plugin-id' version 'version' }` for community plugins.
- Run `./gradlew checkstyleMain` to enforce code style.

---

## Phase 3: Building a Java Application

### Creating an Executable JAR

Modify `build.gradle` to create a runnable JAR with dependencies.

**Example: Fat JAR**

```groovy
jar {
    manifest {
        attributes 'Main-Class': 'com.example.App'
    }
    from {
        configurations.runtimeClasspath.collect { it.isDirectory() ? it : zipTree(it) }
    }
}
```

**Build and Run**:

```bash
./gradlew build
java -jar app/build/libs/my-gradle-app.jar
```

**Output**:

```
Hello, World!
```

### Running Tests

The `java` plugin adds a `test` task using JUnit.

**Example: Test Class (src/test/java/com/example/AppTest.java)**

```java
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class AppTest {
    @Test
    void testApp() {
        assertTrue(true);
    }
}
```

**Run Tests**:

```bash
./gradlew test
```

**Key Points**:

- Tests are in `src/test/java`.
- Use `./gradlew test` to run tests and generate reports in `app/build/reports/tests`.

---

## Phase 4: Advanced Gradle Features

### Multi-Project Builds

Gradle supports modular projects with subprojects.

**Example: Multi-Project Structure**

```
my-gradle-app/
├── settings.gradle
├── app/
│   └── build.gradle
├── library/
│   └── build.gradle
```

**settings.gradle**:

```groovy
rootProject.name = 'my-gradle-app'
include 'app', 'library'
```

**library/build.gradle**:

```groovy
plugins {
    id 'java-library'
}

dependencies {
    implementation 'com.google.guava:guava:33.3.0-jre'
}
```

**app/build.gradle**:

```groovy
plugins {
    id 'application'
}

dependencies {
    implementation project(':library')
}
```

**Key Points**:

- Use `include` in `settings.gradle` to add subprojects.
- Reference subprojects with `project(':subproject-name')`.

### Build Cache and Incremental Builds

Enable the build cache to reuse task outputs:

```groovy
buildCache {
    local {
        enabled = true
    }
}
```

Run with cache:

```bash
./gradlew build --build-cache
```

**Key Points**:

- Incremental builds skip unchanged tasks.
- Build cache stores task outputs for reuse across builds.

### Build Scans

Generate detailed build reports with `--scan`.

**Example**:

```bash
./gradlew build --scan
```

**Key Points**:

- Build Scans provide insights into task execution and dependencies.
- Accept Gradle’s Terms of Service to publish scans.

---

## Phase 5: Recent Updates (Up to 2025)

### Gradle 8.14 (Dec 2024)

- **Configuration Cache Improvements**: Reduced cache file size and faster loading times.
- **Declarative Gradle (EAP)**: Supports testing, list/file support, and new IDE integrations.
- **Dependency Management**: Enhanced supply chain security with GitHub collaboration.

### Declarative Gradle (EAP)

A new way to write build files with a declarative syntax, reducing boilerplate.

**Example: Declarative Build File**

```kotlin
gradle {
    javaApplication {
        mainClass = "com.example.App"
        dependencies {
            implementation("com.google.guava:guava:33.3.0-jre")
        }
    }
}
```

**Key Points**:

- Available in Gradle 8.14 EAP.
- Simplifies build scripts for beginners.

---

## Phase 6: Concurrent Builds with Virtual Threads

Use Java 21+ virtual threads for concurrent task execution or testing.

**Example: Concurrent Test Execution**

```groovy
test {
    useJUnitPlatform()
    maxParallelForks = 4
}
```

**Example: Custom Concurrent Task**

```groovy
task concurrentTask {
    doLast {
        def executor = Executors.newVirtualThreadPerTaskExecutor()
        try {
            (1..3).each { i ->
                executor.submit {
                    println "Task $i running in thread ${Thread.currentThread().name}"
                }
            }
        } finally {
            executor.close()
        }
    }
}
```

**Run**:

```bash
./gradlew concurrentTask
```

**Output**:

```
Task 1 running in thread VirtualThread[#1]
Task 2 running in thread VirtualThread[#2]
Task 3 running in thread VirtualThread[#3]
```

**Key Points**:

- Virtual threads (Java 21+) improve concurrency for I/O-bound tasks.
- Configure `maxParallelForks` for parallel test execution.

---

## Java Features Up to Java 25 for Gradle

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify task definitions.
        
        ```groovy
        tasks.register('hello') { doLast { println 'Hello, Gradle!' } }
        ```
        
    - **Streams**: Process task outputs.
        
        ```groovy
        configurations.runtimeClasspath.files.stream().map { it.name }.forEach { println it }
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Use `module-info.java` for modular projects.
        
        ```groovy
        java {
            modularity.inferModulePath = true
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner code in build scripts.
        
        ```groovy
        var guava = 'com.google.guava:guava:33.3.0-jre'
        dependencies { implementation guava }
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for immutable configuration objects.
        
        ```java
        record BuildConfig(String mainClass, String version) {}
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```groovy
        if (task instanceof JavaCompile jc) {
            jc.options.encoding = 'UTF-8'
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent task execution (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel tasks.
        
        ```groovy
        import java.util.concurrent.StructuredTaskScope
        task structuredTask {
            doLast {
                new StructuredTaskScope.ShutdownOnFailure().withCloseable { scope ->
                    def future1 = scope.fork { 'Task 1' }
                    def future2 = scope.fork { 'Task 2' }
                    scope.join()
                    println "${future1.get()}, ${future2.get()}"
                }
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify utility methods in build scripts.
        
        ```groovy
        implicit class BuildUtils {
            static void addDependency(String dep) {
                dependencies { implementation dep }
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate build configurations.
        
        ```java
        class BuildConfig {
            BuildConfig(String mainClass) {
                this.mainClass = mainClass
                if (mainClass.isEmpty()) throw new IllegalArgumentException('Main class cannot be empty')
            }
        }
        ```
        

---

## Best Practices

1. **Use the Gradle Wrapper**: Ensure consistent builds with `./gradlew`.
2. **Enable Build Cache**: Improve performance with `--build-cache`.
3. **Use Plugins**: Apply `java`, `application`, or community plugins for common tasks.
4. **Modularize Projects**: Use multi-project builds for large applications.
5. **Test with JUnit**:
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    
6. **Publish Build Scans**: Use `./gradlew build --scan` for debugging.

**Related Library: Gradle TestKit**  
For testing Gradle plugins:

```groovy
dependencies {
    testImplementation 'org.gradle:gradle-testkit:8.14.0'
}
```

---

## Real-World Applications

- **Java Applications**: Build, test, and package JARs.
- **Android Apps**: Manage dependencies and build APKs.
- **Microservices**: Use multi-project builds for modular services.
- **CI/CD**: Integrate with Jenkins, Travis CI, or GitHub Actions.

---

## Conclusion

Gradle is a powerful, flexible build tool for Java and other ecosystems. Start with `gradle init` for simple projects, use plugins and dependencies for advanced features, and leverage build cache and virtual threads for performance. Recent updates in Gradle 8.14 and Declarative Gradle EAP enhance performance and usability. Java 25 features like virtual threads and implicit classes make Gradle builds more scalable and concise.

**Resources**:

- [Gradle Guides](https://gradle.org/guides/)[](https://gradle.org/guides/)
- [Gradle User Manual](https://docs.gradle.org/current/userguide/userguide.html)[](https://docs.gradle.org/current/userguide/userguide.html)
- [Spring Gradle Guide](https://spring.io/guides/gs/gradle/)[](https://spring.io/guides/gs/gradle/)



##### *Tags : [[Java]]