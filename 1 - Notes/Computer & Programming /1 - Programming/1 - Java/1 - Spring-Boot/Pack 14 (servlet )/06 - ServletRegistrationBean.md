

**Definition.** `ServletRegistrationBean<T>` is a Spring Boot class that wraps a `Servlet` instance together with its URL mappings and settings, and tells the embedded container to register it at startup. Its siblings are `FilterRegistrationBean<T>` for filters and `ServletListenerRegistrationBean<T>` for listeners. You declare each one as a `@Bean`, and Spring hands it to Tomcat before the server accepts traffic.

## What it replaces

In the last answer, `@ServletComponentScan` let Spring find your `@WebServlet` classes. That works, but the registration is hidden. The URL lives in an annotation on the class, and the settings live nowhere visible. Once you have several servlets and filters, you cannot see at a glance which URLs they own or in what order filters run.

A registration bean moves that information into a configuration class. The servlet class itself no longer needs any annotation, which means it stays a plain object you can construct however you like. That freedom is the main reason to use this approach.

## The shape of a registration

Every registration answers the same four questions: what runs, where it is mapped, what settings it has, and in what order it runs.

```
RegistrationBean
  ├── the object        the servlet, filter, or listener instance
  ├── the mapping       URL patterns it claims
  ├── the settings      name, init parameters, load-on-startup
  └── the order         for filters, which runs first
```

## Servlets: explicit mapping and dependency injection

This is the first reason developers reach for the bean form. A servlet can take constructor arguments, which `@WebServlet` classes cannot receive from Spring.

```java
public class ReportServlet extends HttpServlet {

    private final ReportService reports;   // injected, not created here
    private final String defaultFormat;    // comes from init parameters

    public ReportServlet(ReportService reports, String defaultFormat) {
        this.reports = reports;
        this.defaultFormat = defaultFormat;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String format = req.getParameter("format");
        if (format == null) {
            format = defaultFormat;
        }
        resp.setContentType("text/plain");
        resp.getWriter().println(reports.render(format));
    }
}
```

Now the configuration that creates it:

```java
@Configuration
public class WebConfig {

    @Bean
    public ServletRegistrationBean<ReportServlet> reportServlet(ReportService reports) {
        ServletRegistrationBean<ReportServlet> reg =
                new ServletRegistrationBean<>(
                        new ReportServlet(reports, "csv"),  // the servlet instance
                        "/reports/*");                      // URL pattern(s)

        reg.setName("reportServlet");   // name shown in logs and in the container
        reg.setLoadOnStartup(1);        // create at startup, not on first request
        reg.addInitParameter("env", "prod");
        return reg;
    }
}
```

What each part does:

- `reports` is a parameter of the `@Bean` method, so Spring supplies the real `ReportService` bean. This is the injection that `@ServletComponentScan` could not give you.
- `"/reports/*"` is a prefix pattern. It matches `/reports/q1`, `/reports/2026/summary`, and so on.
- `setLoadOnStartup(1)` makes the container create the servlet during startup. Without it, the first request pays the initialization cost. A positive number also controls order among servlets that load at startup.
- `addInitParameter` attaches a string setting. Read it inside the servlet with `getServletConfig().getInitParameter("env")`, or in `init()`.

## The four kinds of URL pattern

The string you pass to a registration decides which requests it claims. The container uses a fixed set of rules:

|Pattern|Matches|Example|
|---|---|---|
|`/hello`|Exactly that path|`/hello` only|
|`/reports/*`|Any path starting with the prefix|`/reports/q1`, `/reports/x/y`|
|`*.pdf`|Any path ending with the extension|`/files/a.pdf`|
|`/`|The default, used only when nothing else matches|Everything else|

When more than one servlet matches a request, the container picks the most specific one: exact paths win over prefixes, prefixes win over extensions, and the default applies last. `DispatcherServlet` owns `/` in Spring Boot, so an exact or prefix mapping from you takes precedence over it. A mapping of `/*` is different, because it matches everything and takes precedence over the dispatcher too. That is the mistake that silently disables all your controllers.

## Filters: order and scope

Filters are where registration beans matter most, because the order of filters is part of their behavior. A logging filter should run before an authentication filter, for example, so that rejected requests are still logged.

```java
@Configuration
public class FilterConfig {

    @Bean
    public FilterRegistrationBean<AuthFilter> authFilter() {
        FilterRegistrationBean<AuthFilter> reg =
                new FilterRegistrationBean<>(new AuthFilter());

        reg.addUrlPatterns("/admin/*");   // only these paths pass through the filter
        reg.setOrder(2);                  // lower numbers run first
        reg.setName("authFilter");
        return reg;
    }

    @Bean
    public FilterRegistrationBean<RequestLoggingFilter> loggingFilter(
            RequestLoggingFilter filter) {
        FilterRegistrationBean<RequestLoggingFilter> reg =
                new FilterRegistrationBean<>(filter);

        reg.addUrlPatterns("/*");         // every request
        reg.setOrder(1);                  // runs before authFilter
        return reg;
    }
}
```

What this does:

- `setOrder` controls the chain. `loggingFilter` at order 1 wraps `authFilter` at order 2, so a request is logged first, then checked. Each filter must call `chain.doFilter(...)` to pass control onward.
- `addUrlPatterns("/admin/*")` limits the filter to the admin area. Without it, a filter applies to all requests.

**The double-registration trap.** Earlier you saw that a `@Component` implementing `Filter` is registered automatically, on `/*`. If you also declare a `FilterRegistrationBean` for the same class, the filter runs twice on every request, once with your patterns and once with the default. The fix is to choose one path. Either keep the `@Component` annotation and do not declare a bean, or remove the annotation and let the bean control everything. If you must keep both, disable the automatic one:

```java
reg.setEnabled(false);  // on a registration for the same filter, if you keep it as a bean
```

## Listeners: lifecycle events

A `ServletContextListener` runs code when the application starts and stops. Spring Boot usually has no need for these, because `@PostConstruct` and `@PreDestroy` on beans cover most cases. When you do need one, the registration is short:

```java
@Bean
public ServletListenerRegistrationBean<ServletContextListener> startupListener() {
    return new ServletListenerRegistrationBean<>(new ServletContextListener() {
        @Override
        public void contextInitialized(ServletContextEvent sce) {
            System.out.println("Container started");
        }
    });
}
```

What this does: the container calls `contextInitialized` once, during startup, before the first request. The anonymous class is used here only to keep the example short. In real code you would name the class.

## The bean for DispatcherServlet itself

Spring Boot registers `DispatcherServlet` the same way, through a `DispatcherServletRegistrationBean`. That is why `spring.mvc.servlet.path=/api` works: it changes a property on that registration. If you ever need to set `loadOnStartup` for the dispatcher or give it extra mappings, you can define the bean yourself, but most applications never need to.

## Choosing between the two styles

Use `@WebServlet` with `@ServletComponentScan` when the servlet has no dependencies and no special settings. It is shorter and sufficient.

Use a registration bean when any of these is true: the servlet needs injected services, you want the URL and order visible in one file, you need init parameters or load-on-startup, or you need filter ordering.

In Spring code, the registration bean style is the more common choice for anything beyond a trivial endpoint, and `@Component` filters are the default for simple filters.

## Common mistakes

- **Declaring the bean and also annotating the class.** Both register it, so the servlet runs twice or the filter runs on `/*` as well.
- **Forgetting `return reg;`.** The bean is created but the method returns nothing useful, and the registration silently never happens.
- **Mapping a filter to `/*` without meaning to.** Every request, including static files and actuator endpoints, passes through it.
- **Assuming a higher order number runs first.** Lower numbers run first.
- **Writing the servlet's dependencies as `@Autowired` fields.** A `new` instance passed to the registration is not a managed bean, so those fields stay null. Use constructor parameters instead.



[[Servlet]]