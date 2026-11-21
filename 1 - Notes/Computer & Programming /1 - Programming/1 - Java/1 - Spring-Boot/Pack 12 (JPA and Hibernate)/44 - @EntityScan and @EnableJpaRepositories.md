

These two annotations answer two separate questions about your database layer. **`@EntityScan`** answers: "Where are my `@Entity` classes?" **`@EnableJpaRepositories`** answers: "Where are my repository interfaces, like `UserRepository extends JpaRepository<...>`?"

You learned that `@ComponentScan` finds Spring beans. But entities and repositories are special. Entities aren't beans at all (they're data objects that Hibernate maps to tables), and repositories are interfaces with no implementation class you wrote. Because of this, `@ComponentScan` cannot find them, so Spring Data and Hibernate each have their own scanning step. In a normal Spring Boot app both work automatically, and you only touch these annotations when your project layout stops matching the defaults.

---

## Why two more scans exist

Here is a quick comparison of the three scans you now know:

|Scan|What it finds|Who uses the result|Turned on by default in Boot?|
|---|---|---|---|
|`@ComponentScan`|`@Component`, `@Service`, `@Controller`, ...|Spring's container (creates beans)|Yes|
|`@EntityScan`|`@Entity`, `@Embeddable`, `@MappedSuperclass`|Hibernate / JPA (maps to tables)|Yes|
|`@EnableJpaRepositories`|Interfaces extending `Repository` / `JpaRepository`|Spring Data (builds implementations)|Yes|

All three default to **the package of your main class and everything below it**. So with the usual layout, you never write any of them.

---

## The default layout (nothing to configure)

```
com.example.demo
 ├── DemoApplication            ← @SpringBootApplication
 ├── entity
 │    └── User                  ← @Entity
 ├── repository
 │    └── UserRepository        ← extends JpaRepository<User, Long>
 └── service
      └── UserService
```

Everything lives under `com.example.demo`, so Boot's auto-configuration finds the entity, creates the repository, and everything works. Your `UserService` simply injects `UserRepository`.

---

## When you need them: a project split across packages

Imagine a bigger project with a shared module:

```
com.example.app                ← main class lives here
 └── AppApplication

com.example.domain             ← entities (a separate package branch)
 └── Customer                  ← @Entity

com.example.data               ← repositories (another branch)
 └── CustomerRepository
```

Now `Customer` and `CustomerRepository` are **outside** `com.example.app`. Boot scans only `com.example.app`, so you get errors like:

```
Not a managed type: class com.example.domain.Customer
```

or

```
No qualifying bean of type 'CustomerRepository'
```

The fix is to point each scan at the right place:

```java
@SpringBootApplication
@EntityScan("com.example.domain")
@EnableJpaRepositories("com.example.data")
public class AppApplication {
    public static void main(String[] args) {
        SpringApplication.run(AppApplication.class, args);
    }
}
```

Line by line:

1. `@SpringBootApplication` still scans `com.example.app` for normal beans.
2. `@EntityScan("com.example.domain")` tells Hibernate: "Look for `@Entity` classes in this package too."
3. `@EnableJpaRepositories("com.example.data")` tells Spring Data: "Look for repository interfaces in this package."

Both annotations need their own package, because each one controls a different system.

---

## `@EntityScan` in more detail

`@EntityScan` comes from Spring Boot (`org.springframework.boot.persistence.autoconfigure` in recent versions; earlier versions used `org.springframework.boot.autoconfigure.domain`). Check the import your IDE suggests for your Boot version.

It finds these three kinds of classes:

- `@Entity`: maps to a table.
- `@Embeddable`: a value object stored inside another entity's table.
- `@MappedSuperclass`: a base class whose fields are inherited by entities.

Usage options:

```java
@EntityScan("com.example.domain")                          // one package
@EntityScan({"com.example.domain", "com.example.audit"})   // several
@EntityScan(basePackageClasses = Customer.class)           // type-safe
```

`basePackageClasses` is the safest form, because renaming the package updates the reference automatically.

**Important:** `@EntityScan` **replaces** the default scan. Once you write it, the main class's package is no longer scanned for entities unless you list it too. This is the same trap as `@ComponentScan` that you saw earlier.

---

## `@EnableJpaRepositories` in more detail

This one comes from **Spring Data JPA** (`org.springframework.data.jpa.repository.config`). It tells Spring Data to look for interfaces that extend `Repository` (or a sub-interface like `JpaRepository`) and, for each one, **generate an implementation at runtime** and register it as a bean.

```java
@EnableJpaRepositories(
    basePackages = "com.example.data",
    entityManagerFactoryRef = "customerEntityManagerFactory",
    transactionManagerRef = "customerTransactionManager"
)
```

Useful attributes:

|Attribute|Purpose|
|---|---|
|`basePackages` / `value`|Packages to search|
|`basePackageClasses`|Type-safe version of the above|
|`includeFilters` / `excludeFilters`|Narrow what is picked up|
|`repositoryImplementationPostfix`|Suffix for custom implementation classes (default `Impl`)|
|`entityManagerFactoryRef`|Which `EntityManagerFactory` bean to use (for multiple databases)|
|`transactionManagerRef`|Which transaction manager to use|
|`considerNestedRepositories`|Whether to include repository interfaces nested inside other classes|

The last two `...Ref` attributes matter when you have **more than one database**.

---

## A very common trap: adding `@EnableJpaRepositories` turns off auto-configuration

Spring Boot's JPA repository auto-configuration only activates when **you have not** declared a `JpaRepositoryFactoryBean` yourself. When you add `@EnableJpaRepositories`, Boot backs off and uses your settings instead. Then there are two consequences:

1. The default scan no longer applies. Only the packages you list are searched.
2. Some Boot property conveniences, such as `spring.data.jpa.repositories.bootstrap-mode`, may not apply the same way.

So the rule is: **if everything is under the main package, don't add it.** Adding it "just in case" can break something that was working, by shrinking the scan area.

A typical mistake:

```java
@SpringBootApplication
@EnableJpaRepositories("com.example.data")   // now ONLY this package is scanned
public class AppApplication { }
```

If some repositories also live in `com.example.app.repository`, they are now invisible. List both packages:

```java
@EnableJpaRepositories({"com.example.data", "com.example.app.repository"})
```

---

## Where to put them

You can put both annotations on the main class, but a tidier approach is a dedicated configuration class:

```java
@Configuration
@EntityScan(basePackageClasses = Customer.class)
@EnableJpaRepositories(basePackageClasses = CustomerRepository.class)
public class PersistenceConfig { }
```

This keeps the main class clean and groups all persistence wiring in one place. It also ties back to the configuration class lesson.

---

## Using both with several databases

With two databases, each gets its own configuration class, its own packages, and its own `EntityManagerFactory`:

```java
@Configuration
@EnableJpaRepositories(
    basePackages = "com.example.orders.repo",
    entityManagerFactoryRef = "ordersEmf",
    transactionManagerRef = "ordersTm")
public class OrdersDbConfig { /* ordersEmf and ordersTm beans here */ }

@Configuration
@EnableJpaRepositories(
    basePackages = "com.example.users.repo",
    entityManagerFactoryRef = "usersEmf",
    transactionManagerRef = "usersTm")
public class UsersDbConfig { /* usersEmf and usersTm beans here */ }
```

Here `@EnableJpaRepositories` links each group of repositories to the right database, and the entity packages are set when you build each `EntityManagerFactory` (through `packages(...)` on the builder). This is the main real-world reason to write these annotations by hand.

---

## Quick troubleshooting guide

|Error|Likely cause|Fix|
|---|---|---|
|`Not a managed type: class ...`|Entity is outside the scanned packages|Add `@EntityScan`|
|`No qualifying bean of type '...Repository'`|Repository is outside the scanned packages|Add `@EnableJpaRepositories`|
|Repositories vanished after adding `@EnableJpaRepositories`|The new annotation replaced the default scan|List every repository package|
|Entities vanished after adding `@EntityScan`|Same reason|List every entity package|
|`Not a managed type` with two databases|Entity package missing from one `EntityManagerFactory`|Set `packages(...)` on that factory|

---

## Short summary of a related concept: `@EnableJpaAuditing`

While we're on `@Enable...` annotations for JPA, `@EnableJpaAuditing` is a separate switch. It turns on automatic filling of fields like `@CreatedDate` and `@LastModifiedBy` on your entities. It doesn't scan anything; it enables a feature. People often confuse the `@Enable...` family, but the quick rule is that `@EnableJpaRepositories` is about **finding repositories**, while `@EnableJpaAuditing` is about **adding behavior to entities**.

---

## Takeaways

- `@EntityScan` tells Hibernate where the `@Entity` classes are; `@EnableJpaRepositories` tells Spring Data where the repository interfaces are.
- `@ComponentScan` can't do either job, because entities aren't beans and repositories are generated interfaces.
- All three default to the main class's package and below, so a standard layout needs **none** of them.
- Add them only when entities or repositories live **outside** that package, or when you use **several databases**.
- Writing either one **replaces** the default scan, so list every package you need.
- Prefer `basePackageClasses` for typo-proof, refactor-safe settings.






[[Spring Framework]]