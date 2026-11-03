

A dependency is simply something a class needs in order to do its job. If class A uses class B to get its work done, then B is a dependency of A. It's not a Spring-only idea; it exists in all programming. Spring just gives you a nicer way to deal with dependencies.

## The everyday picture

Think of a chef. To cook a meal, the chef needs a knife, a stove, and ingredients. Those are the chef's dependencies: without them, the chef can't work. In code, the same relationship looks like this:

```java
public class OrderService {
    private final PaymentService paymentService;   // dependency
    private final EmailService emailService;       // dependency

    public OrderService(PaymentService paymentService, EmailService emailService) {
        this.paymentService = paymentService;
        this.emailService = emailService;
    }

    public void placeOrder(Order order) {
        paymentService.charge(order);
        emailService.sendConfirmation(order);
    }
}
```

`OrderService` can't place an order without charging a payment and sending an email, so `PaymentService` and `EmailService` are its dependencies. You can spot them easily: they're the other classes that show up as fields or constructor parameters.

## Why dependencies become a problem

Dependencies themselves are normal and healthy, since splitting work into small classes is good design. The trouble starts with **how** a class gets hold of them. If `OrderService` creates its own dependencies with `new`, it becomes tightly coupled to them: hard to test, hard to change, and hard to reuse. And when dependencies have their own dependencies, you end up building a whole tree of objects by hand.

## How Spring helps

Spring takes over that job. You simply declare what a class needs (usually in its constructor), and Spring finds the matching beans and supplies them. This is called **dependency injection**: the dependencies are "injected" into the class from outside rather than created inside it.

That's where the two ideas connect: **beans are the objects Spring manages, and dependencies are the beans a class needs.** One bean's dependency is just another bean.

## A second meaning you'll see

In Spring Boot projects, you'll also hear "dependency" used for libraries your project needs, like the ones you add in `pom.xml` or `build.gradle`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

Same core idea, different level: your project needs that library to work, so it's a dependency of your project. Context usually tells you which meaning is intended.

## Key takeaways

- A dependency is anything a class needs to do its work.
- Dependencies are normal; creating them by hand with `new` is what causes tight coupling.
- Spring supplies dependencies for you by injecting beans.
- "Dependency" can also mean a library in your Maven or Gradle file.


[[Spring Framework]]