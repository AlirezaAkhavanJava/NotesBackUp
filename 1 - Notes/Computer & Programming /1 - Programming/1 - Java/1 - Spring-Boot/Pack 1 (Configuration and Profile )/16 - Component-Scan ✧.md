


`@ComponentScan` tells Spring **where to look for classes that should become beans**. When Spring starts, it doesn't know about your classes. They are just files on the classpath. `@ComponentScan` gives Spring a list of packages, and Spring walks through them, finds every class marked with `@Component` (or `@Service`, `@Repository`, `@Controller`, and so on), and registers each one as a bean.

Think of it as sending a search party into certain folders with the instruction, "Bring back everything wearing a Spring badge." Folders you didn't mention are never searched, so classes in them stay invisible, even if they carry the badge. Most "why isn't my bean being found?" problems come down to this one idea, so it's worth learning well.

---

## The smallest example

```java
package com.example.shop;

@Configuration
@ComponentScan("com.example.shop")
public class AppConfig { }
```

```java
package com.example.shop.service;

@Service
public class OrderService { }
```

Line by line:

1. `@Configuration` makes `AppConfig` a configuration class.
2. `@ComponentScan("com.example.shop")` says: "Search `com.example.shop` and **all its sub-packages**."
3. `OrderService` lives in `com.example.shop.service`, a sub-package, so Spring finds it.
4. Because it has `@Service`, Spring registers it as a bean named `orderService`.

If `OrderService` were in `com.other.stuff`, Spring would never see it, and injecting it would fail with `NoSuchBeanDefinitionException`.

---

## What the scanner looks for

The scanner reads each class file in the packages and checks for these annotations:

|Annotation|Meaning|
|---|---|
|`@Component`|A generic bean|
|`@Service`|A business-logic bean|
|`@Repository`|A data-access bean (also translates database exceptions)|
|`@Controller` / `@RestController`|A web controller|
|`@Configuration`|A configuration class (itself a component)|

All of the last four are meta-annotated with `@Component`, so the scanner treats them the same way. Any custom annotation you build that is itself annotated with `@Component` is also detected.

**What it does _not_ pick up:** plain classes with no annotation, interfaces, and abstract classes.

---

## The Spring Boot twist: you usually don't write it

Your main class looks like this:

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

`@SpringBootApplication` already includes `@ComponentScan`, with no arguments. When you give no arguments, Spring scans **the package of the annotated class, and everything below it**.

So if your main class is `com.example.demo.DemoApplication`:

```
com.example.demo
 ├── DemoApplication          ← scanning starts here
 ├── config                   ← found
 ├── controller               ← found
 ├── service                  ← found
 └── repository               ← found

com.example.other
 └── ExtraService             ← NOT found (different branch)
```

This is why people say "keep your main class in the root package." If you put it in a sub-package like `com.example.demo.app`, the sibling packages `controller` and `service` fall outside the scan, and beans vanish.

---

## Controlling what gets scanned

### Several packages

```java
@ComponentScan({"com.example.shop", "com.example.billing"})
```

or with the named attribute:

```java
@ComponentScan(basePackages = {"com.example.shop", "com.example.billing"})
```

### Type-safe packages: `basePackageClasses`

Strings in code can have typos, and refactoring tools may not update them when you rename a package. A safer form points to a class and uses its package:

```java
@ComponentScan(basePackageClasses = {OrderService.class, InvoiceService.class})
```

Spring scans the package where each of those classes lives. Rename the package, and the reference follows.

### Filtering: include and exclude

You can narrow the search with filters:

```java
@ComponentScan(
    basePackages = "com.example.shop",
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.ASSIGNABLE_TYPE,
        classes = LegacyService.class)
)
```

Here, everything is scanned except `LegacyService`.

The filter types are:

|`FilterType`|Matches by|
|---|---|
|`ANNOTATION`|A class carrying a given annotation|
|`ASSIGNABLE_TYPE`|A specific class or interface (and subtypes)|
|`REGEX`|A regular expression on the class name|
|`ASPECTJ`|An AspectJ pattern|
|`CUSTOM`|Your own `TypeFilter` implementation|

Example of an include filter. To pick up classes that carry **no** stereotype annotation but have your own marker, turn off the defaults first:

```java
@ComponentScan(
    basePackages = "com.example.plugins",
    useDefaultFilters = false,
    includeFilters = @ComponentScan.Filter(
        type = FilterType.ANNOTATION,
        classes = MyPlugin.class)
)
```

`useDefaultFilters = false` switches off the normal `@Component` detection, so only `@MyPlugin` classes are picked up.

---

## Bean naming during a scan

By default, the bean name is the class name with a lowercase first letter: `OrderService` becomes `orderService`. You can override it:

```java
@Service("orders")
public class OrderService { }
```

If two scanned classes produce the **same name** (for example, `com.a.UserService` and `com.b.UserService`), Spring throws a `ConflictingBeanDefinitionException`. Give one an explicit name to fix it.

---

## `@ComponentScan` vs `@Bean`: two ways to register beans

||`@ComponentScan`|`@Bean` method|
|---|---|---|
|Who marks the bean?|The class itself (`@Service`, etc.)|A method in a configuration class|
|Good for|Your own classes|Library classes, or beans needing logic|
|Discovery|Automatic, by package|Explicit, one by one|

Most projects use both together, which is why `@Configuration` classes and `@ComponentScan` usually sit side by side.

---

## When things go wrong: a checklist

If a bean isn't found, check these in order:

1. Does the class have a stereotype annotation (`@Component`, `@Service`, ...)?
2. Is it in the main class's package or a sub-package? If not, add `@ComponentScan` or `@SpringBootApplication(scanBasePackages = "...")`.
3. Is an exclude filter or a profile hiding it?
4. Did you write `@ComponentScan` yourself in Spring Boot? **That replaces the default scan**, so the main class's package is no longer scanned automatically unless you list it too.

Point 4 surprises many people. Adding your own `@ComponentScan("com.other")` on a Boot app changes what is searched, so include every package you need.

---

## Short summary of a related concept: `@EntityScan` and `@EnableJpaRepositories`

`@ComponentScan` only finds **Spring beans**. JPA entities (`@Entity`) are not beans, so a separate annotation, `@EntityScan`, tells Spring Data where to find them. In the same way, `@EnableJpaRepositories` tells Spring where to find repository interfaces. In a normal Boot app, all three default to the main class's package, so you rarely set them. If your entities live outside that package, you need `@EntityScan("...")`.

---

## Takeaways

- `@ComponentScan` tells Spring **which packages to search** for `@Component`-style classes.
- Scanning covers the named package **and all sub-packages**.
- `@SpringBootApplication` includes it, scanning from the main class's package downward. Keep the main class in the root package.
- Use `basePackageClasses` for typo-proof settings, and `includeFilters` / `excludeFilters` to fine-tune.
- Writing your own `@ComponentScan` on a Boot app replaces the default scan.
- It finds your annotated classes; use `@Bean` for library classes.





[[Spring Framework]]