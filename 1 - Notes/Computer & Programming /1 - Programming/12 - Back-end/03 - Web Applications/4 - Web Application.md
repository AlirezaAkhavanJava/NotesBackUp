A web application is just software that runs on a server and gets used through a browser. Brutal breakdown:

1. **Client (your browser)**
    
    - You type a URL or click a link.
        
    - Browser sends an **HTTP request** to the server.
        
    - It can send data too (like login info, form fields, cookies, etc.).
        
2. **Server**
    
    - A machine running a web server (e.g., Apache, Nginx, or built-in Spring Boot server).
        
    - It receives the request and hands it to the **application code** (your backend: Java Spring, Node.js, Django, etc.).
        
    - The backend processes logic: authenticate users, fetch data, run algorithms.
        
3. **Database**
    
    - If the app needs data, the backend queries a DB (PostgreSQL, MySQL, MongoDB, etc.).
        
    - Database responds with rows/documents.
        
    - Backend converts that into something usable (objects, JSON, HTML).
        
4. **Response**
    
    - The backend creates a response (HTML, JSON, XML, etc.).
        
    - Sends it back via HTTP.
        
    - Browser receives it.
        
5. **Frontend**
    
    - If response is **HTML**, browser renders it directly.
        
    - If response is **JSON**, frontend JavaScript (React, Angular, etc.) takes it and dynamically builds UI.
        
    - CSS styles everything.
        
6. **User interaction loop**
    
    - Clicking buttons, submitting forms, or making AJAX/fetch calls = new requests.
        
    - Server processes them, updates DB, returns results.
        
    - This cycle repeats.
        

👉 In short:  
**Browser ⇄ HTTP ⇄ Server (App) ⇄ Database**  
That’s the bloodstream of every web app.

![[web-architecture-diagram.jpg]]

#### Tags : [[0 - Back-End]]