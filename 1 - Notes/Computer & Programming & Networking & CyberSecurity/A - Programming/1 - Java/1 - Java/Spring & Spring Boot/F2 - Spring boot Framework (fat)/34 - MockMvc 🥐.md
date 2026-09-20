# MockMvc - Spring MVC Testing Framework

`MockMvc` is Spring's main testing framework for testing Spring MVC applications without starting a full HTTP server. It allows you to test controllers in isolation with mock requests and responses.

## Basic Setup

### 1. Standalone Setup (Controller Level)

```java
@ExtendWith(SpringExtension.class)
@WebMvcTest(MyController.class)
class MyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private MyService myService;

    @Test
    void testGetUser() throws Exception {
        // Given
        when(myService.getUser(1L)).thenReturn(new User(1L, "John"));

        // When & Then
        mockMvc.perform(get("/users/1"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.name").value("John"))
               .andExpect(jsonPath("$.id").value(1));
    }
}
```

### 2. Manual Setup

```java
class MyControllerManualTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        this.mockMvc = MockMvcBuilders.standaloneSetup(new MyController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void testController() throws Exception {
        mockMvc.perform(get("/api/test"))
               .andExpect(status().isOk());
    }
}
```

### 3. Web Application Context Setup

```java
@SpringBootTest
@AutoConfigureMockMvc
class IntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testWithFullContext() throws Exception {
        mockMvc.perform(get("/api/data"))
               .andExpect(status().isOk());
    }
}
```

## Performing Requests

### HTTP Methods

```java
@Test
void testVariousHttpMethods() throws Exception {
    // GET request
    mockMvc.perform(get("/api/users"))
           .andExpect(status().isOk());

    // POST request with JSON body
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\"John\",\"email\":\"john@test.com\"}"))
           .andExpect(status().isCreated());

    // PUT request
    mockMvc.perform(put("/api/users/1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\"John Updated\"}"))
           .andExpect(status().isOk());

    // DELETE request
    mockMvc.perform(delete("/api/users/1"))
           .andExpect(status().isNoContent());

    // PATCH request
    mockMvc.perform(patch("/api/users/1")
            .content("{\"name\":\"John Patched\"}"))
           .andExpect(status().isOk());
}
```

### Request Parameters and Headers

```java
@Test
void testRequestParameters() throws Exception {
    // Query parameters
    mockMvc.perform(get("/api/users")
            .param("page", "0")
            .param("size", "10")
            .param("sort", "name,asc"))
           .andExpect(status().isOk());

    // Headers
    mockMvc.perform(get("/api/users")
            .header("Authorization", "Bearer token123")
            .header("X-Custom-Header", "custom-value"))
           .andExpect(status().isOk());

    // Content Type
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .accept(MediaType.APPLICATION_JSON))
           .andExpect(status().isCreated());

    // Cookies
    mockMvc.perform(get("/api/profile")
            .cookie(new Cookie("sessionId", "abc123")))
           .andExpect(status().isOk());
}
```

### File Upload

```java
@Test
void testFileUpload() throws Exception {
    MockMultipartFile file = new MockMultipartFile(
        "file", 
        "test.txt", 
        "text/plain", 
        "File content".getBytes()
    );

    mockMvc.perform(multipart("/api/upload")
            .file(file)
            .param("description", "Test file"))
           .andExpect(status().isOk())
           .andExpect(content().string("File uploaded successfully"));
}
```

## Response Assertions

### Status and Headers

```java
@Test
void testResponseAssertions() throws Exception {
    mockMvc.perform(get("/api/users/1"))
           .andExpect(status().isOk())
           .andExpect(header().string("Content-Type", MediaType.APPLICATION_JSON_VALUE))
           .andExpect(header().string("X-Custom-Header", "custom-value"))
           .andExpect(cookie().exists("sessionToken"))
           .andExpect(cookie().value("sessionToken", "abc123"));
}
```

### JSON Response Validation

```java
@Test
void testJsonResponse() throws Exception {
    mockMvc.perform(get("/api/users/1"))
           .andExpect(jsonPath("$.id").value(1))
           .andExpect(jsonPath("$.name").value("John Doe"))
           .andExpect(jsonPath("$.email").exists())
           .andExpect(jsonPath("$.address.city").value("New York"))
           .andExpect(jsonPath("$.roles[0]").value("ADMIN"))
           .andExpect(jsonPath("$.active").isBoolean())
           .andExpect(jsonPath("$.createdAt").isNotEmpty());
}
```

### XML Response Validation

```java
@Test
void testXmlResponse() throws Exception {
    mockMvc.perform(get("/api/users/1")
            .accept(MediaType.APPLICATION_XML))
           .andExpect(xpath("/user/id").string("1"))
           .andExpect(xpath("/user/name").string("John Doe"))
           .andExpect(xpath("/user/email").exists());
}
```

### Content and View Validation

```java
@Test
void testContentAndView() throws Exception {
    // HTML content
    mockMvc.perform(get("/users"))
           .andExpect(content().contentType(MediaType.TEXT_HTML))
           .andExpect(content().string(containsString("User List")))
           .andExpect(content().encoding("UTF-8"));

    // View name
    mockMvc.perform(get("/users"))
           .andExpect(view().name("users"))
           .andExpect(model().attributeExists("users"))
           .andExpect(model().attribute("pageTitle", "User Management"));

    // Redirect
    mockMvc.perform(post("/users"))
           .andExpect(redirectedUrl("/users/success"))
           .andExpect(flash().attributeExists("message"));
}
```

## Advanced Testing Scenarios

### Exception Handling

```java
@Test
void testExceptionHandling() throws Exception {
    when(userService.getUser(999L)).thenThrow(new UserNotFoundException("User not found"));

    mockMvc.perform(get("/api/users/999"))
           .andExpect(status().isNotFound())
           .andExpect(jsonPath("$.error").value("User not found"))
           .andExpect(jsonPath("$.timestamp").exists());
}
```

### Security Context

```java
@Test
@WithMockUser(username = "admin", roles = {"ADMIN"})
void testWithAuthentication() throws Exception {
    mockMvc.perform(get("/api/admin/dashboard"))
           .andExpect(status().isOk());
}

@Test
@WithUserDetails("customUser")
void testWithUserDetails() throws Exception {
    mockMvc.perform(get("/api/profile"))
           .andExpect(status().isOk());
}
```

### Session and Flash Attributes

```java
@Test
void testSessionAndFlash() throws Exception {
    mockMvc.perform(post("/api/login")
            .param("username", "user")
            .param("password", "pass"))
           .andExpect(status().isOk())
           .andExpect(request().sessionAttribute("user", notNullValue()))
           .andExpect(flash().attributeCount(1))
           .andExpect(flash().attribute("message", "Login successful"));
}
```

### Async Requests

```java
@Test
void testAsyncRequest() throws Exception {
    MvcResult result = mockMvc.perform(asyncDispatch(
            mockMvc.perform(get("/api/async"))
                   .andExpect(request().asyncStarted())
                   .andReturn()
        ))
        .andExpect(status().isOk())
        .andExpect(content().string("Async result"))
        .andReturn();
}
```

## Custom MockMvc Configuration

### Custom Configurers

```java
@Test
void testWithCustomConfiguration() throws Exception {
    MockMvc mockMvc = MockMvcBuilders.standaloneSetup(userController)
            .setCustomArgumentResolvers(new PageableHandlerMethodArgumentResolver())
            .setMessageConverters(new MappingJackson2HttpMessageConverter())
            .setControllerAdvice(new GlobalExceptionHandler())
            .addFilter(new SecurityFilter())
            .alwaysDo(print()) // Always print results
            .alwaysExpect(status().isOk())
            .build();

    mockMvc.perform(get("/api/users"))
           .andExpect(jsonPath("$").isArray());
}
```

### REST Docs Integration

```java
@ExtendWith({SpringExtension.class, RestDocumentationExtension.class})
class ApiDocumentationTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setup(WebApplicationContext context, 
               RestDocumentationContextProvider restDocumentation) {
        this.mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(documentationConfiguration(restDocumentation))
                .alwaysDo(document("{method-name}"))
                .build();
    }

    @Test
    void documentUserApi() throws Exception {
        mockMvc.perform(get("/api/users/1"))
               .andExpect(status().isOk())
               .andDo(document("get-user",
                       pathParameters(
                           parameterWithName("id").description("User ID")
                       ),
                       responseFields(
                           fieldWithPath("id").description("User ID"),
                           fieldWithPath("name").description("User name"),
                           fieldWithPath("email").description("User email")
                       )
                   ));
    }
}
```

## Best Practices

### 1. Test Structure

```java
class UserControllerTest {

    @Autowired private MockMvc mockMvc;
    @MockBean private UserService userService;

    @Test
    void getUser_WithValidId_ReturnsUser() throws Exception {
        // Given
        Long userId = 1L;
        User user = new User(userId, "John Doe");
        when(userService.getUser(userId)).thenReturn(user);

        // When & Then
        mockMvc.perform(get("/api/users/{id}", userId))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.id").value(userId))
               .andExpect(jsonPath("$.name").value("John Doe"));
    }

    @Test
    void getUser_WithInvalidId_ReturnsNotFound() throws Exception {
        // Given
        Long invalidId = 999L;
        when(userService.getUser(invalidId))
            .thenThrow(new UserNotFoundException("User not found"));

        // When & Then
        mockMvc.perform(get("/api/users/{id}", invalidId))
               .andExpect(status().isNotFound());
    }
}
```

### 2. Common Configuration

```java
@TestConfiguration
class TestConfig {
    
    @Bean
    public ObjectMapper testObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.findAndRegisterModules();
        mapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        return mapper;
    }
}
```

MockMvc provides a comprehensive testing framework that allows you to test Spring MVC controllers with fine-grained control over requests and responses, making it an essential tool for testing web applications in Spring.


----

# MockMvc Theory and Concepts

## What is MockMvc?

**MockMvc** is a Spring Testing framework that provides a powerful, flexible way to test Spring MVC applications without requiring a running server. It simulates the complete Spring MVC request/response cycle in a controlled testing environment.

## Core Philosophy

### 1. **Isolated Testing**
- Tests controllers in isolation from the network layer
- No HTTP server required
- Faster execution compared to integration tests
- More predictable test environment

### 2. **Simulated Request/Response Cycle**
```
Test Request → DispatcherServlet → Controllers → Response → Test Assertions
    ↑              ↑                  ↑            ↑            ↑
  MockHttp      Mock MVC           Your Actual   MockHttp     Your
   Request      Infrastructure    Controllers    Response   Assertions
```

## Architectural Components

### 1. **DispatcherServlet Simulation**
```java
// MockMvc mimics this flow:
Request → DispatcherServlet → HandlerMapping → Controller → ViewResolver → Response
```

### 2. **Key MockMvc Components**
- **MockHttpServletRequest** - Simulates HTTP requests
- **MockHttpServletResponse** - Captures response data
- **FilterChain** - Applies configured filters
- **HandlerAdapter** - Executes controller methods
- **ViewResolver** - Resolves view names

## Testing Pyramid Context

```
    ↗ End-to-End Tests (Full server, Selenium)
   ↗ Integration Tests (@SpringBootTest)
  ↗ Unit Tests (MockMvc - Controller Level)
 ↗ Unit Tests (Plain Java - Service Level)
↗ Unit Tests (Plain Java - Utility Level)
```

**MockMvc sits between pure unit tests and full integration tests**

## Benefits Over Other Approaches

### vs. Real HTTP Server Tests
```java
// Real server test - slower, more fragile
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class RealServerTest {
    @Autowired TestRestTemplate restTemplate;
    
    @Test void test() {
        ResponseEntity<String> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/api/users", String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}

// MockMvc test - faster, more control
@WebMvcTest
class MockMvcTest {
    @Autowired MockMvc mockMvc;
    
    @Test void test() throws Exception {
        mockMvc.perform(get("/api/users"))
               .andExpect(status().isOk());
    }
}
```

### vs. Plain Unit Tests
```java
// Plain unit test - doesn't test MVC infrastructure
class PlainUnitTest {
    @Test void testControllerMethod() {
        MyController controller = new MyController();
        String result = controller.getUser(1L);
        assertEquals("expected", result);
        // Missing: JSON serialization, HTTP status, headers, etc.
    }
}

// MockMvc test - tests full MVC stack
class MockMvcTest {
    @Test void testController() throws Exception {
        mockMvc.perform(get("/api/users/1"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.name").value("John"));
        // Tests: URL mapping, parameter binding, JSON serialization, status codes
    }
}
```

## Request Processing Theory

### 1. **Request Building Phase**
```java
mockMvc.perform(
    get("/api/users")                    // HTTP method and URL
        .param("page", "0")             // Query parameters
        .header("Authorization", "Bearer token") // Headers
        .contentType(MediaType.APPLICATION_JSON) // Content type
        .content("{\"name\":\"John\"}") // Request body
);
```

### 2. **Spring MVC Integration Phase**
- **Handler Mapping**: Finds the appropriate controller method
- **Argument Resolution**: Converts request data to method parameters
- **Validation**: Applies Bean Validation if configured
- **Interceptor Execution**: Runs pre/post handlers

### 3. **Controller Execution Phase**
- Your actual controller code runs
- Service layers are typically mocked
- Business logic executes

### 4. **Response Processing Phase**
- Return value handling
- Exception translation
- View resolution (if applicable)
- Message conversion (JSON/XML)

### 5. **Assertion Phase**
```java
.andExpect(status().isOk())              // HTTP status
.andExpect(header().exists("Location"))  // Response headers
.andExpect(jsonPath("$.id").value(1))    // Response body content
.andExpect(content().contentType(MediaType.APPLICATION_JSON)); // Content type
```

## Configuration Strategies Theory

### 1. **Standalone Setup**
```java
MockMvcBuilders.standaloneSetup(userController)
    .setControllerAdvice(globalExceptionHandler)
    .addInterceptors(authInterceptor)
    .build();
```
**Use Case**: Testing single controller in isolation

### 2. **Web Application Context Setup**
```java
MockMvcBuilders.webAppContextSetup(webApplicationContext)
    .addFilters(securityFilter)
    .apply(springSecurity())
    .build();
```
**Use Case**: Testing with full application configuration

### 3. **Annotation-based Setup**
```java
@WebMvcTest(UserController.class)
class ControllerTest {
    @Autowired MockMvc mockMvc;
    @MockBean UserService userService;
}
```
**Use Case**: Most common - Spring Boot auto-configuration

## Testing Scope Theory

### What MockMvc Tests:
- **URL mapping** - Correct endpoint routing
- **Parameter binding** - Request params, path variables, request body
- **Validation** - Input validation rules
- **HTTP semantics** - Status codes, headers, content types
- **Serialization** - JSON/XML mapping
- **Exception handling** - Controller advice, error responses
- **Security** - Method security, interceptors

### What MockMvc Doesn't Test:
- **Network issues** - Timeouts, connection problems
- **Server configuration** - SSL, compression, clustering
- **Client behavior** - Browser-specific issues
- **Full integration** - Database, external services (unless configured)

## Best Practices Theory

### 1. **Test Organization**
```
Test Class Structure:
├── Setup (Mock dependencies)
├── Happy Path Tests
├── Edge Case Tests
├── Error Condition Tests
└── Security Tests
```

### 2. **Test Isolation**
- Each test should be independent
- Mock external dependencies
- Clear setup and teardown
- Consistent test data

### 3. **Assertion Strategy**
- Test behavior, not implementation
- Verify contracts, not internals
- Use meaningful assertion messages
- Test both success and failure paths

## When to Use MockMvc

### ✅ **Good Use Cases:**
- Controller unit testing
- API contract testing
- Serialization/deserialization testing
- Security configuration testing
- Error handling testing

### ❌ **Not Ideal For:**
- Full integration testing
- Performance testing
- Browser compatibility testing
- Network reliability testing

MockMvc bridges the gap between pure unit tests and full integration tests, providing the right balance of isolation and realism for testing Spring MVC applications efficiently.


##### Tags : [[0 - Spring Framework]]