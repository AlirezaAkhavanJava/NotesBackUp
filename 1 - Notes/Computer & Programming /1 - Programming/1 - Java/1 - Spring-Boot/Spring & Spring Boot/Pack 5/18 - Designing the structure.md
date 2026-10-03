

## Mental model: a building's floor plan

Your code is a building, and packages are the **rooms**. There are two ways to lay out the floors:

- **By layer:** one floor for all kitchens, one floor for all bathrooms, one floor for all bedrooms. To use one apartment's kitchen and bedroom, you run up and down the building.
- **By feature:** each apartment has its own kitchen, bathroom, and bedroom. Everything for one feature is together.

Controllers are just one "room type" in that plan. The question is how to arrange the rooms.

## 1. Package by layer (what most tutorials show)

```
com.alireza.shop
├── ShopApplication.java
├── controller
│   ├── ProductController.java
│   ├── OrderController.java
│   └── UserController.java
├── service
│   ├── ProductService.java
│   ├── OrderService.java
│   └── UserService.java
├── repository
│   ├── ProductRepository.java
│   └── ...
├── entity
│   └── ...
├── dto
│   └── ...
└── exception
    └── GlobalExceptionHandler.java
```

**Pros:** it is instantly understandable, and every tutorial uses it, so it's fine for learning.

**Cons:**

- Adding one feature touches **five packages**.
- Everything must be `public` so layers can see each other. Nothing can be hidden.
- With 40 controllers in one folder, nothing tells you which belong together.
- It describes the _technology_, not the _business_. Opening the project tells you "Spring app", not "shop".

## 2. Package by feature (recommended for real projects)

```
com.alireza.shop
├── ShopApplication.java
├── product
│   ├── ProductController.java
│   ├── ProductService.java
│   ├── ProductRepository.java
│   ├── Product.java                  (entity)
│   ├── ProductRequest.java           (DTO in)
│   ├── ProductResponse.java          (DTO out)
│   ├── ProductMapper.java
│   └── ProductNotFoundException.java
├── order
│   ├── OrderController.java
│   ├── OrderService.java
│   ├── ...
├── user
│   └── ...
└── shared (or common)
    ├── GlobalExceptionHandler.java
    ├── WebConfig.java                (CORS)
    └── ApiError.java
```

**Why it's better:**

- **High cohesion:** things that change together live together. "Add a field to Product" touches one folder.
- **Encapsulation returns.** Inside `product`, only the controller needs to be `public`:

```java
// package-private: invisible outside the product package
class ProductRepository extends JpaRepository<Product, Long> { }
class ProductMapper { ... }

@Service
class ProductService { ... }          // other features can't touch it by accident

@RestController
@RequestMapping("/api/products")
public class ProductController { ... }  // Spring finds it anyway
```

Spring can instantiate package-private classes (it uses reflection), so you lose nothing and gain a compiler-enforced boundary: `order` can't import `ProductRepository` and bypass `ProductService`.

- **Easy to extract.** If `order` becomes its own microservice later, you move one folder.

**Cons:** features that depend on each other need a clear rule about who may call whom (see gotchas).

## 3. The hybrid (also common)

Feature first, layers inside:

```
product
├── web          ProductController, ProductRequest, ProductResponse
├── domain       Product, ProductRepository, ProductService
└── ...
```

Useful when a feature grows large (15+ classes). Start flat inside the feature and split only when it hurts.

## 4. The rule that makes it work: where the main class sits

`@SpringBootApplication` includes `@ComponentScan`, which scans **the main class's package and everything below it**.

```
com.alireza.shop.ShopApplication      ← scans com.alireza.shop.**
com.alireza.shop.product.ProductController   ✅ found
com.alireza.other.SomeController             ❌ NOT found
```

If a controller is outside, its endpoints simply return **404**, with no error at startup. This is the most common "my controller doesn't work" bug for beginners. The fix is to move it under the main class's package, or add `scanBasePackages`.

Also, never put the main class in the **default package** (no `package` line). Spring would scan the whole classpath, including libraries, and fail or run very slowly.

## 5. What goes inside the controller's responsibility

The structure only works if each layer stays in its lane.

```
Controller  →  Service  →  Repository  →  Database
HTTP only      business     data access
```

|Layer|Does|Must NOT do|
|---|---|---|
|**Controller**|Receive the request, validate input shape (`@Valid`), call the service, choose the status and headers|Business rules, database calls, transactions, `if` logic about prices or stock|
|**Service**|Business rules, transactions, orchestrating repositories|Know about HTTP (`ResponseEntity`, `HttpServletRequest`, status codes)|
|**Repository**|Queries|Business logic|

A **thin controller** is the goal. A good controller method is 3 to 6 lines:

```java
@PostMapping
public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductRequest req) {
    ProductResponse saved = service.create(req);            // all the real work
    URI location = locationOf(saved.id());
    return ResponseEntity.created(location).body(saved);
}
```

**Why:** if business logic lives in the controller, it can only be reached through HTTP. You can't reuse it from a scheduled job, a message listener, or a CLI, and you can't test it without a web layer.

**The test:** if you removed Spring MVC and replaced it with a command-line interface, would your service still work unchanged? If yes, the layering is right.

## 6. Where the supporting pieces go

|Piece|Place|Reason|
|---|---|---|
|Request/response DTOs|Inside the feature, next to the controller|They are the controller's contract|
|Entities|Inside the feature, but **never returned** by the controller|Keeps the DB shape private|
|Mapper (entity ↔ DTO)|Inside the feature, package-private|Only the feature uses it|
|Feature exceptions|Inside the feature|`ProductNotFoundException` belongs to product|
|`@RestControllerAdvice`|`shared`/`common`, or at root|It applies to **all** controllers|
|CORS, security, Jackson config|`config` package|Cross-cutting, not a feature|
|Constants, utilities|`shared`/`common`|Used by several features|

## 7. API versioning in the structure

When you need `/api/v1` and `/api/v2` side by side:

```
product
├── v1
│   ├── ProductControllerV1.java
│   └── ProductResponseV1.java
├── v2
│   ├── ProductControllerV2.java
│   └── ProductResponseV2.java
└── ProductService.java            ← shared business logic
```

```java
@RestController
@RequestMapping("/api/v1/products")
class ProductControllerV1 { ... }
```

Only the **web contract** is duplicated, while the service stays shared. This works because the controller is thin: a new version means a new adapter, not a rewrite.

## 8. Naming conventions

|Thing|Convention|Example|
|---|---|---|
|Controller|`<Feature>Controller`|`ProductController`|
|Request DTO|`<Feature>Request` / `Create<Feature>Request`|`CreateProductRequest`|
|Response DTO|`<Feature>Response`|`ProductResponse`|
|Base path|plural noun, lowercase, kebab-case|`/api/order-items`|
|Packages|lowercase, singular nouns|`product`, not `Products`|

Keep **one controller per resource** (`/products`, `/orders`), not one per HTTP verb and not one giant `ApiController`.

## What if we don't structure properly?

|Mistake|Consequence|
|---|---|
|Main class in a sub-package, controllers beside it|Controllers never discovered, silent 404s|
|Business logic in controllers|Untestable without HTTP, duplicated across endpoints, and transactions get messy|
|Controller calls the repository directly|Skips business rules and transaction boundaries. You end up duplicating logic in each controller|
|Everything `public` in layered packages|Any class can use any other, so dependencies tangle until nothing can change safely|
|Entities as DTOs|Schema leaks into the API, and infinite JSON recursion with relationships|
|One huge controller|Merge conflicts, a 2,000-line file, impossible to find anything|
|`@ControllerAdvice` buried in one feature|Looks feature-specific but affects the whole app, which is confusing|

## Nuances and gotchas

**1. Cross-feature calls.** `order` needs product data. The rule: depend on the **service** (or a small public interface), never on another feature's repository or entity.

```java
// order package
@Service
class OrderService {
    private final ProductService products;   // ✅ via the public API of the other feature
    // private final ProductRepository repo; // ❌ reaching into another feature's internals
}
```

Avoid **cycles**: if `order` calls `product` and `product` calls `order`, extract the shared piece or use events.

**2. Package-private only works within one package.** If you split a feature into `web` and `domain` sub-packages, the controller can no longer see a package-private service in `domain`. You must make that service `public` (or keep the feature flat). It's a trade-off between hiding and sub-structure.

**3. Don't over-engineer a small app.** For a learning project with 2 or 3 entities, layered packages are fine. Switching to feature packages costs nothing once it grows, because IDEs move packages with refactoring.

**4. Enforce the structure with tests.** Conventions that aren't enforced decay. **ArchUnit** lets you write rules as unit tests, for example "classes in `..controller..` must not depend on `..repository..`". Spring also offers **Spring Modulith**, which verifies feature-package boundaries for you.

**5. `@RequestMapping` base paths and packages are independent.** The package `product` doesn't create the URL `/product`. Only the annotation does. Keep them aligned by habit, not by magic.

**6. Test structure mirrors main structure.**

```
src/test/java/com/alireza/shop/product/ProductControllerTest.java
```

The same package lets tests see package-private classes. Controller tests typically use `@WebMvcTest(ProductController.class)`, which loads _only_ the web layer, and that is another reason a thin, isolated controller pays off.

**7. Your Angular front-end maps nicely.** A feature-based backend (`product`, `order`) mirrors feature-based Angular folders (`features/product`, `features/order`), so one feature = one backend package + one front-end folder.

## Recommended starting layout

```
com.alireza.shop
├── ShopApplication.java
├── product        ← controller, service, repository, entity, DTOs, mapper
├── order
├── user
├── config         ← WebConfig (CORS), SecurityConfig
└── shared         ← GlobalExceptionHandler, ProblemDetail helpers, utils
```





[[Spring Framework]]