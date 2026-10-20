## BeanFactory in Spring

`BeanFactory` is the **core IoC (Inversion of Control) container interface** in Spring. It is responsible for **creating, configuring, and managing Spring Beans**.

Think of it as the **factory that produces objects**.

```
BeanFactory

       |
       |
       v

Creates ---> Bean Objects
Manages ---> Bean Lifecycle
Provides --> Dependencies
```

---

## Basic idea

Without Spring:

```java
public class Main {

    public static void main(String[] args) {

        UserService service = new UserService();

    }
}
```

You manually create objects.

With Spring:

```java
UserService service = beanFactory.getBean(UserService.class);
```

Spring creates and gives you the object.

---

# BeanFactory example

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService();
    }
}
```

Create the container:

```java
BeanFactory factory =
        new AnnotationConfigApplicationContext(AppConfig.class);
```

Get the bean:

```java
UserService service =
        factory.getBean(UserService.class);
```

---

# BeanFactory responsibilities

## 1. Bean creation

Creates objects:

```java
@Bean
public Database database() {
    return new Database();
}
```

Spring creates:

```
Database object
       |
       v
BeanFactory
```

---

## 2. Dependency Injection

Example:

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

Spring sees:

```
OrderService needs PaymentService

        |
        v

Find PaymentService bean

        |
        v

Inject it
```

---

## 3. Bean lifecycle management

BeanFactory manages:

```
Create Object
      |
      v
Inject Dependencies
      |
      v
Initialize Bean
      |
      v
Use Bean
      |
      v
Destroy Bean
```

---

## 4. Bean lookup

You can ask:

```java
factory.getBean("userService");
```

or:

```java
factory.getBean(UserService.class);
```

---

# BeanFactory vs ApplicationContext

In modern Spring Boot, you almost never use `BeanFactory` directly.

Spring Boot uses:

```
ApplicationContext
          |
          |
          v
     BeanFactory
```

`ApplicationContext` extends `BeanFactory`.

Hierarchy:

```
BeanFactory
     |
     |
     v
ApplicationContext
     |
     |
     v
Spring Boot Application
```

---

## BeanFactory vs ApplicationContext

|Feature|BeanFactory|ApplicationContext|
|---|---|---|
|Bean creation|✅|✅|
|Dependency Injection|✅|✅|
|Bean lifecycle|✅|✅|
|Internationalization|❌|✅|
|Events|❌|✅|
|AOP integration|Limited|Better|
|Eager initialization|❌|✅|
|Used in Spring Boot|Rarely|Always|

---

## Why does BeanFactory still exist?

Historically, Spring started with `BeanFactory`.

Early Spring applications needed a lightweight container:

```
BeanFactory
   |
   |
small memory footprint
```

Later applications needed more features:

```
ApplicationContext
   |
   +-- Events
   +-- AOP
   +-- Security integration
   +-- Validation
   +-- Messages
```

So Spring Boot uses `ApplicationContext`.

---

## Spring Boot startup flow

When you run:

```bash
./mvnw spring-boot:run
```

Internally:

```
SpringApplication.run()
          |
          v
Create ApplicationContext
          |
          v
Create BeanFactory
          |
          v
Scan Components
          |
          v
Create Beans
          |
          v
Inject Dependencies
          |
          v
Application Ready
```

---

### Mental model

- **Bean** → Object managed by Spring
    
- **BeanFactory** → Object factory + manager
    
- **ApplicationContext** → Advanced BeanFactory with enterprise features
    
- **Spring Boot** → Automatically creates and configures the ApplicationContext for you
    

In modern Spring Boot development, you mostly interact with **ApplicationContext indirectly** through annotations like `@Component`, `@Service`, `@Autowired`, and constructor injection.


[[Spring Framework]]