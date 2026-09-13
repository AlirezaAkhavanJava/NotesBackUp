**Date**: 2025-08-24  
**Tags**: [[Java]] 

## What Are Java Modules?

Java Modules, introduced in **Java 9** via the **Java Platform Module System (JPMS)**, are a way to organize code into reusable, self-contained units called **modules**. Think of a module as a box that holds related classes, with rules about what it shares and what it uses from other modules. Modules make Java applications more organized, secure, and maintainable.

---

## Why Use Modules?

- **Better Organization**: Group related code together, like a library or app component.
- **Hide Internal Code**: Control which parts of your code are visible to others.
- **Reduce Errors**: Prevent accidental use of internal classes or libraries.
- **Smaller Apps**: Create lightweight runtimes with only needed modules (using `jlink`).
- **Works for All Levels**: Simple for beginners, powerful for advanced developers.

## Key Concepts (Beginner-Friendly)

- **Module**: A collection of packages (Java classes) with a `module-info.java` file that defines its name, dependencies, and exports.
- **module-info.java**: A special file that describes the module (what it needs and what it shares).
- **Exports**: Specifies which packages in a module other modules can use.
- **Requires**: Lists other modules your module depends on.
- **Module Path**: Like the classpath, but for modules; tells Java where to find modules.
- **JAR vs. Modular JAR**: A regular JAR is a zip of classes; a modular JAR includes a `module-info.class`.


---

## How Modules Work

1. **Create a Module**: Write a `module-info.java` file to define the module.
2. **Define Dependencies**: Use `requires` to list modules your code needs.
3. **Share Code**: Use `exports` to share specific packages with other modules.
4. **Compile and Run**: Use `javac` and `java` with the `--module-path` option.
5. **Package**: Create a modular JAR or a custom runtime with `jlink`.

## Simple Example (Beginner)

Let’s create a tiny app with two modules: one for a greeting service and one for the main app.

### Step 1: Project Structure

```
myapp/
├── com.example.greeting/
│   ├── module-info.java
│   └── Greeting.java
├── com.example.app/
│   ├── module-info.java
│   └── Main.java
```

### Step 2: Greeting Module

**com.example.greeting/module-info.java**:

```java
module com.example.greeting {
    exports com.example.greeting; // Share this package
}
```

**com.example.greeting/Greeting.java**:

```java
package com.example.greeting;

public class Greeting {
    public String sayHello(String name) {
        return "Hello, " + name + "!";
    }
}
```

### Step 3: Main App Module

**com.example.app/module-info.java**:

```java
module com.example.app {
    requires com.example.greeting; // Depends on greeting module
}
```

**com.example.app/Main.java**:

```java
package com.example.app;
import com.example.greeting.Greeting;

public class Main {
    public static void main(String[] args) {
        Greeting greeting = new Greeting();
        System.out.println(greeting.sayHello("Alice"));
    }
}
```

### Step 4: Compile and Run

1. Compile:
    
    ```bash
    javac --module-path . -d mods/com.example.greeting com.example.greeting/*.java
    javac --module-path mods -d mods/com.example.app com.example.app/*.java
    ```
    
2. Run:
    
    ```bash
    java --module-path mods -m com.example.app/com.example.app.Main
    ```
    

**Output**: `Hello, Alice!`

**Explanation**:

- `com.example.greeting` shares its `Greeting` class via `exports`.
- `com.example.app` uses `Greeting` by declaring `requires com.example.greeting`.
- The module system ensures only exported packages are accessible.

## Common Issues (Beginner-Friendly)

- **Missing module-info.java**: Without it, your code isn’t a module.
    - **Fix**: Add a `module-info.java` file in the module’s root.
- **Wrong Module Name**: Module names must match directory structure (e.g., `com.example.greeting`).
    - **Fix**: Ensure module name matches package structure.
- **Access Errors**: Trying to use a non-exported package causes errors.
    - **Fix**: Add `exports` for needed packages in `module-info.java`.
- **Missing Dependency**: Forgetting `requires` for a needed module.
    - **Fix**: Add `requires <module-name>` in `module-info.java`.

## Advanced Features

For developers ready to dive deeper, here are advanced module concepts:

- **Open Modules**: Allow runtime access (e.g., for reflection) with `open module my.module {}`.
    
- **Services**: Define and consume services (like plugins) using `provides` and `uses`.
    
    ```java
    module com.example.greeting {
        provides com.example.greeting.Greeting with com.example.greeting.GreetingImpl;
    }
    module com.example.app {
        uses com.example.greeting.Greeting;
    }
    ```
    
- **Automatic Modules**: Use existing JARs as modules by placing them on the module path (no `module-info.java` needed).
    
- **jlink**: Create a custom runtime with only needed modules.
    
    ```bash
    jlink --module-path mods --add-modules com.example.app --output myapp
    ```
    
- **Module Layers**: Create isolated module environments for advanced use cases (e.g., plugin systems).
    

## Best Practices

1. **Start Simple**: Use modules for small projects to learn `module-info.java`.
2. **Name Modules Clearly**: Use package-like names (e.g., `com.example.myapp`).
3. **Export Only What’s Needed**: Avoid exposing internal packages with `exports`.
4. **Use Spring Boot with Modules**: Spring Boot supports JPMS for modular apps.
5. **Test Modules**: Use JUnit with modular projects to ensure compatibility.
6. **Leverage jlink**: Create lightweight runtimes for deployment.

## Common Issues (Advanced)

- **Reflection Issues**: Libraries using reflection (e.g., Spring, Hibernate) may fail if packages aren’t exported or opened.
    - **Fix**: Use `opens` or `open module` for reflective access.
- **Legacy JARs**: Non-modular JARs on the module path become automatic modules, which may cause naming issues.
    - **Fix**: Check `MANIFEST.MF` for `Automatic-Module-Name` or add `module-info.java`.
- **Complex Dependencies**: Large projects with many modules can be hard to manage.
    - **Fix**: Use build tools like Maven or Gradle with JPMS support.

## Example with Spring Boot (Advanced)

```java
// module-info.java for a Spring Boot app
module com.example.app {
    requires spring.boot;
    requires spring.boot.autoconfigure;
    requires spring.data.jpa;
    requires com.example.greeting;
    opens com.example.app to spring.core; // Allow Spring reflection
}

// Spring Boot Main
package com.example.app;
import com.example.greeting.Greeting;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {
    private final Greeting greeting;

    public Application(Greeting greeting) {
        this.greeting = greeting;
    }

    @GetMapping("/hello")
    public String sayHello() {
        return greeting.sayHello("Spring User");
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

**Note**:

- Add dependencies: `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, and the greeting module.
- Configure `application.properties` for the database.
- Compile and run with Maven/Gradle, ensuring the module path includes dependencies.
- Access via `http://localhost:8080/hello`.

## Summary

Java Modules (JPMS) organize code into reusable units with `module-info.java`, controlling what’s shared (`exports`) and needed (`requires`). They’re beginner-friendly for small projects and powerful for advanced apps with features like services and `jlink`. Use modules to make code modular, secure, and maintainable, especially with Spring Boot. Start with simple modules, avoid common issues like missing exports, and leverage advanced features as needed.