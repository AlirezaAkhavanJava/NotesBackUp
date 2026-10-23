


## The problem it solves
You ever build a web app that lives on your laptop or a simple Spring Boot backend and then want to call it from a web page on `https://my-cool-site.com`?  

Most browsers block that call. They think “hey, that’s not the same person as me” and say “nope, not allowed.” This is called **Cross-Origin Resource Sharing**. Without it, your frontend could never talk to your Spring Boot API — and your whole app would fall apart.

CORS is the browser’s polite handshake that says “okay, I trust you, you can access my resources.”

## The analogy / big picture
Imagine your house has a big front door.  
- Your friend’s house has a small side door.  
- If you just knock on the side door, the police come.  
- CORS gives your friend a special “visitor pass” (a header) so he can come in through the main door and say “I’m cool, I’m allowed here.”

The browser (police) checks that pass before letting your page talk to the API.

## How CORS works – step by step
Here’s the exact flow when your browser makes an API call:

1. **Browser sends the request**  
   Your JavaScript (fetch, axios, Angular, etc.) asks the API.

2. **Server sees the Origin**  
   Every browser automatically adds an `Origin:` header like:  
   `Origin: https://my-cool-site.com`

3. **Server decides**  
   Your Spring Boot controller or filter looks at that header and says “yes” or “no”.

4. **Server replies**  
   If allowed, the API returns normal JSON + two special headers:  
   `Access-Control-Allow-Origin: https://my-cool-site.com`  
   `Access-Control-Allow-Methods: GET, POST, PUT, DELETE`

5. **Browser checks**  
   If the header is there and matches, the request goes through.  
   If not, you get a friendly “CORS error” in the browser console.

That’s it. No extra code needed for the simple case.

## Spring Boot example – super simple
Let’s make the API allow your frontend from any site (we’ll tighten this in a second).

```java
@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/greet")
    public String greet() {
        return "Hello from CORS!";
    }
}
```

Now open it in your browser at `http://localhost:8080/api/greet` — it works.  
Why? Because Spring Boot’s default behaviour is to **deny everything** for security (smart!). You have to explicitly say “we’re cool”.

## Spring Boot – the real version (recommended)
Create a tiny filter (runs on every request):

```java
@Component
public class CorsFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletResponse response = (HttpServletResponse) res;
        response.setHeader("Access-Control-Allow-Origin", "*");           // any site OK
        response.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "*");           // accept any header

        if ("OPTIONS".equalsIgnoreCase(((HttpServletRequest) req).getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        chain.doFilter(req, res);
    }
}
```

**Line-by-line**  
- `@Component` – Spring Boot auto-registers it.  
- `Access-Control-Allow-Origin: *` – allows **every** website (for dev). In real life we’ll use the exact Origin.  
- `Allow-Methods` – tells the browser what HTTP verbs are allowed.  
- `Allow-Headers` – lets the frontend send any data it wants.  
- The `OPTIONS` check – pre-flight request explained below.

**Pre-flight request (OPTIONS)**  
Modern browsers automatically send an extra `OPTIONS` request to check “is this really allowed?”  
If your filter answers yes, the real GET/POST goes through. That’s why you sometimes see two requests instead of one.

## Spring Boot – the real production version (tight control)
Don’t use `*` in production — it’s dangerous.

```java
// In application.properties
cors.allowed-origins=http://localhost:3000,https://my-cool-site.com
```

Then in the filter:

```java
response.setHeader("Access-Control-Allow-Origin", 
    Arrays.asList(allowedOrigins).contains(origin) ? origin : "");  // or "*" for dev only
```

## Try it yourself (super quick)
1. Run your Spring Boot app.
2. Open a browser and go to `http://localhost:8080/api/greet` from a normal page.
3. If you see “Hello from CORS!”, you’re done.
4. Want to test the full thing? Run this tiny HTML in your browser:

```html
<!DOCTYPE html>
<html>
<head>
    <script>
        fetch("http://localhost:8080/api/greet", {
            method: "GET",
            mode: "cors"  // this is the magic line
        })
        .then(r => r.text())
        .then(console.log);
    </script>
</head>
</html>
```

That’s it — you just tested CORS in the browser.

## Common mistakes
| Mistake | Why it hurts | How to fix |
|---------|--------------|----------|
| Forgetting the filter | Browser blocks the call | Add the `@Component` filter above |
| Using `*` in production | Anyone can steal your data | Use specific Origin or `Access-Control-Allow-Credentials: true` |
| No `Allow-Methods` or `Allow-Headers` | Frontend can’t send POST or custom headers | Add both headers |
| Missing `mode: "cors"` in fetch | Request treated as same-origin | Always add it |
| CORS error in console but no headers in browser | Filter not running on every request | Check `chain.doFilter` is called |

## Related concept, briefly
**CORS vs Same-Origin Policy**  
Same-Origin Policy is the default rule that blocks everything. CORS is the polite exception that lets you opt-in. They work together: the browser checks CORS after Same-Origin blocks the request.

## The whole picture

| Question | Answer |
|----------|--------|
| What is CORS? | Browser rules that let one website ask another for data |
| Why does it exist? | Same-Origin Policy blocks cross-site calls |
| How does the server say “yes”? | Special `Access-Control-Allow-*` headers |
| What about pre-flight? | Extra OPTIONS request handled by the filter |
| Spring Boot default? | Denies everything (security-first) |
| Real-world security? | Never use `*` in production |





[[Spring Security]]