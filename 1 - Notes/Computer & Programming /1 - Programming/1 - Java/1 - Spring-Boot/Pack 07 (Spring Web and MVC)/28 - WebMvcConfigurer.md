
`WebMvcConfigurer` is the interface Spring MVC gives you for customizing the web layer without replacing it. Spring Boot already configures MVC for you: message converters, static resources, content negotiation, formatters, and so on. When you need to change one piece, such as adding an interceptor, a custom type converter, or a static resource location, you implement `WebMvcConfigurer`, override only the methods you care about, and register the class as a bean. Everything else keeps its Boot defaults.

The mechanism behind it is a callback list. Spring builds the MVC infrastructure (`HandlerMapping`, `HandlerAdapter`, and the rest of what you saw in the request handler lesson) in a class called `DelegatingWebMvcConfiguration`. That class collects **every** `WebMvcConfigurer` bean in the context and calls each one while the infrastructure is being assembled. That is why you can have several configurers, and why none of them needs to know about the others.

## What implements it

There are fewer implementations than people expect:

|Implementation|Who writes it|What it does|
|---|---|---|
|`WebMvcAutoConfiguration.WebMvcAutoConfigurationAdapter`|Spring Boot|Applies Boot's defaults: `spring.mvc.*` and `spring.web.resources.*` properties, default static locations, message converters.|
|`WebMvcConfigurerComposite`|Spring (internal)|Holds the list of all configurer beans and forwards each call to every one. You never touch it.|
|**Your classes**|You|Each one adds or changes one concern.|

Since Java 8, every method on the interface is a `default` method with an empty body. That is why you override only what you need. The old `WebMvcConfigurerAdapter` base class existed for the pre-Java-8 era, was deprecated, and is **removed** in Spring 6+. If an old tutorial extends it, translate it to `implements WebMvcConfigurer`.

There is a trap right next to this interface. `WebMvcConfigurationSupport` is the class that actually builds the MVC setup. Boot's auto-configuration is declared with `@ConditionalOnMissingBean(WebMvcConfigurationSupport.class)`. So if you add `@EnableWebMvc` (which imports it) or extend it yourself, **Boot's MVC defaults switch off entirely**. In a Boot application, never add `@EnableWebMvc`. Implement `WebMvcConfigurer` instead, which _adds to_ the defaults.

## The methods and what each one controls

|Method|Controls|
|---|---|
|`addInterceptors`|`HandlerInterceptor`s around controller calls|
|`addResourceHandlers`|Serving static files from extra locations|
|`addViewControllers`|URL → view/forward/redirect with no controller code|
|`addFormatters`|`Converter`s and `Formatter`s for `@RequestParam`, `@PathVariable`, form fields|
|`addArgumentResolvers`|Custom controller method parameters|
|`addReturnValueHandlers`|Custom controller return types|
|`extendMessageConverters`|Add or modify JSON/XML converters while keeping defaults|
|`configureMessageConverters`|**Replace** the default converter list (rarely wanted)|
|`configureContentNegotiation`|How `Accept` header / extension picks JSON vs XML|
|`configurePathMatch`|Path matching rules, per-package URL prefixes|
|`configureAsyncSupport`|Executor and timeout for async controller returns|
|`configureViewResolvers`|View resolution (Thymeleaf, JSP)|
|`extendHandlerExceptionResolvers`|Add exception resolvers (you used `@RestControllerAdvice` for this instead)|
|`addCorsMappings`|CORS (see below)|
|`getValidator`|Supply your own `Validator`|

Newer Spring Framework versions also add API-versioning configuration to this interface, so check your version's Javadoc for the full list. Two of these deserve a warning right away.

- **CORS.** `addCorsMappings` works for plain MVC, but you already built the `CorsConfigurationSource` bean inside Spring Security. Keep CORS in that one place. Defining it again here creates two sources of truth.
- **Message converters.** `configureMessageConverters` _replaces_ the default list, so you lose Jackson's Boot configuration and every other default. Use `extendMessageConverters` if you really need to touch converters. For JSON formatting, which is the usual reason, use `spring.jackson.*` properties instead and don't touch converters at all.

## How to create one: the standard shape

The production pattern is **one small `@Configuration` class per concern**, each implementing `WebMvcConfigurer`, with values coming from properties. This is the same idea as your earlier configuration class lesson, applied to the web layer.

```java
@Configuration
public class RequestTracingWebConfig implements WebMvcConfigurer {

    private final RequestIdInterceptor requestIdInterceptor;

    public RequestTracingWebConfig(RequestIdInterceptor requestIdInterceptor) {
        this.requestIdInterceptor = requestIdInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(requestIdInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/health")
                .order(Ordered.HIGHEST_PRECEDENCE);
    }
}
```

The other valid form is a `@Bean` method that returns an anonymous implementation. It suits a configurer that lives next to other beans in a bigger `@Configuration` class:

```java
@Bean
WebMvcConfigurer formattingConfigurer() {
    return new WebMvcConfigurer() {
        @Override
        public void addFormatters(FormatterRegistry registry) {
            registry.addConverter(new StringToStatusConverter());
        }
    };
}
```

Use the dedicated-class form by default. It is easier to find, test, and order.

## The configurers you will actually write

### 1. Interceptors

A `HandlerInterceptor` runs around the controller method. It knows _which handler_ is about to run, which a servlet filter does not.

```java
@Component
public class RequestIdInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse res, Object handler) {
        String id = Optional.ofNullable(req.getHeader("X-Request-Id"))
                            .orElse(UUID.randomUUID().toString());
        MDC.put("requestId", id);
        res.setHeader("X-Request-Id", id);
        return true;                       // false = stop here, controller is not called
    }

    @Override
    public void afterCompletion(HttpServletRequest req, HttpServletResponse res,
                                Object handler, Exception ex) {
        MDC.clear();                       // always runs, even when the controller threw
    }
}
```

Line by line: `preHandle` runs before the controller, and returning `false` stops the request. `afterCompletion` runs after the response is done, even on exceptions, so it is the right place for cleanup such as `MDC.clear()`. There is also `postHandle`, which runs after the controller returns but before the view is rendered, and it is skipped when the controller throws.

Choosing the right tool among the three interception layers:

||Runs|Knows|Use for|
|---|---|---|---|
|Servlet `Filter` / Security filter|Before `DispatcherServlet`|Raw request/response|Authentication, CORS, compression|
|`HandlerInterceptor`|Inside MVC, around the handler|The matched handler method|Request IDs, timing, locale, per-endpoint checks|
|AOP `@Aspect`|Around any bean method|Method and arguments|Business-level logging, transactions|

An interceptor must not be your security layer. It never sees requests that MVC does not route (static resources aside), and Spring Security is built for that job.

### 2. Static resources and SPA fallback

Boot already serves `/static`, `/public`, `/resources`, and `META-INF/resources` from the classpath. Add your own location only when you need one:

```java
@Configuration
public class StaticResourceWebConfig implements WebMvcConfigurer {

    private final String uploadDir;

    public StaticResourceWebConfig(@Value("${app.uploads.dir}") String uploadDir) {
        this.uploadDir = uploadDir;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/files/**")
                .addResourceLocations("file:" + uploadDir + "/")
                .setCacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic());
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("forward:/index.html");
    }
}
```

The `file:` prefix makes the location a filesystem path, and the trailing `/` is required. `addViewControllers` maps `/` to `index.html` without writing a controller. Never point a resource handler at a directory that also holds anything non-public.

### 3. Formatters and converters

Without a converter, `?status=active` fails for an enum `Status.ACTIVE`. A converter fixes it once for the whole application:

```java
public class StringToStatusConverter implements Converter<String, Status> {
    @Override
    public Status convert(String source) {
        return Status.valueOf(source.trim().toUpperCase());
    }
}
```

```java
@Override
public void addFormatters(FormatterRegistry registry) {
    registry.addConverter(new StringToStatusConverter());
}
```

A bad value throws a conversion exception, which your `@RestControllerAdvice` should turn into a `ProblemDetail` `400` instead of a `500`. A `Converter` goes one way (String → type). A `Formatter` also prints the type back to text, which matters mostly for views.

### 3b. A custom controller parameter

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.PARAMETER)
public @interface CurrentUserId {}

public class CurrentUserIdResolver implements HandlerMethodArgumentResolver {

    @Override
    public boolean supportsParameter(MethodParameter p) {
        return p.hasParameterAnnotation(CurrentUserId.class)
            && p.getParameterType().equals(Long.class);
    }

    @Override
    public Object resolveArgument(MethodParameter p, ModelAndViewContainer mav,
                                  NativeWebRequest req, WebDataBinderFactory f) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return ((AppUserDetails) auth.getPrincipal()).getId();
    }
}
```

Register it with `resolvers.add(new CurrentUserIdResolver())` inside `addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers)`. Controllers can then declare `@CurrentUserId Long userId`. It reads from the `Authentication` object, as in your earlier lesson, so there is no repository lookup per request.

### 4. Async and path prefix

```java
@Override
public void configurePathMatch(PathMatchConfigurer configurer) {
    configurer.addPathPrefix("/api", HandlerTypePredicate.forAnnotation(RestController.class));
}
```

This prefixes every `@RestController` with `/api` in one place. Use it instead of repeating `/api` in each `@RequestMapping`. For async controller returns (`Callable`, `DeferredResult`), define the executor in `configureAsyncSupport`. For ordinary blocking controllers on JDK 25, `spring.threads.virtual.enabled=true` is the usual simpler route, as in your thread-types lesson.

## Rules for using it in production

**Keep each configurer to one concern.** `WebCorsConfig`, `RequestTracingWebConfig`, `StaticResourceWebConfig`, `FormattingWebConfig`. A single `WebConfig` with 300 lines becomes the file nobody dares to touch.

**Drive values from properties.** Upload paths, cache durations, and excluded paths come from `@ConfigurationProperties` (or `@Value` for one value). Combined with profiles, the same class behaves differently in `dev` and `prod` without an `if`.

**Order explicitly.** Interceptors run in registration order unless you set `.order(...)`. Several configurer beans are applied in bean order, so put `@Order` on the class if two configurers touch the same registry.

**Prefer Boot properties first.** Content negotiation, Jackson formatting, static locations, and multipart limits all have `spring.*` properties. Write Java configuration only for what properties cannot express.

**Test it with a slice.** `@WebMvcTest` loads your `WebMvcConfigurer` beans, so you can verify the wiring without the full application:

```java
@WebMvcTest(controllers = BookController.class)
@Import({RequestTracingWebConfig.class, RequestIdInterceptor.class})
class RequestTracingTest {

    @Autowired MockMvc mockMvc;

    @Test
    void responseCarriesRequestId() throws Exception {
        mockMvc.perform(get("/api/books"))
               .andExpect(header().exists("X-Request-Id"));
    }
}
```

## Mistakes that bite

- Adding `@EnableWebMvc` in a Boot app, then wondering why static resources and JSON settings stopped working.
- Using `configureMessageConverters` and losing every default converter.
- Putting authentication logic in an interceptor instead of the `SecurityFilterChain`.
- Forgetting `excludePathPatterns`, so the interceptor also runs on error and health endpoints.
- Registering the interceptor _instance_ with `new` inside the configurer, so it cannot use injected beans. Inject it as a bean, as the first example does.
- Forgetting the trailing `/` on `file:` resource locations.


[[Spring Framework]]