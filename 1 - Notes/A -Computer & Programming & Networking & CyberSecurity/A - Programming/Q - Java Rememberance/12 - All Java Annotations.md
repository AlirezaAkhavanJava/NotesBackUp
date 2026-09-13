# All Java Annotations — Name, Definition, Usage (up to JDK 26)

A single master table. Only **name · definition · usage**. No examples, no prose — just the reference.

---

## A. Core Language Annotations (`java.lang`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Override` | Declares a method overrides a supertype method. | Catch signature typos at compile time. |
| `@Deprecated` | Marks an API as obsolete. | Warn callers; optionally state `since` and `forRemoval`. |
| `@SuppressWarnings` | Silences specified compiler warnings. | Suppress `unchecked`, `deprecation`, `rawtypes`, etc. |
| `@SafeVarargs` | Asserts a varargs method doesn't cause heap pollution. | Removes unchecked warning on generic varargs (`static`/`final`/`private` only). |
| `@FunctionalInterface` | Asserts an interface has exactly one abstract method. | Document lambda targets; compiler enforces single abstract method. |
| `@Native` | Marks a field as a native constant. | Tool hint for JNI-generated constants; rarely used directly. |

---

## B. Meta-Annotations (`java.lang.annotation`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Retention` | Declares how long an annotation is kept. | Choose `SOURCE`, `CLASS`, or `RUNTIME`. |
| `@Target` | Declares where an annotation may be placed. | Restrict to TYPE, FIELD, METHOD, PARAMETER, etc. |
| `@Documented` | Includes the annotation in Javadoc. | Make custom annotations visible in generated docs. |
| `@Inherited` | Class annotations propagate to subclasses. | Framework class-level inheritance (e.g., `@Entity` on base). |
| `@Repeatable` | Allows multiple applications of the same annotation. | Wrap repeated annotations in a container annotation. |

---

## C. Compile-Time / Safety (`java.lang`, `java.io`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Override` | (Also valid on interface implementations since Java 6.) | Confirm you're implementing an interface method. |
| `@Deprecated(since, forRemoval)` | Enhanced deprecation metadata. | Document when deprecated and whether removal is planned. |
| `@Serial` | Marks serialization-related members. | Validate `serialVersionUID`, `writeObject`, `readObject`, `readResolve`, `writeReplace`. |
| `@SuppressWarnings` | (Repeated here for completeness.) | Local suppression of compiler warnings. |

---

## D. JDK Internal / JVM Hints (`jdk.internal.*`)

> Not for application code; used inside the JDK. Listed for completeness.

| Annotation | Definition | Usage |
|---|---|---|
| `@Contended` | Pads a field to avoid false sharing. | High-performance concurrent data structures. |
| `@ForceInline` | Forces JIT inlining of a method. | JDK hot paths. |
| `@DontInline` | Prevents JIT inlining. | JDK internal tuning. |
| `@Stable` | Hints that a field rarely changes. | JIT optimization of final-like fields. |
| `@Hidden` | Hides a member from stack traces/reflection. | JDK internals. |

---

## E. Java EE / Jakarta EE — Injection & Lifecycle (`jakarta.inject`, `jakarta.annotation`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Inject` | Requests dependency injection. | Fields, constructors, or methods to receive beans. |
| `@Named` | Names a bean for lookup. | Reference beans by string; also CDI bean marker. |
| `@Qualifier` | Disambiguates multiple beans of the same type. | Select a specific implementation (CDI). |
| `@Scope` | Declares bean scope. | `@RequestScoped`, `@SessionScoped`, `@ApplicationScoped`. |
| `@Singleton` | One instance per container. | Shared stateless services. |
| `@Dependent` | Default CDI scope — one instance per injection point. | Short-lived beans. |
| `@PostConstruct` | Lifecycle callback after injection. | Initialize resources after construction. |
| `@PreDestroy` | Lifecycle callback before destruction. | Release resources on shutdown. |
| `@Resource` | Injects a named JNDI resource. | DataSources, JMS queues, mail sessions. |
| `@Resources` | Container for multiple `@Resource`. | Declare several resource injections on one class. |
| `@Priority` | Orders interceptors, alternatives, providers. | Control execution order. |
| `@DeclareRoles` | Declares security roles on a bean. | EJB/Servlet authorization. |
| `@RunAs` | Runs a bean under a different security role. | Privilege escalation inside a call. |
| `@RolesAllowed` | Restricts method to roles. | EJB/Jakarta Security authorization. |
| `@PermitAll` | Allows all roles. | Open access on protected beans. |
| `@DenyAll` | Denies all roles. | Lock down a method/class. |

---

## F. Jakarta EE — Web / REST (`jakarta.ws.rs`, `jakarta.servlet`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Path` | Maps a class/method to a URL path. | JAX-RS resource routing. |
| `@GET` `@POST` `@PUT` `@DELETE` `@PATCH` `@HEAD` `@OPTIONS` | Binds method to HTTP verb. | REST endpoint declaration. |
| `@Produces` | Declares response media types. | `application/json`, `text/xml`. |
| `@Consumes` | Declares accepted request media types. | Content negotiation. |
| `@PathParam` | Binds parameter to URL path segment. | `/users/{id}` → `long id`. |
| `@QueryParam` | Binds parameter to query string. | `?expand=roles`. |
| `@HeaderParam` | Binds parameter to HTTP header. | Auth, locale, custom headers. |
| `@CookieParam` | Binds parameter to a cookie. | Session/tracking cookies. |
| `@FormParam` | Binds parameter to form field. | `application/x-www-form-urlencoded`. |
| `@MatrixParam` | Binds parameter to matrix path segment. | `;name=value` style params. |
| `@BeanParam` | Injects a bean whose fields carry param annotations. | Group multiple params into one object. |
| `@DefaultValue` | Provides default for a param. | Fallback when param is missing. |
| `@Context` | Injects a JAX-RS context (UriInfo, Request, etc.). | Access request-level infrastructure. |
| `@Provider` | Marks a JAX-RS extension. | Filters, interceptors, exception mappers. |
| `@NameBinding` | Creates a custom binding annotation for filters. | Attach filter to selected resources. |
| `@WebServlet` | Declares a servlet. | Map servlet to URL pattern. |
| `@WebFilter` | Declares a servlet filter. | Cross-cutting request handling. |
| `@WebListener` | Declares a servlet listener. | Session/context lifecycle hooks. |
| `@MultipartConfig` | Configures multipart handling. | File uploads. |
| `@ServletSecurity` | Declares servlet-level security constraints. | Container-managed auth. |
| `@HandlesTypes` | Declares types a `ServletContainerInitializer` cares about. | Framework bootstrap. |

---

## G. Persistence — JPA / Jakarta Persistence (`jakarta.persistence`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Entity` | Maps a class to a DB table. | ORM entity declaration. |
| `@Table` | Specifies table name/schema/catalog. | Override default table naming. |
| `@SecondaryTable` | Maps fields to a second table. | Split an entity across tables. |
| `@SecondaryTables` | Container for `@SecondaryTable`. | Multiple secondary tables. |
| `@Id` | Marks the primary key. | Every entity needs one. |
| `@IdClass` | Composite PK via separate class. | Legacy composite keys. |
| `@EmbeddedId` | Composite PK via embedded object. | Modern composite keys. |
| `@GeneratedValue` | Declares ID generation strategy. | `IDENTITY`, `SEQUENCE`, `TABLE`, `AUTO`, `UUID`. |
| `@SequenceGenerator` | Declares a DB sequence. | Named sequence config. |
| `@TableGenerator` | Declares a table-based ID generator. | Portable ID generation. |
| `@Column` | Maps field to a column. | Name, nullable, length, unique, precision. |
| `@JoinColumn` | Declares FK column. | Relationship mapping. |
| `@JoinColumns` | Container for `@JoinColumn`. | Composite FK. |
| `@JoinTable` | Declares a join table. | Many-to-many mapping. |
| `@OneToOne` | One-to-one relationship. | User ↔ Profile. |
| `@OneToMany` | One-to-many relationship. | Order → Lines. |
| `@ManyToOne` | Many-to-one relationship. | Line → Order. |
| `@ManyToMany` | Many-to-many relationship. | Student ↔ Course. |
| `@ElementCollection` | Collection of basic/embeddable values. | `List<String>` mapped to a table. |
| `@Embeddable` | Class embeddable in an entity. | Value objects like `Address`. |
| `@Embedded` | Embeds an embeddable class. | Reuse value objects. |
| `@AttributeOverride` | Overrides embeddable column mapping. | Rename columns per embedding. |
| `@AttributeOverrides` | Container for `@AttributeOverride`. | Multiple overrides. |
| `@MapsId` | Derives PK from a relationship. | Shared primary keys. |
| `@Transient` | Excludes a field from persistence. | Derived/computed fields. |
| `@Enumerated` | Maps enum as `ORDINAL` or `STRING`. | Store enums readably (`STRING`). |
| `@Temporal` | Maps `Date`/`Calendar` as DATE/TIME/TIMESTAMP. | Legacy date mapping. |
| `@Lob` | Maps to a large object (BLOB/CLOB). | Files, big text. |
| `@Basic` | Configures fetch and optionality. | Tune lazy/eager for basics. |
| `@Access` | Chooses FIELD or PROPERTY access. | Control mapping style. |
| `@Version` | Optimistic locking column. | Concurrent-update detection. |
| `@OrderBy` | Orders a collection. | JPQL fragment for collection order. |
| `@OrderColumn` | Persists list index. | `List` ordered by a column. |
| `@MapKey` | Key of a mapped `Map`. | Map a `Map<K,V>` relationship. |
| `@MapKeyClass` | Declares the map key class. | When key type is generic. |
| `@MapKeyColumn` | Column for map keys. | Persisted map key storage. |
| `@MapKeyJoinColumn` | FK column for map key entity. | Entity-valued map keys. |
| `@MapKeyEnumerated` | Enum storage for map keys. | Enum keyed maps. |
| `@MapKeyTemporal` | Temporal storage for map keys. | Date keyed maps. |
| `@NamedQuery` | Named JPQL query. | Reusable queries. |
| `@NamedQueries` | Container for `@NamedQuery`. | Multiple named queries. |
| `@NamedNativeQuery` | Named SQL query. | Vendor SQL reuse. |
| `@NamedNativeQueries` | Container. | Multiple native queries. |
| `@NamedEntityGraph` | Declares an entity graph. | Control fetch joins at query time. |
| `@NamedEntityGraphs` | Container. | Multiple graphs. |
| `@EntityGraph` | Applies an entity graph to a query. | Override default fetch plan. |
| `@NamedStoredProcedureQuery` | Declares a stored procedure. | Typed SP invocation. |
| `@NamedStoredProcedureQueries` | Container. | Multiple SPs. |
| `@StoredProcedureParameter` | Declares SP parameter. | IN/OUT/INOUT config. |
| `@QueryHint` | Vendor query hint. | E.g., JPA query timeout. |
| `@Cacheable` | Marks entity as cacheable. | L2 cache opt-in. |
| `@Inheritance` | Inheritance strategy. | `SINGLE_TABLE`, `JOINED`, `TABLE_PER_CLASS`. |
| `@DiscriminatorColumn` | Discriminator column for inheritance. | `SINGLE_TABLE`/`JOINED`. |
| `@DiscriminatorValue` | Value identifying a subclass. | Distinguish rows. |
| `@PrimaryKeyJoinColumn` | PK shared with superclass in JOINED. | Join inheritance mapping. |
| `@PrimaryKeyJoinColumns` | Container. | Composite join inheritance. |
| `@AssociationOverride` | Overrides relationship mapping. | Adjust FK in embeddables. |
| `@AssociationOverrides` | Container. | Multiple overrides. |
| `@Converts` / `@Convert` | Applies an `AttributeConverter`. | Custom field ↔ column conversion. |
| `@Converter` | Declares an attribute converter. | Encrypt/encode fields transparently. |
| `@ConvertGroup` | Validation group per conversion. | Constrain converter output. |
| `@ExcludeSuperclassListeners` | Excludes inherited listeners. | Listener control. |
| `@ExcludeDefaultListeners` | Excludes default listeners. | Listener control. |
| `@EntityListeners` | Registers entity lifecycle listeners. | Audit, timestamp, soft-delete. |
| `@PrePersist` | Callback before INSERT. | Set created timestamp. |
| `@PostPersist` | Callback after INSERT. | Post-insert side effects. |
| `@PreUpdate` | Callback before UPDATE. | Set updated timestamp. |
| `@PostUpdate` | Callback after UPDATE. | Post-update side effects. |
| `@PreRemove` | Callback before DELETE. | Soft-delete prep. |
| `@PostRemove` | Callback after DELETE. | Cleanup. |
| `@PostLoad` | Callback after entity loaded. | Derived fields, decryption. |
| `@SqlResultSetMapping` | Maps native query results. | Custom DTO/projection. |
| `@SqlResultSetMappings` | Container. | Multiple mappings. |
| `@ConstructorResult` | Maps to a constructor. | DTO projection from native query. |
| `@ColumnResult` | Maps a column in a result set. | Result set mapping. |
| `@EntityResult` | Maps an entity in a result set. | Result set mapping. |
| `@FieldResult` | Maps a field in an entity result. | Result set mapping. |
| `@TupleResult` | Maps a query to `Tuple`. | Tuple projection. |

---

## H. Jakarta Bean Validation (`jakarta.validation`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Valid` | Triggers cascading validation. | Validate nested beans/collections. |
| `@Validated` | Spring's class-level validation trigger. | Method parameter/return validation. |
| `@NotNull` | Must not be null. | Required references. |
| `@Null` | Must be null. | Enforce absence. |
| `@AssertTrue` / `@AssertFalse` | Boolean must be true/false. | Business rule checks. |
| `@Min` / `@Max` | Numeric lower/upper bound. | Range constraints. |
| `@DecimalMin` / `@DecimalMax` | BigDecimal bounds. | Precision-sensitive limits. |
| `@Positive` / `@PositiveOrZero` | > 0 / ≥ 0. | Quantities, prices. |
| `@Negative` / `@NegativeOrZero` | < 0 / ≤ 0. | Debits, deltas. |
| `@Digits(integer, fraction)` | Restricts digits. | Money, measurements. |
| `@Size(min, max)` | Size of string/collection/map/array. | Length limits. |
| `@NotEmpty` | Non-null and not empty. | Collections, strings. |
| `@NotBlank` | Non-null and contains non-whitespace. | Names, titles. |
| `@Email` | Valid email format. | Contact fields. |
| `@Pattern(regexp)` | Matches regex. | Custom formats. |
| `@Past` / `@PastOrPresent` | Date in the past. | Birth date. |
| `@Future` / `@FutureOrPresent` | Date in the future. | Expiry date. |
| `@Constraint` | Declares a custom constraint. | Write your own validator. |
| `@ReportAsSingleViolation` | Combine constraints into one message. | Composite constraints. |
| `@GroupSequence` | Orders validation groups. | Multi-step validation. |
| `@ConvertGroup` | Redirects group during cascade. | Nested validation control. |
| `@OverridesAttribute` | Overrides a composed constraint's attribute. | Custom composites. |
| `@SupportedValidationTarget` | Declares cross-parameter validation. | Method-level validation. |
| `@ValidateUnwrappedValue` | Unwraps `Optional`/`List` for validation. | Container element validation. |

---

## I. Jackson JSON (`com.fasterxml.jackson.annotation`)

| Annotation | Definition | Usage |
|---|---|---|
| `@JsonProperty` | Renames a property. | `first_name` ↔ `firstName`. |
| `@JsonPropertyOrder` | Declares property order. | Stable JSON output. |
| `@JsonIgnore` | Skips a property. | Passwords, internals. |
| `@JsonIgnoreProperties` | Class-level ignore list. | Ignore unknown props + fields. |
| `@JsonIgnoreType` | Ignores all properties of a type. | Skip a helper class everywhere. |
| `@JsonInclude` | Controls inclusion of null/empty values. | `NON_NULL`, `NON_EMPTY`. |
| `@JsonIncludeProperties` | Allow-list of properties. | Strict output shape. |
| `@JsonFormat` | Format for date/number/shape. | `yyyy-MM-dd`, locale, timezone. |
| `@JsonUnwrapped` | Flattens nested object. | Flatten value objects. |
| `@JsonView` | Conditional serialization view. | Different DTOs per endpoint. |
| `@JsonManagedReference` / `@JsonBackReference` | Break circular references. | Parent ↔ child graphs. |
| `@JsonIdentityInfo` | Emits object id instead of duplicating. | Shared references. |
| `@JsonCreator` | Marks a constructor/factory for deserialization. | Immutable types. |
| `@JsonValue` | Uses a method's return as the whole value. | Enum with custom serialization. |
| `@JsonAnyGetter` / `@JsonAnySetter` | Catch-all for extra properties. | Dynamic/extensible payloads. |
| `@JsonGetter` / `@JsonSetter` | Marks getter/setter explicitly. | Non-standard naming. |
| `@JsonPropertyDescription` | Description for JSON schema. | Documentation. |
| `@JsonPOJOBuilder` | Marks a builder class. | Custom builder patterns. |
| `@JsonDeserialize` | Custom deserializer. | Special parsing. |
| `@JsonSerialize` | Custom serializer. | Special output. |
| `@JsonTypeInfo` | Polymorphic type discriminator. | Include `@type` in JSON. |
| `@JsonSubTypes` | Maps subtype names to classes. | Polymorphic deserialization. |
| `@JsonTypeName` | Names a subtype. | Discriminator values. |
| `@JsonAlias` | Alternate names on input. | Backwards compatibility. |
| `@JsonFilter` | Attaches a runtime filter. | Dynamic field filtering. |
| `@JsonAutoDetect` | Controls auto-detection of members. | Fine-grained visibility. |
| `@JsonRootName` | Wraps output in a root name. | XML-ish envelope. |
| `@JsonIgnoreProperties` (repeat) | — | — |

---

## J. JUnit 5 (`org.junit.jupiter.api`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Test` | Marks a test method. | Unit tests. |
| `@BeforeEach` | Runs before each test. | Per-test setup. |
| `@AfterEach` | Runs after each test. | Per-test teardown. |
| `@BeforeAll` | Runs once before all tests. | Class-level setup. |
| `@AfterAll` | Runs once after all tests. | Class-level teardown. |
| `@Disabled` | Skips the test. | Temporarily disable. |
| `@DisplayName` | Human-readable test name. | Readable reports. |
| `@DisplayNameGeneration` | Naming strategy for tests. | Auto-generated names. |
| `@Nested` | Inner class grouping. | BDD structure. |
| `@Tag` | Categorizes tests. | Filter "slow", "integration". |
| `@Timeout` | Fails test if it exceeds duration. | Guard against hangs. |
| `@RepeatedTest` | Runs test N times. | Flakiness detection. |
| `@ParameterizedTest` | Runs with multiple inputs. | Data-driven tests. |
| `@ValueSource` | Single-type input source. | Ints, strings, etc. |
| `@EnumSource` | Enum constants as inputs. | Enum coverage. |
| `@MethodSource` | Factory method provides inputs. | Complex objects. |
| `@CsvSource` | Inline CSV inputs. | Simple tabular data. |
| `@CsvFileSource` | CSV file inputs. | Large data sets. |
| `@ArgumentsSource` | Custom `ArgumentsProvider`. | Dynamic input generation. |
| `@TestFactory` | Dynamic test generator. | Programmatic tests. |
| `@TestTemplate` | Template invoked by providers. | Custom test engines. |
| `@TestMethodOrder` | Orders test methods. | Deterministic order. |
| `@Order` | Sets method order. | With `@TestMethodOrder`. |
| `@TestInstance` | Lifecycle per method or per class. | Non-static `@BeforeAll`. |
| `@ExtendWith` | Registers extensions. | Mockito, Spring, custom. |
| `@RegisterExtension` | Registers a programmatic extension. | Conditional extensions. |
| `@TempDir` | Injects a temp directory. | File I/O tests. |
| `@IndicativeSentencesGeneration` | Sentence-style display names. | Readable output. |
| `@Suite` | Declares a test suite. | JUnit Platform Suite. |
| `@SelectClasses` / `@SelectPackages` / `@SelectDirectories` | Suite selectors. | Compose suites. |
| `@IncludeTags` / `@ExcludeTags` | Tag filters. | Suite filtering. |
| `@DisabledIf` / `@EnabledIf` | Conditional run (env, OS, JRE). | Environment-gated tests. |
| `@DisabledOnOs` / `@EnabledOnOs` | OS-gated tests. | Platform-specific. |
| `@DisabledOnJre` / `@EnabledOnJre` | JRE-gated tests. | Version-specific. |
| `@DisabledForJreRange` / `@EnabledForJreRange` | JRE range gating. | Version ranges. |
| `@DisabledIfSystemProperty` / `@EnabledIfSystemProperty` | System property gating. | CI flags. |
| `@DisabledIfEnvironmentVariable` / `@EnabledIfEnvironmentVariable` | Env var gating. | Secrets, environment. |

---

## K. Testing Libraries

### Mockito (`org.mockito`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Mock` | Creates a mock instance. | Isolate dependencies. |
| `@Spy` | Wraps a real object. | Partial mocking. |
| `@InjectMocks` | Injects mocks into the subject. | Wire mocks into the class under test. |
| `@Captor` | Captures method arguments. | Verify argument values. |
| `@MockBean` (Spring Boot) | Adds/replaces a Spring bean with a mock. | Integration tests. |
| `@SpyBean` (Spring Boot) | Wraps a Spring bean in a spy. | Partial integration mocking. |

### AssertJ / Hamcrest
No standard annotations; use JUnit's.

---

## L. Lombok (`lombok`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Getter` / `@Setter` | Generates getters/setters. | Remove boilerplate. |
| `@ToString` | Generates `toString()`. | Debug output. |
| `@EqualsAndHashCode` | Generates `equals`/`hashCode`. | Value semantics. |
| `@Data` | Bundle: getter, setter, toString, equals, hashCode, required ctor. | Simple POJOs. |
| `@Value` | Immutable variant of `@Data`. | Value objects. |
| `@Builder` | Generates a builder. | Fluent construction. |
| `@SuperBuilder` | Builder for class hierarchies. | Builder + inheritance. |
| `@NoArgsConstructor` | Generates no-arg constructor. | JPA, frameworks. |
| `@RequiredArgsConstructor` | Constructor for `final`/`@NonNull` fields. | DI-friendly. |
| `@AllArgsConstructor` | Constructor for all fields. | Quick construction. |
| `@NonNull` | Null check on parameter/field. | Fast fail. |
| `@Cleanup` | Auto-close a resource. | try-with-resources alternative. |
| `@SneakyThrows` | Throws checked exceptions unchecked. | Rare; shortcut. |
| `@Synchronized` | Synchronized method on a private lock. | Safer locking. |
| `@Log` / `@Slf4j` / `@Log4j2` / `@CommonsLog` | Injects a logger. | Logging boilerplate removal. |
| `@ToString.Exclude` | Excludes a field from `toString`. | Hide secrets. |
| `@EqualsAndHashCode.Exclude` | Excludes from equality. | Ignore mutable fields. |
| `@EqualsAndHashCode.Include` | Includes only listed fields. | Selective equality. |
| `@FieldNameConstants` | Generates string constants for field names. | Type-safe reflection/query keys. |
| `@StandardException` | Generates standard exception constructors. | Custom exceptions. |
| `@Jacksonized` | Makes `@Builder` Jackson-compatible. | JSON + builder. |
| `@With` | Generates `withX()` copy methods. | Immutable updates. |
| `@Accessors` | Custom accessor naming/fluent style. | Fluent APIs. |
| `@ExtensionMethod` | Adds extension methods (experimental). | Kotlin-like syntax. |

---

## M. MapStruct (`org.mapstruct`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Mapper` | Declares a mapper interface. | Generate bean mapping implementation. |
| `@Mapping` | Maps one source to one target. | Field rename, transform. |
| `@Mappings` | Container for `@Mapping`. | Multiple mappings. |
| `@MappingTarget` | Marks the target parameter for update. | Update existing bean. |
| `@IterableMapping` | Maps element types. | Collection element conversion. |
| `@MapMapping` | Maps key/value types. | Map conversion. |
| `@BeanMapping` | Configures result type, ignore rules. | Whole-bean options. |
| `@ValueMapping` | Maps enum constants. | Enum conversion. |
| `@ValueMappings` | Container. | Multiple enum mappings. |
| `@SubclassMapping` | Polymorphic subtype mapping. | Handle subclasses. |
| `@EnumMapping` | Enum naming strategies. | Case/prefix handling. |
| `@InheritConfiguration` | Inherits method-level config. | DRY mapping. |
| `@InheritInverseConfiguration` | Uses reverse of another method. | One-way definitions. |
| `@AfterMapping` | Callback after mapping. | Post-processing. |
| `@BeforeMapping` | Callback before mapping. | Pre-processing. |
| `@ObjectFactory` | Custom object creation. | Non-default constructors. |
| `@Condition` | Custom presence check. | Conditional mapping. |
| `@Source` / `@Target` (within `@Mapping`) | Nested property paths. | Deep mapping. |
| `@Context` | Passes context into mapping methods. | Locale, tenant, etc. |
| `@Qualifier` (MapStruct) | Names a mapping method for selection. | Disambiguate converters. |
| `@Named` (MapStruct) | Names a mapping method. | Qualifier selection. |

---

## N. Spring Framework & Boot (`org.springframework.*`)

| Annotation | Definition | Usage |
|---|---|---|
| `@Component` | Generic Spring-managed bean. | Base stereotype. |
| `@Service` | Business-layer stereotype. | Semantic alias of `@Component`. |
| `@Repository` | Persistence-layer stereotype + exception translation. | DAO beans. |
| `@Controller` | MVC controller. | Web layer. |
| `@RestController` | `@Controller` + `@ResponseBody`. | REST endpoints. |
| `@Configuration` | Java-based config class. | `@Bean` definitions. |
| `@Bean` | Declares a bean method. | Explicit bean creation. |
| `@Autowired` | Injects a dependency. | Spring DI. |
| `@Qualifier` (Spring) | Selects a specific bean. | Multiple candidates. |
| `@Primary` | Preferred bean when multiple match. | Default selection. |
| `@Lazy` | Delays bean creation. | Break cycles, save startup. |
| `@Scope` (Spring) | Bean scope (singleton/prototype/request/session). | Lifecycle control. |
| `@Value` | Injects a property value. | Config values, SpEL. |
| `@ConfigurationProperties` | Binds external config to a bean. | Grouped properties. |
| `@EnableConfigurationProperties` | Enables `@ConfigurationProperties` beans. | Register config beans. |
| `@PropertySource` | Adds a property file. | Extra config files. |
| `@Profile` | Activates beans by profile. | Env-specific beans. |
| `@Conditional` | Conditional bean registration. | Auto-config. |
| `@ConditionalOnClass` / `@ConditionalOnMissingBean` / `@ConditionalOnProperty` | Boot-specific conditions. | Auto-configuration. |
| `@SpringBootApplication` | `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan`. | Main app class. |
| `@EnableAutoConfiguration` | Enables Boot auto-config. | Auto-config opt-in. |
| `@ComponentScan` | Scans packages for beans. | Component discovery. |
| `@Import` | Imports config classes. | Compose configurations. |
| `@ImportResource` | Imports XML config. | Legacy support. |
| `@DependsOn` | Declares bean init order. | Ordering guarantee. |
| `@Order` | Orders beans/listeners. | Deterministic execution. |
| `@RequestMapping` | Maps URL to handler. | Class- or method-level. |
| `@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping` / `@PatchMapping` | HTTP verb-specific mappings. | REST handlers. |
| `@PathVariable` | Binds path segment. | `/users/{id}`. |
| `@RequestParam` | Binds query/form param. | `?page=2`. |
| `@RequestBody` | Binds request body. | JSON payload → object. |
| `@ResponseBody` | Writes return value to body. | REST responses. |
| `@ResponseStatus` | Sets HTTP status. | Created, No Content. |
| `@RequestHeader` | Binds header. | Custom headers. |
| `@CookieValue` | Binds cookie. | Session cookies. |
| `@ModelAttribute` | Binds form/model attributes. | MVC forms. |
| `@SessionAttributes` | Stores model attributes in session. | Multi-step forms. |
| `@CrossOrigin` | Enables CORS. | Browser cross-origin calls. |
| `@ExceptionHandler` | Handles exceptions in controller. | Error mapping. |
| `@ControllerAdvice` / `@RestControllerAdvice` | Global exception/handler advice. | Cross-cutting handling. |
| `@InitBinder` | Customizes data binding. | Register editors/validators. |
| `@Transactional` | Wraps method in a transaction. | DB atomicity. |
| `@EnableTransactionManagement` | Enables `@Transactional`. | Config opt-in. |
| `@EnableScheduling` | Enables `@Scheduled`. | Cron/interval jobs. |
| `@Scheduled` | Schedules a method. | Fixed rate, cron. |
| `@EnableAsync` | Enables `@Async`. | Async execution. |
| `@Async` | Runs method on a thread pool. | Non-blocking calls. |
| `@EnableCaching` | Enables caching annotations. | Config opt-in. |
| `@Cacheable` | Caches method result. | Read-through cache. |
| `@CachePut` | Updates cache with result. | Write-through. |
| `@CacheEvict` | Removes cache entries. | Invalidation. |
| `@Caching` | Combines multiple cache ops. | Complex cache logic. |
| `@CacheConfig` | Class-level cache defaults. | DRY cache names. |
| `@EventListener` | Subscribes to application events. | Decoupled handlers. |
| `@TransactionalEventListener` | Event listener bound to tx phase. | After-commit side effects. |
| `@EnableJpaRepositories` / `@EnableMongoRepositories` / `@EnableJdbcRepositories` | Enables Spring Data repositories. | Repository scanning. |
| `@Query` (Spring Data) | Declares a query. | JPQL/native. |
| `@Modifying` | Marks a modifying query. | UPDATE/DELETE. |
| `@Param` | Names a query parameter. | Bind `:name`. |
| `@EntityGraph` (Spring Data) | Fetch plan on a repository method. | Avoid N+1. |
| `@Lock` | Locking mode for a query. | Pessimistic/optimistic. |
| `@NoRepositoryBean` | Marks a base repository interface. | Framework use. |
| `@EnableWebSecurity` | Enables Spring Security web config. | Security setup. |
| `@PreAuthorize` | Expression-based pre-authorization. | Method security. |
| `@PostAuthorize` | Expression-based post-authorization. | Return-value checks. |
| `@PreFilter` / `@PostFilter` | Filters collections by expression. | Field-level security. |
| `@Secured` | Role-based method security. | Simple role check. |
| `@RolesAllowed` (Spring) | JSR-250 role check. | Standard alternative. |
| `@EnableMethodSecurity` | Enables method security. | Config opt-in. |
| `@WithMockUser` | Injects a mock user in tests. | Security testing. |
| `@WithUserDetails` | Loads a user in tests. | Integration security tests. |
| `@Retryable` (Spring Retry) | Retries a method on failure. | Transient errors. |
| `@Recover` | Fallback after retries. | Failure handling. |
| `@Backoff` | Retry backoff config. | Delay strategy. |
| `@CircuitBreaker` (Resilience4j) | Circuit breaker around a method. | Fault isolation. |

---

## O. Miscellaneous Frameworks

### Quarkus (`io.quarkus`, `jakarta.*`)

| Annotation | Definition | Usage |
|---|---|---|
| `@ApplicationScoped` / `@Singleton` / `@RequestScoped` | CDI scopes. | Bean lifetimes. |
| `@QuarkusMain` | Entry point. | CLI apps. |
| `@Blocking` / `@NonBlocking` | Declares threading model. | Reactive endpoints. |
| `@Route` | Reactive route. | Vert.x routes. |
| `@ConfigProperty` | Injects a config property. | Quarkus config. |
| `@Scheduled` (Quarkus) | Scheduled task. | Background jobs. |
| `@CacheResult` / `@CacheInvalidate` | Caching. | Method caching. |
| `@Transactional` (Quarkus) | Transactions. | DB atomicity. |
| `@Startup` | Eager bean init. | Startup hooks. |

### Micrometer / Observability

| Annotation | Definition | Usage |
|---|---|---|
| `@Timed` | Times a method. | Latency metrics. |
| `@Counted` | Counts invocations. | Throughput metrics. |
| `@Metered` | Rate + count. | Frequency metrics. |
| `@ExceptionMetered` | Counts exceptions. | Error metrics. |
| `@Gauge` | Reports a gauge value. | Point-in-time values. |

### Async / Reactive

| Annotation | Definition | Usage |
|---|---|---|
| `@NonBlocking` (Vert.x) | Declares a non-blocking handler. | Event loop work. |
| `@Stream` (Vert.x) | Marks a stream subscriber. | Reactive streams. |
| `@ConsumeEvent` / `@ConsumeEvents` (Quarkus) | Subscribes to Vert.x events. | Event bus. |
| `@Observes` (CDI) | Observes CDI events. | Event-driven beans. |
| `@ObservesAsync` (CDI) | Async event observer. | Non-blocking events. |
| `@Disposes` (CDI) | Disposer for a producer. | Cleanup on scope end. |
| `@Produces` (CDI) | Producer method/field. | Custom bean creation. |

---

## P. Summary Counts by Category

| Category | Approx. Count |
|---|---|
| Core language (`java.lang`) | 6 |
| Meta-annotations (`java.lang.annotation`) | 5 |
| JDK internal hints | 5 |
| Jakarta EE injection/lifecycle | ~20 |
| Jakarta REST / Servlet | ~25 |
| JPA / Jakarta Persistence | ~90 |
| Bean Validation | ~25 |
| Jackson | ~30 |
| JUnit 5 | ~35 |
| Mockito / test | ~6 |
| Lombok | ~24 |
| MapStruct | ~20 |
| Spring / Boot | ~70 |
| Quarkus / Micrometer / misc | ~25 |
| **Total** | **~380+** |

---

## Notes

- **JDK 26 relevance:** The JDK itself adds no new annotations beyond the core set since Java 9 (`@Serial` in 14, `@Deprecated(since, forRemoval)` in 9). Most growth happens in **frameworks**, not the JDK.
- **`@SuppressWarnings` values** (not annotations, but commonly paired): `unchecked`, `deprecation`, `rawtypes`, `unused`, `serial`, `fallthrough`, `preview`, `removal`, `module`, `exports`, `opens`, `requires-automatic`, `requires-transitive-automatic`.
- **Retention rule of thumb:** `SOURCE` for compiler hints, `CLASS` for bytecode tools, `RUNTIME` for reflection-driven frameworks.

[[Java]]
[[0 - Spring Framework]]
[[1 - Junit 5 🥭]]
[[2 - Mokito 🍫]]
