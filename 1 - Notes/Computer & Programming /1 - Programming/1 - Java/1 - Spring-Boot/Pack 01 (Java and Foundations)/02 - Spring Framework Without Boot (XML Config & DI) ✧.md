
Spring works just fine without Spring Boot — Boot is really just a "convenience layer" that auto-configures things for you. Strip that away, and you're back to classic Spring, where you wire your beans yourself using an XML file. That's what's happening in this note: you define your objects (beans) in XML, tell Spring how they depend on each other, and Spring builds and connects them for you at startup.

## 1. Dependencies (no Boot starter)

Without Boot, you pull in Spring's core jars directly:

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>6.0.11</version>
</dependency>
```

`spring-context` alone is usually enough — it transitively pulls in `spring-core` and `spring-beans`, since the container can't exist without them.

## 2. Defining beans in XML

Instead of `@Component` or `@Bean`, you declare every bean by hand in an XML file (commonly `applicationContext.xml`, placed in `src/main/resources`):

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="messageService" class="com.example.MessageService">
        <property name="message" value="Hello, Spring!" />
    </bean>

    <bean id="messagePrinter" class="com.example.MessagePrinter">
        <constructor-arg ref="messageService" />
    </bean>
</beans>
```

- `id` — the bean's name in the container (how you'll look it up later).
- `class` — the fully qualified class Spring should instantiate.
- `<property>` — setter injection: Spring calls `setMessage("Hello, Spring!")`.
- `<constructor-arg>` — constructor injection: Spring passes `messageService` into `MessagePrinter`'s constructor.

## 3. Constructor vs. setter injection

Both are just two ways of handing a bean its dependencies:

```java
public class MessageService {
    private String message;
    public void setMessage(String message) { this.message = message; }
    public String getMessage() { return message; }
}

public class MessagePrinter {
    private final MessageService messageService;
    public MessagePrinter(MessageService messageService) { this.messageService = messageService; }
    public void printMessage() { System.out.println(messageService.getMessage()); }
}
```

Constructor injection forces the dependency to exist before the object does — good for required dependencies. Setter injection allows the dependency to be set (or changed) after construction — more flexible, but the object can briefly exist in a half-wired state.

## 4. Autowiring

Rather than wiring every `<constructor-arg>` or `<property>` by hand, you can tell Spring to figure it out itself:

```xml
<bean id="messagePrinter" class="com.example.MessagePrinter" autowire="byType" />
```

- `byType` — finds a bean whose type matches the constructor/setter parameter. Breaks if two beans share that type.
- `byName` — matches the property name to a bean `id`.
- `constructor` — resolves constructor arguments by type, like `byType` but for constructors specifically.

Autowiring is convenient but implicit — it's easy to lose track of exactly what's wired to what, which is why most real projects keep wiring explicit (or move to annotations/Java config instead).

## 5. Non-bean property values

`<property>` isn't just for wiring beans together — plain values work the same way:

```xml
<bean id="messageService" class="com.example.MessageService">
    <property name="message" value="Hello, Spring!" />
    <property name="count" value="5" />
</bean>
```

`value` sets a literal (string, number, etc.); `ref` points at another bean's `id`.

## 6. Bootstrapping the container yourself

Without Boot, there's no auto-started embedded container — you load the context explicitly in `main`:

```java
ApplicationContext context = new ClassPathXmlApplicationContext("applicationContext.xml");
MessagePrinter printer = context.getBean("messagePrinter", MessagePrinter.class);
printer.printMessage(); // Hello, Spring!
```

`ClassPathXmlApplicationContext` reads your XML, builds every bean in the right order (resolving `<constructor-arg>`/`<property>` dependencies first), and hands you back a fully wired object graph via `getBean`.



[[Spring Framework]]