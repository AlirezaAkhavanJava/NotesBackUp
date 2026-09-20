

## What is Maven?

**Maven** is an open-source build automation tool primarily for Java projects. It simplifies and standardizes the build process by providing a uniform build system, dependency management, and a central repository for libraries and plugins. Maven's philosophy is **"Convention over Configuration"** and **"Don't Repeat Yourself" (DRY)**, which minimizes manual configuration and promotes reusable build logic.

**Key Features**:

- **Standardized Build Process**: Uses a declarative `pom.xml` file to define the build process.
- **Dependency Management**: Automatically downloads and manages libraries from repositories like Maven Central.
- **Plugin-Based Architecture**: Extends functionality through plugins (e.g., for compiling, testing, packaging).
- **Central Repository**: Access to a vast ecosystem of libraries and dependencies.
---

## Maven Basics

### 1. Installing Maven

- Download Maven from [maven.apache.org](https://maven.apache.org/download.cgi).
- Set up environment variables:
    - `M2_HOME`: Path to Maven installation.
    - Add `M2_HOME/bin` to `PATH`.
- Verify installation:
    
    ```bash
	mvn -version
    ```


#### Creating a project 


```bash
mvn archetype:generate -DgroupId=com.example \
                       -DartifactId=myapp \
                       -DarchetypeArtifactId=maven-archetype-quickstart \
                       -DinteractiveMode=false

```

#### Build the project 

```bash 
mvn clean install
```


#### Run the app 

```bash 
mvn exec:java -Dexec.mainClass="com.example.App"

```
### 2. Project Structure

Maven enforces a standard directory structure:

```
my-project/
├── src/
│   ├── main/
│   │   ├── java/       # Java source code
│   │   ├── resources/  # Configuration files, properties
│   ├── test/
│   │   ├── java/       # Test source code
│   │   ├── resources/  # Test resources
├── pom.xml             # Project Object Model file
```

### 3. The POM File (`pom.xml`)

The **POM (Project Object Model)** file is the heart of a Maven project. It defines the project’s configuration, dependencies, and build process.

**Basic `pom.xml` Example**:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

---
🐐 Translation:  
This top line is like saying:
- “Dear Maven, this XML speaks your dialect (`POM/4.0.0`).
- If you’re confused, here’s the dictionary (the XSD) so you know the grammar.”

- **groupId + artifactId + version = goat’s full name** → `com.goatfarm:goat-service:1.0.0`.
- This is how Maven finds and shares dependencies.


---
**Key Elements**:

- **groupId**: Unique identifier for your organization or project (e.g., `com.example`).
- **artifactId**: Name of the project (e.g., `my-app`).
- **version**: Version of the project (e.g., `1.0-SNAPSHOT`).
- **packaging**: Output type (e.g., `jar`, `war`, `pom`).
- **dependencies**: Libraries required by the project.

### 4. Maven Lifecycle and Commands

Maven has a **build lifecycle** with phases ***executed in sequence***:

- **validate**: Validates the project structure and POM file.
- **compile**: Compiles source code.
- **test**: Runs unit tests.
- **package**: Packages compiled code into a distributable format (e.g., JAR).
- **install**: Installs the package to the local repository.
- **deploy**: Deploys the package to a remote repository.

**Common Commands**:

```bash
mvn clean       # Clears target/ directory
mvn compile     # Compiles source code
mvn test        # Runs tests
mvn package     # Creates JAR/WAR
mvn install     # Installs artifact to local repository
mvn deploy      # Deploys to remote repository
```

---

## Intermediate Maven Concepts

### 1. Dependency Management

Maven simplifies dependency management by downloading libraries from repositories like Maven Central.

**Adding a Dependency**:

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-core</artifactId>
    <version>6.1.14</version>
</dependency>
```

**Dependency Scopes**:

- `compile`: Default, available in all classpaths.
- `test`: Only for testing (e.g., JUnit).
- `provided`: Available at compile-time but provided by the runtime environment (e.g., Servlet API).
- `runtime`: Needed at runtime but not for compilation (e.g., JDBC drivers).
- `system`: Local dependencies (not recommended).

**Transitive Dependencies**:  
Maven automatically resolves dependencies of dependencies. Use `mvn dependency:tree` to view the dependency tree.

### 2. Plugins

Plugins extend Maven’s functionality. Each plugin has goals that can be executed during the build lifecycle.

**Example (Surefire Plugin for Testing)**:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.5.0</version>
            <configuration>
                <includes>
                    <include>**/*Test.java</include>
                </includes>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**Common Plugins**:

- `maven-compiler-plugin`: Configures Java version for compilation.
- `maven-jar-plugin`: Customizes JAR packaging.
- `maven-war-plugin`: For WAR file creation.

### 3. Managing Dependencies in Multi-Module Projects

In large projects, you can organize code into multiple modules under a parent POM.

**Parent `pom.xml`**:

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>parent-project</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <modules>
        <module>module1</module>
        <module>module2</module>
    </modules>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-core</artifactId>
                <version>6.1.14</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
</project>
```

**Child Module `pom.xml`**:

```xml
<project>
    <parent>
        <groupId>com.example</groupId>
        <artifactId>parent-project</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <artifactId>module1</artifactId>
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-core</artifactId>
        </dependency>
    </dependencies>
</project>
```

**Benefits**:

- Centralized dependency versions in the parent POM.
- Simplified maintenance for large projects.

---

## Advanced Maven Concepts

### 1. Profiles

Profiles allow customization of builds for different environments (e.g., dev, prod).

**Example (Profile for Dev Environment)**:

```xml
<profiles>
    <profile>
        <id>dev</id>
        <properties>
            <env>development</env>
        </properties>
        <build>
            <resources>
                <resource>
                    <directory>src/main/resources/dev</directory>
                </resource>
            </resources>
        </build>
    </profile>
</profiles>
```

**Activate Profile**:

```bash
mvn package -Pdev
```

### 2. Repository Management

Maven supports local and remote repositories:

- **Local Repository**: `~/.m2/repository` stores downloaded dependencies.
- **Remote Repositories**: Maven Central, or custom repositories like Nexus or Artifactory.

**Custom Repository in `pom.xml`**:

```xml
<repositories>
    <repository>
        <id>my-repo</id>
        <url>https://my-repo.com/releases</url>
    </repository>
</repositories>
```

### 3. Maven Archetypes

Archetypes are templates for creating new projects with predefined structures.

**Create a Project from Archetype**:

```bash
mvn archetype:generate -DgroupId=com.example -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

**Common Archetypes**:

- `maven-archetype-quickstart`: Basic Java project.
- `maven-archetype-webapp`: Web application.

### 4. Dependency Exclusion and Version Management

- **Excluding Transitive Dependencies**:

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-web</artifactId>
    <version>6.1.14</version>
    <exclusions>
        <exclusion>
            <groupId>commons-logging</groupId>
            <artifactId>commons-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

- **Using Properties for Versions**:

```xml
<properties>
    <spring.version>6.1.14</spring.version>
</properties>
<dependencies>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-core</artifactId>
        <version>${spring.version}</version>
    </dependency>
</dependencies>
```

### 5. Maven Wrapper

The Maven Wrapper (`mvnw`) ensures consistent Maven versions across environments.

**Setup**:

```bash
mvn -N wrapper:wrapper
```

This generates `mvnw` (Unix) and `mvnw.cmd` (Windows) scripts.

**Usage**:

```bash
./mvnw clean install
```

---

## Example: Spring Boot Project with Maven

Below is a complete `pom.xml` for a Spring Boot project.

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>spring-boot-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

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
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

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

**Key Points**:

- Uses `spring-boot-starter-parent` for default configurations.
- Includes dependencies for web, JPA, and an in-memory H2 database.
- The `spring-boot-maven-plugin` enables executable JAR creation.

**Run the Application**:

```bash
mvn spring-boot:run
```

---

## Best Practices

- **Keep POM Clean**: Use `dependencyManagement` for large projects.
- **Use Maven Wrapper**: Ensure consistent builds across teams.
- **Avoid SNAPSHOT Dependencies**: Use stable versions in production.
- **Leverage Plugins**: Customize builds with plugins like `maven-shade-plugin` for fat JARs.
- **Check Dependency Conflicts**: Use `mvn dependency:tree` to resolve conflicts.

---

## Conclusion

Maven is a powerful tool that streamlines Java project builds, dependency management, and deployment. From basic project setup to advanced multi-module projects and profiles, Maven’s conventions and plugins make it indispensable for modern Java development. Start with the official Maven documentation and experiment with archetypes to master Maven.

---
# Notes : 

### **Build automation tool**

A **build automation tool** is software that automates the process of converting source code into a runnable application. Instead of manually compiling code, copying files, packaging libraries, or running tests, a build tool handles these tasks automatically.


---

# 🟦 Part 1 — **Checkstyle**

### 🔹 What it is

Checkstyle is like a **robot teacher** that yells at you if your code formatting or naming doesn’t follow rules.  
It ensures **consistency** in big projects.

---

### 🔹 How it works

- It reads your **Java source files**.
    
- Compares them against a set of **rules** (XML config file).
    
- Produces a **report** telling you where you broke the rules.
    

---

### 🔹 Example rules it checks

- Method names must start with lowercase.
    
- Indentation should be 4 spaces.
    
- Each class must have Javadoc.
    
- No trailing whitespace.
    

For example, if you write:

```java
public class myclass {  // Wrong naming
  void DoStuff() {      // Wrong naming
      System.out.println("hi"); // Indentation bad
  }
}
```

Checkstyle will complain. ✅

---

### 🔹 Using it in Maven

Add this plugin in `pom.xml`:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-checkstyle-plugin</artifactId>
  <version>3.3.1</version>
  <configuration>
    <configLocation>google_checks.xml</configLocation>
    <encoding>UTF-8</encoding>
    <consoleOutput>true</consoleOutput>
    <failsOnError>true</failsOnError>
  </configuration>
</plugin>
```

Now run:

```bash
mvn checkstyle:checkstyle
```

Reports will be here:

```
target/site/checkstyle.html
```

---

# 🟩 Part 2 — **PMD**

### 🔹 What it is

PMD is like a **bug hunter** that looks for:

- Bad coding practices.
    
- Inefficient or dangerous code.
    
- Complexity issues.
    

---

### 🔹 Example rules it checks

- Unused imports:
    

```java
import java.util.List; // <- If unused, PMD complains
```

- Empty `catch`:
    

```java
try {
  riskyCode();
} catch (Exception e) {
  // silence... BAD
}
```

- Long/complex methods.
    
- Too many fields in a class.
    

---

### 🔹 Using it in Maven

Add plugin:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-pmd-plugin</artifactId>
  <version>3.21.2</version>
  <configuration>
    <printFailingErrors>true</printFailingErrors>
  </configuration>
</plugin>
```

Run:

```bash
mvn pmd:pmd
```

Report will be:

```
target/site/pmd.html
```

---

# 🟨 Key Difference

- **Checkstyle** → Are you writing code that **looks right**?
    
- **PMD** → Are you writing code that **works safely**?
    

Both are **static analysis tools** (check code without running it).



##### Tags :  [[0 - Spring Framework]]