

A Spring bean is just a regular Java object, except that Spring creates it, holds onto it, and hands it to you when you need it, instead of you creating it yourself with `new`. Nothing special about the class itself; what makes it a "bean" is that Spring is in charge of it.

## The problem beans solve

Imagine an `OrderService` that needs a `PaymentService`. Without Spring you'd write:

```java
public class OrderService {
    private PaymentService paymentService = new PaymentService();
}
```

This looks fine, but it causes real headaches. `OrderService` is now glued to one specific `PaymentService`, so swapping it for a fake one in a test is painful. If `PaymentService` itself needs other objects, you have to build that whole chain by hand. And every class creating its own copies wastes memory and makes shared configuration messy.

## The Spring way

You tell Spring "this class is a bean," and Spring builds it once and gives it to whoever asks:

```java
@Service
public class PaymentService { }

@Service
public class OrderService {
    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

`@Service` (also `@Component`, `@Repository`, `@Controller`, and so on) marks the class as a bean. `OrderService` never writes `new`; it just says what it needs, and Spring supplies it. You can also declare a bean with a method:

```java
@Configuration
public class AppConfig {
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
```

This is handy for classes you don't own (like library classes) where you can't add an annotation.

## So why is it called a "bean"?

The name is a bit of Java history. In 1996, Sun Microsystems introduced **JavaBeans**, a convention for writing reusable Java components. The name came from Java's coffee branding: Java is coffee, and a bean is one small reusable ingredient that you combine with others to make something bigger. When Spring arrived, it borrowed the word for the same idea: small, reusable building blocks that get assembled into an application.

So the picture is: your app is the cup of coffee, and beans are the pieces it's made from.

## Key takeaways

- A bean is an ordinary object managed by Spring.
- You mark classes with annotations like `@Service`, or declare them with `@Bean` methods.
- Spring creates them and injects them where needed, so your code stays loosely coupled and easy to test.
- The name comes from JavaBeans, a coffee-themed pun on "reusable component."





[[Spring Framework]]