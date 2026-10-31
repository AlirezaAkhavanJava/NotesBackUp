

## 1. The problem it solves

Imagine you're building a Spring Boot application that sends notifications.

Your application supports:

- Email notifications
    
- SMS notifications
    

Both services share some logic, such as validating the recipient and message, but they deliver notifications differently.

Instead of duplicating code, we can use:

1. **Interface:** Defines the contract.
    
2. **Abstract class:** Implements shared functionality.
    
3. **Concrete class:** Implements the remaining abstract methods.
    
4. **Spring IoC Container:** Creates and manages the concrete object.
    

## 2. Step 1 — Create the interface

```java
public interface NotificationService {

    void send(String recipient, String message);

    void validate(String recipient, String message);
}
```

We have two methods:

- `send()` — Send the notification.
    
- `validate()` — Validate the notification data.
    

At this point, we haven't implemented anything.

## 3. Step 2 — Create an abstract class

```java
public abstract class AbstractNotificationService
        implements NotificationService {

    @Override
    public void validate(String recipient, String message) {

        if (recipient == null || recipient.isBlank()) {
            throw new IllegalArgumentException(
                "Recipient cannot be empty"
            );
        }

        if (message == null || message.isBlank()) {
            throw new IllegalArgumentException(
                "Message cannot be empty"
            );
        }
    }

    // send() remains unimplemented
}
```

Notice:

- We implemented the `NotificationService` interface.
    
- We provided an implementation for `validate()`.
    
- We left `send()` unimplemented.
    
- This is legal because our class is abstract.
    

We can reuse this validation logic in every notification service.

## 4. Step 3 — Create a concrete service

Now let's create an email notification service.

```java
import org.springframework.stereotype.Service;

@Service
public class EmailNotificationService
        extends AbstractNotificationService {

    @Override
    public void send(String recipient, String message) {

        validate(recipient, message);

        System.out.println(
            "Sending email to: " + recipient
        );

        System.out.println(message);
    }
}
```

Here's what happened:

1. `EmailNotificationService` extends our abstract class.
    
2. It inherits the already implemented `validate()` method.
    
3. It implements the remaining `send()` method.
    
4. `@Service` tells Spring to register this concrete class as a bean.
    

**Important:** We placed `@Service` on the concrete class, not on the abstract class.

Spring cannot directly instantiate an abstract class.

## 5. Step 4 — Inject the service into a controller

```
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(
            NotificationService notificationService) {

        this.notificationService = notificationService;
    }

    @PostMapping("/send")
    public String send(
            @RequestParam String recipient,
            @RequestParam String message) {

        notificationService.send(recipient, message);

        return "Notification sent";
    }
}
```

Notice something interesting:

```
private final NotificationService notificationService;
```

We declared the dependency using the **interface**, not the concrete class.

But we never wrote:

```
new EmailNotificationService();
```

So who creates the object?

**Spring does!**

During application startup, component scanning discovers `EmailNotificationService`, registers it as a bean, and Spring creates the instance.

Then Spring injects that instance into `NotificationController`.

This is dependency injection combined with polymorphism.

For example, conceptually Spring is accomplishing something similar to:

```
NotificationService service =
        new EmailNotificationService();
```

Except Spring manages the bean's creation, lifecycle, and dependencies.

## 6. Understanding the flow

```
           NotificationService
                (Interface)
                    |
                implements
                    |
       AbstractNotificationService
             (Abstract Class)
                    |
                  extends
                    |
        EmailNotificationService
           (@Service Concrete)
                    |
            Spring IoC Container
                    |
             Creates the Bean
                    |
                    v
          NotificationController
             (Constructor DI)
                    |
                    v
       notificationService.send()
```

When a client sends a request:

```
POST /api/notifications/send?recipient=test@example.com&message=Hello
```

Spring MVC calls the controller, which uses the injected implementation of `NotificationService`.

The example prints the notification to the console; it doesn't actually send an email.

## 7. What if we have multiple implementations?

We could also create:

```
@Service
public class SmsNotificationService
        extends AbstractNotificationService {

    @Override
    public void send(String recipient, String message) {

        validate(recipient, message);

        System.out.println(
            "Sending SMS to: " + recipient
        );
    }
}
```

Now Spring has two beans implementing `NotificationService`:

- `EmailNotificationService`
    
- `SmsNotificationService`
    

If we inject `NotificationService` without further configuration, Spring won't know which bean to choose.

We can solve this using `@Qualifier`:

```
public NotificationController(
        @Qualifier("emailNotificationService")
        NotificationService notificationService) {

    this.notificationService = notificationService;
}
```

Now Spring specifically injects the email implementation.

Another option is `@Primary`, which selects a preferred bean when multiple candidates match.

## 8. Rules in Spring Boot

|Question|Answer|
|---|---|
|Can an abstract class implement a service interface?|Yes|
|Must it implement all interface methods?|No|
|Can an abstract class have dependencies?|Yes|
|Can it have a constructor?|Yes|
|Can Spring instantiate an abstract class directly?|No|
|Can a concrete subclass be a Spring bean?|Yes|
|Should `@Service` go on the concrete implementation?|Generally, yes|
|Can the controller inject the interface?|Yes|
|Can multiple services implement the same interface?|Yes|

## 9. The whole picture

In a Spring Boot application, the design might look like this:

```
service/
│
├── NotificationService.java
│       (Interface)
│
├── AbstractNotificationService.java
│       (Abstract Class)
│
├── EmailNotificationService.java
│       (@Service Concrete Class)
│
└── SmsNotificationService.java
        (@Service Concrete Class)
```

This organization is useful when multiple services genuinely share implementation logic.

However, you don't need an abstract class for every service.

If there's no common implementation to reuse, a concrete `@Service` implementing an interface is usually sufficient.

### Final mental model

- **Interface:** What functionality should be available?
    
- **Abstract class:** What functionality can we implement once and reuse?
    
- **Concrete class:** What implementation details are specific to this service?
    
- **Spring IoC Container:** Which concrete object should be created and injected?
    

The key is that **Spring manages the concrete objects, while Java's inheritance and polymorphism rules work exactly as they normally do.**

[[Spring Framework]]
[[Java]]