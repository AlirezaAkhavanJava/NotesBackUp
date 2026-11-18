# Spring Security Configuration Through `application.properties`

This guide covers the properties Spring Boot reads to configure Spring Security, what each one controls, and how to combine them safely. It assumes Spring Boot 3.x with Spring Security 6.x, which is what current projects use.

## Part 1: How Properties Reach Spring Security

**Definition.** Spring Boot reads key-value pairs from `application.properties` (or `application.yml`) at startup and binds them to typed configuration classes such as `SecurityProperties`, `ServerProperties`, and `OAuth2ClientProperties`. Those classes then feed Spring Security's auto-configuration.

**Why it exists.** Security has many settings, such as usernames, token issuers, and cookie flags, that change between environments. Writing them as Java code would require recompiling for every change. Properties let you change behavior without touching code.

**What problem it solves.** Without this mechanism you would have to hard-code credentials, issuer URLs, and secrets into your classes, which is both inflexible and dangerous.

**How it works.** Spring Boot's auto-configuration classes are conditional. For example, `UserDetailsServiceAutoConfiguration` only creates a default user if the classpath contains Spring Security and you have not defined your own `UserDetailsService` bean. Properties supply the values those auto-configured beans use. This has an important consequence: **if you define your own security beans in Java, most of the `spring.security.user.*` properties are silently ignored.** Properties are the shortcut layer. Java configuration is the full control layer.

**How you will use it.** You will use properties for quick setup, for OAuth2 provider details, and for cookie and session hardening. You will use Java `SecurityFilterChain` beans for authorization rules and custom logic.

---

## Part 2: The Default User (`spring.security.user.*`)

**Definition.** These properties configure a single in-memory user that Spring Boot creates automatically.

**Why it exists.** When you add Spring Security to a project, every endpoint becomes protected immediately. Boot needs a way to let you log in during development without writing any code, so it provides this default user.

**What problem it solves.** It gives you a working login in seconds, which is useful for learning and for prototypes.

```properties
# Username for the built-in in-memory user (default: "user")
spring.security.user.name=alireza

# Password for that user. If omitted, Boot generates a random one
# and prints it in the console at startup.
spring.security.user.password=changeme123

# Roles granted to that user. Spring Security stores them with a "ROLE_" prefix.
# Here the user gets ROLE_ADMIN and ROLE_USER.
spring.security.user.roles=ADMIN,USER
```

**What each line does.** The `name` property sets the login username. The `password` property sets the login password, and leaving it out makes Boot print a random one at startup that looks like `Using generated security password: 8f2a...`. The `roles` property assigns authorities. Writing `ADMIN` produces the authority `ROLE_ADMIN`, which is what `hasRole("ADMIN")` checks.

**How you will use it.** Use it only while learning or for local testing. Once you write a `UserDetailsService` bean, these properties stop having any effect. Do not ship a plaintext password in a properties file; you will see how to avoid that in Part 7.

---

## Part 3: The Security Filter Chain (`spring.security.filter.*`)

**Definition.** Spring Security works as a chain of servlet filters that run before your controllers. These properties control where Spring Security's filter chain sits in the overall servlet filter order and which request dispatch types it applies to.

**Why it exists.** Other filters in your application, such as logging, character encoding, or CORS, may need to run before or after security. The order determines which one sees the request first.

**What problem it solves.** If security runs too late, a filter might process a request before authentication happens. If it runs too early, it might block things it should not. The order matters.

```properties
# Position of Spring Security's filter in the servlet filter chain.
# Lower numbers run earlier. Boot's default is already correct,
# so you rarely change this.
spring.security.filter.order=-100

# Which servlet dispatch types the security filter applies to.
# Default is ASYNC, ERROR, and REQUEST.
spring.security.filter.dispatcher-types=ASYNC,ERROR,REQUEST
```

**What each line does.** `filter.order` controls the position of the security filter, and a more negative number means earlier. `dispatcher-types` controls which kinds of request processing are secured. `ERROR` matters because error pages should not leak data past security, and `ASYNC` matters because async responses must still be protected.

**How you will use it.** Leave these at their defaults unless you add a custom filter that must run before security, or you see a bug caused by filter ordering. In practice you will rarely touch them.

---

## Part 4: Session Cookie Security (`server.servlet.session.*`)

**Definition.** A session is server-side state that remembers a logged-in user between HTTP requests. The browser holds only a cookie (by default `JSESSIONID`) that identifies the session. These properties control how that cookie is created and how long it lives.

**Why it exists.** HTTP is stateless, so the server needs a way to recognize that request #2 comes from the same user who logged in with request #1. The session cookie is that link.

**What problem it solves.** Session cookies are a common attack target. If someone steals the cookie, they can impersonate the user. Cookie flags reduce that risk, and timeouts limit how long a stolen cookie stays useful.

```properties
# How long an idle session stays valid. After 30 minutes of inactivity,
# the user must log in again.
server.servlet.session.timeout=30m

# Name of the session cookie. Changing it slightly complicates
# fingerprinting, but it is not a real security boundary.
server.servlet.session.cookie.name=APP_SESSION

# Prevent JavaScript (including XSS payloads) from reading the cookie.
# Default is true. Keep it true.
server.servlet.session.cookie.http-only=true

# Send the cookie only over HTTPS. Turn this on in production.
# Leave it false only during local HTTP development.
server.servlet.session.cookie.secure=true

# Controls whether the browser sends the cookie on cross-site requests.
# Strict: never on cross-site. Lax: on top-level navigations only.
# None: always (requires secure=true).
server.servlet.session.cookie.same-site=lax

# Only track sessions with cookies, never by putting the session ID in URLs.
server.servlet.session.tracking-modes=cookie
```

**What each line does.** `timeout` sets the idle expiry. `cookie.name` renames the cookie. `http-only` blocks JavaScript access, which defends against cookie theft through XSS. `secure` forces the cookie onto HTTPS only. `same-site` limits cross-site sending, which reduces CSRF risk. `tracking-modes=cookie` prevents the session ID from appearing in URLs, where it could leak through logs or the Referer header.

**How you will use it.** Set `secure=true` and `same-site` before deploying anything. The `http-only` default is already safe. Note that `secure=true` will break login over plain `http://localhost` in some browsers, so you may need a dev profile for that (see Part 7).

---

## Part 5: OAuth2 Login (`spring.security.oauth2.client.*`)

**Definition.** OAuth2 is a protocol that lets your application log users in through a third party, such as Google or GitHub, without ever seeing their password. Your app is the **client**. The third party is the **provider**. These properties tell Spring Security how to talk to both.

**Why it exists.** Users do not want to create yet another password. Delegating login to a trusted provider is safer for both the user and your application.

**What problem it solves.** Implementing the OAuth2 handshake yourself (redirects, authorization codes, token exchange, and signature checks) is complex and easy to get wrong. Spring Security does it once, correctly, and you supply the configuration.

**How it works.** You register your app with the provider and receive a client ID and client secret. You put them in properties under a **registration ID** (a name you choose, such as `github` or `google`). Spring Boot then builds the login redirect and the callback handling. Known providers (Google, GitHub, Facebook, Okta) have their URLs built in, so you usually need only the registration block.

```properties
# Registration for GitHub login. "github" is the registration ID
# and becomes part of the URLs Spring generates.
spring.security.oauth2.client.registration.github.client-id=${GITHUB_CLIENT_ID}
spring.security.oauth2.client.registration.github.client-secret=${GITHUB_CLIENT_SECRET}

# Scopes define what information you ask the provider for.
spring.security.oauth2.client.registration.github.scope=read:user,user:email

# Registration for Google. Google uses OpenID Connect, so "openid" is required.
spring.security.oauth2.client.registration.google.client-id=${GOOGLE_CLIENT_ID}
spring.security.oauth2.client.registration.google.client-secret=${GOOGLE_CLIENT_SECRET}
spring.security.oauth2.client.registration.google.scope=openid,profile,email

# Custom provider (for example, a company's own Keycloak server).
# You must supply the provider URLs yourself.
spring.security.oauth2.client.registration.keycloak.client-id=${KC_CLIENT_ID}
spring.security.oauth2.client.registration.keycloak.client-secret=${KC_CLIENT_SECRET}
spring.security.oauth2.client.registration.keycloak.scope=openid,profile
spring.security.oauth2.client.registration.keycloak.provider=keycloak

spring.security.oauth2.client.provider.keycloak.issuer-uri=https://auth.example.com/realms/myapp
```

**What each line does.** `client-id` and `client-secret` identify your app to the provider. The secret must stay private. `scope` lists the permissions you request. `provider` links a registration to a provider block. `issuer-uri` tells Spring to fetch the provider's configuration (authorization endpoint, token endpoint, and signing keys) from a standard discovery URL.

**Important detail.** The redirect URI is generated automatically as `{baseUrl}/login/oauth2/code/{registrationId}`, for example `http://localhost:8080/login/oauth2/code/github`. You must register that exact URL in the provider's developer console, or the login will fail with a redirect mismatch error.

**How you will use it.** Use this when you add "Login with Google" or "Login with GitHub" to a Spring Boot app. Keep the secrets in environment variables, as shown with `${...}` above.

---

## Part 6: Resource Server (`spring.security.oauth2.resourceserver.*`)

**Definition.** A resource server is an API that accepts access tokens and checks them before serving data. Unlike the OAuth2 client, it does not perform the login redirect. It only validates tokens that clients send in the `Authorization: Bearer ...` header.

**Why it exists.** Modern systems have a front-end app (such as Angular, which you are learning) that calls a Spring Boot API. The API needs to verify that each request carries a valid token, without storing sessions itself.

**What problem it solves.** Validating a JWT correctly requires checking its signature, its expiry, and its issuer. Getting any one of those wrong creates a serious vulnerability. These properties let Spring do that validation for you.

**How it works.** For a JWT, the resource server downloads the public keys (the JWK set) from the issuer and uses them to verify each token's signature. You can give it the issuer URL and let it discover the keys, or give it the key URL directly.

```properties
# Option A: Spring discovers the signing keys from the issuer's
# well-known configuration. This is the most common and recommended setup.
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://auth.example.com/realms/myapp

# Option B: Give the JWK set URL directly, if you do not want discovery.
# Use this instead of issuer-uri, not in addition to it.
# spring.security.oauth2.resourceserver.jwt.jwk-set-uri=https://auth.example.com/realms/myapp/protocol/openid-connect/certs

# Option C: Opaque tokens. The API asks the auth server "is this token valid?"
# on every request, instead of checking a signature locally.
# spring.security.oauth2.resourceserver.opaquetoken.introspection-uri=https://auth.example.com/introspect
# spring.security.oauth2.resourceserver.opaquetoken.client-id=${INTROSPECT_ID}
# spring.security.oauth2.resourceserver.opaquetoken.client-secret=${INTROSPECT_SECRET}
```

**What each line does.** `jwt.issuer-uri` tells Spring who issues the tokens. Spring then checks the token's `iss` claim against it and fetches the signing keys. `jwt.jwk-set-uri` supplies the keys directly. The opaque token settings are for systems where tokens are random strings, not self-contained JWTs, so each check requires a network call.

**How you will use it.** This is the setup for a Spring Boot REST API protected by Keycloak, Auth0, Okta, or similar. You will combine it with a `SecurityFilterChain` bean that says which endpoints require which roles.

---

## Part 7: Keeping Secrets Out of Properties Files

**Definition.** A secret is any value that gives access to a system, such as a password, client secret, API key, or database credential.

**Why it matters.** Properties files are typically committed to Git. A secret committed once stays in the repository history even after you delete it, and anyone with repository access can read it.

**What to do instead.** Reference environment variables with `${VAR_NAME}`, and optionally give a fallback with `${VAR_NAME:default}`.

```properties
# Good: value comes from the environment at startup.
spring.security.oauth2.client.registration.github.client-secret=${GITHUB_CLIENT_SECRET}

# Good: fallback for local development only. Never put a real secret here.
spring.security.user.password=${APP_PASSWORD:devonly-password}

# Bad: real secret in a committed file.
# spring.security.oauth2.client.registration.github.client-secret=abc123realsecret
```

Set the variables in your shell before running the app:

```bash
export GITHUB_CLIENT_ID="your-id"
export GITHUB_CLIENT_SECRET="your-secret"
./mvnw spring-boot:run
```

On Debian, you can make these persist by adding the exports to `~/.bashrc` or by using a systemd service's `Environment=` or `EnvironmentFile=` setting for production. Do not put the secret directly in `~/.bashrc` if the file is shared, and never commit a `.env` file containing real secrets.

**Why this design.** Spring resolves `${...}` placeholders at startup, so the same properties file works in every environment, and each environment supplies its own secrets.

---

## Part 8: Profiles, So Dev and Prod Differ Safely

**Definition.** A profile is a named set of configuration. Spring loads `application-{profile}.properties` on top of the base `application.properties` when that profile is active.

**Why it exists.** Development needs `secure=false` for HTTP testing and a simple default user. Production needs `secure=true`, real providers, and no default user. Profiles keep both sets of rules in one project.

**How it works.** Activate a profile with `spring.profiles.active`, or with the environment variable `SPRING_PROFILES_ACTIVE`.

`application.properties` (shared):
```properties
server.servlet.session.cookie.http-only=true
server.servlet.session.timeout=30m
```

`application-dev.properties` (local development):
```properties
# Allow session cookies over plain http://localhost
server.servlet.session.cookie.secure=false
spring.security.user.name=dev
spring.security.user.password=devpassword
spring.security.user.roles=ADMIN
```

`application-prod.properties` (production):
```properties
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
# No default user in production. Real users come from a database or provider.
```

Run with the dev profile:
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Or run a packaged jar in production:
```bash
SPRING_PROFILES_ACTIVE=prod java -jar target/myapp.jar
```

**How you will use it.** Put every environment-specific security setting in a profile file. If you ever find a `secure=false` in your main file, that is a deployment risk waiting to happen.

---

## Part 9: The Limits of Properties

Properties cover the simple, declarative parts of security. They cannot express:

- Which URLs need which roles (`/admin/**` requires `ADMIN`).
- Custom login pages or logic after login.
- Custom CORS, CSRF, or header rules.
- Password hashing policy (you need a `PasswordEncoder` bean).
- Loading users from a database.

Those are configured in Java with a `SecurityFilterChain` bean. The properties from this guide still matter there, because the Java configuration sits on top of them. You will need both.

---



[[Spring Security]]