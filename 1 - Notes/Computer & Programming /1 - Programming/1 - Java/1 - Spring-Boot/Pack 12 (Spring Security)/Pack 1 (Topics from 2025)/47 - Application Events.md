

![[Pasted image 20251118124837.png]]
## What Are Application Events?

Application Events in Spring implement the **Observer Design Pattern**, allowing different parts of your application to communicate without being tightly coupled.

### Real-World Analogy
Think of it like a **newspaper subscription**:
- **Publisher**: The newspaper company (publishes news)
- **Subscribers**: People who want the news (listen for specific topics)
- **Events**: The actual news articles

The publisher doesn't need to know who the subscribers are, and subscribers don't need to know about each other.

## Core Concepts Explained

### 1. The Three Main Components

```
Event Publisher → Creates & Sends Events
       ↓
Application Context → Event Bus (Manages Event Delivery)
       ↓
Event Listeners → Receive & Process Events
```

![[Pasted image 20251118125044.png]]
### 2. How It Actually Works

```java
// Step 1: Someone publishes an event
eventPublisher.publishEvent(new UserRegisteredEvent("john", "john@email.com"));

// Step 2: Spring Framework looks for all listeners that care about UserRegisteredEvent
// Step 3: Spring calls each listener method with the event
```

## Detailed Code Walkthrough

### Step 1: Creating Custom Events

**What are events?** Events are simple Java objects that carry information about something that happened.

```java
/**
 * A custom event representing user registration
 * This is just a plain Java object that carries data
 */
public class UserRegisteredEvent {
    // These fields store information about what happened
    private String username;
    private String email;
    private LocalDateTime timestamp;
    private boolean welcomeEmailSent = false;

    // Constructor - called when creating the event
    public UserRegisteredEvent(String username, String email) {
        this.username = username;
        this.email = email;
        this.timestamp = LocalDateTime.now(); // Record when it happened
    }

    // Getters - allow listeners to access the event data
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public LocalDateTime getTimestamp() { return timestamp; }
    public boolean isWelcomeEmailSent() { return welcomeEmailSent; }
    
    // Setter - allows listeners to modify the event
    public void setWelcomeEmailSent(boolean sent) { this.welcomeEmailSent = sent; }
}
```

**Key Points:**
- Events are just data containers
- They should be immutable (can't change after creation) or have controlled modification
- They represent something that already happened (past tense naming)

### Step 2: Publishing Events

**What is publishing?** Publishing means announcing that something happened to anyone who might be interested.

```java
@Service
public class UserService {
    
    // Spring automatically provides this - it's the "announcer"
    private final ApplicationEventPublisher eventPublisher;
    private final UserRepository userRepository;

    // Constructor injection - Spring provides the dependencies
    public UserService(ApplicationEventPublisher eventPublisher, UserRepository userRepository) {
        this.eventPublisher = eventPublisher = eventPublisher;
        this.userRepository = userRepository;
    }

    public User registerUser(String username, String email, String password) {
        System.out.println("=== Starting user registration ===");
        
        // 1. Create user in database (main business logic)
        User user = new User(username, email, password);
        User savedUser = userRepository.save(user);
        System.out.println("User saved to database: " + username);

        // 2. PUBLISH THE EVENT - announce that registration happened
        System.out.println("Publishing UserRegisteredEvent...");
        UserRegisteredEvent event = new UserRegisteredEvent(username, email);
        eventPublisher.publishEvent(event);
        System.out.println("Event published successfully!");

        // 3. Return the created user
        return savedUser;
    }
}
```

**What happens when publishEvent() is called:**
1. The method creates a `UserRegisteredEvent` object with the user data
2. It calls `eventPublisher.publishEvent(event)`
3. Spring takes over and delivers this event to ALL interested listeners
4. The registerUser method continues immediately - it doesn't wait for listeners to finish

### Step 3: Listening to Events

**What are listeners?** Listeners are methods that "subscribe" to specific types of events and get automatically called when those events occur.

```java
@Component  // This tells Spring: "I'm a component that needs to be managed"
public class NotificationEventListener {

    @EventListener  // This tells Spring: "Call this method when a UserRegisteredEvent happens"
    public void handleUserRegistered(UserRegisteredEvent event) {
        System.out.println("📧 [Email Listener] Sending welcome email to: " + event.getEmail());
        
        // Simulate sending email
        try {
            Thread.sleep(1000); // Simulate time to send email
            System.out.println("✅ Welcome email sent to: " + event.getEmail());
            
            // We can even update the event if needed
            event.setWelcomeEmailSent(true);
        } catch (InterruptedException e) {
            System.out.println("❌ Failed to send email to: " + event.getEmail());
        }
    }
}
```

**Another Listener Example:**
```java
@Component
public class AnalyticsEventListener {

    @EventListener
    public void trackUserRegistration(UserRegisteredEvent event) {
        System.out.println("📊 [Analytics Listener] Tracking new user: " + event.getUsername());
        // In real application, this would send data to analytics service
        System.out.println("✅ User tracked in analytics: " + event.getUsername());
    }
}
```

## Complete Working Example

Let's create a complete example you can run and understand:

### 1. Create the Event Classes

```java
// Event 1: User registration
public class UserRegisteredEvent {
    private String username;
    private String email;
    
    public UserRegisteredEvent(String username, String email) {
        this.username = username;
        this.email = email;
    }
    // getters
    public String getUsername() { return username; }
    public String getEmail() { return email; }
}

// Event 2: Order creation  
public class OrderCreatedEvent {
    private String orderId;
    private BigDecimal amount;
    
    public OrderCreatedEvent(String orderId, BigDecimal amount) {
        this.orderId = orderId;
        this.amount = amount;
    }
    // getters
    public String getOrderId() { return orderId; }
    public BigDecimal getAmount() { return amount; }
}
```

### 2. Create the Service (Event Publisher)

```java
@Service
public class ECommerceService {
    private final ApplicationEventPublisher eventPublisher;

    public ECommerceService(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    public void registerUser(String username, String email) {
        System.out.println("\n--- User Registration Process ---");
        System.out.println("1. Saving user to database: " + username);
        
        // Simulate database save
        try { Thread.sleep(500); } catch (InterruptedException e) {}
        
        System.out.println("2. Publishing UserRegisteredEvent");
        eventPublisher.publishEvent(new UserRegisteredEvent(username, email));
        
        System.out.println("3. User registration completed!");
    }

    public void createOrder(String orderId, BigDecimal amount) {
        System.out.println("\n--- Order Creation Process ---");
        System.out.println("1. Creating order in database: " + orderId);
        
        // Simulate database save  
        try { Thread.sleep(500); } catch (InterruptedException e) {}
        
        System.out.println("2. Publishing OrderCreatedEvent");
        eventPublisher.publishEvent(new OrderCreatedEvent(orderId, amount));
        
        System.out.println("3. Order creation completed!");
    }
}
```

### 3. Create Multiple Listeners

```java
@Component
public class EmailServiceListener {
    
    @EventListener
    public void sendWelcomeEmail(UserRegisteredEvent event) {
        System.out.println("   ✉️  [EMAIL] Sending welcome email to: " + event.getEmail());
    }
    
    @EventListener  
    public void sendOrderConfirmation(OrderCreatedEvent event) {
        System.out.println("   ✉️  [EMAIL] Sending order confirmation for: " + event.getOrderId());
    }
}

@Component
public class AnalyticsServiceListener {
    
    @EventListener
    public void trackNewUser(UserRegisteredEvent event) {
        System.out.println("   📈 [ANALYTICS] Tracking new user: " + event.getUsername());
    }
    
    @EventListener
    public void trackNewOrder(OrderCreatedEvent event) {
        System.out.println("   📈 [ANALYTICS] Tracking new order: " + event.getOrderId() + 
                          ", Amount: $" + event.getAmount());
    }
}

@Component  
public class InventoryServiceListener {
    
    @EventListener
    public void updateInventory(OrderCreatedEvent event) {
        System.out.println("   📦 [INVENTORY] Updating stock for order: " + event.getOrderId());
    }
}
```

### 4. Test Controller to See It in Action

```java
@RestController
public class TestController {
    private final ECommerceService ecommerceService;

    public TestController(ECommerceService ecommerceService) {
        this.ecommerceService = ecommerceService;
    }

    @GetMapping("/test-events")
    public String testEvents() {
        System.out.println("=== STARTING EVENT DEMO ===");
        
        // Test user registration
        ecommerceService.registerUser("john_doe", "john@example.com");
        
        // Test order creation  
        ecommerceService.createOrder("ORD-123", new BigDecimal("99.99"));
        
        return "Check console output to see events in action!";
    }
}
```

## Expected Output

When you call `/test-events`, you'll see:

```
=== STARTING EVENT DEMO ===

--- User Registration Process ---
1. Saving user to database: john_doe
2. Publishing UserRegisteredEvent
   ✉️  [EMAIL] Sending welcome email to: john@example.com
   📈 [ANALYTICS] Tracking new user: john_doe
3. User registration completed!

--- Order Creation Process ---
1. Creating order in database: ORD-123
2. Publishing OrderCreatedEvent
   ✉️  [EMAIL] Sending order confirmation for: ORD-123
   📈 [ANALYTICS] Tracking new order: ORD-123, Amount: $99.99
   📦 [INVENTORY] Updating stock for order: ORD-123
3. Order creation completed!
```

## Key Learning Points

### 1. **Loose Coupling**
- `ECommerceService` doesn't know about email, analytics, or inventory services
- It just publishes events and doesn't care who listens
- You can add new listeners without changing the publisher

### 2. **Separation of Concerns**
- User registration logic is separate from email logic
- Analytics tracking is separate from inventory management
- Each service focuses on one responsibility

### 3. **Automatic Delivery**
- Spring automatically finds all listeners for an event type
- You don't have to manually register listeners
- The publisher doesn't need to maintain a list of subscribers

### 4. **Synchronous by Default**
- Events are processed immediately in the same thread
- The publisher waits for all listeners to finish
- This ensures data consistency but can slow down responses

## Advanced Features

### Asynchronous Events
```java
@Configuration
@EnableAsync
public class AsyncConfig {
}

@Component
public class SlowEventListener {
    
    @Async  // This makes the method run in a different thread
    @EventListener
    public void sendSlowEmail(UserRegisteredEvent event) {
        System.out.println("Starting slow email process...");
        try { Thread.sleep(3000); } catch (InterruptedException e) {} // 3 seconds
        System.out.println("Slow email sent!");
    }
}
```

### Conditional Events
```java
@EventListener(condition = "#event.amount > 100")
public void handleLargeOrder(OrderCreatedEvent event) {
    System.out.println("Large order detected: " + event.getOrderId());
    // Special handling for expensive orders
}
```

## When to Use Application Events

**✅ Good Use Cases:**
- Sending notifications (email, SMS)
- Updating search indexes
- Cache invalidation
- Audit logging
- Integration with external systems

**❌ Bad Use Cases:**
- Critical business logic that must succeed
- Time-sensitive operations
- Operations that need immediate feedback
- Replacement for method calls within the same transaction

## Summary

**Application Events = In-App Notification System**

- **Publisher**: "Hey, something happened!" (creates and publishes events)
- **Listeners**: "I care about that!" (automatically receive relevant events)  
- **Spring**: The postal service that delivers events to the right listeners

This pattern makes your code more modular, testable, and maintainable by reducing direct dependencies between components.

###### Tags : [[1 - Spring Security 🍌]]