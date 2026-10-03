
# ApplicationEventPublisher in Spring

The `ApplicationEventPublisher` is a core interface in the Spring Framework that enables **application-wide event handling** using the **Observer design pattern**. It allows different components of your application to communicate in a **loosely-coupled** way.

>An **event** is an object (often extending `ApplicationEvent`) that carries info about something that just happened.
## How It Works

```
Event Publisher → Publish Event → ApplicationContext → Notify → Event Listeners
```

## Key Interfaces and Classes

### 1. ApplicationEventPublisher Interface
```java
@FunctionalInterface
public interface ApplicationEventPublisher {
    void publishEvent(ApplicationEvent event);
    default void publishEvent(Object event) { ... }
}
```

### 2. ApplicationEvent (Base class for events)
```java
public abstract class ApplicationEvent extends EventObject {
    public ApplicationEvent(Object source) {
        super(source);
    }
}
```

### 3. @EventListener Annotation
```java
@Target({ElementType.METHOD, ElementType.ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface EventListener {
    // Used to mark methods as event listeners
}
```

## Basic Usage Examples

### 1. Creating Custom Events

```java
// Simple custom event
public class UserRegisteredEvent {
    private String username;
    private String email;
    private LocalDateTime timestamp;

    public UserRegisteredEvent(String username, String email) {
        this.username = username;
        this.email = email;
        this.timestamp = LocalDateTime.now();
    }

    // getters
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public LocalDateTime getTimestamp() { return timestamp; }
}

// Event extending ApplicationEvent (traditional approach)
public class OrderCreatedEvent extends ApplicationEvent {
    private Long orderId;
    private BigDecimal amount;

    public OrderCreatedEvent(Object source, Long orderId, BigDecimal amount) {
        super(source);
        this.orderId = orderId;
        this.amount = amount;
    }

    // getters
    public Long getOrderId() { return orderId; }
    public BigDecimal getAmount() { return amount; }
}
```

### 2. Publishing Events

```java
@Service
public class UserService {

    private final ApplicationEventPublisher eventPublisher;
    private final UserRepository userRepository;

    // Constructor injection
    public UserService(ApplicationEventPublisher eventPublisher, UserRepository userRepository) {
        this.eventPublisher = eventPublisher;
        this.userRepository = userRepository;
    }

    public User registerUser(String username, String email, String password) {
        // Create user logic
        User user = new User(username, email, password);
        userRepository.save(user);

        // Publish event
        UserRegisteredEvent event = new UserRegisteredEvent(username, email);
        eventPublisher.publishEvent(event);

        return user;
    }

    public void createOrder(User user, BigDecimal amount) {
        // Order creation logic
        Long orderId = // ... save order
        
        // Publish traditional ApplicationEvent
        OrderCreatedEvent event = new OrderCreatedEvent(this, orderId, amount);
        eventPublisher.publishEvent(event);
    }
}
```

### 3. Listening to Events

```java
@Component
public class NotificationEventListener {

    @EventListener
    public void handleUserRegistered(UserRegisteredEvent event) {
        System.out.println("Sending welcome email to: " + event.getEmail());
        // Email sending logic here
    }

    @EventListener
    public void handleOrderCreated(OrderCreatedEvent event) {
        System.out.println("Processing order: " + event.getOrderId());
        // Order processing logic here
    }
}
```

## Advanced Event Listening

### 1. Multiple Events in One Listener
```java
@Component
public class MultipleEventListener {

    @EventListener({UserRegisteredEvent.class, OrderCreatedEvent.class})
    public void handleMultipleEvents(ApplicationEvent event) {
        if (event instanceof UserRegisteredEvent userEvent) {
            System.out.println("User registered: " + userEvent.getUsername());
        } else if (event instanceof OrderCreatedEvent orderEvent) {
            System.out.println("Order created: " + orderEvent.getOrderId());
        }
    }
}
```

### 2. Conditional Event Listening with SpEL
```java
@Component
public class ConditionalEventListener {

    @EventListener(condition = "#event.amount > 1000")
    public void handleLargeOrder(OrderCreatedEvent event) {
        System.out.println("Large order detected: " + event.getOrderId());
        // Special handling for large orders
    }

    @EventListener(condition = "#event.username.startsWith('admin')")
    public void handleAdminUser(UserRegisteredEvent event) {
        System.out.println("Admin user registered: " + event.getUsername());
        // Special handling for admin users
    }
}
```

### 3. Asynchronous Event Processing
```java
@Configuration
@EnableAsync
public class AsyncConfig {
}

@Component
public class AsyncEventListener {

    @Async
    @EventListener
    public void handleAsyncEvent(UserRegisteredEvent event) {
        // This will run in a separate thread
        System.out.println("Async processing for: " + event.getUsername());
        // Time-consuming operations like sending emails, generating reports, etc.
    }
}
```

### 4. Ordered Event Listeners
```java
@Component
public class OrderedEventListeners {

    @EventListener
    @Order(1)
    public void firstListener(UserRegisteredEvent event) {
        System.out.println("First listener executed");
    }

    @EventListener
    @Order(2)
    public void secondListener(UserRegisteredEvent event) {
        System.out.println("Second listener executed");
    }

    @EventListener
    @Order(3)
    public void thirdListener(UserRegisteredEvent event) {
        System.out.println("Third listener executed");
    }
}
```

## Complete Real-World Example

### 1. E-commerce Application Events

```java
// Events
public class PaymentReceivedEvent {
    private final String orderId;
    private final BigDecimal amount;
    private final String paymentMethod;

    public PaymentReceivedEvent(String orderId, BigDecimal amount, String paymentMethod) {
        this.orderId = orderId;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
    }
    // getters
}

public class InventoryUpdatedEvent {
    private final String productId;
    private final int quantity;

    public InventoryUpdatedEvent(String productId, int quantity) {
        this.productId = productId;
        this.quantity = quantity;
    }
    // getters
}

public class ShippingRequestedEvent {
    private final String orderId;
    private final String address;

    public ShippingRequestedEvent(String orderId, String address) {
        this.orderId = orderId;
        this.address = address;
    }
    // getters
}
```

### 2. Event Publishers
```java
@Service
@Transactional
public class OrderService {

    private final ApplicationEventPublisher eventPublisher;
    private final OrderRepository orderRepository;

    public OrderService(ApplicationEventPublisher eventPublisher, OrderRepository orderRepository) {
        this.eventPublisher = eventPublisher;
        this.orderRepository = orderRepository;
    }

    public void completeOrder(String orderId, BigDecimal amount, String paymentMethod) {
        // Update order status
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException(orderId));
        order.complete();

        // Publish multiple events
        eventPublisher.publishEvent(new PaymentReceivedEvent(orderId, amount, paymentMethod));
        eventPublisher.publishEvent(new InventoryUpdatedEvent(order.getProductId(), -1));
        eventPublisher.publishEvent(new ShippingRequestedEvent(orderId, order.getShippingAddress()));
    }
}
```

### 3. Event Listeners
```java
@Component
public class OrderEventListeners {

    private final EmailService emailService;
    private final InventoryService inventoryService;
    private final ShippingService shippingService;
    private final AnalyticsService analyticsService;

    public OrderEventListeners(EmailService emailService, InventoryService inventoryService,
                             ShippingService shippingService, AnalyticsService analyticsService) {
        this.emailService = emailService;
        this.inventoryService = inventoryService;
        this.shippingService = shippingService;
        this.analyticsService = analyticsService;
    }

    @EventListener
    public void handlePaymentReceived(PaymentReceivedEvent event) {
        // Process payment confirmation
        emailService.sendPaymentConfirmation(event.getOrderId());
        analyticsService.trackPayment(event.getOrderId(), event.getAmount());
    }

    @EventListener
    public void handleInventoryUpdate(InventoryUpdatedEvent event) {
        // Update inventory
        inventoryService.updateStock(event.getProductId(), event.getQuantity());
    }

    @EventListener
    public void handleShippingRequest(ShippingRequestedEvent event) {
        // Initiate shipping process
        shippingService.schedulePickup(event.getOrderId(), event.getAddress());
    }

    // Global exception handler for events
    @EventListener
    public void handleEventException(UncaughtExceptionEvent event) {
        System.err.println("Event processing failed: " + event.getSource());
        event.getException().printStackTrace();
    }
}
```

## Transaction-Bound Events

### 1. @TransactionalEventListener
```java
@Component
public class TransactionalEventListeners {

    // Executes only if transaction commits successfully
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void afterCommit(UserRegisteredEvent event) {
        System.out.println("After commit: " + event.getUsername());
    }

    // Executes after rollback
    @TransactionalEventListener(phase = TransactionPhase.AFTER_ROLLBACK)
    public void afterRollback(UserRegisteredEvent event) {
        System.out.println("After rollback: " + event.getUsername());
    }

    // Executes before commit
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void beforeCommit(UserRegisteredEvent event) {
        System.out.println("Before commit: " + event.getUsername());
    }
}
```

## Testing Event Publishing

```java
@SpringBootTest
class EventPublishingTest {

    @Autowired
    private UserService userService;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    @MockBean
    private EmailService emailService;

    @Test
    void testUserRegistrationPublishesEvent() {
        // Given
        String username = "testuser";
        String email = "test@example.com";

        // When
        userService.registerUser(username, email, "password");

        // Then
        verify(emailService).sendWelcomeEmail(email);
    }

    @Test
    void testEventPublisher() {
        // Given
        UserRegisteredEvent event = new UserRegisteredEvent("test", "test@example.com");
        
        // When & Then - verify no exception is thrown
        assertDoesNotThrow(() -> eventPublisher.publishEvent(event));
    }
}
```

## Benefits of Using ApplicationEventPublisher

1. **Loose Coupling**: Components don't need direct references to each other
2. **Separation of Concerns**: Business logic separated from cross-cutting concerns
3. **Extensibility**: Easy to add new listeners without modifying publishers
4. **Transactional Support**: Events can be tied to transaction boundaries
5. **Asynchronous Processing**: Long-running tasks can be handled asynchronously
6. **Error Isolation**: Failure in one listener doesn't affect others

## Common Use Cases

- **Notifications**: Email, SMS, push notifications
- **Audit Logging**: Tracking user actions
- **Cache Eviction**: Clearing caches when data changes
- **Integration**: Triggering external system updates
- **Analytics**: Tracking user behavior and metrics
- **Workflow**: Coordinating multi-step business processes

The `ApplicationEventPublisher` provides a powerful mechanism for building responsive, maintainable applications with clean separation between business logic and cross-cutting concerns.


###### Tags : [[1 - Spring Security 🍌]]