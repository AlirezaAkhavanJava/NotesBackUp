
A **build automation tool** is a program that automates the repetitive work required to turn your source code into a runnable/distributable application.

In Java, **Maven** and **Gradle** are the two major examples.

### The basic idea

Without a build tool, you would manually do something like:

```text
1. Download dependencies
2. Put them on the classpath
3. Compile .java files
4. Run tests
5. Process resources
6. Package .class files into a JAR
7. Maybe create documentation
8. Maybe run static analysis
9. Maybe publish the JAR
```

A build automation tool turns that into:

```bash
mvn package
```

or:

```bash
./gradlew build
# if you had a permission problem run : 
chmod +x gradlew
```

---

## What does "build" mean?

**Build** = taking your project's source code and producing some usable artifact.

For a Java application:

```text
Java source
    │
    ▼
Compile
    │
    ▼
.class files
    │
    ▼
Tests
    │
    ▼
Package
    │
    ▼
app.jar
```

The build tool coordinates all of these steps.

---

## Maven

A Maven project usually has:

```text
my-app/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/
    │   └── resources/
    └── test/
        └── java/
```

The important file is:

```text
pom.xml
```

It describes things such as:

```xml
<dependencies>
    <dependency>
        ...
    </dependency>
</dependencies>
```

and the project's build configuration.

Then:

```bash
mvn compile
```

means roughly:

```text
resolve dependencies
        ↓
compile source code
```

while:

```bash
mvn test
```

does:

```text
resolve dependencies
        ↓
compile
        ↓
run tests
```

and:

```bash
mvn package
```

does roughly:

```text
resolve dependencies
        ↓
compile
        ↓
test
        ↓
package
        ↓
target/my-app.jar
```

---

# Gradle

Gradle solves the same general problem but uses a different build model and configuration syntax.

For example:

```text
build.gradle
```

or:

```text
build.gradle.kts
```

Gradle can be used with Java, Kotlin, Android, etc.

A typical command:

```bash
./gradlew build
```

runs the project's build lifecycle.

---

# What else do they do?

This is where build tools become much more powerful.

### 1. Dependency management

Instead of manually downloading:

```text
Spring
Hibernate
JUnit
Jackson
PostgreSQL driver
Lombok
...
```

you declare them.

Maven/Gradle downloads them and their **transitive dependencies**.

```text
Your application
      │
      ├── Spring
      │     ├── dependency A
      │     └── dependency B
      │
      └── PostgreSQL driver
```

---

### 2. Compilation

They invoke the Java compiler with the appropriate configuration.

```text
.java
  ↓
javac
  ↓
.class
```

---

### 3. Testing

They can automatically run:

```text
JUnit
Mockito
integration tests
...
```

For example:

```bash
mvn test
```

---

### 4. Packaging

They can produce:

```text
.jar
.war
.zip
```

For Spring Boot:

```bash
mvn package
```

can produce:

```text
target/
└── my-application-1.0.jar
```

which you can run:

```bash
java -jar target/my-application-1.0.jar
```

---

### 5. Clean builds

You can remove previous build output:

```bash
mvn clean
```

For example:

```text
target/
├── classes/
├── test-classes/
└── my-app.jar
```

gets removed.

Then:

```bash
mvn clean package
```

essentially means:

```text
delete previous build
        ↓
build everything from scratch
```

---

# The important distinction

Don't think:

> "Maven is a dependency manager."

That's only **one part** of Maven.

Think:

> **Maven is a build automation and project management tool that includes dependency management.**

Similarly:

> **Gradle is a build automation system with dependency management and a programmable build model.**

The mental model is:

```text
                    Build Tool
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
 Dependencies      Compilation      Testing
        │              │              │
        ↓              ↓              ↓
   Maven Central     javac           JUnit
        │              │              │
        └──────────────┼──────────────┘
                       ↓
                    Packaging
                       │
                       ↓
                    app.jar
```

And for your Spring Boot projects, when you run:

```bash
mvn spring-boot:run
```

Maven is also being used to **invoke a plugin** that knows how to start your Spring Boot application.

So Maven is basically the **orchestrator of the project's build process**.


[[Java]]