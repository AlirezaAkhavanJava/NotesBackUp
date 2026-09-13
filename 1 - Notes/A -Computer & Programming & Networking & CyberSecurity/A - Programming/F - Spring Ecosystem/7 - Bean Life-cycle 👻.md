


A **bean** is born, configured, used, then destroyed. Think of it as a very polite object that announces every phase of its existence.

**1) Container startup**  
Spring Boot starts the `ApplicationContext` and scans for components (`@Component`, `@Service`, `@Bean`, etc.).

**2) Bean instantiation**  
Spring creates the object using:

- constructor (preferred),
    
- or factory method (`@Bean`).
    

At this point, the object exists but is dumb and empty.

**3) Dependency injection**  
Spring injects dependencies:

- constructor injection,
    
- field injection,
    
- setter injection.
    

Now the bean knows about other beans.

**4) Aware callbacks (optional)**  
If the bean implements certain _Aware_ interfaces, Spring hands it internal tools:

- `BeanNameAware` → bean name
    
- `ApplicationContextAware` → context reference  
    This is advanced plumbing, not everyday work.
    

**5) BeanPostProcessor – before init**  
All `BeanPostProcessor`s run:

```java
postProcessBeforeInitialization()
```

This is how Spring adds magic like proxies (AOP, transactions).

**6) Initialization**  
Any of these run (in this order):

- `@PostConstruct`
    
- `InitializingBean.afterPropertiesSet()`
    
- `initMethod` from `@Bean`
    

This is where you open connections, validate config, warm caches.

**7) BeanPostProcessor – after init**

```java
postProcessAfterInitialization()
```

Often where proxies are finalized.

**8) Bean is ready**  
The bean is fully initialized and used by the application.

**9) Container shutdown**  
When the app stops, Spring shuts down gracefully.

**10) Destruction**  
Cleanup callbacks run:

- `@PreDestroy`
    
- `DisposableBean.destroy()`
    
- `destroyMethod` from `@Bean`
    

This is where you close connections and free resources.

---

**Minimal lifecycle summary (the one to remember):**

```
Instantiate
→ Inject dependencies
→ @PostConstruct
→ Ready to use
→ @PreDestroy
```

Spring Boot’s trick is not changing this lifecycle, but **removing the boilerplate** so you rarely notice it—until you need to hook into it.

Once you see beans as living organisms with rituals, Spring stops feeling mystical and starts feeling engineered.

##### Tags : [[0 - Spring Framework]]