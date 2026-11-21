

Putting a Spring app on a real server means answering one question: **who listens to the internet, and who runs your Java code?** Tomcat runs your code. Nginx is a fast, hardened front door that faces the internet, handles HTTPS, and passes requests on to your app. You can use Tomcat alone, but the most common setup uses both.

Good news: with Spring Boot you do not need to install Tomcat at all, because it is already inside your JAR. So this lesson has two paths. **Path 1** is a Boot JAR with Nginx in front, which is what most people do today. **Path 2** is a separate Tomcat running a WAR file, which you meet in older or corporate projects. I'll show both on Debian 13, since that is what you use.

---

## The picture first

```
Internet
   │  :443 (HTTPS)
   ▼
 Nginx  ── handles HTTPS, static files, public traffic
   │  :8080 (plain HTTP, only on this machine)
   ▼
 Tomcat (inside your JAR, or standalone)
   ▼
 Your Spring app ── talks to PostgreSQL
```

||Path 1: Boot JAR|Path 2: WAR in Tomcat|
|---|---|---|
|Tomcat comes from|Inside your JAR|`apt install tomcat10`|
|You run it with|`java -jar` (via systemd)|`systemctl start tomcat10`|
|Several apps per Tomcat|No, one app per process|Yes|
|Best for|New Spring Boot projects|Legacy servers, shared Tomcat|

---

## Path 1: Spring Boot JAR + systemd + Nginx

### Step 1: Build the JAR

On your dev machine:

```bash
mvn clean package
```

This creates `target/myapp-0.0.1-SNAPSHOT.jar`. It is a "fat JAR," meaning your code, all libraries, and Tomcat packed into one file.

### Step 2: Prepare the server

```bash
sudo apt update
sudo apt install openjdk-21-jre-headless
sudo useradd -r -s /usr/sbin/nologin springapp
sudo mkdir -p /opt/myapp
sudo chown springapp:springapp /opt/myapp
```

Line by line:

- `openjdk-21-jre-headless` is Java without any desktop pieces. A server needs no GUI. Use the Java version your project builds with.
- `useradd -r -s /usr/sbin/nologin springapp` creates a **system user** that cannot log in. Your app runs as this user, so if someone breaks into the app, they do not get a powerful account.
- `/opt/myapp` is where the JAR will live.

Copy the JAR over (from your machine):

```bash
scp target/myapp-0.0.1-SNAPSHOT.jar you@yourserver:/tmp/
sudo mv /tmp/myapp-0.0.1-SNAPSHOT.jar /opt/myapp/app.jar
sudo chown springapp:springapp /opt/myapp/app.jar
```

### Step 3: Tell Spring it sits behind a proxy

In `application.properties`:

```properties
server.port=8080
server.address=127.0.0.1
server.forward-headers-strategy=framework
```

- `server.port=8080` is the port Tomcat listens on.
- `server.address=127.0.0.1` makes it listen **only on the machine itself**. The outside world cannot reach port 8080 directly. Only Nginx can.
- `server.forward-headers-strategy=framework` makes Spring trust the headers Nginx sends (`X-Forwarded-Proto` and friends). Without it, Spring thinks every request is plain HTTP from `127.0.0.1`. That breaks redirects and generated links.

Keep secrets such as database passwords out of the JAR. Put them in environment variables, which the service file below can set.

### Step 4: Run it as a service with systemd

**systemd** is Debian's service manager. It starts your app on boot and restarts it if it crashes. Create `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=My Spring Boot App
After=network.target postgresql.service

[Service]
User=springapp
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/java -jar /opt/myapp/app.jar
Environment=SPRING_DATASOURCE_PASSWORD=change-me
Restart=on-failure
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
```

- `After=` means "start me after the network and PostgreSQL are up."
- `User=springapp` runs the app as the restricted user.
- `ExecStart=` is the command, the same one you would type by hand.
- `Environment=` sets a variable. Spring maps `SPRING_DATASOURCE_PASSWORD` onto `spring.datasource.password` automatically.
- `Restart=on-failure` restarts the app if it crashes.
- `SuccessExitStatus=143` tells systemd that exit code 143 (what Java returns when stopped politely) is a normal exit, not a failure.
- `WantedBy=multi-user.target` means "start this at normal boot."

Start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
sudo systemctl status myapp
journalctl -u myapp -f
```

`enable --now` means "start at boot and start right now." The last command follows your app's logs live. Test it:

```bash
curl http://127.0.0.1:8080/
```

If this answers, your app works. Nginx comes next.

### Step 5: Install and configure Nginx

```bash
sudo apt install nginx
```

Create `/etc/nginx/sites-available/myapp`:

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Line by line:

- `listen 80;` means this block answers on port 80 (HTTP).
- `server_name` is the domain this block is for. Nginx picks the block whose name matches the request's `Host` header.
- `location / { ... }` means "every URL starting with `/`" (so, everything).
- `proxy_pass http://127.0.0.1:8080;` forwards the request to your Spring app.
- `proxy_set_header Host $host;` keeps the original domain name. Otherwise your app would see `127.0.0.1:8080`.
- `X-Real-IP` and `X-Forwarded-For` carry the **real visitor's IP**. Without them, every request would look like it came from Nginx itself.
- `X-Forwarded-Proto $scheme;` tells Spring whether the visitor used `http` or `https`. This is the header that `forward-headers-strategy` reads.

Turn the site on and check it:

```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

- Debian keeps all site files in `sites-available/`, and a **symlink** in `sites-enabled/` switches one on.
- `nginx -t` **tests the config**. Always run it before reloading. A typo here would otherwise take the site down.
- `reload` applies the config without dropping connections.

You may also want to remove the default site: `sudo rm /etc/nginx/sites-enabled/default`.

### Step 6: Add HTTPS

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

Certbot gets a free certificate from Let's Encrypt and edits your Nginx file for you. It adds the `listen 443 ssl` block and a redirect from HTTP to HTTPS. It also sets up automatic renewal. Your DNS must already point at the server, or this step will fail.

### Step 7: Open the firewall (if you use ufw)

```bash
sudo ufw allow 'Nginx Full'
```

Do **not** open port 8080. Only Nginx should be public.

---

## Path 2: A WAR inside a standalone Tomcat

Use this when a company already runs Tomcat, or you want several apps in one Tomcat.

### Change the app to build a WAR

In `pom.xml`:

```xml
<packaging>war</packaging>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-tomcat</artifactId>
  <scope>provided</scope>
</dependency>
```

- `packaging war` builds a WAR instead of a JAR.
- `scope provided` means "the server will supply Tomcat, so do not bundle it." Without this, you would have two Tomcats fighting.

In your main class:

```java
@SpringBootApplication
public class DemoApplication extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(DemoApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

When Tomcat is in charge, nobody calls `main`. Tomcat finds `SpringBootServletInitializer`, which is the hook that boots Spring inside it. `configure` tells it which class is your application. `main` still works for running locally.

### Install Tomcat

```bash
sudo apt install tomcat10
```

**Match the version to your Spring version.** Spring Boot 3 uses the `jakarta.*` packages, so it needs Tomcat 10.1 or newer. Spring Boot 4 needs Tomcat 11. Check with `apt search tomcat` and your Boot version's documentation, because Debian's package names change by release.

Debian's layout:

|Path|What it is|
|---|---|
|`/var/lib/tomcat10/webapps/`|Drop WAR files here|
|`/etc/tomcat10/`|Config (`server.xml` and others)|
|`/var/log/tomcat10/`|Logs|

### Deploy

```bash
sudo cp target/myapp.war /var/lib/tomcat10/webapps/ROOT.war
sudo systemctl restart tomcat10
```

The file name decides the URL path:

|WAR name|URL|
|---|---|
|`myapp.war`|`http://server:8080/myapp/`|
|`ROOT.war`|`http://server:8080/`|

Tomcat spots the new WAR, unpacks it, and starts your app. Then put Nginx in front exactly like in Path 1, with the same `proxy_pass http://127.0.0.1:8080;`. The only difference is that Tomcat must tell your app about the proxy headers. Add this inside `<Host>` in `/etc/tomcat10/server.xml`:

```xml
<Valve className="org.apache.catalina.valves.RemoteIpValve" />
```

A **Valve** is a small plug-in step in Tomcat's request pipeline. `RemoteIpValve` reads `X-Forwarded-For` and `X-Forwarded-Proto` so your app sees the real client IP and the real protocol. It does the same job as `forward-headers-strategy` in Path 1.

---

## When things go wrong

|What you see|Likely cause|What to check|
|---|---|---|
|**502 Bad Gateway** from Nginx|Spring app is down, or wrong port|`systemctl status myapp`, `curl 127.0.0.1:8080`|
|**Redirects go to `http://`**|Proxy headers not trusted|`server.forward-headers-strategy`, `X-Forwarded-Proto`|
|**404 on the WAR**|Wrong WAR name, so wrong path|Use `ROOT.war` or add `/myapp/`|
|**"Port already in use"**|Two things on 8080|`sudo ss -ltnp \| grep 8080`|
|**App won't start under systemd**|Missing env var or permissions|`journalctl -u myapp -e`|
|**Nginx won't reload**|Typo in config|`sudo nginx -t` shows the line|

---

## Related concept: reverse proxy vs forward proxy

A **reverse proxy** stands in front of _servers_ and speaks for them. Visitors think they talk to Nginx, and Nginx quietly talks to your app. A **forward proxy** stands in front of _clients_ (like a company network that routes everyone's browsing through one gate). Nginx here is a reverse proxy. It can also spread load across several app instances and cache responses.

---

## Quick recap

- For a new Spring Boot project, use **Path 1**: build the JAR, run it with systemd on `127.0.0.1:8080`, and put Nginx in front.
- Use **Path 2** (WAR in standalone Tomcat) when the server already has Tomcat or hosts many apps.
- Keep port 8080 private. Only Nginx faces the internet, and certbot adds HTTPS.
- Tell your app it sits behind a proxy (`forward-headers-strategy` or `RemoteIpValve`), or links and redirects will break.
- Always run `nginx -t` before reloading, and read `journalctl` when something fails.





[[Spring Framework]]