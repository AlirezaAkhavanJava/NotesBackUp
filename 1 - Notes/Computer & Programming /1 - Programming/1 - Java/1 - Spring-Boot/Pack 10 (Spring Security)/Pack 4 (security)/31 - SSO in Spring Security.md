

SSO in Spring Security is a chain of small, replaceable pieces, and each piece is a class you can see, configure, or swap. When a user clicks "Login", a set of **servlet filters** redirects the browser to the identity provider (IdP), receives a one-time **code** on the way back, trades it for **tokens**, validates them, and builds an **authenticated user** stored in the session. You don't have to write any of that, but you can change every step.

In this lesson we follow one login through the actual code, from the first request to logout. We build a runnable lab first, then open the hood: the filters, the HTTP messages, the token contents, and the classes that process them. After that come the customizations you will need in real projects (database users, roles, calling other APIs, protecting REST endpoints, SAML, tests, debugging).

---

## Part 1: The lab (run this first)

### 1.1 Start Keycloak with Docker

```yaml
# docker-compose.yml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.0
    command: start-dev
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: admin
    ports:
      - "8180:8080"
```

```bash
docker compose up -d
```

Open `http://localhost:8180`, log in as `admin/admin`, then:

1. Create a realm named `myrealm`.
2. Create a client `my-app`: _Client authentication = ON_, valid redirect URI `http://localhost:8080/login/oauth2/code/keycloak`. Copy its secret from the **Credentials** tab.
3. Create realm roles `USER` and `ADMIN`, and a test user with a password and one of those roles.

### 1.2 Dependencies

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
  </dependency>
  <!-- Client side: login with an IdP -->
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
  </dependency>
  <!-- API side: validate bearer tokens (used in Part 7) -->
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-test</artifactId>
    <scope>test</scope>
  </dependency>
</dependencies>
```

### 1.3 `application.yml`

```yaml
server:
  port: 8080

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
            client-authentication-method: client_secret_basic
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
        provider:
          keycloak:
            issuer-uri: http://localhost:8180/realms/myrealm
            user-name-attribute: preferred_username
```

|Key|What it means|
|---|---|
|`registration.keycloak`|Your chosen name. It becomes `registrationId` and appears in URLs.|
|`client-authentication-method`|How your app proves itself at the token endpoint. `client_secret_basic` sends the secret in an `Authorization: Basic` header.|
|`issuer-uri`|Spring fetches `{issuer-uri}/.well-known/openid-configuration` at startup and learns the authorize, token, JWKS, userinfo, and logout URLs.|
|`user-name-attribute`|Which claim becomes `authentication.getName()`. Default is `sub`, which is an unreadable UUID.|

### 1.4 The minimum security config

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/public/**").permitAll()
                .anyRequest().authenticated())
            .oauth2Login(Customizer.withDefaults());
        return http.build();
    }
}
```

```java
@RestController
class MeController {
    @GetMapping("/me")
    Map<String, Object> me(@AuthenticationPrincipal OidcUser user) {
        return user.getClaims();
    }
}
```

Run it and open `http://localhost:8080/me`. You are redirected to Keycloak, you log in, and you see your claims as JSON. Everything below explains what just happened.

---

## Part 2: What `.oauth2Login()` really installs

That single line adds filters to your chain. These three matter:

|Filter|Watches URL|Job|
|---|---|---|
|`OAuth2AuthorizationRequestRedirectFilter`|`/oauth2/authorization/{registrationId}`|Builds the authorize URL and redirects the browser to the IdP|
|`OAuth2LoginAuthenticationFilter`|`/login/oauth2/code/{registrationId}`|Receives `code` + `state`, runs the authentication|
|`DefaultLoginPageGeneratingFilter`|`/login`|Generates a page with one link per registered provider|

When an unauthenticated user hits `/me`, `ExceptionTranslationFilter` catches the `AccessDeniedException`, and the `LoginUrlAuthenticationEntryPoint` redirects to `/login` (or straight to `/oauth2/authorization/keycloak` if you have only one provider).

### 2.1 Step 1: building the authorize redirect (simplified)

This is a simplified version of what `OAuth2AuthorizationRequestRedirectFilter` and its resolver do:

```java
// 1. Find which provider: "/oauth2/authorization/keycloak" -> "keycloak"
String registrationId = resolveRegistrationId(request);
ClientRegistration reg = clientRegistrationRepository.findByRegistrationId(registrationId);

// 2. Build the request with random state (and nonce for OIDC)
OAuth2AuthorizationRequest authRequest = OAuth2AuthorizationRequest.authorizationCode()
    .clientId(reg.getClientId())
    .authorizationUri(reg.getProviderDetails().getAuthorizationUri())
    .redirectUri(expandedRedirectUri)
    .scopes(reg.getScopes())
    .state(randomString())                      // CSRF protection for the login flow
    .additionalParameters(p -> p.put("nonce", randomString()))  // replay protection for the ID token
    .build();

// 3. Remember it so we can verify the callback later (stored in the HTTP session)
authorizationRequestRepository.saveAuthorizationRequest(authRequest, request, response);

// 4. Redirect the browser
response.sendRedirect(authRequest.getAuthorizationRequestUri());
```

Why step 3 matters: when the browser comes back, Spring compares the returned `state` with the saved one. If they differ, someone forged the callback, and the login is rejected.

### 2.2 The real HTTP message the browser follows

```
GET http://localhost:8180/realms/myrealm/protocol/openid-connect/auth
    ?response_type=code
    &client_id=my-app
    &scope=openid%20profile%20email
    &state=Xy12AbC...
    &redirect_uri=http://localhost:8080/login/oauth2/code/keycloak
    &nonce=Q1wErT...
```

|Param|Why it is there|
|---|---|
|`response_type=code`|Authorization Code Flow: "send me a code, not tokens."|
|`scope=openid ...`|`openid` makes this OIDC and gets you an ID token.|
|`state`|Anti-forgery value, returned unchanged.|
|`nonce`|Gets embedded inside the ID token so a stolen token can't be replayed.|
|`redirect_uri`|Where to send the user back. It must match the registered URI exactly.|

### 2.3 Step 2: the callback

After login, the IdP redirects to:

```
GET http://localhost:8080/login/oauth2/code/keycloak?code=7f3a...&state=Xy12AbC...&session_state=...
```

### 2.4 Step 3: `OAuth2LoginAuthenticationFilter` (simplified)

```java
public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) {
    // a) must have code + state
    MultiValueMap<String, String> params = toMultiMap(request.getParameterMap());
    if (!isAuthorizationResponse(params)) throw new OAuth2AuthenticationException(...);

    // b) load and REMOVE the saved request (one-time use) and check state
    OAuth2AuthorizationRequest authRequest =
        authorizationRequestRepository.removeAuthorizationRequest(request, response);
    if (authRequest == null) throw new OAuth2AuthenticationException("authorization_request_not_found");

    // c) find the provider settings
    String registrationId = authRequest.getAttribute(OAuth2ParameterNames.REGISTRATION_ID);
    ClientRegistration reg = clientRegistrationRepository.findByRegistrationId(registrationId);

    // d) package request + response and hand over to the provider chain
    OAuth2AuthorizationResponse authResponse =
        OAuth2AuthorizationResponseUtils.convert(params, redirectUri);
    var token = new OAuth2LoginAuthenticationToken(
        reg, new OAuth2AuthorizationExchange(authRequest, authResponse));
    OAuth2LoginAuthenticationToken result =
        (OAuth2LoginAuthenticationToken) getAuthenticationManager().authenticate(token);

    // e) remember the tokens (access + refresh) for later API calls
    OAuth2AuthorizedClient client = new OAuth2AuthorizedClient(
        result.getClientRegistration(), principalName,
        result.getAccessToken(), result.getRefreshToken());
    authorizedClientRepository.saveAuthorizedClient(client, result, request, response);

    return result;
}
```

The `authenticationManager` delegates to `OidcAuthorizationCodeAuthenticationProvider`, which does the real work.

### 2.5 Step 4: `OidcAuthorizationCodeAuthenticationProvider` (simplified)

```java
// 1. Exchange the code for tokens (HTTP POST to the token endpoint)
OAuth2AccessTokenResponse tokenResponse = accessTokenResponseClient.getTokenResponse(codeGrantRequest);

// 2. Pull out the raw ID token string
String rawIdToken = (String) tokenResponse.getAdditionalParameters().get("id_token");

// 3. Validate + decode it (signature, iss, aud, exp, nonce)
OidcIdToken idToken = createOidcToken(clientRegistration, tokenResponse);
validateNonce(authorizationRequest, idToken);

// 4. Load user details (calls userinfo endpoint if needed) via OidcUserService
OidcUser oidcUser = userService.loadUser(new OidcUserRequest(
    clientRegistration, accessToken, idToken, additionalParameters));

// 5. Let your GrantedAuthoritiesMapper change the authorities
Collection<? extends GrantedAuthority> mapped =
    authoritiesMapper.mapAuthorities(oidcUser.getAuthorities());

// 6. Return the authenticated token
return new OAuth2LoginAuthenticationToken(clientRegistration, exchange, oidcUser, mapped, accessToken, refreshToken);
```

**Step 1 on the wire** (server to server; the browser never sees this):

```
POST http://localhost:8180/realms/myrealm/protocol/openid-connect/token
Authorization: Basic bXktYXBwOnNlY3JldA==      <- base64("my-app:secret")
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=7f3a...&redirect_uri=http://localhost:8080/login/oauth2/code/keycloak
```

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "expires_in": 300,
  "refresh_token": "eyJhbGciOiJIUzUxMiIs...",
  "token_type": "Bearer",
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "scope": "openid email profile"
}
```

**The decoded ID token** (payload part of the JWT):

```json
{
  "iss": "http://localhost:8180/realms/myrealm",
  "sub": "f1c2d3e4-....",
  "aud": "my-app",
  "azp": "my-app",
  "exp": 1790000300,
  "iat": 1790000000,
  "nonce": "Q1wErT...",
  "preferred_username": "ahmed",
  "email": "ahmed@example.com",
  "name": "Ahmed Ali",
  "realm_access": { "roles": ["USER", "ADMIN"] }
}
```

**What step 3 checks:**

|Check|Meaning|
|---|---|
|Signature|Verified with the IdP's public key from its `jwks_uri`|
|`iss`|Must equal the provider's issuer|
|`aud`|Must contain your `client-id`|
|`exp`|Not expired (default clock skew: 60 s)|
|`nonce`|Must equal the nonce you stored in step 1|

### 2.6 What ends up in the session

```java
SecurityContext ctx = SecurityContextHolder.getContext();
OAuth2AuthenticationToken auth = (OAuth2AuthenticationToken) ctx.getAuthentication();

auth.getPrincipal();                         // OidcUser (the person)
auth.getAuthorities();                       // [OIDC_USER, SCOPE_openid, SCOPE_profile, SCOPE_email]
auth.getAuthorizedClientRegistrationId();    // "keycloak"
```

The tokens live separately in the `OAuth2AuthorizedClientRepository` (default: HTTP session).

---

## Part 3: The beans you can replace

Each box in the flow above is an interface with a default implementation.

|Concern|Interface / Class|Default|
|---|---|---|
|Provider settings|`ClientRegistrationRepository`|`InMemoryClientRegistrationRepository` (built from YAML)|
|Storing the pending request|`AuthorizationRequestRepository<OAuth2AuthorizationRequest>`|`HttpSessionOAuth2AuthorizationRequestRepository`|
|Building the authorize URL|`OAuth2AuthorizationRequestResolver`|`DefaultOAuth2AuthorizationRequestResolver`|
|Code to tokens|`OAuth2AccessTokenResponseClient<OAuth2AuthorizationCodeGrantRequest>`|`RestClientAuthorizationCodeTokenResponseClient` (older: `DefaultAuthorizationCodeTokenResponseClient`)|
|Validating the ID token|`JwtDecoderFactory<ClientRegistration>`|`OidcIdTokenDecoderFactory`|
|Building the user|`OAuth2UserService<OidcUserRequest, OidcUser>`|`OidcUserService`|
|Mapping authorities|`GrantedAuthoritiesMapper`|none (keeps what the user service made)|
|Storing tokens|`OAuth2AuthorizedClientRepository` / `Service`|HTTP session / in-memory|

The wiring DSL shows where each one plugs in:

```java
http.oauth2Login(oauth -> oauth
    .loginPage("/login")                                        // your own login page
    .authorizationEndpoint(a -> a
        .baseUri("/oauth2/authorization")
        .authorizationRequestResolver(myResolver)
        .authorizationRequestRepository(myRequestRepo))
    .redirectionEndpoint(r -> r.baseUri("/login/oauth2/code/*"))
    .tokenEndpoint(t -> t.accessTokenResponseClient(myTokenClient))
    .userInfoEndpoint(u -> u.oidcUserService(myOidcUserService)
                            .userService(myPlainOAuth2UserService))   // for non-OIDC providers like GitHub
    .authorizedClientService(myAuthorizedClientService)
    .successHandler(mySuccessHandler)
    .failureHandler(myFailureHandler));
```

---

## Part 4: Customizing the login

### 4.1 Custom login page

```java
.oauth2Login(o -> o.loginPage("/login"))
```

```java
@Controller
class LoginController {
    @GetMapping("/login")
    String login() { return "login"; }
}
```

```html
<!-- templates/login.html -->
<a href="/oauth2/authorization/keycloak">Login with Company SSO</a>
<a href="/oauth2/authorization/google">Login with Google</a>
```

The link format is always `/oauth2/authorization/{registrationId}`.

### 4.2 Add parameters to the authorize request (force re-login, PKCE, hints)

```java
@Bean
OAuth2AuthorizationRequestResolver authorizationRequestResolver(ClientRegistrationRepository repo) {
    var resolver = new DefaultOAuth2AuthorizationRequestResolver(repo, "/oauth2/authorization");

    resolver.setAuthorizationRequestCustomizer(customizer -> customizer
        .additionalParameters(params -> {
            params.put("prompt", "login");              // always show the IdP login screen
            params.put("login_hint", "ahmed@example.com");
        }));

    // Add PKCE explicitly for a confidential client too:
    // resolver.setAuthorizationRequestCustomizer(OAuth2AuthorizationRequestCustomizers.withPkce());
    return resolver;
}
```

Then register it: `.authorizationEndpoint(a -> a.authorizationRequestResolver(resolver))`.

Line by line:

- `DefaultOAuth2AuthorizationRequestResolver(repo, "/oauth2/authorization")`: the standard resolver and its URL prefix.
- `setAuthorizationRequestCustomizer`: gives you the `OAuth2AuthorizationRequest.Builder` just before it is finalized.
- `additionalParameters`: anything the IdP understands. `prompt=login` forces a fresh login; `prompt=none` does a silent check.

### 4.3 Syncing the user into your database (PostgreSQL)

Most apps need their own user row (preferences, orders, relations). Replace `OidcUserService` with one that saves the user on every login:

```java
@Entity
@Table(name = "app_user")
public class AppUser {
    @Id
    private String sub;            // the IdP's stable user id
    private String email;
    private String fullName;
    private Instant lastLogin;
    // getters/setters
}

public interface AppUserRepository extends JpaRepository<AppUser, String> {}
```

```java
@Bean
OAuth2UserService<OidcUserRequest, OidcUser> oidcUserService(AppUserRepository users) {
    OidcUserService delegate = new OidcUserService();

    return request -> {
        OidcUser oidcUser = delegate.loadUser(request);          // 1. normal OIDC processing

        AppUser user = users.findById(oidcUser.getSubject())     // 2. find or create
                            .orElseGet(AppUser::new);
        user.setSub(oidcUser.getSubject());
        user.setEmail(oidcUser.getEmail());
        user.setFullName(oidcUser.getFullName());
        user.setLastLogin(Instant.now());
        users.save(user);                                        // 3. persist

        return oidcUser;                                         // 4. keep the same principal
    };
}
```

```java
.oauth2Login(o -> o.userInfoEndpoint(u -> u.oidcUserService(oidcUserService)))
```

Always key the row by `sub`, not by email. Emails change; `sub` never does for a given IdP.

If you also want authorities from your own tables, return a new principal:

```java
Set<GrantedAuthority> authorities = new HashSet<>(oidcUser.getAuthorities());
authorities.add(new SimpleGrantedAuthority("ROLE_" + user.getRole()));
return new DefaultOidcUser(authorities, oidcUser.getIdToken(), oidcUser.getUserInfo(), "preferred_username");
```

### 4.4 Mapping IdP roles to Spring roles

Keycloak puts roles in `realm_access.roles` (and per-client roles in `resource_access.{client}.roles`). Spring doesn't know that, so you map them:

```java
@Bean
GrantedAuthoritiesMapper authoritiesMapper() {
    return authorities -> {
        Set<GrantedAuthority> mapped = new HashSet<>(authorities);

        authorities.stream()
            .filter(OidcUserAuthority.class::isInstance)
            .map(OidcUserAuthority.class::cast)
            .forEach(oidc -> {
                Map<String, Object> realmAccess = oidc.getIdToken().getClaim("realm_access");
                if (realmAccess == null) return;

                @SuppressWarnings("unchecked")
                List<String> roles = (List<String>) realmAccess.get("roles");
                if (roles == null) return;

                roles.forEach(r -> mapped.add(new SimpleGrantedAuthority("ROLE_" + r.toUpperCase())));
            });

        return mapped;
    };
}
```

- `OidcUserAuthority` is the authority that carries the ID token and userinfo.
- `getIdToken().getClaim("realm_access")` reads the claim you saw in the decoded token.
- The `ROLE_` prefix is what `hasRole("ADMIN")` and `@PreAuthorize("hasRole('ADMIN')")` expect.

Because it is a bean of type `GrantedAuthoritiesMapper`, Spring picks it up automatically. By default the realm roles appear in the **access token** and the ID token only if the client mapper is configured to include them. If the claim is missing, check Keycloak's _Client scopes → roles_ mapper settings.

Use it:

```java
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .requestMatchers("/", "/public/**").permitAll()
    .anyRequest().authenticated())
```

```java
@Configuration
@EnableMethodSecurity
class MethodSecurityConfig {}

@Service
class ReportService {
    @PreAuthorize("hasRole('ADMIN')")
    public Report secretReport() { ... }
}
```

### 4.5 Success and failure handlers

```java
.oauth2Login(o -> o
    .successHandler((request, response, authentication) -> {
        OidcUser u = (OidcUser) authentication.getPrincipal();
        log.info("Login ok: {}", u.getEmail());
        response.sendRedirect("/dashboard");
    })
    .failureHandler((request, response, exception) -> {
        log.warn("Login failed: {}", exception.getMessage());
        response.sendRedirect("/login?error");
    }))
```

If you use no success handler, Spring redirects back to the page the user originally wanted (saved by `RequestCache`).

### 4.6 Tolerating clock differences and custom ID token validation

```java
@Bean
JwtDecoderFactory<ClientRegistration> idTokenDecoderFactory() {
    OidcIdTokenDecoderFactory factory = new OidcIdTokenDecoderFactory();
    factory.setJwtValidatorFactory(reg -> new DelegatingOAuth2TokenValidator<>(
        new JwtTimestampValidator(Duration.ofMinutes(2)),     // 2 minutes of clock skew
        new OidcIdTokenValidator(reg)                         // iss, aud, nonce rules
    ));
    return factory;
}
```

### 4.7 Several providers at once

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: ${GOOGLE_ID}
            client-secret: ${GOOGLE_SECRET}
            scope: openid, profile, email
          keycloak:
            client-id: my-app
            client-secret: ${KEYCLOAK_SECRET}
            scope: openid, profile, email
        provider:
          keycloak:
            issuer-uri: http://localhost:8180/realms/myrealm
```

Google is a built-in provider, so it needs no `provider` block. The default `/login` page now shows two links. Use `registrationId` inside a handler to know which one was used: `((OAuth2AuthenticationToken) auth).getAuthorizedClientRegistrationId()`.

---

## Part 5: Using the user's access token to call another API

The ID token says _who_ the user is. The **access token** lets your app call an API _on their behalf_. Spring stored it for you.

```java
@RestController
class OrdersProxyController {

    private final RestClient restClient = RestClient.create("http://localhost:9000");

    @GetMapping("/my-orders")
    String myOrders(@RegisteredOAuth2AuthorizedClient("keycloak") OAuth2AuthorizedClient client) {
        String accessToken = client.getAccessToken().getTokenValue();

        return restClient.get()
            .uri("/orders")
            .headers(h -> h.setBearerAuth(accessToken))     // Authorization: Bearer ...
            .retrieve()
            .body(String.class);
    }
}
```

- `@RegisteredOAuth2AuthorizedClient("keycloak")` loads the stored tokens. If the access token is expired and a refresh token exists, Spring refreshes it for you.
- `setBearerAuth` adds the `Authorization: Bearer ...` header.

To make refresh explicit (and reusable):

```java
@Bean
OAuth2AuthorizedClientManager authorizedClientManager(
        ClientRegistrationRepository registrations,
        OAuth2AuthorizedClientRepository clients) {

    OAuth2AuthorizedClientProvider provider = OAuth2AuthorizedClientProviderBuilder.builder()
        .authorizationCode()
        .refreshToken()
        .build();

    var manager = new DefaultOAuth2AuthorizedClientManager(registrations, clients);
    manager.setAuthorizedClientProvider(provider);
    return manager;
}
```

In recent Spring Security versions (6.4 and later) you can attach this manager to a `RestClient` through `OAuth2ClientHttpRequestInterceptor`, so the Bearer header is added automatically.

Token lifetimes in this lab: access token 5 minutes (`expires_in: 300`), refresh token much longer. That is why refresh matters.

---

## Part 6: Logout done right

Logging out of your app only destroys _your_ session. The IdP session lives on, so the next "Login" click signs the user straight back in. There are two levels of fixing this.

### 6.1 RP-initiated logout (your app tells the IdP)

```java
@Bean
SecurityFilterChain webChain(HttpSecurity http, ClientRegistrationRepository repo) throws Exception {

    var logoutHandler = new OidcClientInitiatedLogoutSuccessHandler(repo);
    logoutHandler.setPostLogoutRedirectUri("{baseUrl}/");

    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .oauth2Login(Customizer.withDefaults())
        .logout(l -> l
            .logoutSuccessHandler(logoutHandler)
            .invalidateHttpSession(true)
            .clearAuthentication(true)
            .deleteCookies("JSESSIONID"));
    return http.build();
}
```

What happens when the user submits `POST /logout`:

1. Spring clears your session.
2. `OidcClientInitiatedLogoutSuccessHandler` reads `end_session_endpoint` from the provider metadata.
3. It redirects the browser to `.../logout?id_token_hint=...&post_logout_redirect_uri=http://localhost:8080/`.
4. The IdP ends its session and sends the user back.

Remember to register the post-logout redirect URI in Keycloak, and that logout is a **POST** (CSRF protection):

```html
<form th:action="@{/logout}" method="post"><button>Logout</button></form>
```

### 6.2 Back-channel logout (the IdP tells your app)

When the user logs out from _another_ app in the same SSO group, the IdP can call your app so it ends the session too:

```java
http
    .oauth2Login(Customizer.withDefaults())
    .oidcLogout(logout -> logout.backChannel(Customizer.withDefaults()));
```

In Keycloak, set the client's **Backchannel logout URL** to:

```
http://localhost:8080/logout/connect/back-channel/keycloak
```

Spring exposes that endpoint, validates the signed _logout token_ sent by the IdP, and invalidates the matching session. This is real "single logout".

---

## Part 7: The API side (Resource Server) and mixing both in one app

If you also expose REST endpoints that SPAs or mobile apps call with bearer tokens, you need a **second filter chain**. Cookies and sessions suit browsers; tokens suit APIs.

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    // ---------- Chain 1: the API (stateless, bearer tokens) ----------
    @Bean
    @Order(1)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/api/**")                          // only handles /api/**
            .authorizeHttpRequests(a -> a
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .oauth2ResourceServer(o -> o
                .jwt(j -> j.jwtAuthenticationConverter(jwtAuthConverter())))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .csrf(csrf -> csrf.disable());                       // no cookies, so no CSRF risk
        return http.build();
    }

    // ---------- Chain 2: the website (sessions, login redirect) ----------
    @Bean
    @Order(2)
    SecurityFilterChain webChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(a -> a
                .requestMatchers("/", "/public/**").permitAll()
                .anyRequest().authenticated())
            .oauth2Login(Customizer.withDefaults());
        return http.build();
    }

    // ---------- Turn token claims into Spring roles ----------
    @Bean
    JwtAuthenticationConverter jwtAuthConverter() {
        var converter = new JwtAuthenticationConverter();
        converter.setPrincipalClaimName("preferred_username");
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess == null) return List.of();

            @SuppressWarnings("unchecked")
            List<String> roles = (List<String>) realmAccess.get("roles");
            return roles.stream()
                .map(r -> (GrantedAuthority) new SimpleGrantedAuthority("ROLE_" + r.toUpperCase()))
                .toList();
        });
        return converter;
    }

    // ---------- Stronger validation: issuer + audience ----------
    @Bean
    JwtDecoder jwtDecoder(@Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}") String issuer) {
        NimbusJwtDecoder decoder = (NimbusJwtDecoder) JwtDecoders.fromIssuerLocation(issuer);

        OAuth2TokenValidator<Jwt> withIssuer = JwtValidators.createDefaultWithIssuer(issuer);
        OAuth2TokenValidator<Jwt> withAudience = jwt ->
            jwt.getAudience().contains("my-api")
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(
                      new OAuth2Error("invalid_token", "Token is not for this API", null));

        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(withIssuer, withAudience));
        return decoder;
    }
}
```

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8180/realms/myrealm
```

Why `@Order` and `securityMatcher` matter: Spring picks the **first** chain whose matcher fits the request. `/api/**` goes to chain 1; everything else falls through to chain 2. Without `securityMatcher`, the first chain would swallow every request.

Using the validated token in a controller:

```java
@RestController
@RequestMapping("/api")
class ApiController {

    @GetMapping("/orders")
    List<String> orders(@AuthenticationPrincipal Jwt jwt) {
        String user = jwt.getClaimAsString("preferred_username");
        return List.of("order-1 for " + user);
    }

    @GetMapping("/admin/stats")
    @PreAuthorize("hasRole('ADMIN')")
    Map<String, Object> stats() { return Map.of("users", 42); }
}
```

Call it:

```bash
TOKEN=$(curl -s -X POST http://localhost:8180/realms/myrealm/protocol/openid-connect/token \
  -d grant_type=password -d client_id=my-app -d client_secret=$KEYCLOAK_SECRET \
  -d username=ahmed -d password=1234 | jq -r .access_token)

curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/orders
```

(The `password` grant is only for a local lab. It requires "Direct access grants" to be enabled on the client, and you should not use it in real apps.)

**What the JWT decoder does on each request:** reads the `Authorization` header, verifies the signature using the cached public keys from the IdP, checks `exp`, `iss`, and `aud`, then builds a `JwtAuthenticationToken`. There is no session and no IdP call per request, which is why this scales well.

---

## Part 8: SAML 2.0 version of the same idea

Use this when your customer's IdP (ADFS, Okta, Entra, and so on) speaks SAML.

```xml
<dependency>
  <groupId>org.springframework.security</groupId>
  <artifactId>spring-security-saml2-service-provider</artifactId>
</dependency>
```

Depending on your Spring Security version, OpenSAML may need the Shibboleth Maven repository (`https://build.shibboleth.net/maven/releases/`).

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          okta:
            signing:
              credentials:
                - private-key-location: classpath:saml/private.key
                  certificate-location: classpath:saml/public.crt
            assertingparty:
              metadata-uri: https://dev-123.okta.com/app/abc123/sso/saml/metadata
```

```java
@Bean
SecurityFilterChain samlChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .saml2Login(Customizer.withDefaults())
        .saml2Logout(Customizer.withDefaults());
    return http.build();
}
```

```java
@GetMapping("/me")
Map<String, Object> me(@AuthenticationPrincipal Saml2AuthenticatedPrincipal principal) {
    return Map.of("name", principal.getName(),
                  "attributes", principal.getAttributes());
}
```

|OIDC word|SAML word|
|---|---|
|Client|Relying Party (your app)|
|Identity Provider|Asserting Party|
|ID token (JWT)|Assertion (signed XML)|
|`issuer-uri` discovery|`metadata-uri`|
|`/login/oauth2/code/{id}`|`/login/saml2/sso/{id}`|
|(none)|`/saml2/service-provider-metadata/{id}` (give this XML to the IdP admin)|

To map SAML attributes to roles, you customize the provider's response authentication converter. The exact class name depends on your OpenSAML version (`OpenSaml4AuthenticationProvider` or `OpenSaml5AuthenticationProvider`).

---

## Part 9: Testing SSO code without a real IdP

`spring-security-test` fakes the login for you.

```java
@WebMvcTest(MeController.class)
class MeControllerTest {

    @Autowired MockMvc mvc;

    @Test
    void returnsClaims() throws Exception {
        mvc.perform(get("/me")
                .with(oidcLogin().idToken(t -> t
                    .claim("email", "ahmed@example.com")
                    .claim("preferred_username", "ahmed"))))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.email").value("ahmed@example.com"));
    }

    @Test
    void anonymousIsRedirected() throws Exception {
        mvc.perform(get("/me"))
           .andExpect(status().is3xxRedirection());
    }
}
```

```java
@Test
void apiNeedsAdmin() throws Exception {
    mvc.perform(get("/api/admin/stats")
            .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMIN"))))
       .andExpect(status().isOk());

    mvc.perform(get("/api/admin/stats")
            .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_USER"))))
       .andExpect(status().isForbidden());
}
```

Static imports come from `SecurityMockMvcRequestPostProcessors` (`oidcLogin()`, `jwt()`).

---

## Part 10: Debugging and common errors

Turn on logging first:

```yaml
logging:
  level:
    org.springframework.security: TRACE
    org.springframework.security.oauth2: DEBUG
```

TRACE shows the filter chain, each filter, and why a request was denied.

If your app runs behind Nginx or a load balancer, tell Spring to trust the forwarded headers so `{baseUrl}` becomes `https://yourdomain.com`:

```yaml
server:
  forward-headers-strategy: framework
```

|Error|What it means and how to fix it|
|---|---|
|`[authorization_request_not_found]`|The session was lost between redirect and callback (cookie blocked, different host, server restarted).|
|`invalid_redirect_uri` / `redirect_uri mismatch`|Registered URI at the IdP differs from `redirect-uri` (check `http` vs `https` and `localhost` vs `127.0.0.1`).|
|`[invalid_nonce]`|Same cause as above, or the IdP/proxy mangled the request.|
|`[invalid_id_token] ... iss`|`issuer-uri` doesn't match the token's `iss` exactly (trailing slash, hostname). Common in Docker: the app sees `keycloak:8080`, the browser sees `localhost:8180`.|
|`Another exception ... Connection refused` at startup|Spring fetches discovery on boot. IdP isn't running.|
|403 after login|Authorities not mapped (Part 4.4).|
|Infinite redirect loop|Missing `forward-headers-strategy`, or session cookie not set (SameSite/secure cookie issues on HTTP).|

---

## Related concepts, in short

- **JWKS (JSON Web Key Set):** the IdP's public keys published at a URL. Spring downloads and caches them to verify signatures, and re-fetches when it sees an unknown key id (`kid`).
- **Opaque tokens:** random strings instead of JWTs. A resource server then calls the IdP's introspection endpoint on each request, using `.oauth2ResourceServer(o -> o.opaqueToken(...))`. It is slower but tokens can be revoked instantly.
- **PKCE:** a one-time secret (`code_verifier`, sent as a hashed `code_challenge`) that proves the app finishing the login is the one that started it. It is vital for public clients and harmless for confidential ones.
- **Token exchange between services:** when service A must call service B for the user, use the `client_credentials` grant for machine-to-machine calls, or token exchange to pass the user's identity along.

## What to practice next

1. Run the lab (Part 1) and read the TRACE logs of one full login.
2. Add `app_user` syncing (4.3) and confirm a row appears in PostgreSQL after login.
3. Map Keycloak roles (4.4) and protect `/admin`.
4. Add the API chain (Part 7) and call it with a Bearer token, then test it with `jwt()`.
5. Create a second client in the same realm, log in to both, and then try back-channel logout (6.2).




[[Spring Security]]
