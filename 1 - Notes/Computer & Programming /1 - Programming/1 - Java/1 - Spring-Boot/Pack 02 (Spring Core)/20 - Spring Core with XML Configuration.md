

## 1. What is XML-Based Configuration in Spring?

**XML-based configuration** is a way to tell the Spring IoC container how to create, configure, and connect objects (beans) using an XML file instead of Java annotations or Java configuration classes.

Spring reads the XML configuration, creates the bean definitions, instantiates the required objects, and injects their dependencies.

For example, you can tell Spring:

- Create a `ProductService`.
- Create a `ProductController`.
- Inject `ProductService` into `ProductController`.
- Set the `author` property to `"Alireza"`.

Spring handles these operations instead of requiring you to instantiate and connect every object manually.

---

## 2. What Is a Spring Bean?

A **Spring Bean** is an object that is instantiated, configured, and managed by the Spring IoC container.

Normally, you create objects yourself:

```java
ProductRepository repository = new ProductRepository();
ProductService service = new ProductService(repository);
ProductController controller = new ProductController(service);
```

With Spring, you delegate object creation and dependency management to the container.

A bean can be registered in several ways:

1. XML configuration using `<bean>`.
2. Component scanning using annotations such as `@Component`.
3. Java configuration using `@Bean` inside a `@Configuration` class.

---

## 3. Declaring Beans Using XML

Spring provides the `<bean>` element to register an object in the application context.

Example:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
           https://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="productRepository"
          class="com.me.ProductRepository"/>

</beans>
```

Let's understand the important attributes:

- `id`: The bean's identifier inside the Spring container.
- `class`: The fully qualified name of the Java class Spring should instantiate.

Conceptually, Spring performs something similar to:

```java
ProductRepository repository = new ProductRepository();
```

However, Spring also manages the resulting object inside its application context.

You can retrieve the bean using:

```java
ApplicationContext context =
        new ClassPathXmlApplicationContext("beans.xml");

ProductRepository repository =
        context.getBean("productRepository", ProductRepository.class);
```

### Important: Spring cannot instantiate an interface directly

Consider:

```java
public interface ProductRepository {
    void save();
}
```

This XML declaration is invalid for creating an object:

```xml
<bean id="productRepository"
      class="com.me.ProductRepository"/>
```

Why?

Because an interface cannot be instantiated:

```java
new ProductRepository(); // Compilation error
```

You need a concrete implementation:

```java
public class ProductRepositoryImpl implements ProductRepository {

    @Override
    public void save() {
        System.out.println("Product saved");
    }
}
```

Now register the implementation:

```xml
<bean id="productRepository"
      class="com.me.ProductRepositoryImpl"/>
```

You can still inject it using the interface type:

```java
public class ProductService {

    private final ProductRepository repository;

    public ProductService(ProductRepository repository) {
        this.repository = repository;
    }
}
```

**Remember:** The implementation is instantiated, but your application can depend on the interface. This is an important principle of programming against abstractions.

---

## 4. How Spring Data JPA Creates Beans From Interfaces

You might wonder:

"If Spring cannot instantiate an interface, how does Spring Boot create a bean from an interface extending `JpaRepository`?"

For example:

```java
@Repository
public interface ProductRepository
        extends JpaRepository<Product, Long> {
}
```

This is possible because Spring Data JPA provides additional infrastructure.

It detects repository interfaces and creates runtime proxy implementations for them.

A **proxy** is an object that implements an interface and delegates or intercepts method calls to perform additional operations.

Conceptually:

```text
ProductRepository (interface)
          |
          v
Spring Data JPA
          |
          v
Runtime-generated proxy
          |
          v
Repository operations
```

You don't need to write `ProductRepositoryImpl` yourself.

However, there is an important distinction:

- `@Repository` alone does not generate an implementation.
- Extending `JpaRepository` allows Spring Data JPA to recognize the interface as a repository.
- Repository infrastructure must be configured and enabled.

In XML-based configuration, Spring Data JPA repository scanning can be enabled using:

```xml
<jpa:repositories base-package="com.me.repository"/>
```

This requires the appropriate JPA XML namespace and JPA infrastructure configuration.

**Do not confuse component scanning with Spring Data repository scanning.** They are different mechanisms.

---

## 5. Dependency Injection (DI)

**Dependency Injection** is a design pattern in which an object receives the other objects it needs from an external source instead of creating them itself.

A dependency is something a class needs to perform its responsibilities.

For example:

```java
public class ProductService {

    private final ProductRepository repository;

    public ProductService(ProductRepository repository) {
        this.repository = repository;
    }
}
```

Here, `ProductRepository` is a dependency of `ProductService`.

Without dependency injection, you might write:

```java
public class ProductService {

    private final ProductRepository repository =
            new ProductRepositoryImpl();
}
```

This tightly couples `ProductService` to a specific implementation.

With dependency injection, the dependency is provided externally:

```java
ProductRepository repository = new ProductRepositoryImpl();

ProductService service = new ProductService(repository);
```

Spring automates this process.

### Why is it called injection?

Because the required dependency is provided to the object from outside.

Think of it like a computer that needs electricity: the computer doesn't generate its own power connection; an external power source supplies it.

The same idea applies to objects and their dependencies.

---

## 6. Constructor Injection

**Constructor injection** means providing dependencies through a class constructor.

Example:

```java
public class ProductService {

    private final ProductRepository repository;

    public ProductService(ProductRepository repository) {
        this.repository = repository;
    }
}
```

XML configuration:

```xml
<bean id="productRepository"
      class="com.me.ProductRepositoryImpl"/>

<bean id="productService"
      class="com.me.ProductService">

    <constructor-arg ref="productRepository"/>

</bean>
```

The `constructor-arg` element tells Spring which value or bean reference should be passed to the constructor.

There are two important attributes:

| Attribute | Meaning |
|---|---|
| `ref` | Passes a reference to another Spring bean |
| `value` | Passes a literal value |

For example:

```xml
<constructor-arg ref="productRepository"/>
```

Passes an existing Spring bean.

```xml
<constructor-arg value="Alireza"/>
```

Passes the literal string `"Alireza"`.

### Constructor arguments by index

You can explicitly specify the constructor parameter position:

```xml
<bean id="productController"
      class="com.me.ProductController">

    <constructor-arg index="0" ref="productService"/>
    <constructor-arg index="1" value="Alireza"/>

</bean>
```

Here:

- `index="0"` refers to the first constructor parameter.
- `index="1"` refers to the second constructor parameter.

Your constructor must match:

```java
public class ProductController {

    private final ProductService productService;
    private final String author;

    public ProductController(
            ProductService productService,
            String author) {

        this.productService = productService;
        this.author = author;
    }
}
```

### Understanding constructor errors

You encountered an error similar to:

```text
Could not resolve matching constructor
on bean class [com.me.ProductController]
```

This means Spring couldn't find a constructor matching the arguments provided in your XML configuration.

For example, if your XML provides two arguments:

```xml
<constructor-arg ref="productService"/>
<constructor-arg value="Alireza"/>
```

But your Java class only has:

```java
public ProductController(ProductService productService) {
}
```

Spring cannot match the two arguments to that one-parameter constructor.

**Always make sure your XML constructor arguments match an available Java constructor.**

---

## 7. Setter Injection

**Setter injection** means providing a dependency or configuration value through a setter method after the object has been instantiated.

Example:

```java
public class ProductController {

    private String author;

    public void setAuthor(String author) {
        this.author = author;
    }
}
```

XML configuration:

```xml
<bean id="productController"
      class="com.me.ProductController">

    <property name="author" value="Alireza"/>

</bean>
```

Spring performs operations conceptually similar to:

```java
ProductController controller = new ProductController();

controller.setAuthor("Alireza");
```

### Understanding the `<property>` element

The `name` attribute refers to the JavaBean property name, not the setter method name.

For example:

```java
public void setAuthor(String author) {
    this.author = author;
}
```

The property name is `author`, so XML uses:

```xml
<property name="author" value="Alireza"/>
```

Not:

```xml
<property name="setAuthor" value="Alireza"/>
```

### Injecting a bean versus injecting a literal

You can use setter injection for both dependencies and literal values.

**Injecting another Spring bean:**

```xml
<property name="productService" ref="productService"/>
```

**Injecting a literal:**

```xml
<property name="author" value="Alireza"/>
```

Java class:

```java
public class ProductController {

    private ProductService productService;
    private String author;

    public void setProductService(ProductService productService) {
        this.productService = productService;
    }

    public void setAuthor(String author) {
        this.author = author;
    }
}
```

| XML attribute | Purpose |
|---|---|
| `ref` | References another Spring bean |
| `value` | Injects a literal value |

---

## 8. Component Scanning

So far, we have registered beans manually using `<bean>`.

But imagine having 50 classes. Writing a bean declaration for every class would become tedious.

**Component scanning** allows Spring to discover eligible classes automatically by scanning specified packages.

Spring recognizes stereotype annotations such as:

- `@Component`
- `@Service`
- `@Repository`
- `@Controller`

For example:

```java
@Component
public class ProductRepository {
}
```

```java
@Service
public class ProductService {
}
```

```java
@Controller
public class ProductController {
}
```

Spring can discover these classes automatically.

### Declaring component scanning in XML

First, declare the context namespace:

```xml
xmlns:context="http://www.springframework.org/schema/context"
```

Then declare its corresponding XSD in `xsi:schemaLocation`:

```xml
http://www.springframework.org/schema/context
https://www.springframework.org/schema/context/spring-context.xsd
```

Finally, enable component scanning:

```xml
<context:component-scan base-package="com.me"/>
```

A complete XML example:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"

       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
           https://www.springframework.org/schema/beans/spring-beans.xsd

           http://www.springframework.org/schema/context
           https://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.me"/>

</beans>
```

### What does `base-package` mean?

```xml
<context:component-scan base-package="com.me"/>
```

Spring scans:

```text
com.me
com.me.repository
com.me.service
com.me.controller
com.me.anything
```

It scans the specified package and its subpackages for eligible components.

---

## 9. XML Namespaces and XSD Schema Locations

You encountered an XML error:

```text
The matching wildcard is strict, but no declaration
can be found for element 'context:component-scan'.
```

The reason was that you declared the `context` namespace but didn't provide its schema location.

To understand this, distinguish two things:

**1. Namespace declaration**

```xml
xmlns:context="http://www.springframework.org/schema/context"
```

This associates the prefix `context` with a namespace.

**2. Schema location**

```xml
xsi:schemaLocation="
    http://www.springframework.org/schema/context
    https://www.springframework.org/schema/context/spring-context.xsd"
```

This tells the XML parser where to find the schema describing the elements and attributes belonging to that namespace.

Think of it this way:

- Namespace: identifies which vocabulary an XML element belongs to.
- XSD: describes which elements and attributes are valid in that vocabulary.

You need both for Spring's XML namespace elements.

### Common Spring XML namespaces

| Namespace | Purpose |
|---|---|
| `beans` | Declaring Spring beans |
| `context` | Component scanning and application context configuration |
| `util` | Utility-related XML configuration |
| `tx` | Transaction configuration |
| `aop` | Aspect-oriented programming configuration |
| `jpa` | Spring Data JPA repository configuration |

Each namespace needs its corresponding schema location when you use its XML elements.

---

## 10. The Difference Between `@Autowired` and `@Value`

You encountered another important error:

```text
Unsatisfied dependency expressed through constructor parameter 1:
No qualifying bean of type 'java.lang.String' available
```

This happened because Spring tried to autowire a `String` constructor parameter.

Consider:

```java
@Component
public class ProductController {

    private final ProductService productService;
    private final String author;

    public ProductController(
            ProductService productService,
            String author) {

        this.productService = productService;
        this.author = author;
    }
}
```

Spring knows how to find a `ProductService` bean, but where should it get the `String` value?

It doesn't automatically know that you want `"Alireza"`.

### Using `@Autowired`

`@Autowired` tells Spring to resolve a dependency from the application context.

For example:

```java
@Autowired
public ProductController(ProductService productService) {
    this.productService = productService;
}
```

Spring searches for a matching bean.

### Using `@Value`

`@Value` tells Spring to inject a configured value.

For example:

```java
@Component
public class ProductController {

    private final String author;

    public ProductController(
            @Value("Alireza") String author) {

        this.author = author;
    }
}
```

You can also use a properties file.

`application.properties`:

```properties
app.author=Alireza
```

Java:

```java
public ProductController(
        @Value("${app.author}") String author) {

    this.author = author;
}
```

Here, Spring resolves `${app.author}` from the configured property sources.

**Important:** `@Value` and `@Autowired` solve different problems. One injects configured values; the other resolves dependencies from the container.

---

## 11. A Complete Example: Putting Everything Together

Let's build a small application using component scanning, constructor injection, and setter injection.

### ProductRepository.java

```java
package com.me;

import org.springframework.stereotype.Repository;

@Repository
public class ProductRepository {

    public void save() {
        System.out.println("Product saved!");
    }
}
```

### ProductService.java

```java
package com.me;

import org.springframework.stereotype.Service;

@Service
public class ProductService {

    private final ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    public void saveProduct() {
        productRepository.save();
    }
}
```

Spring automatically injects `ProductRepository` into `ProductService` through its constructor.

### ProductController.java

```java
package com.me;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;

@Controller
public class ProductController {

    private final ProductService productService;
    private String author;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @Value("Alireza")
    public void setAuthor(String author) {
        this.author = author;
    }

    public void createProduct() {
        System.out.println("Author: " + author);
        productService.saveProduct();
    }
}
```

Here:

- `ProductService` is injected through constructor injection.
- `author` is injected through setter injection using `@Value`.

### beans.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"

       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
           https://www.springframework.org/schema/beans/spring-beans.xsd

           http://www.springframework.org/schema/context
           https://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.me"/>

</beans>
```

### App.java

```java
package com.me;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class App {

    public static void main(String[] args) {

        ApplicationContext context =
                new ClassPathXmlApplicationContext("beans.xml");

        ProductController controller =
                context.getBean(ProductController.class);

        controller.createProduct();
    }
}
```

Expected output:

```text
Author: Alireza
Product saved!
```

### How the application works

```text
                 beans.xml
                    |
                    v
          Spring ApplicationContext
                    |
                    v
          Component Scanning
                    |
          +---------+---------+
          |         |         |
          v         v         v
     Repository  Service  Controller
          |         |         |
          +---------+---------+
                    |
                    v
           Dependency Injection
                    |
                    v
             Application Ready
```

Spring discovers the components, creates their beans, resolves their dependencies, and injects the configured values.

Notice that we didn't manually create any of these objects using `new`.

---

## 12. Common Mistakes and Their Solutions

| Error or mistake | Cause | Solution |
|---|---|---|
| `Specified class is an interface` | Spring is trying to instantiate an interface | Register a concrete implementation or configure Spring Data repository infrastructure |
| `Could not resolve matching constructor` | XML arguments don't match the Java constructor | Match argument count, types, and positions |
| `No qualifying bean of type String` | Spring is trying to autowire a literal as a bean | Use `@Value` or XML `value` |
| `No declaration can be found for element context:component-scan` | Context XSD is missing | Add the context schema to `xsi:schemaLocation` |
| `NotWritablePropertyException` | The property doesn't have a suitable setter or writable property | Add the correct setter and check the property name |
| `No qualifying bean of type ProductService` | Spring cannot find a matching bean | Register it or scan the package containing it |
| Duplicate bean definitions | The same class is registered through multiple mechanisms | Avoid defining the same component both manually and through scanning |

---

## 13. Exercises

Try these without looking at the examples above.

**Exercise 1 — Bean Declaration**

Create a `ProductRepository` class and register it using XML.

**Exercise 2 — Constructor Injection**

Create a `ProductService` class that requires `ProductRepository` through its constructor. Configure both beans in XML.

**Exercise 3 — Setter Injection**

Add a `String author` property to `ProductController`. Inject `"Alireza"` using XML setter injection.

**Exercise 4 — Component Scanning**

Replace your manual bean declarations with component scanning. Use `@Repository`, `@Service`, and `@Controller`.

**Exercise 5 — Diagnose the Error**

Why does this constructor fail when using component scanning?

```java
public ProductController(ProductService service, String author) {
}
```

Fix it using `@Value`.

**Exercise 6 — Interfaces**

Create a `ProductRepository` interface and a `ProductRepositoryImpl` class. Register the implementation in XML and inject it into `ProductService` through the interface type.

---

## 14. Final Summary

| Concept | Definition |
|---|---|
| Spring Bean | An object managed by the Spring IoC container |
| IoC | Inversion of Control: delegating object creation and management to a container |
| Dependency | An object or resource another object requires |
| Dependency Injection | Providing dependencies externally |
| Constructor Injection | Injecting dependencies through a constructor |
| Setter Injection | Injecting dependencies or values through setter methods |
| `ref` | References another Spring bean in XML |
| `value` | Supplies a literal value in XML |
| `@Autowired` | Resolves a dependency from the Spring container |
| `@Value` | Injects a configured value |
| Component Scanning | Automatically discovers eligible annotated components |
| XML Namespace | Identifies the vocabulary to which an XML element belongs |
| XSD | Defines the valid XML structure for a schema |
| Spring Data JPA Proxy | A runtime-generated implementation of a repository interface |

[[Spring Framework]]