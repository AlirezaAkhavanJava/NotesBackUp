Date : 2025-09-04


REST Assured is a Java library for testing RESTful APIs, providing a fluent, easy-to-use API for sending HTTP requests and validating responses. It simplifies testing REST APIs by offering a domain-specific language (DSL) that integrates well with testing frameworks like JUnit 5 and TestNG. This tutorial covers REST Assured from beginner to advanced levels, with practical examples and features up to Java 25 (September 2025). It includes recent updates from REST Assured 5.6.0 (Dec 2024).

---

## Phase 1: Getting Started with REST Assured

### What is REST Assured?

REST Assured is a Java library that simplifies testing REST APIs by providing a fluent API to send HTTP requests (GET, POST, PUT, DELETE, etc.) and validate responses (status codes, headers, body, etc.). It supports JSON, XML, and other formats, making it ideal for API testing.

### Key Features

- **Fluent API**: Chain methods for readable tests (e.g., `given().when().then()`).
- **Response Validation**: Validate status codes, headers, and body content.
- **JSON/XML Parsing**: Built-in support for JSONPath and XmlPath.
- **Integration**: Works with JUnit, TestNG, and Spring.
- **Mocking**: Supports mocking APIs with libraries like WireMock.

### Setting Up REST Assured

Add REST Assured and JUnit 5 dependencies to your project.

**Maven (pom.xml)**:

```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.6.0</version> <!-- Latest as of Dec 2024 -->
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.11.0</version>
    <scope>test</scope>
</dependency>
```

**Gradle (build.gradle)**:

```groovy
dependencies {
    testImplementation 'io.rest-assured:rest-assured:5.6.0'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
}
```

### Basic GET Request Test

Test a public API (e.g., JSONPlaceholder: `https://jsonplaceholder.typicode.com`).

**Example: Basic GET Test**

```java
import io.restassured.RestAssured;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class BasicApiTest {
    @Test
    void testGetRequest() {
        given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts/1")
        .then()
            .statusCode(200)
            .body("userId", equalTo(1))
            .body("id", equalTo(1))
            .body("title", notNullValue());
    }
}
```

**Run Tests**:

- **IDE**: Run via IntelliJ IDEA or Eclipse.
- **Gradle**: `gradlew test`
- **Maven**: `mvn test`

**Output** (if test passes):

```
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

**Key Points**:

- Use `given().when().then()` for request setup, execution, and validation.
- `baseUri` sets the API base URL.
- Hamcrest matchers (e.g., `equalTo`, `notNullValue`) validate response data.
- JSONPlaceholder is a free API for testing.

---

## Phase 2: Core REST Assured Concepts

### HTTP Methods

REST Assured supports common HTTP methods: GET, POST, PUT, DELETE, PATCH.

**Example: POST Request**

```java
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class PostTest {
    @Test
    void testPostRequest() {
        String requestBody = """
            {
                "title": "New Post",
                "body": "This is a test post",
                "userId": 1
            }
            """;

        given()
            .baseUri("https://jsonplaceholder.typicode.com")
            .contentType(ContentType.JSON)
            .body(requestBody)
        .when()
            .post("/posts")
        .then()
            .statusCode(201)
            .body("title", equalTo("New Post"))
            .body("id", notNullValue());
    }
}
```

**Key Points**:

- Set `contentType` for request body format (e.g., JSON).
- Use multiline strings (Java 15+) for JSON payloads.
- Status code `201` indicates resource creation.

### Response Extraction

Extract response data for further validation or reuse.

**Example: Extract Response**

```java
import io.restassured.response.Response;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class ExtractTest {
    @Test
    void testExtractResponse() {
        Response response = given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts/1")
        .then()
            .statusCode(200)
            .extract().response();

        String title = response.jsonPath().getString("title");
        int userId = response.jsonPath().getInt("userId");
        System.out.println("Title: " + title + ", UserId: " + userId);
    }
}
```

**Output**:

```
Title: sunt aut facere repellat provident occaecati excepturi optio reprehenderit, UserId: 1
```

**Key Points**:

- Use `extract().response()` to get the full response.
- `jsonPath()` extracts fields from JSON responses.

---

## Phase 3: Advanced REST Assured Features

### JSONPath and XmlPath

REST Assured supports JSONPath and XmlPath for querying complex response structures.

**Example: JSONPath Query**

```java
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class JsonPathTest {
    @Test
    void testJsonPath() {
        given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts")
        .then()
            .statusCode(200)
            .body("[0].userId", equalTo(1)) // First post's userId
            .body("size()", equalTo(100)); // Number of posts
    }
}
```

**Key Points**:

- Use `[index]` for arrays, `.field` for objects in JSONPath.
- `size()` returns the length of an array.

### Request and Response Specifications

Reuse common request/response settings with specifications.

**Example: Request/Response Specification**

```java
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;

public class SpecificationTest {
    private static final RequestSpecification requestSpec = new RequestSpecBuilder()
        .setBaseUri("https://jsonplaceholder.typicode.com")
        .setContentType(ContentType.JSON)
        .build();

    private static final ResponseSpecification responseSpec = new ResponseSpecBuilder()
        .expectStatusCode(200)
        .expectBody("userId", notNullValue())
        .build();

    @Test
    void testWithSpecs() {
        given()
            .spec(requestSpec)
        .when()
            .get("/posts/1")
        .then()
            .spec(responseSpec);
    }
}
```

**Key Points**:

- `RequestSpecBuilder` defines reusable request settings.
- `ResponseSpecBuilder` defines reusable response validations.

### Parameterized Tests

Use JUnit 5’s parameterized tests with REST Assured.

**Example: Parameterized Test**

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static io.restassured.RestAssured.*;

public class ParameterizedApiTest {
    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3})
    void testMultiplePosts(int postId) {
        given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts/" + postId)
        .then()
            .statusCode(200)
            .body("id", equalTo(postId));
    }
}
```

---

## Phase 4: Recent Updates (REST Assured 5.6.0, Dec 2024)

- **Improved JSONPath**: Enhanced support for complex queries and nested arrays.
- **GraalVM Compatibility**: Optimized for native image builds.
- **Performance**: Reduced memory usage for large responses.
- **Spring 6 Support**: Seamless integration with Spring Boot 3.3.x.
- **New Matchers**: Added Hamcrest matchers for JSON schema validation.

**Example: JSON Schema Validation**

```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>json-schema-validator</artifactId>
    <version>5.6.0</version>
    <scope>test</scope>
</dependency>
```

```java
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.*;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;

public class SchemaTest {
    @Test
    void testJsonSchema() {
        given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts/1")
        .then()
            .statusCode(200)
            .body(matchesJsonSchemaInClasspath("post-schema.json"));
    }
}
```

**post-schema.json** (in `src/test/resources`):

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "userId": {"type": "integer"},
    "id": {"type": "integer"},
    "title": {"type": "string"},
    "body": {"type": "string"}
  },
  "required": ["userId", "id", "title", "body"]
}
```

---

## Phase 5: Concurrent Testing with Virtual Threads

Use Java 21+ virtual threads for concurrent API testing.

**Example: Concurrent API Tests**

```java
import org.junit.jupiter.api.Test;
import java.util.concurrent.Executors;
import static io.restassured.RestAssured.*;

public class ConcurrentApiTest {
    @Test
    void testConcurrentRequests() {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 1; i <= 3; i++) {
                int postId = i;
                executor.submit(() -> {
                    given()
                        .baseUri("https://jsonplaceholder.typicode.com")
                    .when()
                        .get("/posts/" + postId)
                    .then()
                        .statusCode(200)
                        .body("id", equalTo(postId));
                    System.out.println("Tested post " + postId + " on " + Thread.currentThread().getName());
                });
            }
        }
    }
}
```

**Output**:

```
Tested post 1 on VirtualThread[#1]
Tested post 2 on VirtualThread[#2]
Tested post 3 on VirtualThread[#3]
```

**Key Points**:

- Virtual threads scale I/O-bound API tests efficiently.
- Use `@Execution(ExecutionMode.CONCURRENT)` with JUnit for parallel test execution.

---

## Phase 6: Integration with Other Tools

### Spring Boot Testing

Test Spring Boot REST APIs with REST Assured.

**Example: Spring Boot Test**

```java
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import static io.restassured.RestAssured.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class SpringBootApiTest {
    @LocalServerPort
    private int port;

    @Test
    void testSpringApi() {
        given()
            .baseUri("http://localhost:" + port)
        .when()
            .get("/api/hello")
        .then()
            .statusCode(200)
            .body(equalTo("Hello, World!"));
    }
}
```

**Dependency**:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>3.3.4</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

### WireMock for Mocking

Mock APIs for isolated testing.

**Dependency**:

```xml
<dependency>
    <groupId>com.github.tomakehurst</groupId>
    <artifactId>wiremock-jre8</artifactId>
    <version>3.0.1</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: WireMock Test**

```java
import com.github.tomakehurst.wiremock.WireMockServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static io.restassured.RestAssured.*;

public class WireMockTest {
    private static WireMockServer wireMockServer;

    @BeforeAll
    static void setup() {
        wireMockServer = new WireMockServer(8080);
        wireMockServer.start();
        stubFor(get(urlEqualTo("/mock"))
            .willReturn(aResponse()
                .withStatus(200)
                .withBody("Mocked response")));
    }

    @AfterAll
    static void teardown() {
        wireMockServer.stop();
    }

    @Test
    void testMockedApi() {
        given()
            .baseUri("http://localhost:8080")
        .when()
            .get("/mock")
        .then()
            .statusCode(200)
            .body(equalTo("Mocked response"));
    }
}
```

---

## Java Features Up to Java 25 for REST Assured

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify response validations.
        
        ```java
        given().when().get("/posts/1").then().body(r -> r.jsonPath().getInt("id") == 1);
        ```
        
    - **Streams**: Process API responses.
        
        ```java
        List<Integer> ids = given().when().get("/posts").then().extract().jsonPath().getList("id");
        ids.stream().forEach(System.out::println);
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Use `module-info.java` for modular tests.
        
        ```java
        module myapp.tests {
            requires io.restassured;
            requires org.junit.jupiter.api;
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner test code.
        
        ```java
        var response = given().when().get("/posts/1").then().extract().response();
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for request/response DTOs.
        
        ```java
        record Post(int id, int userId, String title, String body) {}
        Post post = given().when().get("/posts/1").then().extract().as(Post.class);
        ```
        
- **Java 15 (2020)**:
    
    - **Text Blocks**: Simplify JSON payloads.
        
        ```java
        String body = """
            {
                "title": "Test",
                "body": "Content"
            }
            """;
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (response.body().as(Object.class) instanceof Map map) {
            assertThat(map).containsKey("id");
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent API testing (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel API tests.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        @Test
        void testConcurrent() throws Exception {
            try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
                var future = scope.fork(() -> given().when().get("/posts/1").then().extract().response());
                scope.join().throwIfFailed();
                assertEquals(200, future.get().statusCode());
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify test utilities.
        
        ```java
        implicit class ApiUtils {
            static void assertStatusCode(String path, int expectedCode) {
                given().when().get(path).then().statusCode(expectedCode);
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate test configurations.
        
        ```java
        class ApiTester {
            ApiTester(String baseUri) {
                RestAssured.baseURI = baseUri;
                if (baseUri.isEmpty()) throw new IllegalArgumentException("Base URI cannot be empty");
            }
        }
        ```
        

---

## Best Practices

1. **Use Specifications**: Reuse request/response settings for consistency.
2. **Validate Responses**: Use Hamcrest matchers or JSON schema for robust checks.
3. **Mock External APIs**: Use WireMock for isolated testing.
4. **Leverage Parameterized Tests**: Test multiple scenarios efficiently.
5. **Use Text Blocks**: Simplify JSON/XML payloads.
6. **Integrate with CI/CD**: Run tests in Jenkins or GitHub Actions.

**Related Library: TestNG**  
Alternative to JUnit for REST Assured tests:

```xml
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.10.2</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: TestNG with REST Assured**

```java
import org.testng.annotations.Test;
import static io.restassured.RestAssured.*;

public class TestNGTest {
    @Test
    void testGet() {
        given()
            .baseUri("https://jsonplaceholder.typicode.com")
        .when()
            .get("/posts/1")
        .then()
            .statusCode(200);
    }
}
```

---

## Real-World Applications

- **API Testing**: Validate REST endpoints in microservices.
- **Integration Testing**: Test API integrations with Spring Boot.
- **Regression Testing**: Ensure API changes don’t break functionality.
- **Performance Testing**: Combine with tools like JMeter for load testing.

---

## Conclusion

REST Assured is a powerful, fluent library for testing REST APIs in Java, offering seamless integration with JUnit, Spring Boot, and mocking tools like WireMock. Start with basic GET/POST tests, use specifications and JSONPath for advanced scenarios, and leverage virtual threads for concurrent testing. Recent updates (REST Assured 5.6.0) improve JSONPath and GraalVM support. Java 25 features like virtual threads and implicit classes enhance testing scalability and simplicity.

**Resources**:

- [REST Assured Documentation](https://rest-assured.io/)
- [REST Assured GitHub](https://github.com/rest-assured/rest-assured)
- [Spring Boot REST Testing Guide](https://spring.io/guides/gs/testing-web/)


##### *Tags : [[Java]]