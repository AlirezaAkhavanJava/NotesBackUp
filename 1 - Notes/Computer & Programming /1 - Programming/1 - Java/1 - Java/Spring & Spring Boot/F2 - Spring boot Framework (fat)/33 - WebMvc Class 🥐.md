
I'll explain the `WebMvc` class in Spring Framework, which is central to configuring Spring MVC applications.

## What is WebMvc?

`WebMvc` refers to Spring's web MVC (Model-View-Controller) framework. It's not a single class but rather a configuration system for building web applications in Spring.

## Key Configuration Approaches

### 1. @EnableWebMvc Annotation

```java
@Configuration
@EnableWebMvc
public class WebMvcConfig implements WebMvcConfigurer {
    
    // Configure view resolvers
    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.jsp("/WEB-INF/views/", ".jsp");
    }
    
    // Configure static resources
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/resources/**")
                .addResourceLocations("/resources/");
    }
    
    // Configure message converters
    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        converters.add(new MappingJackson2HttpMessageConverter());
    }
}
```

### 2. WebMvcConfigurer Interface

The `WebMvcConfigurer` interface provides callback methods to customize Spring MVC configuration:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    // CORS configuration
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("https://example.com")
                .allowedMethods("GET", "POST");
    }
    
    // Interceptors
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoggingInterceptor())
                .addPathPatterns("/**");
    }
    
    // Formatters
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addFormatter(new DateFormatter("yyyy-MM-dd"));
    }
}
```

### 3. WebMvcConfigurationSupport

For more advanced configuration:

```java
@Configuration
public class CustomWebMvcConfig extends WebMvcConfigurationSupport {
    
    @Bean
    @Override
    public RequestMappingHandlerMapping requestMappingHandlerMapping() {
        RequestMappingHandlerMapping handlerMapping = super.requestMappingHandlerMapping();
        handlerMapping.setOrder(0);
        handlerMapping.setInterceptors(getInterceptors());
        return handlerMapping;
    }
    
    @Bean
    public ViewResolver viewResolver() {
        InternalResourceViewResolver resolver = new InternalResourceViewResolver();
        resolver.setPrefix("/WEB-INF/views/");
        resolver.setSuffix(".jsp");
        return resolver;
    }
}
```

## Common Configuration Examples

### Static Resources and View Resolution

```java
@Configuration
@EnableWebMvc
public class MvcConfig implements WebMvcConfigurer {
    
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/css/**")
                .addResourceLocations("classpath:/static/css/");
        registry.addResourceHandler("/js/**")
                .addResourceLocations("classpath:/static/js/");
        registry.addResourceHandler("/images/**")
                .addResourceLocations("classpath:/static/images/");
    }
    
    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        ThymeleafViewResolver resolver = new ThymeleafViewResolver();
        resolver.setTemplateEngine(templateEngine());
        resolver.setCharacterEncoding("UTF-8");
        registry.viewResolver(resolver);
    }
    
    @Bean
    public SpringTemplateEngine templateEngine() {
        SpringTemplateEngine engine = new SpringTemplateEngine();
        engine.setTemplateResolver(templateResolver());
        return engine;
    }
    
    private ITemplateResolver templateResolver() {
        SpringResourceTemplateResolver resolver = new SpringResourceTemplateResolver();
        resolver.setPrefix("classpath:/templates/");
        resolver.setSuffix(".html");
        resolver.setTemplateMode(TemplateMode.HTML);
        return resolver;
    }
}
```

### REST API Configuration

```java
@Configuration
@EnableWebMvc
public class RestMvcConfig implements WebMvcConfigurer {
    
    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        // JSON converter
        MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter();
        converter.setObjectMapper(objectMapper());
        converters.add(converter);
        
        // String converter
        StringHttpMessageConverter stringConverter = new StringHttpMessageConverter();
        stringConverter.setSupportedMediaTypes(Arrays.asList(
            MediaType.TEXT_PLAIN,
            MediaType.TEXT_HTML
        ));
        converters.add(stringConverter);
    }
    
    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        return mapper;
    }
    
    @Override
    public void configureContentNegotiation(ContentNegotiationConfigurer configurer) {
        configurer.favorParameter(false)
                  .ignoreAcceptHeader(false)
                  .defaultContentType(MediaType.APPLICATION_JSON);
    }
}
```

## Spring Boot Auto-configuration

In Spring Boot, much of the WebMvc configuration is auto-configured:

```java
@Configuration
public class WebMvcAutoConfiguration {
    // Auto-configures:
    // - View resolvers
    // - Static resource handling
    // - Message converters
    // - Formatters
    // - And more...
}
```

You can still customize it:

```java
@Configuration
public class CustomWebMvcConfig implements WebMvcConfigurer {
    
    // Your customizations here
    // Spring Boot will apply auto-configuration + your customizations
}
```

## Key Components Configured by WebMvc

- **Handler Mappings**: Map requests to handlers
- **Handler Adapters**: Execute handlers
- **View Resolvers**: Resolve view names to actual views
- **Message Converters**: Convert request/response bodies
- **Exception Resolvers**: Handle exceptions
- **Argument Resolvers**: Resolve handler method parameters

The `WebMvc` configuration system provides a flexible way to customize Spring MVC behavior while leveraging Spring's powerful auto-configuration capabilities.


##### Tags : [[0 - Spring Framework]]