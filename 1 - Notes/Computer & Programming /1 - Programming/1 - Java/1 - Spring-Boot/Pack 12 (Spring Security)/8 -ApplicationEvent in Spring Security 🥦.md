
# **ApplicationEvent in Spring Security**

Spring Security fires several **built-in application events** during authentication and authorization.  
These events let you **listen** to security actions (login success, login failure, logout, etc.) and react.

You **do NOT** create these events yourself — Spring Security publishes them automatically.

---

# **Most important Spring Security events**

## ✅ **Authentication events**

|Event|When it fires|
|---|---|
|**AuthenticationSuccessEvent**|User authentication succeeded|
|**AbstractAuthenticationFailureEvent**|Authentication failed (wrong password, disabled, locked…)|
|**InteractiveAuthenticationSuccessEvent**|User logged in through a UI (not remember-me)|
|**AuthenticationSwitchUserEvent**|When using SwitchUserFilter (`/login/impersonate`)|

---

## ✅ **Authorization events**

|Event|Meaning|
|---|---|
|**AuthorizationFailureEvent**|Access denied before method/URL invocation|
|**AuthorizedEvent**|Access granted|
|**AuthorizationDeniedEvent**|(newer event) consistent Deny event|

---

## **Example: Listen to login success / failure**

### Listener

```java
@Component
public class SecurityEventsListener {

    @EventListener
    public void onSuccess(AuthenticationSuccessEvent event) {
        System.out.println("LOGIN SUCCESS: " + event.getAuthentication().getName());
    }

    @EventListener
    public void onFailure(AbstractAuthenticationFailureEvent event) {
        System.out.println("LOGIN FAILED: " + event.getException().getMessage());
    }
}
```

Spring fires these events automatically — you only listen.

---

# **Where are these fired?**

Internally from:

- `ProviderManager`
    
- `AbstractUserDetailsAuthenticationProvider`
    
- `DaoAuthenticationProvider`
    
- `AffirmativeBased` / authorization managers (new stack)
    

---

# **Summary (brutal truth version)**

- `ApplicationEvent` itself = old but still used under the hood.
    
- Spring Security **still uses events heavily**, even after POJO-event support.
    
- You attach listeners with `@EventListener` — simple.
    
- Useful for logging, auditing, counting failed logins, lockout systems, etc.
    

---




###### Tags : [[1 - Spring Security 🍌]]