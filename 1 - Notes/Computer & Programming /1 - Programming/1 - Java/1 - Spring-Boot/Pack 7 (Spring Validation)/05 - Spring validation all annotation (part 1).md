
Here is a map of the Spring annotations worth knowing, grouped by what they do. The Spring ecosystem has hundreds of annotations, so I kept the ones that earn a place in real projects. Each line says what the annotation is for, so you can see where it fits. Ones you have already studied are listed in one line only, and the groups you haven't covered yet get the detail.

## Core container (beans and wiring)

|Annotation|Use it for|
|---|---|
|`@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`|Mark a class as a bean, with the layer stated in its name|
|`@Configuration` + `@Bean`|Create beans in Java code, especially for third-party classes|
|`@ComponentScan`|Choose where Spring looks for beans|
|`@Import`|Pull one configuration class into another|
|`@Primary`|Pick the default when several beans have the same type|
|`@Qualifier`|Pick one specific bean by name when several match|
|`@Lazy`|Create a bean on first use, not at startup|
|`@DependsOn`|Force bean creation order|
|`@Scope`|Change the bean scope (`prototype`, `request`, `session`)|
|`@Order`|Order beans inside a list, like filters or interceptors|
|`@Value`|Inject a single property value|
|`@Profile`|Activate a bean only in some environments|
|`@PostConstruct`, `@PreDestroy`|Run code after creation and before destruction|

## Spring Boot

|Annotation|Use it for|
|---|---|
|`@SpringBootApplication`|Entry point: bundles `@Configuration`, `@ComponentScan` and auto-configuration|
|`@ConfigurationProperties`|Bind a group of properties to a typed class (a record works well)|
|`@ConfigurationPropertiesScan`|Register those classes automatically|
|`@ConditionalOnProperty`|Create a bean only if a property has a given value|
|`@ConditionalOnMissingBean`|Create a default bean only if the user hasn't defined one|
|`@ConditionalOnClass`, `@ConditionalOnBean`|Create a bean depending on classpath or other beans|
|`@EntityScan`, `@EnableJpaRepositories`|Tell Spring where entities and repositories live|

The `@Conditional...` family is mostly for writing your own starters and shared configuration. `@ConditionalOnProperty` is also handy for feature flags in normal apps.

## Web (Spring MVC)

|Annotation|Use it for|
|---|---|
|`@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping`, `@DeleteMapping`|Map HTTP methods to handler methods (prefer these over `@RequestMapping`)|
|`@RequestMapping`|Class-level base path like `/api/v1/orders`|
|`@PathVariable`|Read a value from the URL path|
|`@RequestParam`|Read a query parameter|
|`@RequestBody`|Read and deserialize the JSON body|
|`@RequestHeader`, `@CookieValue`|Read a header or cookie|
|`@RequestPart`|Read one part of a multipart upload|
|`@ResponseStatus`|Fix the HTTP status of a method or exception|
|`@ExceptionHandler`|Handle a specific exception in one place|
|`@RestControllerAdvice`|Global exception handling and shared response rules|
|`@Valid`, `@Validated`|Trigger Bean Validation on a body, parameter or class|
|`@CrossOrigin`|Quick per-endpoint CORS (see the warning section below)|

## Data and JPA

|Annotation|Use it for|
|---|---|
|`@Entity`, `@Table`, `@Id`, `@GeneratedValue`, `@Column`|Basic mapping of a class to a table|
|`@Enumerated`, `@JdbcTypeCode`|Map enums, including PostgreSQL native enums|
|`@OneToMany`, `@ManyToOne`, `@OneToOne`, `@ManyToMany`|Relationships|
|`@JoinColumn`, `@JoinTable`|Foreign key column or join table details|
|`@Embedded`, `@Embeddable`|Reuse a group of fields (like an address) across entities|
|`@ElementCollection`, `@CollectionTable`|Collection of simple values stored in their own table|
|`@Convert`, `@Converter`|Custom conversion between a Java type and a column|
|`@Version`|Optimistic locking, so concurrent updates are detected|
|`@Transient`|Field that is not persisted|
|`@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@EnableJpaAuditing`|Automatic audit columns|
|`@Query`|Write JPQL or native SQL on a repository method|
|`@Modifying`|Mark an `@Query` that runs an `UPDATE` or `DELETE`|
|`@Param`|Name a parameter used inside `@Query`|
|`@EntityGraph`|Fetch chosen relations in one query, avoiding N+1|
|`@Lock`|Pessimistic locking on a repository query|
|`@Transactional`|Transaction boundary in the service layer|

## Validation (Jakarta Bean Validation)

These go on DTO fields, mostly record components:

`@NotNull`, `@NotBlank` (strings that must have text), `@NotEmpty` (collections), `@Size`, `@Min`, `@Max`, `@Positive`, `@Email`, `@Pattern`, `@Past`, `@Future`.

## Security

|Annotation|Use it for|
|---|---|
|`@EnableWebSecurity`|Turn on and customize the security filter chain|
|`@EnableMethodSecurity`|Allow security annotations on methods|
|`@PreAuthorize`|Check permissions before a method runs; the modern default|
|`@PostAuthorize`|Check the returned object before handing it back|
|`@AuthenticationPrincipal`|Inject the current user into a controller method|

## Cross-cutting features

|Annotation|Use it for|
|---|---|
|`@Async` + `@EnableAsync`|Run a method on another thread (always configure the executor)|
|`@Scheduled` + `@EnableScheduling`|Run a method on a timer or cron expression|
|`@Cacheable`, `@CachePut`, `@CacheEvict` + `@EnableCaching`|Cache method results; pairs well with Redis|
|`@EventListener`|React to an application event|
|`@TransactionalEventListener`|React only after the transaction commits|
|`@Aspect`, `@Around`, `@Before`, `@After`|Write your own cross-cutting behavior|

## Testing

|Annotation|Use it for|
|---|---|
|`@SpringBootTest`|Full application context; use for a few end-to-end tests|
|`@WebMvcTest`|Test only the controller layer, fast|
|`@DataJpaTest`|Test only repositories and entities|
|`@MockitoBean`|Replace a bean with a Mockito mock inside the Spring context|
|`@ActiveProfiles`, `@TestPropertySource`|Choose profile or properties for a test|
|`@Testcontainers` + `@ServiceConnection`|Run a real PostgreSQL in Docker for tests|
|`@Sql`|Run SQL scripts before a test|

Prefer slice tests (`@WebMvcTest`, `@DataJpaTest`) over `@SpringBootTest`. They start in a fraction of the time. `@MockitoBean` replaces the older `@MockBean`, which Spring Boot has retired.

## Jackson (JSON shaping)

`@JsonProperty`, `@JsonIgnore`, `@JsonFormat`, `@JsonInclude`. They are not Spring annotations, but you meet them in every REST API.

## Use with care

These work, but they are the usual source of bugs or bad design:

|Annotation|Why to be careful|
|---|---|
|`@Autowired` on fields|Hides dependencies and blocks easy testing; use constructor injection|
|`@CrossOrigin` on many controllers|Scatters the CORS rules; one central configuration is easier to audit|
|`@EnableWebMvc`|Switches off Spring Boot's MVC auto-configuration|
|`@Transactional` on controllers|The boundary belongs in the service layer|
|`@Async` without a configured executor|Can create unbounded threads or hide failures|
|`@Data` or `@EqualsAndHashCode` (Lombok) on entities|Breaks `equals`/`hashCode` and can trigger lazy loading|
|`@Secured`|Older and less flexible than `@PreAuthorize`|
|`@SpringBootTest` everywhere|Slow test suite|




[[Spring Framework]]