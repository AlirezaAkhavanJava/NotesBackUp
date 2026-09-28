
# Angular: from zero to a GUI for your Spring Boot backend

## 1. The core intuition

Think of a restaurant. **Spring Boot is the kitchen.** It holds the recipes (business rules), the pantry (database), and the health inspector (security). **Angular is the dining room.** It has the menus, tables, and waiters, and it presents things to the customer and carries orders back to the kitchen.

Angular's technical definition is a **TypeScript framework for building single-page applications (SPAs)** that run inside the user's browser. The mapping to what you know:

|Java world|Angular world|
|---|---|
|Java source → bytecode → runs on JVM|TypeScript → JavaScript → runs in the browser's JS engine|
|Spring Boot (framework with DI, conventions)|Angular (framework with DI, conventions)|
|Maven/Gradle + `pom.xml`|npm + `package.json`|
|Maven Central / `~/.m2`|npm registry / `node_modules`|
|`public static void main`|`src/main.ts`|
|`@RestController` mapping URLs to methods|Router mapping URLs to components|
|`@Service` + `@Autowired`|`@Injectable` + `inject()`|
|DTO / record|`interface` in TypeScript|

So your question "is it GUI or logic?" has a precise answer. **Angular contains GUI plus presentation logic** (what to show, when to show a spinner, form validation for user comfort). **The real business logic and security stay in Spring Boot.** The browser belongs to the user, who can edit any JavaScript in it, so nothing in Angular can be trusted. Validation in Angular is politeness, and validation in Spring is law.

## 2. The three building blocks

**Component = LEGO brick.** A class (logic) plus a template (HTML) plus optional styles. The whole page is a tree of bricks: `App` contains `Navbar` and `ProductList`, and `ProductList` contains many `ProductCard`s.

**Service = specialist worker.** A plain class with no UI that does a job, such as fetching data from Spring or holding login state. Components ask for one instead of creating it. This is the same dependency injection idea as Spring's container.

**Router = the map from URL to brick.** `/products` shows the `ProductList` component. There's only one real HTML page (`index.html`), and Angular swaps the bricks in and out without reloading. That is what "single-page" means.

## 3. What `ng new` gives you

Modern Angular projects look like this (the file names shift slightly between versions, see the note below the tree):

```
shop-ui/
├── package.json          # dependencies & scripts  (≈ pom.xml)
├── angular.json          # build/serve/test config (≈ maven plugins config)
├── tsconfig*.json        # TypeScript compiler settings
├── public/               # static files copied as-is (favicon, images)
└── src/
    ├── index.html        # the ONE html page; contains <app-root>
    ├── main.ts           # entry point (≈ main method)
    ├── styles.css        # global styles
    └── app/
        ├── app.ts            # root component
        ├── app.html
        ├── app.css
        ├── app.config.ts     # global providers (≈ @Configuration class)
        └── app.routes.ts     # URL → component table
```

`main.ts` boots the root component using `app.config.ts`, and `app.config.ts` registers global things like the router and the HTTP client. This is like `SpringApplication.run()` plus your `@Configuration` beans.

> **Version note:** Since Angular 17, new projects are standalone by default, meaning components list their own dependencies directly instead of being declared inside `NgModule` classes. Older tutorials you'll find online use NgModules (`app.module.ts`), so if a tutorial shows that, it's the legacy style. Newer CLI versions (v20+, as far as I know) also generate `app.ts` instead of `app.component.ts`. Run `ng version` to check yours, and the concepts are identical either way.

### The folder layout you liked: core / shared / features

Here is a subtlety. **Angular does not enforce this structure.** `ng new` only creates `app/`, and `core/shared/features` is a community convention that makes large projects tidy:

```
src/app/
├── core/                  # app-wide singletons, used once, loaded at startup
│   ├── services/          #   auth.service.ts
│   ├── interceptors/      #   adds JWT token to every HTTP call
│   ├── guards/            #   blocks routes if not logged in
│   └── models/            #   interfaces shared everywhere (User, ApiError)
├── shared/                # dumb reusable UI bricks, no business knowledge
│   ├── components/        #   button, modal, spinner
│   └── pipes/             #   formatting helpers
└── features/              # one folder per business area
    ├── products/
    │   ├── product-list/  #   component
    │   ├── product.service.ts
    │   └── product.model.ts
    └── orders/
```

The rule of thumb is that `core` is what the whole app needs exactly once, `shared` is what many features reuse but which knows nothing about your business, and `features` is one vertical slice per business capability. If you know the "package-by-layer vs package-by-feature" debate in Spring, `features/` is package-by-feature, and it usually scales better because deleting a feature means deleting one folder.

## 4. Create a project on Debian 13

Angular's tooling runs on Node.js. Node is only a build-time tool here, since the final product is static files. The version matters, because each Angular release requires a specific Node range and Debian's packaged `nodejs` can lag behind. The most reliable route is `nvm`, which installs into your home directory with no `sudo`:

```bash
sudo apt install curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
# restart the terminal, then:
nvm install --lts
node -v

npm install -g @angular/cli
ng new shop-ui          # answer the prompts; SSR = No is fine for now
cd shop-ui
ng serve                # http://localhost:4200
```

`ng serve` runs a dev server with hot reload, so save a file and the browser updates. Angular's CLI is like Spring Initializr and the Maven wrapper combined: `ng generate component ...` (short: `ng g c`) scaffolds bricks for you.

## 5. Hands-on: a GUI that shows data from Spring Boot

**Spring Boot side** (the kitchen):

```java
record ProductDto(Long id, String name, double price) {}

@RestController
@RequestMapping("/api/products")
class ProductController {
    @GetMapping
    List<ProductDto> all() {
        return List.of(new ProductDto(1L, "Keyboard", 49.9),
                       new ProductDto(2L, "Mouse", 19.5));
    }
}
```

**The CORS problem.** Browsers block a page from `localhost:4200` from calling `localhost:8080`, because they count as different origins. In development, the clean fix is to make Angular's dev server forward `/api` calls, so the browser thinks everything is one origin. Create `proxy.conf.json` in the project root:

```json
{ "/api": { "target": "http://localhost:8080", "secure": false } }
```

Then run `ng serve --proxy-config proxy.conf.json`. You could instead configure CORS in Spring, but the proxy also mirrors how production will look.

**Angular side.** Register the HTTP client globally in `app.config.ts`:

```ts
export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes), provideHttpClient()],
};
```

The model, an interface that mirrors your DTO (`features/products/product.model.ts`):

```ts
export interface Product { id: number; name: string; price: number; }
```

The service, your `@Service`:

```ts
@Injectable({ providedIn: 'root' })   // one shared instance app-wide
export class ProductService {
  private http = inject(HttpClient);   // DI, like constructor injection

  getAll() {
    return this.http.get<Product[]>('/api/products');
  }
}
```

The component, generated with `ng g c features/products/product-list`:

```ts
import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-product-list',
  imports: [CurrencyPipe],
  template: `
    <h2>Products</h2>
    <ul>
      @for (p of products(); track p.id) {
        <li>{{ p.name }}: {{ p.price | currency }}</li>
      } @empty {
        <li>Nothing yet…</li>
      }
    </ul>
  `,
})
export class ProductList {
  products = toSignal(inject(ProductService).getAll(), { initialValue: [] });
}
```

Finally, add the route in `app.routes.ts`: `{ path: 'products', component: ProductList }`. Visit `http://localhost:4200/products`, and you'll see data from Spring Boot.

### Two new ideas hiding in that code

- **Observable:** `http.get()` returns an `Observable`, which is like a `CompletableFuture` that can emit many values over time. It is **lazy**, so nothing is sent to the server until something subscribes. Forgetting to subscribe is the classic beginner bug of "my request never fires."
- **Signal:** a value box that Angular watches. `products()` reads it, and when it changes, only the parts of the page that used it re-render. `toSignal` converts the Observable into a signal and handles subscribing and unsubscribing for you.

## 6. Gotchas and nuances

- **TypeScript types vanish at runtime.** `get<Product[]>()` is a promise to the compiler, not a check. If Spring returns a different shape, Angular won't complain and you'll get `undefined` at runtime. This is unlike Jackson, which fails when JSON doesn't fit your class.
- **Deep links.** In production, someone opening `/products` directly asks the web server for a file that doesn't exist. The server must fall back to `index.html` for unknown paths, and Angular's router then takes over.
- **Security lives in Spring.** Route guards in Angular only hide screens. Enforce authorization on every endpoint in Spring Security.

## 7. Building for production

```bash
ng build
```

This compiles, bundles, minifies, and tree-shakes into static files, usually under `dist/shop-ui/browser/` (path can vary by version). There is no Node at runtime. You have two common deployment options:

1. **Separate hosting:** serve those files with nginx and proxy `/api` to Spring Boot. This is the standard setup, and it lets you scale and deploy each side independently.
2. **Bundled into Spring Boot:** copy the files into `src/main/resources/static/`. It's a single JAR, which is simple for small projects, but you'll need a controller or resource config that forwards unknown routes to `index.html`.

## What we've built on

You now have the map. Angular is the browser-side framework, components are the bricks, services are the workers, the router maps URLs, and Spring Boot stays the source of truth. Good next steps, in increasing difficulty: **templates and data binding in depth**, then **forms**, then **routing with guards and lazy loading**, then **RxJS operators**, then **JWT auth with an interceptor**. Tell me which one to open next.


[[Java]]
[[0 - Spring Framework]]