## **What is CSRF?**

Cross-Site Request Forgery (CSRF) is a security vulnerability where an attacker tricks a user into performing actions on a web application without their consent.

When a user logs in, a session ID is generated and sent to the client (which can be a human user, Postman, or any application). This session ID is included with every request the client makes to the server. However, if a malicious application obtains the session ID, it can use it to send requests to the server and access or manipulate resources, impersonating the legitimate user. This security risk is referred to as CSRF.

## **What are Cookies ?**

A cookie is a small piece of data a website stores in your browser so it can recognize you later.
When your browser talks to a server, HTTP itself is *stateless*. Each request is amnesiac. Cookies are how we give the server a memory.

## **Why are Cookies Important in Authentication?**

When a user logs in with valid credentials, these credentials are verified against the database, and upon successful authentication, the user is taken to the first page.

However, subsequent page requests (like accessing the second or third page) also need to confirm that the same authenticated user is accessing them. Since HTTP is a stateless protocol, cookies play a crucial role in maintaining the user’s session across multiple requests by identifying the user as the one previously authenticated

## **Security Concerns in CRUD Operations**

CRUD operations (Create, Read, Update, Delete) involve different HTTP methods:

GET: Retrieves data from the server.  
POST, PUT, DELETE: Involve modifications to the server’s state.

By default, Spring Security allows GET requests but blocks state-changing operations (POST, PUT, DELETE) without additional verification to prevent CSRF attacks.

---
## **How a CSRF token is generated ? 

A **CSRF token** is created as a **random, unpredictable value** by the server and tied to the user session. The key idea is **uniqueness per user session** so that attackers can’t guess it. Here’s the process in detail:

### 1. Server generates the token

- The server uses a **cryptographically secure random generator** to create a string.
- Common methods:
    - Java: `SecureRandom` + Base64 encoding
    - Spring Security handles it automatically with `DefaultCsrfTokenRepository`.
- Example in Java:
    
```java
SecureRandom secureRandom = new SecureRandom();
byte[] tokenBytes = new byte[32];
secureRandom.nextBytes(tokenBytes);
String csrfToken = Base64.getUrlEncoder().encodeToString(tokenBytes);
```

- This gives a **long, unpredictable token**, impossible to guess.
### 2. Token is associated with the user session

- The server stores the token **in the user’s session**.
    
- In Spring Security, this is handled by `HttpSessionCsrfTokenRepository`.
    
- So each user gets a unique token tied to their session.
### 3. Token is sent to the client

- Typically included in:
    
    - HTML forms as a hidden input field:
        
```html
<input type="hidden" name="_csrf" value="the_token_here"/>
```

- Or in SPA apps, as a response header:
    
```
X-CSRF-TOKEN: the_token_here
```

- The client must send it back with every **state-changing request** (POST, PUT, DELETE).
    
### 4. Server validates the token

- When a request comes in, the server checks:
    
    1. Is the token present?
        
    2. Does it match the token in the session?
        
- If yes → request proceeds.
    
- If no → request is rejected as a potential CSRF attack.
    
### **Key points**

- Token must be **unpredictable**. Predictable tokens defeat the purpose.
    
- Token is **session-scoped**, so attackers can’t forge it without access to the user’s session.
    
- Some systems rotate tokens per request for extra security.
    
---

A CSRF token proves that a request really comes from your site and your user, not from a malicious site. It stops attackers from tricking your browser into performing unwanted actions while logged in.

It figures this out by **matching the CSRF token sent in the request with the one stored in the user’s session**.

Here’s the logic:
1. When a user visits your site, the server generates a **unique token** and stores it in their session.
2. The same token is sent to the client (hidden in a form or in headers).
3. When the client makes a state-changing request (POST, PUT, DELETE), it **must send the token back**.
4. The server checks:
    - Is the token present?
    - Does it match the session’s token?
 If yes → request is legitimate (same person).  
If no → request is rejected (likely an attacker), because a malicious site **cannot read the token** from the user’s session due to browser security (same-origin policy).

So the token acts as a **shared secret between the server and the real client**—cookies alone can’t prove intent.

#### Tags : [[1 - Spring Security 🍌]]