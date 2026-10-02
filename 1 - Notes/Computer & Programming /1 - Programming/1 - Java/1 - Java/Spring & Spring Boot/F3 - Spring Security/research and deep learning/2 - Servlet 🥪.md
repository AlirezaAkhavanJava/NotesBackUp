
A servlet is *a Java programming language class that is used to extend the capabilities of servers that host applications accessed by means of a request-response programming model*. Although servlets can respond to any type of request, they are commonly used to extend the applications hosted by web servers.

![[Pasted image 20251203104048.png]]



---

#### Front Controller : 

Front Controller is defined as “**a controller that handles all requests for a Web site**”. It stands in front of a web-application and delegates requests to subsequent resources. It also provides an interface to common behavior such as security, internationalization and presenting particular views to certain users.

![[Pasted image 20251203104408.png]]

DispatcherServlet is **the Front Controller in a Spring web application**. It acts as the entry point for all incoming HTTP requests. When a user makes a request (e.g., student.com/save), the DispatcherServlet receives it first, then decides which controller should handle it (e.g., Controller_1 for /save).
###### Tags : [[1 - Spring Security 🍌]]