

## Spring Framework roadmap

|Stage|Concepts to learn|What you should be able to do|
|---|---|---|
|0|Prerequisites||
|1|Java OOP, interfaces, inheritance, polymorphism, exceptions, generics, annotations, reflection|Understand the Java features Spring relies on|
|2|Maven, `pom.xml`, dependencies, classpath, packaging JAR/WAR|Build and run a Spring application without Boot|
|3|Spring Core||
|4|IoC (Inversion of Control), DI (Dependency Injection), loose coupling|Explain why Spring creates and injects objects|
|5|`BeanFactory`, `ApplicationContext`, Spring beans|Create and retrieve objects from the container|
|6|`@Component`, `@Service`, `@Repository`, `@Controller`, `@ComponentScan`|Register application classes as Spring beans|
|7|`@Autowired`, constructor injection, `@Qualifier`, `@Primary`|Inject dependencies correctly, including multiple implementations|
|8|`@Configuration`, `@Bean`, `@Import`, Java-based configuration|Configure the application without Spring Boot|
|9|Bean scopes, lifecycle callbacks, initialization and destruction|Understand when beans are created and destroyed|
|10|`@Value`, `Environment`, properties files, profiles|Externalize configuration and separate development settings|
|11|Application events, `ApplicationListener`, resource loading|Work with Spring events and application resources|
|12|AOP, proxies, advice, pointcuts, aspects|Understand cross-cutting concerns such as logging|
|13|Database integration||
|14|JDBC, `DataSource`, `JdbcTemplate`, DAO pattern|Connect Spring to PostgreSQL or MariaDB|
|15|Transactions, `@Transactional`, propagation, isolation, rollback|Manage database transactions reliably|
|16|JPA, Hibernate, entity mapping, relationships, persistence context|Map Java objects to database tables|
|17|Spring MVC||
|18|Java Servlet API, HTTP, request/response, servlet lifecycle|Understand the web infrastructure beneath Spring MVC|
|19|`DispatcherServlet`, `WebApplicationContext`, `WebApplicationInitializer`|Start Spring MVC without Spring Boot|
|20|`@RequestMapping`, `@GetMapping`, `@PostMapping`, controllers|Build endpoints that handle HTTP requests|
|21|`@PathVariable`, `@RequestParam`, `@RequestBody`, data binding|Receive and process request data|
|22|`@RestController`, JSON, `HttpMessageConverter`, Jackson integration|Create REST APIs that exchange JSON|
|23|Validation, `@Valid`, `BindingResult`, exception handling, `@ControllerAdvice`|Validate input and return meaningful error responses|
|24|Interceptors, servlet filters, CORS, content negotiation|Handle cross-cutting HTTP behavior|
|25|View resolvers, MVC model, JSP or another view technology|Understand server-rendered web applications|
|26|Testing and production readiness||
|27|JUnit, Mockito, unit tests, integration tests|Test services and repositories|
|28|Spring TestContext Framework, `MockMvc`|Test Spring configuration and MVC endpoints|
|29|Logging, exception diagnosis, configuration management|Debug real applications|
|30|External Tomcat deployment, WAR packaging, environment variables|Deploy a traditional Spring web application|
|31|Additional ecosystem||
|32|Spring Security: authentication, authorization, filter chain|Secure endpoints and users|
|33|Spring Data JPA, pagination, sorting, repository abstractions|Reduce repetitive database code|
|34|Scheduling, caching, email, asynchronous tasks|Add common application capabilities|

The roadmap follows the official Spring Framework documentation, which separates core container technologies, data access, MVC, and testing.


## Official documentation

- [Spring Framework Reference](https://docs.spring.io/spring-framework/reference/?utm_source=chatgpt.com) — the main guide.
    
- [Core Container and Beans](https://docs.spring.io/spring-framework/reference/core/beans.html?utm_source=chatgpt.com) — start here.
    
- [Data Access](https://docs.spring.io/spring-framework/reference/data-access.html?utm_source=chatgpt.com) — JDBC and transactions.
    
- [Spring MVC](https://docs.spring.io/spring-framework/reference/web/webmvc.html?utm_source=chatgpt.com) — web development.
    
- [Testing](https://docs.spring.io/spring-framework/reference/testing.html?utm_source=chatgpt.com) — application testing.
    





[[Spring Framework]]