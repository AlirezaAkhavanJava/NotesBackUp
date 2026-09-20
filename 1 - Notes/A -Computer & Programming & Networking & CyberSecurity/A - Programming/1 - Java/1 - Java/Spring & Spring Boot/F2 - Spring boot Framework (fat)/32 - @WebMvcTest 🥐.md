
# **@WebMvcTest – Quick Reference & Workflow Guide**  
*(Master Spring MVC Testing – Never Get Stuck Again!)*

---

## What is `@WebMvcTest`?

> **A Spring Boot test slice annotation** for **testing Spring MVC controllers** in isolation.

It:
- Loads **only the web layer** (`@Controller`, `@RestController`, `WebMvcConfigurer`, etc.)
- **Mocks** the service layer (`@Service`) by default
- **Does NOT start** a real server (no `RandomPort`, no HTTP client needed)
- Auto-configures:
  - `MockMvc`
  - `JacksonTester` / `JsonPath`
  - `ObjectMapper`
- **Excludes** JPA, DataSource, Security, etc. (unless explicitly included)

---

## Core Workflow of `@WebMvcTest`

```text
1. Spring Test Context Starts
   ↓
2. @WebMvcTest(YourController.class) → loads only MVC beans
   ↓
3. @Autowired MockMvc → ready to send fake HTTP requests
   ↓
4. @MockBean YourService → injects mock into controller
   ↓
5. Perform request → controller → mock service
   ↓
6. Assert response: status, JSON, headers, etc.
```

---

## Requirements

| Requirement | Why |
|-----------|-----|
| `spring-boot-starter-test` | Includes `MockMvc`, `Mockito`, `AssertJ` |
| Controller class | Must be specified or discovered via package scan |
| `@MockBean` for services | To mock business logic |

---

## Maven: Already Included (No Extra Deps!)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

> **No H2 needed!** (Unlike `@DataJpaTest`)

---

## Typical `@WebMvcTest` Example

```java
@WebMvcTest(GamersController.class)
class GamersControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GamersService gamersService;

    @Test
    void shouldReturnGamerWhenFound() throws Exception {
        // Given
        Gamers gamer = Gamers.builder()
                .gamerId(1L)
                .gamerName("Joan")
                .build();

        when(gamersService.findById(1L)).thenReturn(Optional.of(gamer));

        // When & Then
        mockMvc.perform(get("/api/gamers/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.gamerName").value("Joan"))
                .andExpect(jsonPath("$.gamerId").value(1));
    }

    @Test
    void shouldReturn404WhenNotFound() throws Exception {
        when(gamersService.findById(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/gamers/99"))
                .andExpect(status().isNotFound());
    }
}
```

---

## Key Annotations

| Annotation | Purpose |
|----------|--------|
| `@WebMvcTest(Controller.class)` | Load **only** this controller |
| `@WebMvcTest` (no args) | Load **all** `@Controller` beans in context |
| `@MockBean` | Mock any Spring bean (service, repo, etc.) |
| `@Autowired MockMvc` | Send HTTP requests without server |
| `@Autowired ObjectMapper` | For manual JSON serialization |

---

## Common Pitfalls & Fixes

| Problem | Cause | Fix |
|-------|------|-----|
| `No qualifying bean of type 'GamersService'` | Service not mocked | Add `@MockBean GamersService service;` |
| `404` even though endpoint exists | Wrong URL or HTTP method | Double-check `get("/path")`, `post()`, etc. |
| JSON assertions fail | Wrong `jsonPath` | Use `$` for root, `$.field`, `$[0].field` |
| Security blocks request | `@PreAuthorize` on controller | Add `@WithMockUser` or disable security |
| Full context loads | Used `@SpringBootTest` instead | Use `@WebMvcTest` for controllers |

---

## Want to Test **Security**?

```java
@WebMvcTest(GamersController.class)
@Import(SecurityConfig.class)  // if needed
class GamersControllerSecurityTest {

    @Autowired MockMvc mockMvc;

    @MockBean GamersService service;

    @Test
    @WithMockUser(username = "admin")
    void shouldAllowAdmin() throws Exception {
        mockMvc.perform(get("/api/admin"))
                .andExpect(status().isOk());
    }

    @Test
    void shouldBlockUnauthenticated() throws Exception {
        mockMvc.perform(get("/api/admin"))
                .andExpect(status().isUnauthorized());
    }
}
```

---

## Want to Test **Filters or Interceptors**?

```java
@WebMvcTest
@AutoConfigureMockMvc(addFilters = false)  // disable default filters
class CustomFilterTest {

    @Autowired MockMvc mockMvc;

    @Test
    void shouldApplyCustomFilter() throws Exception {
        mockMvc = MockMvcBuilders
                .standaloneSetup(new GamersController())
                .addFilter(new MyCustomFilter())
                .build();

        mockMvc.perform(get("/api/gamers"))
                .andExpect(header().string("X-Custom", "applied"));
    }
}
```

---

## Pro Tips

| Tip | Why |
|-----|-----|
| Use `@WebMvcTest(Controller.class)` | Faster, clearer intent |
| Always `@MockBean` services | Prevent real DB calls |
| Use `andDo(print())` when stuck | See full request/response |
| Combine with `@JsonTest` for DTOs | Full test layering |
| Use `standaloneSetup()` for non-Spring controllers | Rare, but useful |

---

## `@WebMvcTest` vs Others

| Annotation | Loads | Use Case |
|----------|------|---------|
| `@WebMvcTest` | MVC layer only | **Controller tests** |
| `@DataJpaTest` | JPA + embedded DB | **Repository tests** |
| `@JsonTest` | Jackson/Gson | **DTO serialization** |
| `@SpringBootTest` | Full app | **Integration tests** |
| `@SpringBootTest(webEnvironment = MOCK)` | Full + MockMvc | When you need DB + MVC |

---

## One-Liner to Remember

> **@WebMvcTest = MockMvc + Controller + @MockBean Services**  
> → **No server, no DB, no surprises**

---

## Final Checklist Before Running `@WebMvcTest`

- [ ] `spring-boot-starter-test` in `pom.xml`
- [ ] `@WebMvcTest(YourController.class)`
- [ ] `@MockBean` for every service/repo used
- [ ] Use `mockMvc.perform(get/post(...))`
- [ ] Assert with `.andExpect(status().isXxx())`, `jsonPath()`, etc.
- [ ] Add `@WithMockUser` if security is involved

---

**Save this note. Paste it in your project’s `docs/` folder.**

---

> **You got this, Ethan!**  
> *— Future You, November 10, 2025, 05:02 PM +04*  
> *Baku, Azerbaijan*

##### Tags : [[0 - Spring Framework]]