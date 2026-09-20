Date : {{Date}}
Concept : Spring with no boot 
Course : [Link](https://www.youtube.com/watch?v=-Fe0zk-F4OA&t=2994s)
Tags : [[0 - Spring Framework]]



This note explains how to use the Spring Framework without Spring Boot, focusing on dependency injection (DI), configuring beans using XML, autowiring, and setting property values in a simple way.

## 1. Setting Up Spring Framework

To use Spring without Spring Boot, include the core Spring dependencies in your project. For Maven, add the following to your `pom.xml`:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-context</artifactId>
        <version>6.0.11</version>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-core</artifactId>
        <version>6.0.11</version>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-beans</artifactId>
        <version>6.0.11</version>
    </dependency>
</dependencies>
```

## 2. Configuring Beans with XML

Spring uses an XML configuration file (e.g., `applicationContext.xml`) to define beans and their dependencies. Place this file in the `src/main/resources` directory.

### Example XML Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Define a simple bean -->
    <bean id="messageService" class="com.example.MessageService">
        <!-- Set property values -->
        <property name="message" value="Hello, Spring!" />
    </bean>

    <!-- Define a bean with dependencies -->
    <bean id="messagePrinter" class="com.example.MessagePrinter">
        <!-- Constructor injection -->
        <constructor-arg ref="messageService" />
    </bean>
</beans>
```

### Explanation

- `<bean>`: Defines a bean with an `id` (unique identifier) and `class` (fully qualified class name).
- `<property>`: Sets a property value on the bean using setter injection.
- `<constructor-arg>`: Injects dependencies via the constructor.

## 3. Dependency Injection (DI)

Spring supports two main types of DI:

- **Constructor Injection**: Dependencies are provided through the constructor.
- **Setter Injection**: Dependencies are set via setter methods.

### Example Classes

#### MessageService

```java
package com.example;

public class MessageService {
    private String message;

    // Setter for property injection
    public void setMessage(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }
}
```

#### MessagePrinter

```java
package com.example;

public class MessagePrinter {
    private final MessageService messageService;

    // Constructor for DI
    public MessagePrinter(MessageService messageService) {
        this.messageService = messageService;
    }

    public void printMessage() {
        System.out.println(messageService.getMessage());
    }
}
```

## 4. Autowiring

Autowiring allows Spring to automatically resolve and inject dependencies. You can enable autowiring in the XML configuration using the `autowire` attribute.

### Example with Autowiring

```xml
<bean id="messageService" class="com.example.MessageService">
    <property name="message" value="Hello, Spring!" />
</bean>

<bean id="messagePrinter" class="com.example.MessagePrinter" autowire="byType" />
```

### Autowiring Modes

- `byType`: Matches beans by their type.
- `byName`: Matches beans by the property name to the bean ID.
- `constructor`: Autowires dependencies via the constructor.

**Note**: Use autowiring cautiously to avoid ambiguity when multiple beans of the same type exist.

## 5. Setting Property Values

Properties can be set using the `<property>` tag in the XML configuration, as shown in the `messageService` bean above. For simple values (e.g., strings, numbers), use the `value` attribute. For injecting other beans, use the `ref` attribute.

### Example with Multiple Properties

```xml
<bean id="messageService" class="com.example.MessageService">
    <property name="message" value="Hello, Spring!" />
    <property name="count" value="5" />
</bean>
```

#### Updated MessageService

```java
package com.example;

public class MessageService {
    private String message;
    private int count;

    public void setMessage(String message) {
        this.message = message;
    }

    public void setCount(int count) {
        this.count = count;
    }

    public String getMessage() {
        return message + " (Count: " + count + ")";
    }
}
```

## 6. Loading the Spring Context

To use the configured beans, load the Spring application context in your Java code.

### Example Main Class

```java
package com.example;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Main {
    public static void main(String[] args) {
        // Load the Spring context from the XML file
        ApplicationContext context = new ClassPathXmlApplicationContext("applicationContext.xml");

        // Retrieve the bean from the context
        MessagePrinter printer = context.getBean("messagePrinter", MessagePrinter.class);

        // Use the bean
        printer.printMessage();
    }
}
```

### Output

```
Hello, Spring!
```

## 7. Best Practices

- **Keep XML Simple**: Use clear, descriptive bean IDs and avoid overly complex configurations.
- **Use Autowiring Sparingly**: Explicitly define dependencies for clarity unless autowiring simplifies the setup significantly.
- **Organize Beans**: Group related beans in the XML file for maintainability.
- **Test Thoroughly**: Ensure all dependencies are correctly wired to avoid runtime errors.

This setup provides a lightweight way to use Spring's DI and bean management without the overhead of Spring Boot, suitable for small applications or learning purposes.