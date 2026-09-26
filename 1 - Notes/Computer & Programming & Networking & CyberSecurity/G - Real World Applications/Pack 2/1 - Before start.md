
The most critical phase of building a Spring Boot 4 application happens **before** you write your first `@Service` or `@RestController`. The framework's power comes with a specific set of design constraints and opportunities — especially in Spring Boot 4, where modularization, virtual threads, and native image support fundamentally change how you should think about your architecture.

This is the analysis framework I'd follow, structured as a series of decisions you must make **before** touching code.

---

## 1. The Mental Model: Spring Boot Is Not a Framework — It's an Opinionated Runtime

**Analogy**: Think of Spring Boot as a fully furnished apartment. The furniture (auto-configuration) is already there when you move in. Your job isn't to build the apartment — it's to decide which rooms you'll use, what you'll change, and what you'll leave alone. The analysis phase is your **floor plan review**: you look at what's already provided, what you need to remove, and what you need to add before you start living there.

**Why this matters for analysis**: In Spring Boot 3 and earlier, the "apartment" was enormous — a single 2 MiB `spring-boot-autoconfigure` jar that contained auto-configuration for virtually every technology Spring supports. You had to actively exclude things you didn't want. In Spring Boot 4, the apartment is modular — each technology has its own room. This changes your analysis from "What do I need to exclude?" to "What do I need to include?".

---

## 2. The Pre-Code Analysis Checklist

### 2.1 Domain-Driven Package Structure (Before You Name a Single Class)

**What to analyze**: Your bounded contexts, aggregates, and domain boundaries.

Spring Boot 4's modularization makes package structure more consequential than ever. The framework now organizes itself by module (`org.springframework.boot.<module>`), and your application should mirror this discipline.

**The decision**: Feature-oriented vs. layer-oriented packaging.

| Approach | Structure | When to Use |
|---|---|---|
| **Layer-oriented** | `controller/`, `service/`, `repository/` | Small apps, CRUD-heavy, no complex domains |
| **Feature-oriented** | `customer/`, `order/`, `payment/` (each containing its own controller, service, repository) | Any app with distinct business domains |

**The Spring Boot 4 recommendation**: Feature-oriented packaging is strongly preferred. Spring Boot 4's own codebase is now organized this way, and Spring Modulith 2.0 (the official architectural enforcement tool) assumes feature-oriented packages.

**Example structure** (from official Spring docs):

```
com.example.myapp
├── MyApplication.java          // @SpringBootApplication in root
├── customer/
│   ├── Customer.java           // domain entity
│   ├── CustomerController.java
│   ├── CustomerService.java
│   └── CustomerRepository.java
└── order/
    ├── Order.java
    ├── OrderController.java
    ├── OrderService.java
    └── OrderRepository.java
```

**Critical rule**: The main application class must be in the **root package** above all other classes. `@SpringBootApplication` defines a base "search package" for component scanning, entity scanning, and configuration property scanning. If your main class is buried in a sub-package, Spring Boot will scan everything from every JAR on the classpath — a massive performance and correctness problem.

**Edge case**: If you genuinely need classes outside your root package (e.g., shared libraries), use explicit `@ComponentScan(basePackages = ...)` rather than moving your main class. But resist this — it's a sign your boundaries are wrong.

---

### 2.2 Java Version and Runtime Baseline (The First Hard Decision)

**What to analyze**: Which Java LTS version your team can support, and whether you'll target JVM or native image.

Spring Boot 4 requires **Java 17 as the absolute minimum**, with **Java 21 and Java 25 strongly recommended**. This isn't just about language features — it determines which Spring Boot 4 capabilities you can actually use.

| Java Version | What You Unlock |
|---|---|
| **Java 17** | Minimum viable. Spring Boot 4 runs, but virtual threads (Java 21+) are unavailable. |
| **Java 21** | Virtual threads become available. This is the **recommended baseline** for most teams. |
| **Java 25** | Latest LTS. GraalVM native image support requires GraalVM 25 (which is JDK 25). |

**The virtual threads decision**: In Spring Boot 4, virtual threads are the **recommended default** for request processing on Java 21+. This has a profound architectural implication: if you're using Java 21+, you may no longer need WebFlux or reactive programming for high-throughput scenarios. Synchronous code with virtual threads can achieve comparable throughput to reactive stacks with far simpler mental models.

**Analysis question**: Is your team already invested in Reactor/WebFlux? If yes, virtual threads don't invalidate that — but they do change the cost-benefit analysis for new endpoints. If your team struggles with reactive debugging and backpressure, virtual threads may be the simpler path forward.

---

### 2.3 Dependency and Starter Selection (Spring Boot 4's Biggest Change)

**What to analyze**: Exactly which technology starters you need — and which you don't.

This is the single most impactful analysis in Spring Boot 4 because the starter ecosystem was completely restructured.

**Key changes from Spring Boot 3**:

| Spring Boot 3 Starter | Spring Boot 4 Starter | Notes |
|---|---|---|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` | Renamed to clarify it's servlet-based |
| `spring-boot-starter-test` | Per-technology test starters (e.g., `spring-boot-starter-webmvc-test`, `spring-boot-starter-data-jpa-test`) | `spring-boot-starter-test` is now **intentionally minimal** |
| `spring-boot-starter-oauth2-client` | `spring-boot-starter-security-oauth2-client` | Renamed for consistency |
| (no direct equivalent) | `spring-boot-starter-webclient` | New focused module for WebClient without server auto-config |

**The analysis exercise**: For each technology your application needs, identify the **most specific starter** that provides it. Then verify:

1. Does that starter bring in auto-configuration you don't want? In Spring Boot 4, you have finer control — you can include `spring-boot-webclient` without pulling in a servlet container.
2. Is there a paired **test starter**? In Spring Boot 4, every technology starter has a corresponding `-test` starter that brings only the test infrastructure for that technology.
3. Are you building custom starters? The modularization effort makes supporting both Boot 3 and Boot 4 in the same artifact **strongly discouraged**.

**Fallback strategy**: If you're migrating an existing app and need to get running quickly, Spring Boot 4 provides **classic starters** (`spring-boot-starter-classic`, `spring-boot-starter-test-classic`) that replicate the old monolithic behavior. But the official recommendation is to migrate away from these eventually.

---

### 2.4 JSON Serialization: Jackson 3 Is the New Default

**What to analyze**: Your custom Jackson configuration, serializers, deserializers, and any `ObjectMapper` beans.

Spring Boot 4 uses **Jackson 3** as the default JSON library. This is not a version bump — it's a package rename (`com.fasterxml.jackson.*` → `tools.jackson.*`) and an API change.

**Critical edge case**: If you define an `ObjectMapper` bean, Spring Boot 4's auto-configuration may still expect a `JsonMapper` (Jackson 3's concrete type). To override the auto-configured mapper, you must return `JsonMapper`, not just `ObjectMapper`. The auto-configuration condition checks by return type.

**Analysis checklist**:
- List every place you use `@JsonFormat`, `@JsonProperty`, `@JsonIgnore`, or custom serializers
- List every `ObjectMapper` bean or `Jackson2ObjectMapperBuilderCustomizer`
- Determine whether Jackson 2 and Jackson 3 can coexist during migration (they can, but it adds complexity)

---

### 2.5 Testing Strategy: Slice Tests vs. Integration Tests vs. Native Tests

**What to analyze**: Your testing pyramid, and whether Testcontainers is part of it.

Spring Boot 4's testing support was modularized alongside everything else. The key change: `@WebMvcTest` and similar slice annotations now require explicit per-technology test starters.

**The testing decision tree**:

| Test Type | Spring Boot 4 Annotation | Dependency | When to Use |
|---|---|---|---|
| **Unit test** | None (plain JUnit) | None | Pure logic, no Spring context |
| **Slice test** | `@WebMvcTest`, `@DataJpaTest` | `spring-boot-starter-<tech>-test` | Testing one layer in isolation |
| **Integration test** | `@SpringBootTest` | `spring-boot-starter-test` + Testcontainers | Full context with real infrastructure |
| **Native test** | `@SpringBootTest` with AOT | `spring-boot-starter-test` + GraalVM plugin | Verifying native image compatibility |

**Testcontainers in Spring Boot 4**: The preferred wiring is now `@ServiceConnection` with `@ImportTestcontainers`, replacing the older `@DynamicPropertySource` approach. Testcontainers 2.x is the baseline for Spring Boot 4.

**Analysis question**: Do you have integration tests that depend on real databases, message brokers, or external services? If yes, Testcontainers is effectively mandatory in Spring Boot 4 — the framework's testing ergonomics assume it.

---

### 2.6 Observability and Production Readiness (Design It In, Don't Bolt It On)

**What to analyze**: What metrics, traces, and health checks your application must emit from day one.

Spring Boot 4 upgrades to **Micrometer 2** and provides a dedicated **OpenTelemetry starter**. Observability is no longer an afterthought — it's a first-class concern in the auto-configuration.

**The production readiness decisions**:

1. **Health groups**: Will you run on Kubernetes? If yes, you need separate liveness and readiness probes. Spring Boot 4 makes this easier with `management.endpoint.health.probes.add-additional-paths=true`.

2. **Management port isolation**: Will you expose Actuator endpoints on a separate port for security? This is a **strong recommendation** for production deployments.

3. **Graceful shutdown**: Spring Boot 4 has this enabled by default, but verify it works with your deployment platform's termination semantics.

4. **Tracing backend**: Will you use Zipkin, OpenTelemetry, or both? Spring Boot 4 supports both, but the OpenTelemetry path is the more future-proof choice.

**Edge case**: If you're targeting GraalVM native image, `@Profile` and profile-specific configuration have **fundamental limitations**. The bean set is frozen at build time — you cannot conditionally include beans based on runtime profiles in a native image. Design your configuration so that all beans are present in all profiles, or use runtime property checks instead of profile-based bean exclusion.

---

### 2.7 Native Image (If Applicable): The Closed-World Assumption

**What to analyze**: Whether your application's dynamic behavior is compatible with GraalVM's closed-world model.

GraalVM native image compilation performs **static analysis at build time**. Code that cannot be reached from the main entry point is removed. Reflection, resources, serialization, and dynamic proxies must be explicitly registered via `RuntimeHints`.

**The critical limitations for Spring Boot 4 native images**:

- The bean set is **fixed at build time**. You cannot add beans dynamically after AOT processing.
- `@Profile` annotations are evaluated at **build time**, not runtime. A bean excluded during AOT processing for one profile can never be added back for another.
- GraalVM 25 or later is required for Spring Boot 4 native builds.

**Analysis question**: Does your application rely on runtime configuration that changes the set of beans? If yes, native image may not be viable without significant refactoring. If no, native image can reduce startup time to milliseconds and memory footprint to a fraction of JVM-based deployments.

---

### 2.8 Security: Design Before You Code

**What to analyze**: Authentication mechanism, authorization model, and secret management.

Spring Boot 4's security starters were renamed and modularized. The key analysis points:

1. **Authentication**: OAuth2/OIDC, SAML, or custom? Each has a dedicated starter.
2. **Authorization**: Method-level (`@PreAuthorize`), URL-based (`HttpSecurity`), or both?
3. **Secret management**: Environment variables, Vault, AWS Secrets Manager, or Kubernetes secrets? Spring Boot 4's `@ConfigurationPropertiesSource` annotation makes cross-module configuration cleaner.
4. **CSRF/CORS**: Will you serve a browser-based frontend? If yes, CSRF protection is mandatory. If it's a pure API, you may disable it — but understand the trade-off.

---

## 3. The "Should I Even Use `@Configuration`?" Decision

This connects directly to your previous question. **Before coding**, decide your configuration philosophy:

**Use `@Configuration` + `@Bean` when**:
- Configuring third-party library classes you cannot annotate (e.g., `DataSource`, `JsonMapper`, `SecurityFilterChain`)
- The bean requires complex construction logic that doesn't belong in a constructor
- You need full-mode singleton guarantees for intra-class `@Bean` method calls

**Use `@Component`/`@Service`/`@Repository` when**:
- The class is your own domain code
- The class has a single constructor with dependencies that Spring can inject
- You want lite-mode behavior (no CGLIB proxying)

**The Spring Boot 4 recommendation**: Separate your `config/` package from your `service/`, `repository/`, and `controller/` packages. Configuration classes are for **wiring**, not for business logic. If you find yourself putting business logic in a `@Bean` method, that logic belongs in a service class.

---

## 4. Summary: The Pre-Code Decision Matrix

| Decision | Options | Spring Boot 4 Recommendation |
|---|---|---|
| **Java version** | 17, 21, 25 | Java 21 minimum; Java 25 if native image |
| **Packaging** | Layer-oriented vs. Feature-oriented | Feature-oriented (domain-driven) |
| **Main class location** | Anywhere vs. root package | Root package above all other classes |
| **Starters** | Monolithic vs. modular | Modular; use classic starters only for migration |
| **JSON** | Jackson 2 vs. Jackson 3 | Jackson 3 (default in Boot 4) |
| **Virtual threads** | Disabled vs. enabled | Enabled on Java 21+ (default in Boot 4) |
| **Testing** | Unit-only vs. Testcontainers | Testcontainers for integration tests |
| **Observability** | Actuator basic vs. full stack | Micrometer 2 + OpenTelemetry |
| **Native image** | JVM-only vs. native | Native if startup/memory critical; verify `@Profile` compatibility |
| **Configuration** | `@Configuration` everywhere vs. stereotypes | Stereotypes for your code; `@Configuration` for third-party |

The analysis phase is not about predicting every problem — it's about **making the irreversible decisions early**. Package structure, Java version, starter selection, and native image viability are all difficult to change later. Jackson 3 migration, test infrastructure, and observability are easier to add incrementally. Spend your analysis time on the irreversible decisions, and let the reversible ones be guided by Spring Boot's defaults.


[[0 - Spring Framework]]
[[Java]]
[[3 - DataBase 🍂]]