
 For a Spring Boot developer, you don't need to study Jakarta EE as its own platform. You need to recognize which pieces of it you're already using and learn those through Spring's lens.

## What you can skip

You don't need to learn how to deploy to an application server (WildFly, Payara, GlassFish), EJBs, JSF, or the full Jakarta EE platform profile. Spring Boot replaces all of that with an embedded Tomcat and its own container. Most modern Spring jobs never touch these.

## What you should learn, because you use it daily

These Jakarta specs show up inside Spring code, so know them reasonably well:

- **Servlet API**: `HttpServletRequest`, `HttpServletResponse`, `FilterChain`, `OncePerRequestFilter`. Your JWT filter already uses these. Understanding how a request flows through servlet filters makes Spring Security much clearer.
- **Jakarta Persistence (JPA)**: `@Entity`, `@Id`, `@OneToMany`, `EntityManager`. Spring Data JPA hides a lot, but when something breaks (lazy loading errors, N+1 queries), you need to understand JPA itself.
- **Bean Validation**: `@NotNull`, `@Size`, `@Email`, `@Valid`. Small and quick to learn.
- **Jakarta Inject / CDI basics**: worth knowing mainly so you recognize `@Inject` and understand how it compares to `@Autowired`. A light understanding is enough.

## How to learn them

When you learn a Spring feature, ask yourself, "Is this a Spring API or a Jakarta API?" A quick check is the import:

- `org.springframework...` is Spring.
- `jakarta...` is a Jakarta EE standard that Spring is using.
- `javax.sql`, `javax.crypto` and similar are JDK APIs, not Jakarta.

For the Jakarta parts, the Spring docs usually explain the Spring side well, but the Jakarta spec or Hibernate docs explain the underlying behavior. JPA is the best example: learn Spring Data JPA for daily work, and read about JPA/Hibernate itself when you need to understand what's happening underneath.

## When Jakarta EE becomes worth studying more

- You join a company with a legacy Jakarta EE / Java EE app server stack.
- You move to Quarkus or Helidon, which are built more directly on Jakarta and MicroProfile standards.
- You want to understand CDI deeply, since you've been exploring it already.

In those cases, your Spring knowledge transfers well because the concepts (DI, scopes, transactions, REST) are the same, just with different annotations.

Focus on Spring Boot, and treat Jakarta as "the standard APIs underneath that I learn as they come up."


[[Spring Framework]]