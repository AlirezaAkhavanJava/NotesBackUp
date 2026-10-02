
## What is This? 

Imagine you order a pizza 🍕. Your request goes through many steps:

1. **Order taker** answers phone
2. **Chef** makes pizza  
3. **Delivery person** brings it to you

Distributed tracing is like putting a **tracking number** on your pizza order so you can see:
- Where your pizza is right now
- How long it's taking at each step
- If something gets stuck or lost

## Why Do We Need This?

Without tracing: "My pizza is late! No one knows why!" 😠

With tracing: "The chef took 30 minutes, but the delivery is stuck in traffic" 🕵️

## The Simple Pieces You Need

### 1. Micrometer - The "Measuring Tape" 📏
```xml
<!-- Add this to your pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### 2. Zipkin - The "Big Scoreboard" 📺
```bash
# Just run this command
docker run -d -p 9411:9411 openzipkin/zipkin
```

### 3. Tracing Library - The "Tracking Stickers" 🏷️
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-brave</artifactId>
</dependency>
```

## Let's Make It Work - 3 Easy Steps

### Step 1: Tell Your App "Hey, Track Stuff!"
```yaml
# Put this in application.yml
management:
  tracing:
    sampling:
      probability: 1.0  # Track EVERYTHING
```

### Step 2: Tell Your App Where to Send Tracking Info
```yaml
spring:
  zipkin:
    base-url: http://localhost:9411  # Where Zipkin lives
```

### Step 3: Write Normal Code - Magic Happens Automatically! ✨
```java
@RestController
public class PizzaController {
    
    @GetMapping("/order-pizza")
    public String orderPizza() {
        // Spring automatically adds tracing!
        return "Your pizza is being made!";
    }
}
```

## What You'll See 🎉

1. **Run your app**
2. **Go to http://localhost:9411** (Zipkin)
3. **See pretty pictures** showing how requests flow!

You'll see:
- Which services were called
- How long each took
- If anything failed

## Real Example - Pizza Shop 🍕

```java
@RestController
public class PizzaShopController {

    // Order pizza - gets automatic tracing!
    @GetMapping("/order")
    public String orderPizza() {
        makePizza();
        deliverPizza();
        return "Pizza delivered!";
    }
    
    private void makePizza() {
        // This gets traced too!
        System.out.println("Making pizza...");
    }
    
    private void deliverPizza() {
        // This also gets traced!
        System.out.println("Delivering pizza...");
    }
}
```

## Troubleshooting 🔧

If it doesn't work:
1. **Did you run the Zipkin command?** ✅
2. **Did you add the dependencies?** ✅  
3. **Is your app running?** ✅

## Remember This Picture 🖼️

```
Your App → [Automatic Tracing] → Zipkin Dashboard → You See Everything!
```

That's it! You now have superpowers to see inside your app! 🦸‍♂️

Just add those few lines of code and you get free pizza tracking! 🍕➡️👀

[[0 - Spring Framework]]