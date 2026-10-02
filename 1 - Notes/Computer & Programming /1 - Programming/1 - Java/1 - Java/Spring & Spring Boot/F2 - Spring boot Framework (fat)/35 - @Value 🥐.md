
In Spring, `@Value` is an annotation used to inject values into fields, methods, or constructor parameters. These values usually come from:

- Properties files (`application.properties` or `application.yml`)
    
- System/environment variables
    
- Literal values
    

### Examples:

**1. Injecting a property value**

```java
@Value("${app.name}")
private String appName;
```

Here, `app.name` should be defined in `application.properties`:

```
app.name=UltimateArcade
```

**2. Injecting a default value**

```java
@Value("${app.timeout:5000}")
private int timeout;
```

If `app.timeout` is not defined, it will default to `5000`.

**3. Injecting an expression**

```java
@Value("#{2 * 5}")
private int result; // 10
```

**4. Injecting a system/environment variable**

```java
@Value("${JAVA_HOME}")
private String javaHome;
```

**Key points:**

- Can be used on fields, constructors, or methods.
    
- Works with Spring Expression Language (SpEL) for dynamic values.
    
- Often used for configuration values that you don’t want to hardcode.
    


##### Tags : [[0 - Spring Framework]]