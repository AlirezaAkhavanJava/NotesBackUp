
## Table of Contents
1. [Introduction to OAuth2](#introduction-to-oauth2)
2. [OAuth2 Roles and Flow](#oauth2-roles-and-flow)
3. [Setting Up OAuth2 Authorization Server](#setting-up-oauth2-authorization-server)
4. [Configuring Resource Server](#configuring-resource-server)
5. [OAuth2 with JWT](#oauth2-with-jwt)
6. [Social Login (OAuth2 Clients)](#social-login-oauth2-clients)
7. [Advanced Security Configurations](#advanced-security-configurations)
8. [Reactive OAuth2](#reactive-oauth2)
9. [Best Practices and Security Considerations](#best-practices-and-security-considerations)

## Introduction to OAuth2

OAuth2 is an authorization framework that enables applications to obtain limited access to user accounts on HTTP services. It works by delegating user authentication to the service that hosts the user account and authorizing third-party applications to access the user account.

### Why OAuth2?
- **Security**: No need to store user passwords in your application
- **User Experience**: Users don't need to create new accounts
- **Standardization**: Industry-standard protocol
- **Scalability**: Handles authorization across multiple services

## OAuth2 Roles and Flow

### Key Roles
1. **Resource Owner**: The user who owns the protected resources
2. **Client**: The application requesting access to resources
3. **Resource Server**: The server hosting protected resources
4. **Authorization Server**: The server that issues access tokens

### Authorization Code Flow (Most Secure)
1. User clicks "Login" in client application
2. Client redirects to authorization server
3. User authenticates and grants permission
4. Authorization server redirects back with authorization code
5. Client exchanges code for access token
6. Client uses access token to access protected resources

## Setting Up OAuth2 Authorization Server

### Dependencies
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-authorization-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

### Authorization Server Configuration
```java
@Configuration
@EnableAuthorizationServer
public class AuthorizationServerConfig extends AuthorizationServerConfigurerAdapter {
    
    @Autowired
    private AuthenticationManager authenticationManager;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients.inMemory()
            .withClient("clientapp")
            .secret(passwordEncoder.encode("123456"))
            .authorizedGrantTypes("authorization_code", "refresh_token")
            .scopes("read", "write")
            .redirectUris("http://localhost:8080/login/oauth2/code/clientapp")
            .accessTokenValiditySeconds(3600)
            .refreshTokenValiditySeconds(86400);
    }
    
    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
        endpoints.authenticationManager(authenticationManager);
    }
    
    @Override
    public void configure(AuthorizationServerSecurityConfigurer security) {
        security.tokenKeyAccess("permitAll()")
                .checkTokenAccess("isAuthenticated()");
    }
}
```

### Security Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Override
    @Bean
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
            .antMatchers("/oauth/**").permitAll()
            .anyRequest().authenticated()
            .and()
            .formLogin().permitAll();
    }
}
```

## Configuring Resource Server

### Dependencies
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

### Resource Server Configuration
```java
@Configuration
@EnableResourceServer
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {
    
    @Override
    public void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
            .antMatchers("/api/public/**").permitAll()
            .antMatchers("/api/admin/**").hasRole("ADMIN")
            .antMatchers("/api/**").authenticated();
    }
    
    @Override
    public void configure(ResourceServerSecurityConfigurer resources) {
        resources.resourceId("api");
    }
}
```

### Controller with Protected Endpoints
```java
@RestController
@RequestMapping("/api")
public class ApiController {
    
    @GetMapping("/public/hello")
    public String publicHello() {
        return "Hello Public!";
    }
    
    @GetMapping("/user/info")
    public String userInfo(Principal principal) {
        return "Hello " + principal.getName();
    }
    
    @GetMapping("/admin/dashboard")
    @PreAuthorize("hasRole('ADMIN')")
    public String adminDashboard() {
        return "Admin Dashboard";
    }
}
```

## OAuth2 with JWT

### JWT Configuration for Authorization Server
```java
@Configuration
public class JwtConfig {
    
    @Bean
    public JwtAccessTokenConverter accessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey("secret-key"); // Use a proper key in production
        return converter;
    }
    
    @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(accessTokenConverter());
    }
}

// Update AuthorizationServerConfig
@Override
public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
    endpoints.authenticationManager(authenticationManager)
            .tokenStore(tokenStore())
            .accessTokenConverter(accessTokenConverter());
}
```

### Resource Server JWT Configuration
```java
@Configuration
@EnableResourceServer
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {
    
    @Override
    public void configure(ResourceServerSecurityConfigurer resources) {
        resources.tokenServices(tokenServices())
                .resourceId("api");
    }
    
    @Bean
    public JwtAccessTokenConverter accessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey("secret-key"); // Must match auth server
        return converter;
    }
    
    @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(accessTokenConverter());
    }
    
    @Bean
    @Primary
    public DefaultTokenServices tokenServices() {
        DefaultTokenServices defaultTokenServices = new DefaultTokenServices();
        defaultTokenServices.setTokenStore(tokenStore());
        defaultTokenServices.setSupportRefreshToken(true);
        return defaultTokenServices;
    }
}
```

### Customizing JWT Claims
```java
@Component
public class CustomTokenEnhancer implements TokenEnhancer {
    
    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, 
                                    OAuth2Authentication authentication) {
        
        Map<String, Object> additionalInfo = new HashMap<>();
        
        // Add custom claims
        additionalInfo.put("organization", authentication.getName() + "Org");
        
        if (authentication.getUserAuthentication() instanceof UsernamePasswordAuthenticationToken) {
            User user = (User) authentication.getUserAuthentication().getPrincipal();
            additionalInfo.put("userId", user.getUsername());
        }
        
        ((DefaultOAuth2AccessToken) accessToken).setAdditionalInformation(additionalInfo);
        return accessToken;
    }
}

// Register the enhancer
@Override
public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
    endpoints.authenticationManager(authenticationManager)
            .tokenStore(tokenStore())
            .accessTokenConverter(accessTokenConverter())
            .tokenEnhancer(tokenEnhancerChain());
}

@Bean
public TokenEnhancerChain tokenEnhancerChain() {
    TokenEnhancerChain chain = new TokenEnhancerChain();
    chain.setTokenEnhancers(Arrays.asList(new CustomTokenEnhancer(), accessTokenConverter()));
    return chain;
}
```

## Social Login (OAuth2 Clients)

### Dependencies
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
```

### Application Properties
```properties
# Google OAuth2
spring.security.oauth2.client.registration.google.client-id=your-google-client-id
spring.security.oauth2.client.registration.google.client-secret=your-google-client-secret

# GitHub OAuth2
spring.security.oauth2.client.registration.github.client-id=your-github-client-id
spring.security.oauth2.client.registration.github.client-secret=your-github-client-secret

# Facebook OAuth2
spring.security.oauth2.client.registration.facebook.client-id=your-facebook-client-id
spring.security.oauth2.client.registration.facebook.client-secret=your-facebook-client-secret
spring.security.oauth2.client.registration.facebook.scope=email,public_profile
```

### OAuth2 Login Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
            .antMatchers("/", "/login**", "/webjars/**").permitAll()
            .anyRequest().authenticated()
            .and()
            .oauth2Login()
                .loginPage("/login")
                .defaultSuccessUrl("/dashboard")
                .failureUrl("/login?error=true")
                .userInfoEndpoint()
                    .userService(customOAuth2UserService);
    }
    
    @Bean
    public CustomOAuth2UserService customOAuth2UserService() {
        return new CustomOAuth2UserService();
    }
}
```

### Custom OAuth2 User Service
```java
@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest);
        
        // Extract user information
        String provider = userRequest.getClientRegistration().getRegistrationId();
        String providerId = oAuth2User.getAttribute("sub") != null ? 
                           oAuth2User.getAttribute("sub") : oAuth2User.getName();
        
        // Find or create user in your database
        User user = userRepository.findByProviderAndProviderId(provider, providerId)
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setProvider(provider);
                    newUser.setProviderId(providerId);
                    newUser.setEmail(oAuth2User.getAttribute("email"));
                    newUser.setName(oAuth2User.getAttribute("name"));
                    return userRepository.save(newUser);
                });
        
        // Create authorities
        Collection<GrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
        
        // Return custom principal
        return new CustomOAuth2User(oAuth2User, authorities, user.getId());
    }
}

public class CustomOAuth2User extends DefaultOAuth2User {
    private Long userId;
    
    public CustomOAuth2User(OAuth2User oAuth2User, Collection<? extends GrantedAuthority> authorities, Long userId) {
        super(authorities, oAuth2User.getAttributes(), "name");
        this.userId = userId;
    }
    
    public Long getUserId() {
        return userId;
    }
}
```

## Advanced Security Configurations

### Method Level Security
```java
@Configuration
@EnableGlobalMethodSecurity(
    prePostEnabled = true,
    securedEnabled = true,
    jsr250Enabled = true)
public class MethodSecurityConfig extends GlobalMethodSecurityConfiguration {
    
    @Override
    protected MethodSecurityExpressionHandler createExpressionHandler() {
        DefaultMethodSecurityExpressionHandler expressionHandler = 
            new DefaultMethodSecurityExpressionHandler();
        expressionHandler.setPermissionEvaluator(new CustomPermissionEvaluator());
        return expressionHandler;
    }
}

// Usage in controllers/services
@PreAuthorize("hasPermission(#id, 'Todo', 'read')")
@PostAuthorize("returnObject.owner == authentication.name")
@PreFilter("filterObject.owner == authentication.name")
@PostFilter("filterObject.completed == false")
@Secured("ROLE_ADMIN")
@RolesAllowed("ROLE_USER")
```

### Custom Permission Evaluator
```java
@Component
public class CustomPermissionEvaluator implements PermissionEvaluator {
    
    @Autowired
    private TodoService todoService;
    
    @Override
    public boolean hasPermission(Authentication authentication, 
                               Object targetDomainObject, 
                               Object permission) {
        if (targetDomainObject instanceof Todo) {
            Todo todo = (Todo) targetDomainObject;
            String requiredPermission = (String) permission;
            
            switch (requiredPermission) {
                case "read":
                case "write":
                    return todo.getOwner().equals(authentication.getName());
                case "admin":
                    return authentication.getAuthorities().stream()
                            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
            }
        }
        return false;
    }
    
    @Override
    public boolean hasPermission(Authentication authentication, 
                               Serializable targetId, 
                               String targetType, 
                               Object permission) {
        if ("Todo".equals(targetType)) {
            Todo todo = todoService.findById((Long) targetId);
            return hasPermission(authentication, todo, permission);
        }
        return false;
    }
}
```

### CORS and CSRF Configuration
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:3000")
                .allowedMethods("GET", "POST", "PUT", "DELETE")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}

// CSRF configuration for OAuth2
@Override
protected void configure(HttpSecurity http) throws Exception {
    http.csrf(csrf -> csrf
        .ignoringAntMatchers("/oauth/**", "/login/**", "/logout/**")
        .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
    );
}
```

## Reactive OAuth2

### Reactive Resource Server
```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .authorizeExchange()
                .pathMatchers("/api/public/**").permitAll()
                .pathMatchers("/api/admin/**").hasAuthority("ROLE_ADMIN")
                .anyExchange().authenticated()
            .and()
            .oauth2ResourceServer()
                .jwt()
            .and().and()
            .build();
    }
    
    @Bean
    public ReactiveJwtDecoder jwtDecoder() {
        return ReactiveJwtDecoders.fromIssuerLocation("http://auth-server:9000");
    }
}
```

### Reactive OAuth2 Client
```java
@Configuration
@EnableReactiveMethodSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .authorizeExchange()
                .pathMatchers("/", "/login").permitAll()
                .anyExchange().authenticated()
            .and()
            .oauth2Login()
            .and()
            .build();
    }
}
```

### Reactive Controller with Security
```java
@RestController
public class UserController {
    
    @GetMapping("/user")
    public Mono<Map<String, Object>> user(@AuthenticationPrincipal Mono<OAuth2User> oauth2User) {
        return oauth2User
            .map(user -> {
                Map<String, Object> userAttributes = new HashMap<>();
                userAttributes.put("name", user.getAttribute("name"));
                userAttributes.put("email", user.getAttribute("email"));
                return userAttributes;
            });
    }
    
    @GetMapping("/api/todos")
    @PreAuthorize("hasRole('USER')")
    public Flux<Todo> getUserTodos(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getSubject();
        return todoService.findByUserId(userId);
    }
}
```

## Best Practices and Security Considerations

### Security Best Practices
1. **Use HTTPS in production**
2. **Store secrets securely** (not in code)
3. **Implement proper token expiration**
4. **Use PKCE for public clients**
5. **Validate redirect URIs**
6. **Implement proper logout**

### Secure Configuration Example
```java
@Configuration
public class SecureOAuth2Config {
    
    @Value("${security.oauth2.client.secret}")
    private String clientSecret;
    
    @Bean
    public ClientDetailsService clientDetailsService() {
        return new JdbcClientDetailsService(dataSource);
    }
    
    @Bean
    public TokenStore tokenStore() {
        return new JdbcTokenStore(dataSource);
    }
    
    @Bean
    public ApprovalStore approvalStore() {
        return new JdbcApprovalStore(dataSource);
    }
    
    @Bean
    public AuthorizationCodeServices authorizationCodeServices() {
        return new JdbcAuthorizationCodeServices(dataSource);
    }
}

// application-prod.properties
security.oauth2.client.secret=${CLIENT_SECRET:fallback-secret}
security.oauth2.jwt.key-value=${JWT_SIGNING_KEY:complex-signing-key}
```

### Token Management
```java
@Service
public class TokenRevocationService {
    
    @Autowired
    private TokenStore tokenStore;
    
    public void revokeTokens(String username) {
        Collection<OAuth2AccessToken> accessTokens = tokenStore.findTokensByClientIdAndUserName("clientapp", username);
        for (OAuth2AccessToken accessToken : accessTokens) {
            tokenStore.removeAccessToken(accessToken);
            OAuth2RefreshToken refreshToken = accessToken.getRefreshToken();
            if (refreshToken != null) {
                tokenStore.removeRefreshToken(refreshToken);
            }
        }
    }
    
    public void revokeToken(String tokenValue) {
        OAuth2AccessToken accessToken = tokenStore.readAccessToken(tokenValue);
        if (accessToken != null) {
            tokenStore.removeAccessToken(accessToken);
        }
    }
}
```

### Monitoring and Auditing
```java
@Component
public class OAuth2AuthenticationEventListener {
    
    private static final Logger logger = LoggerFactory.getLogger(OAuth2AuthenticationEventListener.class);
    
    @EventListener
    public void onAuthenticationSuccess(AuthenticationSuccessEvent event) {
        Authentication authentication = event.getAuthentication();
        logger.info("User {} authenticated successfully", authentication.getName());
        
        if (authentication instanceof OAuth2Authentication) {
            OAuth2Authentication oauth2Auth = (OAuth2Authentication) authentication;
            // Log OAuth2 specific details
        }
    }
    
    @EventListener
    public void onAuthenticationFailure(AbstractAuthenticationFailureEvent event) {
        Authentication authentication = event.getAuthentication();
        logger.warn("User {} failed to authenticate: {}", 
                   authentication.getName(), event.getException().getMessage());
    }
}
```

This comprehensive guide covers advanced Spring Security with OAuth2, from basic setup to reactive implementations and security best practices. Remember to always follow security best practices and keep your dependencies updated.

[[0 - Spring Framework]]