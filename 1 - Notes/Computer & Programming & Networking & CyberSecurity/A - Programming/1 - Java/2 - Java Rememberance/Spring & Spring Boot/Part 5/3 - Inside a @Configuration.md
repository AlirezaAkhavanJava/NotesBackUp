
Being inside a `@Configuration` class doesn't automatically make something a bean. Only the **methods** annotated with `@Bean` become beans. Everything else in the class (fields, helper methods, constructors, non-`@Bean` methods) is just regular code that supports those bean-producing methods.

```java
@Configuration
public class AppConfig {

    // NOT a bean — just a helper method
    private String buildUrl() {
        return "jdbc:postgresql://localhost:5432/mydb";
    }

    // NOT a bean — a plain field
    private final String appName = "MyApp";

    @Bean
    public DataSource dataSource() {
        DataSource ds = new HikariDataSource();
        ds.setJdbcUrl(buildUrl()); // using the helper above
        return ds;
    }

    @Bean
    public MyService myService() {
        return new MyServiceImpl();
    }
}
```

Here only `dataSource()` and `myService()` are registered as beans in the Spring `ApplicationContext`. `buildUrl()` is never called by Spring directly — it's just a normal Java method that happens to be used _inside_ a bean-producing method.

**Why `@Configuration` matters, though**

The class-level `@Configuration` annotation does something important that's easy to overlook: it enables **CGLIB proxying** of the class, so that if one `@Bean` method calls another `@Bean` method directly, Spring intercepts that call and returns the _same singleton instance_ from the context instead of a brand-new object:

```java
@Bean
public MyService myService() {
    return new MyServiceImpl(dataSource()); // returns the SAME dataSource bean
}
```

If you used `@Component` (or plain `@Configuration(proxyBeanMethods = false)`) instead, calling `dataSource()` here would create a _new_ `DataSource` object each time, bypassing Spring's container — which is usually not what you want.

**Summary**

- `@Configuration` → marks the class as a source of bean definitions (and enables the proxy behavior above).
- `@Bean` → marks an individual _method_ whose return value should be registered as a bean.
- Anything else in the class is just normal Java, not managed by Spring.


[[0 - Spring Framework]]