API = **Application Programming Interface**.

It’s a **set of rules, methods, or contracts** that allow different software systems (or parts of a system) to talk to each other.
![[diagram-what-is-an-api-postman-illustration.svg]]
- If you write code that exposes functions for others to use → that’s an API.
    
- If you call functions provided by a library, framework, or web service → you’re using their API.
    

Think of it as a **menu in a restaurant**:

- The menu = API (it lists what you can order).
    
- The kitchen = internal implementation (you don’t see how it works).
    
- You order from the menu, get the dish, without knowing how it was cooked.

---
### 1. **Local (Library / Language) APIs**

- Example: `java.util.List` in Java.
    
- This is just a **set of interfaces and classes** that Java provides.
    
- You import and call them **inside your code**, no network needed.
    
- They define _how you interact_ with data structures (like List) without caring about how they’re implemented.
    

👉 `List` is an **API** — specifically, the **Java Collections API**.

---

### 2. **Remote (Web) APIs**

- Example: Weather API, GitHub API, etc.
    
- These are **hosted on another server**.
    
- You interact with them **over a network (usually HTTP/HTTPS)**.
    
- They expose endpoints (URLs) instead of methods in a library.
    

👉 A Web API is just an API, but **accessible over the internet**.

---

⚡ So the **difference**:

- **Library API** → already in your programming environment, used locally.
    
- **Web API** → exposed remotely, you call it through network requests.
    

Both are APIs because in both cases you’re using a **contract** someone else defined (methods, interfaces, endpoints) without touching the internal implementation.

---



















[[0 - Spring Framework]][[Java]]
