

In software security, Auth usually refers to one of two concepts:

- Authentication (AuthN): Who are you?
    
- Authorization (AuthZ): What are you allowed to do?
    

They are different processes, but they work together to protect applications.

For example, when you build a Spring Boot application, authentication verifies that someone is a legitimate user. Authorization decides whether that user can access a particular API endpoint.

## The problem it solves

Imagine you are building a banking application with Spring Boot.

Your application has these endpoints:

|Endpoint|Purpose|
|---|---|
|`POST /login`|Log in to an account|
|`GET /accounts/me`|View your account|
|`POST /transfer`|Transfer money|
|`GET /admin/users`|Manage all users|

Without security, anyone might be able to access sensitive operations.

You need two different checks.

1. Authentication: Verify that the person making the request is a known user.
    
2. Authorization: Verify that this user has permission to perform the requested operation.
    

### A simple analogy

Think of entering an office building.

Authentication is showing your identification to the security guard.

Authorization is checking whether your identification permits you to enter the server room.

You might be a legitimate employee but still have no permission to enter that room.

This is exactly the distinction between authentication and authorization.

## Part 1 — Authentication (AuthN)

Authentication is the process of verifying an identity.

There are many ways to authenticate users. There is no single fixed number of authentication methods because different methods can be combined, and new protocols continue to emerge.

We can group them into several major categories.

### Authentication factors

Before examining the technologies, you should understand three fundamental authentication factors.

|Factor|Meaning|Example|
|---|---|---|
|Something you know|A secret you remember|Password, PIN|
|Something you have|An object or device you possess|Security key, authenticator device|
|Something you are|A biometric characteristic|Fingerprint, face|

Multifactor authentication (MFA) combines two or more different factors.

For example, a password plus a hardware security key is MFA. Two passwords are not.

Now let's examine the main authentication methods used in applications.

## Part 2 — Major authentication methods

### 1. HTTP Basic Authentication

Basic Authentication is one of the simplest HTTP authentication schemes.

The client sends a username and password with each request.

```
GET /api/profile HTTP/1.1
Authorization: Basic YWxpOnNlY3JldA==
```

- `GET` requests the user's profile.
    
- `Authorization` carries the authentication credentials.
    
- `Basic` identifies the HTTP authentication scheme.
    
- The encoded value represents `ali:secret` in Base64.
    

Spring Security can process this using `BasicAuthenticationFilter`.

Typical use: Simple internal APIs, development environments, and controlled integrations.

Limitation: Credentials are repeatedly transmitted, so HTTPS is essential.

### 2. Form-Based Authentication

This is the familiar login form used by many websites.

Sign in

Username

Password

Log inIllustrative login form

Here's the typical process:

1. The user submits a username and password.
    
2. Spring Security verifies the credentials.
    
3. The server creates an authenticated session.
    
4. The browser receives a session cookie.
    
5. Subsequent requests include that cookie.
    

In Spring Security, `UsernamePasswordAuthenticationFilter` commonly handles form login submissions.

Typical use: Traditional web applications.

Important: Form login and session authentication are not identical concepts. Form login describes how credentials are submitted; sessions describe how authentication state is maintained.

### 3. Session-Based Authentication

Session authentication allows a server to remember an authenticated user between requests.

Instead of submitting the password on every request, the browser sends a session identifier.

Browser

Cookie: JSESSIONID=abc123

HTTP request with cookie

Spring Boot Server

Looks up the session

Server-side session

Session ID: abc123

Authenticated user: alireza

Authorities: ROLE_USER

The session ID works like a coat-check ticket. You don't have to show the original proof of ownership each time; you present the ticket.

Typical use: Browser-based applications.

Limitation: Sessions require lifecycle management, expiration, and potentially shared session storage across multiple servers.

### 4. Token-Based Authentication

With token-based authentication, a client sends a token that the server recognizes as proof of authentication.

A token is a piece of data representing an authentication or access grant.

A common example is a Bearer token:

```
GET /api/profile HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

- `GET` requests a protected resource.
    
- `Authorization` carries the token.
    
- `Bearer` means possession of the token is generally sufficient to use it.
    
- The remaining value represents the token.
    

Tokens can be opaque or structured.

An opaque token is an identifier whose meaning is not directly available to the client; the server or authorization service must look it up or introspect it.

A JWT (JSON Web Token) is a structured token format that can contain claims, such as a user identifier, issuer, expiration, or permissions.

JWTs are often signed so a server can detect tampering. A signed JWT is not necessarily encrypted.

Typical use: REST APIs, mobile applications, and distributed systems.

Limitation: Stolen Bearer tokens can be reused until they expire or are otherwise invalidated.

### 5. API Key Authentication

API keys are commonly used to identify or authenticate applications rather than individual human users.

For example:

```
GET /api/weather HTTP/1.1
X-API-Key: example-api-key
```

- `GET` requests the resource.
    
- `X-API-Key` is an example custom header.
    
- The value is a secret assigned to the calling application.
    

API keys are not a single standardized HTTP authentication protocol. Their format and verification depend on the service.

Typical use: Third-party API integrations, internal services, and developer platforms.

Limitation: API keys are often long-lived secrets. They need secure storage, rotation, revocation, and limited permissions.

### 6. OAuth 2.0

OAuth 2.0 is primarily an authorization framework, not an authentication protocol.

It allows one application to obtain limited access to resources managed by another service without requiring the user to give the application their password.

For example, imagine a calendar application that wants permission to read your Google Calendar events.

Rather than receiving your Google password, the application obtains an access token with a limited scope.

A scope describes what an access token is allowed to access.

OAuth 2.0 involves several roles:

|Role|Responsibility|
|---|---|
|Resource owner|Owns or controls the protected resources|
|Client|Application requesting access|
|Authorization server|Issues access tokens|
|Resource server|Hosts protected resources|

Typical use: Third-party API access and delegated permissions.

Important: OAuth 2.0 alone does not standardize how an application verifies a user's identity. That is where OpenID Connect becomes relevant.

### 7. OpenID Connect (OIDC)

OpenID Connect is an authentication protocol built on OAuth 2.0.

It allows applications to authenticate users through an identity provider.

An identity provider is a service responsible for authenticating users and supplying identity information.

For example, when you click "Sign in with Google," the application may use OpenID Connect.

The general process is:

1. Your application redirects the user to an identity provider.
    
2. The identity provider authenticates the user.
    
3. The user is redirected back through a secure protocol flow.
    
4. Your application validates an ID token and establishes the user's identity.
    

An ID token is a token containing claims about an authentication event and the authenticated user.

Typical use: Social login, enterprise single sign-on, and centralized identity systems.

### 8. Passkeys and WebAuthn

Passkeys provide passwordless authentication based on public-key cryptography.

Public-key cryptography uses a pair of related keys: a private key and a public key.

The private key stays protected by the user's authenticator, while the server stores the public key.

During authentication, the authenticator signs a challenge, and the server verifies that signature.

This avoids transmitting a reusable password.

Passkeys commonly use the WebAuthn standard, which also binds credentials to a website's identity to resist phishing.

Typical use: Modern passwordless login.

Limitation: Applications must handle registration, account recovery, and support for different authenticator devices.

### 9. Mutual TLS (mTLS)

Mutual TLS is a method of authenticating both ends of a TLS connection using certificates.

With ordinary HTTPS, the client generally verifies the server's certificate.

With mutual TLS, the server also verifies a certificate presented by the client.

Typical use: Service-to-service authentication, high-security enterprise environments, and internal infrastructure.

Limitation: Certificate issuance, renewal, and revocation require operational management.

## Part 3 — Authentication methods compared

|Method|Main credential|Common use|
|---|---|---|
|Basic Auth|Username/password|Simple HTTP clients|
|Form Login|Username/password|Web login forms|
|Session Auth|Session cookie|Browser applications|
|Bearer Token|Access token|REST APIs|
|API Key|Shared secret|Application integrations|
|OAuth 2.0|Access token|Delegated authorization|
|OpenID Connect|ID token and protocol flow|Federated login|
|WebAuthn / Passkeys|Cryptographic key|Passwordless login|
|mTLS|Client certificate|Service authentication|

Notice that these methods are not all alternatives at the same level.

For example, an application can use OpenID Connect to log in a user, then use a session cookie to maintain that login. Another application can use OAuth 2.0 to obtain a JWT access token and send it using the Bearer scheme.

## Part 4 — Authorization (AuthZ)

Once a user is authenticated, your application must decide what they can access.

This is authorization.

Spring Security supports multiple authorization models.

### 1. Role-Based Access Control (RBAC)

RBAC assigns permissions according to roles.

For example:

|Role|Permissions|
|---|---|
|USER|Read own profile|
|MODERATOR|Moderate content|
|ADMIN|Manage users|

In Spring Security, you can require a role using `hasRole()`.

```
.requestMatchers("/admin/**").hasRole("ADMIN")
.requestMatchers("/profile/**").authenticated()
```

- The first line requires the `ADMIN` role for `/admin/**`.
    
- The second line requires authentication for `/profile/**`.
    

Spring Security normally represents `hasRole("ADMIN")` using the authority `ROLE_ADMIN`.

### 2. Permission-Based Access Control

Instead of assigning broad roles, you can check individual permissions.

For example:

```
.requestMatchers(HttpMethod.DELETE, "/posts/**")
.hasAuthority("POST_DELETE")
```

- The first line matches DELETE requests to `/posts/**`.
    
- `hasAuthority("POST_DELETE")` requires that exact authority.
    

Permissions are often more granular than roles.

### 3. Attribute-Based Access Control (ABAC)

ABAC makes decisions using attributes such as the user, requested resource, action, or environment.

For example, a user might be allowed to update a document only when:

- The user belongs to the document's organization.
    
- The document is not locked.
    
- The user has edit permission.
    

Spring Security can support such rules through custom authorization logic, method security, and authorization managers.

### 4. Ownership-Based Authorization

This is particularly important in REST APIs.

Imagine:

`GET /api/users/42`

A user might be authenticated but should not automatically be able to read another user's private data.

The application must verify whether the current user owns the requested resource or has an appropriate administrative permission.

This protects against a common vulnerability called Broken Object Level Authorization (BOLA).

## Part 5 — How Spring Security combines authentication and authorization

The simplified flow looks like this:

Incoming HTTP request

Authentication

Verify the client's identity

Invalid credentials

401 Unauthorized

Identity verified

Continue

Authorization

Check permissions for this resource

Denied

403 Forbidden

Allowed

Controller executes

This diagram represents the usual protected-resource flow. Public endpoints may not require authentication, and the exact status code depends on the security configuration.

## Try it yourself

You can experiment with both authentication and authorization in a Spring Boot application.

Configure a protected endpoint and a user with the `USER` role. Then try accessing an endpoint that requires the `ADMIN` role.

```
curl -i -u alireza http://localhost:8080/api/profile
```

- `curl` sends an HTTP request.
    
- `-i` displays response headers.
    
- `-u alireza` uses HTTP Basic Authentication and prompts for the password.
    
- The URL points to the profile endpoint.
    

Then test an administrative endpoint:

```
curl -i -u alireza http://localhost:8080/admin/users
```

- `curl -i` sends the request and shows the HTTP response.
    
- `-u alireza` authenticates the same user.
    
- `/admin/users` represents an endpoint protected by the `ADMIN` role.
    

If the first endpoint requires authentication and the second requires `ADMIN`, a valid `USER` account can receive `200 OK` from the first and `403 Forbidden` from the second, assuming both endpoints exist and the first request is otherwise valid.

This demonstrates that successful authentication does not guarantee authorization.

## Common mistakes

|Mistake|Why it hurts|How to fix|
|---|---|---|
|Treating AuthN and AuthZ as identical|Authenticated users may access unauthorized resources|Check identity and permissions separately|
|Thinking OAuth 2.0 is a login protocol|Confuses delegated access with identity verification|Use OIDC for federated authentication|
|Thinking JWT is an authentication protocol|JWT is a token format|Understand token issuance and validation|
|Assuming roles protect individual records|Users may access someone else's data|Check resource ownership|
|Storing passwords in plaintext|A database leak exposes passwords|Use password hashing|
|Treating API keys as public identifiers|Exposes access credentials|Store keys securely and rotate them|
|Disabling CSRF without understanding it|Can expose browser-based applications|Evaluate the authentication mechanism and client behavior|

## Related concept, briefly — Spring Security filters

Spring Security uses a chain of servlet filters to process incoming HTTP requests.

Different authentication mechanisms may involve different filters. For example, `BasicAuthenticationFilter` handles HTTP Basic credentials, while `UsernamePasswordAuthenticationFilter` commonly processes form login submissions.

Authorization checks are also integrated into the security filter chain.

## The whole picture

|Question|Answer|
|---|---|
|What is authentication?|Verifying an identity|
|What is authorization?|Checking permissions|
|How many authentication methods exist?|No fixed number; there are multiple families and protocols|
|What is Basic Auth?|Username/password authentication over HTTP|
|What is session authentication?|Maintaining login state through a session|
|What is JWT?|A structured token format|
|What is OAuth 2.0?|A delegated authorization framework|
|What is OIDC?|An identity layer built on OAuth 2.0|
|What is RBAC?|Authorization based on user roles|
|What does Spring Security do?|Provides infrastructure for authentication and authorization|




[[Spring Security]]