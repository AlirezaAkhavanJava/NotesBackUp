

# **What it is**

`ApplicationEvent` is the **old base class** for defining events in Spring.

Before Spring 4.2, if you wanted to publish a custom event, you **had to** extend `ApplicationEvent`.

Example (OLD STYLE):

```java
public class MyEvent extends ApplicationEvent {
    public MyEvent(Object source) {
        super(source);
    }
}
```

Then:

```java
publisher.publishEvent(new MyEvent(this));
```

---

# **Is it still needed today?**

**No.**  
Spring **does not require** extending `ApplicationEvent` anymore.

You can publish **any POJO** as an event:

```java
public record MyEvent(String message) {}
```

---

# **Is `ApplicationEvent` deprecated?**

It’s **not marked deprecated**, but it’s **legacy** and **almost nobody uses it anymore** in new Spring code.

---

# **In Spring Security?**

Spring Security still fires some **built-in events** that extend `ApplicationEvent`, like:

- `AuthenticationSuccessEvent`
    
- `AbstractAuthenticationFailureEvent`
    
- `AuthorizationFailureEvent`
    

But **you do NOT write your own ApplicationEvent for Spring Security**.

You only _listen_ to what Spring Security publishes.

---

# **Bottom line**

`ApplicationEvent` is in your import only if:

- you're using old-style custom events (not recommended), or
    
- you're listening to Spring Security events (recommended), but you do **not** create your own subclasses.
    

---



###### Tags : [[1 - Spring Security 🍌]]