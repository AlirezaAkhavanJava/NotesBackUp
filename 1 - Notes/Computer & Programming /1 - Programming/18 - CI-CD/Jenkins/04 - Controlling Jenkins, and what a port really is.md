

A **port** is a numbered door on your computer. Your machine has one address (`localhost`), but it can run many programs that talk over the network, so each program listens at its own door number. When your browser opens `http://localhost:8080`, it says "connect me to whatever program is listening at door 8080." Jenkins answers there.

The one rule to remember is this: **only one program can listen on a given port at a time.** Starting and stopping Jenkins (the service control you already learned) decides _whether_ that door is occupied. Changing the port decides _which_ door Jenkins uses. Once you see those two as separate, the conflict with Spring Boot makes complete sense.

## Part 1: Controlling Jenkins

You already know the switches from the systemd lesson. Here is the full control panel in one table:

|Goal|Command|
|---|---|
|Start now|`sudo systemctl start jenkins`|
|Stop now|`sudo systemctl stop jenkins`|
|Restart (after a config change)|`sudo systemctl restart jenkins`|
|Is it running?|`systemctl is-active jenkins`|
|Details and last log lines|`systemctl status jenkins`|
|Don't start at boot|`sudo systemctl disable jenkins`|
|Start at boot|`sudo systemctl enable jenkins`|
|Read the log|`journalctl -u jenkins -n 50 --no-pager`|

Two small details are worth knowing:

- **`restart` vs `stop` then `start`:** `restart` does both in one command. Use it after changing the port, because the old process has to release its door before the new one can take it.
- **Jenkins takes time to be ready.** `systemctl start` returns quickly, but the web page needs 30 to 60 seconds. "Active" means the process exists, not that the page is ready.

## Part 2: Changing the port

Jenkins reads its port from an environment variable called `JENKINS_PORT`. The package's service file sets it to 8080. Don't edit that file directly, since a package update can overwrite it. Use an override, as you learned in the systemd lesson.

**Step 1: Look at the current setting**

```bash
systemctl cat jenkins | grep -i port
```

You should see a line like `Environment="JENKINS_PORT=8080"`.

**Step 2: Create the override**

```bash
sudo systemctl edit jenkins
```

An editor opens. Type these lines **in the empty area at the top**, above the comments that systemd shows:

```ini
[Service]
Environment="JENKINS_PORT=9090"
```

Here is what each line means:

- `[Service]` says "this change belongs to the Service section of the unit file."
- `Environment="JENKINS_PORT=9090"` sets the variable. It replaces the value from the original file, because the override is layered on top.

Save and exit (in nano: `Ctrl+O`, Enter, `Ctrl+X`).

**Step 3: Apply it**

```bash
sudo systemctl restart jenkins
```

`systemctl edit` already reloads the unit files for you, so you don't need a separate `daemon-reload`.

**Step 4: Verify**

```bash
ss -ltnp | grep -E '8080|9090'
```

`ss -ltnp` lists programs that are **l**istening on **t**cp ports, **n**umerically, with the **p**rocess name. You should see Java on 9090 and nothing on 8080. Then open `http://localhost:9090`.

**Step 5: Fix the stored URL**

Jenkins remembers its own address for links in emails and webhooks. In Jenkins, go to **Manage Jenkins → System → Jenkins URL** and change it to `http://localhost:9090/`.

**Undo it any time:**

```bash
sudo systemctl revert jenkins
sudo systemctl restart jenkins
```

`revert` deletes your override and returns to the package default.

### Choosing a good port number

|Range|What it is|Advice|
|---|---|---|
|0 to 1023|Privileged ports (80, 443, 22)|Skip them, since they need root|
|1024 to 49151|Registered and common ports|Pick from here, but avoid well-known ones like 3000, 5432 (Postgres), 8080, 8443|
|49152 and up|Dynamic ports the OS hands out|Avoid, since they can be taken at random|

`9090` is a fine choice for Jenkins. `8081` also works, but it is a common second port for other apps, so you might collide again.

## Part 3: Why Jenkins and Spring Boot both use 8080

The reason is a convention, not a coincidence.

**Port 80 is the official web port**, but ports below 1024 require administrator rights. Developers wanted a web port that a normal user could open, so they settled on **8080** as the "alternative HTTP port", an easy-to-remember cousin of 80. Because it's the traditional answer, every tool that wanted a sensible default for "a web app that a normal user can run" picked it:

|Tool|Default port|
|---|---|
|Spring Boot (embedded Tomcat)|8080|
|Apache Tomcat standalone|8080|
|Jenkins|8080|

None of them knows about the others. Each program simply says "I'll take 8080 unless told otherwise."

## Part 4: Will it be a problem?

It is a problem **only if both are running at the same moment.** The second one to start fails, because the door is already occupied.

|Situation|Result|
|---|---|
|Jenkins running, you start your Spring Boot app|Spring Boot refuses to start|
|Spring Boot app running, you start Jenkins|Jenkins fails to start|
|Only one running at a time|No problem|

The Spring Boot message looks like this:

```
Web server failed to start. Port 8080 was already in use.
```

Because you run Jenkins on demand, you might never hit this by accident. But it will bite when Jenkins and your app run together, which is exactly what CI is for. Imagine a pipeline stage that starts your app to run a smoke test. The app wants 8080, but Jenkins is sitting on it.

**Ways to avoid the clash:**

1. **Move Jenkins** (what you learned in Part 2). Do this once and forget it. Since you'll have many Spring Boot projects that all default to 8080, moving the single Jenkins is the least work.
    
2. **Move the app** in `application.properties`:
    
    ```properties
    server.port=8081
    ```
    
    This ties back to your properties and profiles lessons. You can set a different port per profile (`application-dev.properties`, `application-test.properties`).
    
3. **Let tests choose a free port.** With `@SpringBootTest(webEnvironment = RANDOM_PORT)` Spring picks any free port, so tests never collide with Jenkins. Plain `@SpringBootTest` (the default MOCK mode) doesn't open a port at all.
    
4. **Tell Spring Boot to pick a random port** with `server.port=0`.
    

When something says "port already in use", find out who holds the door:

```bash
ss -ltnp | grep 8080
```

The last column shows the process name and its PID, so you know which program to stop.

## Related concepts, briefly

- **Listen address:** a port belongs to an address too. Jenkins listens on all addresses by default, so other devices on your network can reach it at `http://your-ip:9090`. On a laptop you may prefer to keep it local. Jenkins reads `JENKINS_LISTEN_ADDRESS` for that, which you can set to `127.0.0.1` in the same override, the same way you set the port.
- **Reverse proxy (Nginx):** instead of remembering `:9090`, a reverse proxy listens on port 80 and forwards requests to the right app, for example `jenkins.local` to 9090 and `app.local` to 8080. That's the idea from your Nginx and Tomcat deployment lesson, and it solves the "many apps, one port" problem on real servers.
- **Docker port mapping:** in `docker run -p 9090:8080`, the left number is the door on your machine and the right one is the door inside the container, so the container can keep using 8080 while the outside world sees 9090. It's the same idea as changing Jenkins's port, just done from outside the app.

## Quick practice

Try this in order and predict each result first:

```bash
systemctl cat jenkins | grep -i port
sudo systemctl edit jenkins          # set JENKINS_PORT=9090
sudo systemctl restart jenkins
ss -ltnp | grep -E '8080|9090'
sudo systemctl stop jenkins
ss -ltnp | grep 9090                 # should print nothing now
```

The last line shows the key lesson: stopping the service frees the door. If you can explain why nothing prints there, you've understood ports and services together. When you're ready, we can write your first Jenkinsfile for a Spring Boot project.


[[CICD]]