
Since you're coming from **Java/Spring Boot**, I would not learn “frontend” as a giant pile of technologies. Learn it as a dependency chain.

For your goal — **Angular frontend + Spring Boot backend** — I'd use this order:

## 1. Web fundamentals

Before Angular, understand what the browser is actually doing.

Learn:

1. **HTML**
    
    - elements
        
    - attributes
        
    - forms
        
    - semantic HTML
        
    - DOM
        
2. **CSS**
    
    - selectors
        
    - box model
        
    - positioning
        
    - Flexbox
        
    - Grid
        
    - responsive design
        
    - media queries
        
3. **HTTP**
    
    - request/response
        
    - methods: GET, POST, PUT, PATCH, DELETE
        
    - status codes
        
    - headers
        
    - cookies
        
    - JSON
        
    - CORS
        

You already know some HTTP from Spring, so this part should be relatively quick.

---

# 2. JavaScript

**Do not jump into Angular before learning JavaScript.**

Learn:

```text
Variables
 ↓
Types
 ↓
Operators
 ↓
Functions
 ↓
Objects
 ↓
Arrays
 ↓
Loops
 ↓
Destructuring
 ↓
Modules
 ↓
Classes
 ↓
Promises
 ↓
async/await
 ↓
DOM
 ↓
Events
 ↓
Fetch API
```

For example, eventually you should understand:

```javascript
async function getUsers() {
    const response = await fetch("/api/users");
    const users = await response.json();

    console.log(users);
}
```

You should be able to look at that and understand **every line**.

---

# 3. TypeScript

Angular heavily uses TypeScript.

Since you're a Java developer, this will feel much more familiar than JavaScript.

Learn:

```text
JavaScript
    ↓
TypeScript
    ↓
Angular
```

Focus on:

- types
    
- interfaces
    
- type aliases
    
- enums
    
- classes
    
- access modifiers
    
- generics
    
- union/intersection types
    
- type narrowing
    
- modules
    
- decorators
    
- `async` / `await`
    

Example:

```typescript
interface User {
    id: number;
    email: string;
}

function printUser(user: User): void {
    console.log(user.email);
}
```

---

# 4. Node.js ecosystem

You don't need to become a Node backend developer.

You mainly need to understand the **tooling ecosystem**.

Learn:

```text
Node.js
npm
npx
package.json
package-lock.json
node_modules
npm scripts
NVM
```

You should understand:

```bash
npm install
npm install <package>
npm uninstall <package>
npm run build
npm run start
npx <tool>
```

And understand what this means:

```json
{
    "scripts": {
        "start": "...",
        "build": "...",
        "test": "..."
    }
}
```

---

# 5. Angular

**Now** start Angular.

Don't learn Angular as random decorators.

Learn it in this order:

### 5.1 Angular project structure

Understand:

```text
src/
├── app/
├── assets/
├── styles.scss
├── main.ts
└── index.html
```

And:

```text
package.json
angular.json
tsconfig.json
```

---

### 5.2 Components

This is fundamental.

```text
Component
├── TypeScript
├── HTML
└── CSS
```

Learn:

```typescript
@Component(...)
export class UserComponent {
}
```

Then understand:

```text
Component
    ↓
Template
    ↓
DOM
```

---

### 5.3 Templates

Learn:

- interpolation
    
- property binding
    
- event binding
    
- conditional rendering
    
- loops
    
- template variables
    
- pipes
    

For example:

```html
<h1>{{ user.name }}</h1>

<button (click)="deleteUser()">
    Delete
</button>
```

---

### 5.4 Components communicating

Learn:

```text
Parent
  ↓
@Input
  ↓
Child
```

and:

```text
Child
  ↓
@Output
  ↓
Parent
```

This is extremely important.

---

# 6. Angular services + dependency injection

This will feel very familiar to you because you've already learned Spring DI.

Angular:

```typescript
@Injectable({
    providedIn: 'root'
})
export class UserService {
}
```

Then:

```text
Component
    ↓
Service
    ↓
HTTP API
    ↓
Spring Boot
```

Think of it as Angular's equivalent architectural concept to:

```text
Controller
    ↓
Service
    ↓
Repository
```

although Angular services aren't literally Spring services.

---

# 7. Angular routing

Learn:

```text
URL
 ↓
Angular Router
 ↓
Component
```

For example:

```text
/login
/dashboard
/habits
/profile
```

Then learn:

- routes
    
- route parameters
    
- child routes
    
- navigation
    
- route guards
    
- lazy loading
    

---

# 8. HTTP communication

This is where your Angular application starts talking to your Spring Boot application.

Learn Angular's `HttpClient`.

Conceptually:

```text
Angular
   │
   │ HTTP
   ↓
Spring Boot
   │
   ↓
PostgreSQL
```

Example:

```typescript
this.http.get<User[]>("/api/users");
```

Understand:

- GET
    
- POST
    
- PUT
    
- PATCH
    
- DELETE
    
- request bodies
    
- headers
    
- status codes
    
- interceptors
    
- error handling
    

---

# 9. RxJS

This is one of the biggest Angular concepts.

Don't rush it.

Learn:

```text
Observable
Subscription
Operator
Subject
BehaviorSubject
pipe()
```

Then operators:

```text
map
filter
tap
switchMap
catchError
debounceTime
distinctUntilChanged
```

Eventually you should understand:

```typescript
this.userService.getUsers()
    .pipe(
        map(users => users.filter(user => user.active))
    )
    .subscribe(users => {
        this.users = users;
    });
```

---

# 10. Forms

Learn both:

### Template-driven forms

and primarily:

### Reactive Forms

Learn:

```text
FormControl
FormGroup
FormArray
Validators
```

For example:

```typescript
loginForm = new FormGroup({
    email: new FormControl(""),
    password: new FormControl("")
});
```

This is important for your authentication project.

---

# 11. Authentication

Now connect Angular + Spring Security.

Understand:

```text
Angular
   │
   │ POST /login
   ↓
Spring Security
   │
   ↓
JWT
   │
   ↓
Angular
```

Learn:

- authentication vs authorization
    
- JWT
    
- access tokens
    
- refresh tokens
    
- HTTP interceptors
    
- route guards
    
- logout
    
- token storage/security considerations
    
- CORS
    
- CSRF and when it matters
    

Don't just copy a JWT tutorial. Understand the protocol.

---

# 12. State management

Don't immediately jump into NgRx.

First understand ordinary Angular state:

```text
Component state
        ↓
Service state
        ↓
Signals / RxJS
```

Learn Angular **Signals**.

Then, if your application becomes sufficiently complex, investigate:

```text
NgRx
```

You probably don't need NgRx for your first Angular project.

---

# 13. Testing

Learn:

```text
Unit tests
Component tests
Service tests
Integration/E2E tests
```

Angular's testing ecosystem is worth learning after you've built a couple of real features.

---

# 14. Build & deployment

Eventually understand what happens when you run:

```bash
npm run build
```

Conceptually:

```text
TypeScript
     ↓
Angular compiler
     ↓
JavaScript
     ↓
CSS
     ↓
HTML
     ↓
optimized production files
```

Then you can serve those static files with something like:

```text
Nginx
```

Your production architecture could look like:

```text
                  Internet
                     │
                     ↓
                  Nginx
                /       \
               /         \
              ↓           ↓
       Angular files   /api/*
                          │
                          ↓
                    Spring Boot
                          │
                          ↓
                     PostgreSQL
```

---

# Your complete roadmap

I'd structure your learning like this:

```text
1. HTML
       ↓
2. CSS
       ↓
3. HTTP / Web fundamentals
       ↓
4. JavaScript
       ↓
5. TypeScript
       ↓
6. Node.js + npm + npx
       ↓
7. Angular fundamentals
       ↓
8. Components + Templates
       ↓
9. Services + Dependency Injection
       ↓
10. Routing
       ↓
11. HttpClient / REST
       ↓
12. RxJS
       ↓
13. Reactive Forms
       ↓
14. Authentication
       ↓
15. Signals / State management
       ↓
16. Testing
       ↓
17. Production builds
       ↓
18. Deployment
```

### And for **you specifically**

Because you're already learning **Java + Spring Boot + PostgreSQL**, I'd spend much more time on:

**JavaScript → TypeScript → Angular → RxJS → browser/HTTP → frontend architecture**

and less time on Node.js.

You **do not need to become a Node.js backend developer** just because you're learning Angular.

Your eventual stack can simply be:

```text
             FRONTEND
        Angular + TypeScript
                 │
                HTTP
                 │
                 ↓
             BACKEND
          Spring Boot + Java
                 │
                JDBC
                 │
                 ↓
             PostgreSQL
```

That's a very reasonable stack for your **DoItLater** project.


[[1 - What is Node JS]]