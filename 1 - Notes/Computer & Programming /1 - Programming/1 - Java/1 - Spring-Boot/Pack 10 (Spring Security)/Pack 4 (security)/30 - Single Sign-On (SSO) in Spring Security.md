

SSO means a person logs in **once**, at one trusted place, and then gets into many different applications without typing a password again. Think of a company where you sign in with your work account and then open Email, Jira, and the HR portal with no more login screens. Those apps don't check your password themselves. They trust one central login system to do it for them.

In Spring Security, SSO means your app **hands the login job to someone else** (called an _Identity Provider_, or IdP, like Google, Keycloak, Okta, or Microsoft Entra). Your app only receives proof that the user was authenticated. This is good for you as a developer: you store no passwords, you get features like MFA for free, and your users enjoy one login everywhere. Spring Security supports this through **OAuth2 / OpenID Connect (OIDC)** and **SAML 2.0**, and you can set it up with very little code.

---

## 1. Meet the players

Before any code, learn the four roles. Everything else is just these four talking to each other.

|Role|Who it is|Example|
|---|---|---|
|**User** (Resource Owner)|The human logging in|You|
|**Client**|Your Spring Boot app|`my-app` on `localhost:8080`|
|**Identity Provider / Authorization Server**|The system that checks the password|Keycloak, Google, Okta|
|**Resource Server**|An API that accepts tokens|Your backend REST API|

In SSO, _your Spring Boot app is the Client_. It never sees the password. That is the whole idea.

## 2. OAuth2 vs OIDC vs SAML (the three names you will hear)

These get mixed up a lot, so here is the short version:

- **OAuth2** is about **authorization**: "may this app access this thing on my behalf?" It does not say _who_ the user is.
- **OIDC (OpenID Connect)** is a thin layer on top of OAuth2 that adds **authentication**: "this user is Ahmed, here is his email." It gives you an **ID Token** (a JWT). **Almost all modern SSO uses OIDC.**
- **SAML 2.0** is an older XML-based standard, still very common in big companies. Same goal, different format.

> **Rule of thumb:** new project → OIDC. Enterprise customer insists on SAML → SAML.

## 3. How the login flow works (Authorization Code Flow)

This is what happens when a user clicks "Login" in your app:

```
1. User opens /dashboard             → your app says "you're not logged in"
2. App redirects browser to the IdP  → /authorize?client_id=...&redirect_uri=...&scope=openid
3. User logs in at the IdP           → (password, MFA, whatever the IdP wants)
4. IdP redirects back to your app    → /login/oauth2/code/keycloak?code=abc123
5. Your app calls the IdP directly   → sends the code + client secret, gets ID token + access token
6. Spring creates a session          → user is now logged in
```

Notice step 4: the browser only carries a short-lived **code**, not the real tokens. Your app trades that code for tokens **server to server** (step 5), which is safer. Spring Security does steps 2, 4, 5, and 6 for you automatically.

## 4. Your first SSO app (OIDC with Keycloak or Google)

**Dependencies (Maven):**

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

**`application.yml`:**

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: my-app
            client-secret: ${KEYCLOAK_SECRET}
            scope: openid, profile, email
            authorization-grant-type: authorization_code
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
        provider:
          keycloak:
            issuer-uri: http://localhost:8180/realms/myrealm
```

Line by line:

- `registration.keycloak` : a name _you_ choose. It becomes the `{registrationId}` in URLs.
- `client-id` / `client-secret` : the "username and password" of **your app** at the IdP. You get these when you register the app there.
- `scope: openid, ...` : `openid` is the magic word that turns plain OAuth2 into OIDC. `profile` and `email` ask for those user details.
- `redirect-uri` : where the IdP sends the user back. `{baseUrl}` and `{registrationId}` are placeholders Spring fills in. **It must match exactly what you registered at the IdP**, or you get a "redirect mismatch" error.
- `issuer-uri` : the IdP's address. Spring downloads `/.well-known/openid-configuration` from it and learns every endpoint automatically. That is why you don't list the authorize/token URLs yourself.

> **Shortcut:** for Google, GitHub, Facebook, and Okta, Spring Boot already knows the provider details. You only write `client-id` and `client-secret`.

**Security configuration:**

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2Login(Customizer.withDefaults());
        return http.build();
    }
}
```

- `authorizeHttpRequests(...)` : rules for who may open which URL. Home and public pages are open; everything else needs login.
- `.oauth2Login(...)` : **this one line turns on SSO.** It adds the redirect, callback, and token-exchange logic.
- `Customizer.withDefaults()` : "use the defaults." Spring even generates a login page with a "Login with Keycloak" link.

**Reading who logged in:**

```java
@RestController
class ProfileController {

    @GetMapping("/me")
    Map<String, Object> me(@AuthenticationPrincipal OidcUser user) {
        return Map.of(
            "name", user.getFullName(),
            "email", user.getEmail(),
            "claims", user.getClaims()
        );
    }
}
```

`@AuthenticationPrincipal OidcUser` gives you the logged-in user. A **claim** is just one fact inside the ID token (`email`, `name`, `sub`, and so on).

## 5. What Spring does inside (so it stops feeling like magic)

Three pieces matter:

|Piece|What it does|
|---|---|
|`ClientRegistration`|Holds the settings for one IdP (client id, secret, URLs). Built from your YAML.|
|`OAuth2LoginAuthenticationFilter`|Listens on `/login/oauth2/code/*`, receives the `code`, and exchanges it for tokens.|
|`OidcUserService`|Reads the ID token and builds the `OidcUser` object.|

After this, the user is stored in the normal `SecurityContext` and a normal **session**, so the rest of Spring Security (roles, `@PreAuthorize`, and so on) works as usual.

## 6. Roles and authorities (the part everyone gets stuck on)

The IdP says _who_ the user is. **Your app still decides what they can do.** By default Spring turns OIDC scopes into authorities like `SCOPE_openid`, not the roles you want. Keycloak, for example, puts roles inside a claim called `realm_access.roles`. You map them yourself:

```java
@Bean
GrantedAuthoritiesMapper authoritiesMapper() {
    return authorities -> {
        Set<GrantedAuthority> mapped = new HashSet<>();
        for (GrantedAuthority a : authorities) {
            if (a instanceof OidcUserAuthority oidc) {
                Map<String, Object> realmAccess = oidc.getIdToken().getClaim("realm_access");
                if (realmAccess != null) {
                    List<String> roles = (List<String>) realmAccess.get("roles");
                    roles.forEach(r -> mapped.add(new SimpleGrantedAuthority("ROLE_" + r.toUpperCase())));
                }
            }
        }
        return mapped;
    };
}
```

- Loop over what Spring built from the login.
- If it is an OIDC authority, read the `realm_access` claim out of the ID token.
- Convert each role to a `ROLE_...` authority, which is what `hasRole("ADMIN")` looks for.

Then you can write `.requestMatchers("/admin/**").hasRole("ADMIN")`.

## 7. The same app as a _Resource Server_ (SSO for APIs)

If your backend is a REST API called by a React or mobile app, the user logs in at the IdP, and the front end sends the **access token** in every request:

```
Authorization: Bearer eyJhbGciOi...
```

Your API only validates the token. It does not do any redirect:

```java
http
    .authorizeHttpRequests(a -> a.anyRequest().authenticated())
    .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
```

```yaml
spring.security.oauth2.resourceserver.jwt.issuer-uri: http://localhost:8180/realms/myrealm
```

Spring downloads the IdP's public keys and checks each token's **signature, expiry, and issuer**. Quick comparison:

||`oauth2Login` (Client)|`oauth2ResourceServer` (API)|
|---|---|---|
|Used for|Web apps with pages|REST APIs|
|Login redirect|Yes|No|
|State|Session (cookie)|Stateless (token each request)|
|Receives|Authorization code|Bearer token|

## 8. SAML 2.0 in two minutes

Same idea, different words. The IdP sends your app a signed **XML assertion** instead of a JWT.

```java
http
    .authorizeHttpRequests(a -> a.anyRequest().authenticated())
    .saml2Login(Customizer.withDefaults());
```

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          okta:
            assertingparty:
              metadata-uri: https://dev-123.okta.com/app/xxx/sso/saml/metadata
```

Here your app is the **Relying Party** (RP) and the IdP is the **Asserting Party**. The `metadata-uri` plays the same role as `issuer-uri` in OIDC.

## 9. Logging out properly (Single Logout)

Logging out of your app only ends _your_ session. The user may still be logged in at the IdP, so clicking "Login" again signs them straight back in. To end the IdP session too, use **OIDC RP-Initiated Logout**:

```java
@Bean
SecurityFilterChain chain(HttpSecurity http, ClientRegistrationRepository repo) throws Exception {
    var handler = new OidcClientInitiatedLogoutSuccessHandler(repo);
    handler.setPostLogoutRedirectUri("{baseUrl}/");

    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .oauth2Login(Customizer.withDefaults())
        .logout(l -> l.logoutSuccessHandler(handler));
    return http.build();
}
```

This redirects the browser to the IdP's logout endpoint, then back to your home page.

## 10. Common mistakes

|Symptom|Likely cause|
|---|---|
|`redirect_uri mismatch`|URI in YAML differs from the one registered at the IdP (even `localhost` vs `127.0.0.1`)|
|Login loops forever|Cookie or session problem, often HTTP vs HTTPS or wrong `baseUrl` behind a proxy|
|`hasRole("ADMIN")` always 403|Roles were never mapped, so the user only has `SCOPE_*`|
|`invalid_issuer` / JWT errors|`issuer-uri` does not match the token's `iss` exactly (trailing slash counts)|
|Works locally, breaks in Docker|`issuer-uri` points to `localhost`, which means the container itself|

---

## Related concepts, quickly

- **JWT:** a signed token with three Base64 parts (header, payload, signature). Anyone can read it; only the IdP can sign it.
- **Keycloak:** a free, open-source IdP you can run in Docker to practice SSO locally (you already know Docker basics, so it's a good first lab).
- **CSRF and `state`:** Spring sends a random `state` value during login and checks it on return, which blocks forged callbacks. It does this for you.
- **PKCE:** an extra safety step for apps that can't keep a secret (mobile, SPAs). Spring enables it by default for public clients.

## A good practice path

1. Run Keycloak in Docker and create a realm and a client.
2. Build the `oauth2Login` app from section 4.
3. Map Keycloak roles (section 6) and protect `/admin`.
4. Add a second app that uses the **same** Keycloak. Log in to one and notice the other needs no login. That is real SSO.
5. Build a resource server (section 7) and call it with a token.






[[Spring Security]]