
A **host port** is a port number on your **machine (host)** that maps to a **port inside a Docker container**

When you run:

```bash
docker run -p 8080:80 nginx
```

- `8080` → **host port** (on your computer)
    
- `80` → **container port** (inside the container)
    

So if you open `http://localhost:8080`, Docker forwards traffic to port `80` inside the Nginx container.

✅ **Key points:**

- You can pick any **unused host port**.
    
- You can map multiple containers to different host ports:
    
    ```bash
    docker run -p 8081:80 nginx
    docker run -p 8082:80 nginx
    ```
    
- Without `-p`, the container’s ports stay **isolated** (not reachable from outside).

----
A **port** is like a **door** that data uses to enter or leave your computer over a network.

Every device on a network has:

- an **IP address** → identifies _the machine_
    
- **ports** → identify _specific services_ or _apps_ on that machine
    

💡 **Example:**  
Your computer = building 🏢  
IP address = street address  
Ports = doors to different rooms

|Service|Port|Description|
|---|---|---|
|HTTP|80|Web traffic|
|HTTPS|443|Secure web traffic|
|SSH|22|Remote terminal|
|PostgreSQL|5432|Database|
|Docker app example|8080|Custom app/webserver|

So when you visit `http://localhost:8080`, your browser connects to **port 8080** on your computer, where an app (like a Docker container or web server) is listening.
##### Tags : [[1 - Docker 🧋]]