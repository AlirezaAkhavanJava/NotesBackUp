
#!/usr/bin/env bash
set -euo pipefail

notes=(
    "Servlet Lifecycle"
    "Servlet Initialization and init()"
    "Servlet Request Handling and service()"
    "Servlet Destruction and destroy()"
    "ServletConfig"
    "ServletContext"
    "Servlet Mapping and URL Patterns"
    "Servlet Annotations"
    "GenericServlet"
    "HttpServlet Lifecycle Internals"
    "HttpServlet doGet(), doPost(), doPut(), and doDelete()"
    "HTTP Request Methods in Servlets"
    "HTTP Status Codes and Servlet Responses"
    "Request Parameters and Request Attributes"
    "Servlet Request Dispatching"
    "RequestDispatcher forward()"
    "RequestDispatcher include()"
    "Servlet Filters"
    "Filter Lifecycle"
    "FilterChain"
    "Filter Registration and Ordering"
    "Servlet Listeners"
    "HttpSession"
    "Session Management in Servlets"
    "Cookies in Servlets"
    "Session Tracking Mechanisms"
    "ServletContext Attributes"
    "Servlet Asynchronous Processing"
    "Servlet Non-Blocking I/O"
    "Multipart Requests and File Uploads"
    "Servlet Error Handling"
    "Servlet Thread Safety"
    "Servlet Concurrency and Request Threads"
    "Servlet Container Thread Pool"
    "Servlet Security Constraints"
    "Servlet Authentication and Authorization"
    "Servlet Container Architecture"
    "How Tomcat Processes an HTTP Request"
    "Servlet Deployment and WAR Files"
    "Servlet URL Mapping Conflicts"
    "Servlet API Packages: jakarta.servlet and jakarta.servlet.http"
    "Servlet Specification and Versions"
    "Embedded Tomcat in Spring Boot"
    "Spring Boot Servlet Container Configuration"
    "DispatcherServlet Registration and Initialization"
    "Spring MVC Request Processing Lifecycle"
    "Servlet Filter vs Spring HandlerInterceptor"
    "Servlet Filter vs Spring Security Filter Chain"
    "Servlet Container vs Spring ApplicationContext"
    "How Spring MVC Uses the Servlet API"
)

next=10
created=0
skipped=0

for title in "${notes[@]}"; do
    # Replace characters that cannot safely appear in filenames.
    safe_title="${title//\// - }"
    safe_title="${safe_title//:/ -}"

    filename=$(printf "%02d - %s.md" "$next" "$safe_title")

    if [[ -e "$filename" ]]; then
        printf 'SKIP: %s\n' "$filename"
        ((skipped+=1))
    else
        printf '[[Spring Framework]]\n' > "$filename"
        printf 'CREATED: %s\n' "$filename"
        ((created+=1))
    fi

    ((next+=1))
done

printf '\nFinished.\nCreated: %d\nSkipped: %d\n' "$created" "$skipped"
