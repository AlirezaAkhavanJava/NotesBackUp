Date : 2025-09-01


In Spring Boot, **BeanFactory** and **ApplicationContext** are core components of the Spring Framework’s Inversion of Control (IoC) container, responsible for managing beans (objects). 

### **BeanFactory**
- **Definition**: BeanFactory is the simplest container in the Spring Framework, providing basic support for dependency injection and bean management. It is defined by the `org.springframework.beans.factory.BeanFactory` interface.
- **Purpose**: It creates, configures, and manages beans, resolving their dependencies as defined in configuration metadata (e.g., XML, Java annotations, or Java config).
- **Key Features**:
  - Lazy initialization: Beans are created only when requested, reducing memory usage.
  - Basic dependency injection: Supports wiring beans together.
  - Minimalistic: Provides core IoC functionality without advanced features.
  - Lifecycle management: Handles bean creation, initialization, and destruction.
- **Usage**: Rarely used directly in modern Spring applications due to its limited feature set compared to ApplicationContext.

### **ApplicationContext**
- **Definition**: ApplicationContext is an advanced container, *extending BeanFactory*, and is defined by the `org.springframework.context.ApplicationContext` interface. It adds enterprise-level features and is the primary container used in Spring Boot.
- **Purpose**: It manages beans like BeanFactory but also provides additional functionalities like event propagation, internationalization, and resource loading.


- **Key Features**:
  - Eager initialization: *==By default, beans are created and initialized when the context starts (configurable to lazy).==*
  - Advanced features:
    - Event publishing (e.g., ApplicationEvent support).
    - Internationalization (i18n) for message resolution.
    - Resource loading (e.g., accessing files, classpath resources).
    - Support for annotations like `@Autowired`, `@PostConstruct`, and profiles.
  - Environment abstraction: Access to environment properties and profiles.
  - Integration with Spring Boot: Automatically configured in Spring Boot via `@SpringBootApplication`.
- **Usage**: The default choice in Spring Boot, typically accessed via `SpringApplication.run()` or annotations.

### **Differences Between BeanFactory and ApplicationContext**

| **Aspect**                 | **BeanFactory**                              | **ApplicationContext**                       |
|----------------------------|----------------------------------------------|---------------------------------------------|
| **Interface**              | `org.springframework.beans.factory.BeanFactory` | `org.springframework.context.ApplicationContext` |
| **Initialization**         | Lazy (beans created on demand)              | Eager (beans created at startup, unless configured otherwise) |
| **Feature Set**            | Basic IoC and dependency injection          | Advanced features (events, i18n, resources, profiles, etc.) |
| **Annotation Support**     | Limited (requires manual configuration)     | Full support for annotations (`@Autowired`, `@Configuration`, etc.) |
| **Event Handling**         | No event propagation                        | Supports ApplicationEvent and listeners      |
| **Resource Loading**       | Not supported                               | Supports loading resources (files, classpath) |
| **Internationalization**   | Not supported                               | Built-in support for i18n                   |
| **Environment Access**     | Not supported                               | Access to environment properties/profiles   |
| **Use in Spring Boot**     | Rarely used                                 | Default container, auto-configured          |
| **Performance**            | Lighter due to lazy loading                 | Slightly heavier due to eager loading and additional features |
| **Extensibility**          | Minimalistic, less extensible               | Highly extensible with additional modules   |

### **Key Points in Spring Boot Context**
- **Spring Boot Usage**: In Spring Boot, you typically interact with `ApplicationContext` (e.g., `ConfigurableApplicationContext` returned by `SpringApplication.run()`). BeanFactory is rarely used directly because Spring Boot leverages the richer features of ApplicationContext for auto-configuration, component scanning, and profile management.
- **Configuration**: Both can use XML, Java config, or annotations, but ApplicationContext seamlessly integrates with Spring Boot’s `@SpringBootApplication` and auto-configuration mechanisms.
- **Example**:
  - **BeanFactory**:
    ```java
    XmlBeanFactory factory = new XmlBeanFactory(new ClassPathResource("beans.xml"));
    MyBean bean = factory.getBean(MyBean.class);
    ```
  - **ApplicationContext** (Spring Boot):
    ```java
    @SpringBootApplication
    public class Application {
        public static void main(String[] args) {
            ApplicationContext context = SpringApplication.run(Application.class, args);
            MyBean bean = context.getBean(MyBean.class);
        }
    }
    ```

### **When to Use Which?**
- **BeanFactory**: Use in resource-constrained environments or simple applications where only basic IoC is needed. It’s lightweight but lacks Spring’s advanced features.
- **ApplicationContext**: Use in most Spring Boot applications for its comprehensive feature set, ease of use, and integration with Spring Boot’s auto-configuration.

### **Summary**
BeanFactory is a lightweight, basic IoC container with lazy initialization, suitable for minimalistic applications. ApplicationContext is a more feature-rich container with eager initialization, event handling, and support for Spring Boot’s ecosystem. In Spring Boot, ApplicationContext is the standard choice due to its robustness and seamless integration.



##### *Tags : [[0 - Spring Framework]]