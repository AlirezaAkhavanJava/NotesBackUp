


Here is the surprising part: **Jenkins knows nothing about Spring Boot.** It does not read your `@RestController` classes or understand your beans. Jenkins is a very dependable robot that runs commands on a machine and reacts to whether each command succeeded or failed. Your Spring Boot project is simply a Maven (or Gradle) project, so Jenkins talks to it through the same tools you use on your own laptop: `mvn`, `docker`, `ssh`, and `curl`.

So the interaction is a series of **hand-offs**. Jenkins hands your code to Maven, Maven hands a JAR back, Jenkins hands that JAR to Docker, Docker hands an image to your Debian server, and finally Jenkins asks your running app, "are you healthy?" This lesson follows one commit through each hand-off.

---

## The touchpoints at a glance

|Stage|Jenkins does|Spring Boot side|Result|
|---|---|---|---|
|Checkout|`checkout scm`|Your repo with `pom.xml` and `Jenkinsfile`|Source on the agent|
|Build + test|`./mvnw verify`|Compiles, runs JUnit tests, activates a test profile|Pass/fail, test reports|
|Package|Maven `package` phase|`spring-boot-maven-plugin` makes an executable "fat" JAR|`target/app.jar`|
|Image|`docker build` and `push`|Dockerfile runs `java -jar`|Versioned image in a registry|
|Deploy|`ssh` to the server|Container starts with the `prod` profile|Running app|
|Verify|`curl` the health URL|Actuator `/actuator/health` answers `UP`|Deploy confirmed or failed|

Let's go through them one by one.

---

## 1. Build and test: Jenkins runs Maven for you

The simplest line in your whole pipeline is:

```groovy
sh './mvnw --batch-mode clean verify'
```

**`./mvnw`** is the **Maven Wrapper**, a small script that Spring Initializr puts in every Spring Boot project. It downloads the exact Maven version your project needs. Use it instead of `mvn` and Jenkins no longer needs Maven installed at all, which removes one "it works on my machine" problem. (Remember `tools { maven '...' }` from the Jenkins lesson? The wrapper is a simpler alternative.)

**`verify`** runs these Maven phases in order: compile, test, package, then any integration checks. If one JUnit test fails, Maven exits with an error code, the stage turns red, and the pipeline stops.

### Test profiles and databases

Your tests should not touch your real PostgreSQL. Two common ways to handle this in a pipeline:

|Approach|How it works|Trade-off|
|---|---|---|
|**In-memory DB** (H2)|A test profile points to H2|Fast and simple, but H2 is not exactly PostgreSQL|
|**Testcontainers**|Your test starts a real PostgreSQL container, then throws it away|Realistic, but the Jenkins agent needs access to Docker|

For profiles (you learned these earlier), you can activate the test profile just for the test stage:

```groovy
stage('Test') {
    environment {
        SPRING_PROFILES_ACTIVE = 'test'
    }
    steps {
        sh './mvnw --batch-mode clean verify'
    }
    post {
        always { junit 'target/surefire-reports/*.xml' }
    }
}
```

Spring Boot's **relaxed binding** reads the environment variable `SPRING_PROFILES_ACTIVE` exactly like `spring.profiles.active=test` in `application.properties`. Putting it inside this stage's `environment` block means it does **not** leak into the later deploy stage. (If you set it at the top of the pipeline, your prod image build might pick up the test profile by mistake.)

---

## 2. Package: the fat JAR

When Maven reaches the `package` phase, the `spring-boot-maven-plugin` (already in your `pom.xml`) runs its **repackage** goal. It turns the plain JAR into an **executable JAR** that contains your classes, all dependencies, and an embedded Tomcat. That is why you can run it with a single command:

```bash
java -jar target/myapp-1.0.0.jar
```

Jenkins then stores it:

```groovy
archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
```

The plugin also keeps the original thin JAR as `*.jar.original`. The glob `*.jar` does not match that file, so you archive only the runnable one.

---

## 3. Config and secrets: how values reach Spring Boot

This is the most important connection between the two tools. Your app needs a database URL and password in production, and those must **not** be in Git. The flow is:

```
Jenkins credentials store  ─►  environment variable  ─►  Spring Boot reads it
```

In `application-prod.properties` you write placeholders instead of real values:

```properties
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:5432/appdb
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
```

- **`${DB_HOST:localhost}`** means "use the `DB_HOST` environment variable, or `localhost` if it is missing."
- `${DB_USER}` and `${DB_PASSWORD}` have no default, so the app refuses to start if they are missing. That is a good thing: it fails loudly instead of running with a wrong config.

Spring Boot also accepts `SPRING_DATASOURCE_PASSWORD` directly as an environment variable, which overrides the property of the same name.

Where do the real values live? Two good options:

- **On the server**, in a file such as `/etc/myapp/prod.env` (permissions `600`), passed to Docker with `--env-file`. Jenkins never sees the production password.
- **In Jenkins credentials**, loaded with `withCredentials` and passed along. This works, but then Jenkins holds your production secrets, so protect it well.

The first option is safer for most small projects.

---

## 4. Image: Dockerfile and Jenkins

Jenkins builds your image from a small `Dockerfile` in the repository:

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
```

- **`FROM eclipse-temurin:21-jre`** starts from an image with only a Java runtime (no compiler), which keeps the image smaller.
- **`COPY target/*.jar app.jar`** copies the JAR Maven just built into the image.
- **`EXPOSE 8080`** documents the port Spring Boot listens on.
- **`-XX:MaxRAMPercentage=75`** tells the JVM to use up to 75% of the container's memory limit for heap. This connects to your JVM memory lesson: without it, a container with a small memory limit can be killed because the JVM sized its heap badly.

A shortcut exists too: `./mvnw spring-boot:build-image` builds a Docker image using Cloud Native Buildpacks, with no Dockerfile needed. It is convenient, but the Dockerfile gives you more control and is easier to understand while you learn.

> **Debian detail:** the user that runs Jenkins must be allowed to talk to Docker. On Debian that usually means adding the `jenkins` user to the `docker` group and restarting Jenkins. Be aware that being in that group is effectively root access on the machine, which is one more reason to secure Jenkins.

---

## 5. Deploy: Jenkins reaches your Debian server

The classic approach is **SSH**. Jenkins logs into your server with a key stored in its credentials store, then tells Docker to pull and run the new image.

```groovy
stage('Deploy') {
    when { branch 'main' }
    steps {
        sshagent(credentials: ['debian-deploy-key']) {
            sh '''
                ssh deploy@myserver "
                    docker pull $IMAGE:$BUILD_NUMBER &&
                    docker rm -f myapp || true &&
                    docker run -d --name myapp --restart unless-stopped \
                        -p 127.0.0.1:8080:8080 \
                        --env-file /etc/myapp/prod.env \
                        -e SPRING_PROFILES_ACTIVE=prod \
                        $IMAGE:$BUILD_NUMBER
                "
            '''
        }
    }
}
```

### Line-by-line walkthrough

**`sshagent(credentials: [...])`**: Loads a private key from the Jenkins credentials store for the duration of the block. (This comes from the _SSH Agent_ plugin.) The matching public key sits in `~/.ssh/authorized_keys` of the `deploy` user on your server.

**`ssh deploy@myserver "..."`**: Runs the quoted commands on the server. Note that `$IMAGE` and `$BUILD_NUMBER` are expanded by the _local_ shell on the Jenkins agent before sending, so the server receives the exact image tag.

**`docker pull`**: Downloads the new image from the registry.

**`docker rm -f myapp || true`**: Removes the old container. The `|| true` means "do not fail if it does not exist yet," which is the case on the very first deploy.

**`--restart unless-stopped`**: Docker restarts your app if it crashes or the server reboots.

**`-p 127.0.0.1:8080:8080`**: The port mapping you learned earlier, with one difference. Binding to `127.0.0.1` means only the server itself can reach port 8080. Public traffic goes through **Nginx as a reverse proxy**, like in your deployment lesson. Your app is never exposed directly.

**`--env-file /etc/myapp/prod.env`**: Loads the secrets from the server.

**`-e SPRING_PROFILES_ACTIVE=prod`**: Activates the `prod` profile, so `application-prod.properties` is used.

> **Alternative without Docker:** copy the JAR with `scp` and restart a **systemd** service that runs `java -jar`. Both work. Docker keeps the Java version and the app together, which makes rollbacks easy: just run the previous image tag again.

---

## 6. Verify: asking the app if it is healthy

Starting a container does not mean the app works. Spring Boot may take 10 to 20 seconds to start, and it might crash on a bad config. So the last stage asks the app directly, using **Spring Boot Actuator**.

Add the dependency in `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Then Jenkins polls the health endpoint:

```groovy
stage('Verify') {
    when { branch 'main' }
    steps {
        sh '''
            for i in $(seq 1 30); do
                if curl -fs http://myserver/actuator/health | grep -q '"status":"UP"'; then
                    echo "App is healthy"
                    exit 0
                fi
                sleep 2
            done
            echo "App did not become healthy"
            exit 1
        '''
    }
}
```

- The loop tries up to 30 times, 2 seconds apart.
- **`curl -fs`** means "fail on HTTP errors, stay silent."
- **`grep -q '"status":"UP"'`** checks the JSON answer.
- `exit 1` fails the stage, which turns the build red, and a `post { failure { ... } }` block could send you a message or roll back to the previous image.

Remember to expose only what you need, for example `management.endpoints.web.exposure.include=health,info`, and do not leave the other Actuator endpoints open to the public. If Spring Security is active, you also have to decide whether `/actuator/health` needs authentication. Many teams allow the health endpoint only from inside the network and block it in Nginx for outsiders.

---

## The whole flow together

```
git push ─► webhook ─► Jenkins ─► ./mvnw verify ─► fat JAR
                                      │
                                      ▼
                         docker build + push (tag = build number)
                                      │
                                      ▼
                        ssh ─► Debian: docker run (prod profile)
                                      │
                                      ▼
                         curl /actuator/health  ──► UP ✅ / fail ❌
```

---

## Common problems

|Symptom|Likely cause|Fix|
|---|---|---|
|`Permission denied` on `docker`|`jenkins` user is not in the `docker` group|Add the user, then restart Jenkins|
|Tests pass locally, fail in Jenkins|Different Java version, missing env vars, or timezone|Pin the JDK, print `java -version`, set variables explicitly|
|Testcontainers cannot start|No Docker access on the agent|Allow the Docker socket or use H2 for those tests|
|`./mvnw: Permission denied`|Script lost its executable bit|`git update-index --chmod=+x mvnw`|
|App starts then dies in Docker|Not enough memory, or missing `DB_PASSWORD`|Check `docker logs myapp`, set a memory limit and `MaxRAMPercentage`|
|Deploy works but health check fails|App still starting, wrong port, or Nginx blocking|Raise the wait time, check ports and the Nginx config|
|Old code keeps running|Reusing the `latest` tag|Tag with `$BUILD_NUMBER` or the commit hash|

---

## A related concept in short: Spring Boot Actuator

Actuator is a Spring Boot module that adds **production-ready endpoints** to your app: `/actuator/health` (is it alive and are its dependencies, like the database, reachable?), `/actuator/info` (version and build details), `/actuator/metrics` and more. It is the standard way for outside tools, such as Jenkins, Nginx, Docker health checks, or monitoring systems, to ask your app how it is doing, without needing to know anything about its code.

---

## Quick recap

1. Jenkins does not understand Spring Boot. It runs **Maven, Docker, SSH and curl**, and reacts to success or failure.
2. Use the **Maven Wrapper** (`./mvnw`) so the agent needs no Maven installation.
3. The **spring-boot-maven-plugin** turns your project into an executable **fat JAR**.
4. Config reaches Spring Boot through **environment variables** and **profiles**, and secrets stay out of Git.
5. Build the image once, tag it with the **build number**, and deploy that exact image.
6. Bind the container to `127.0.0.1` and put **Nginx** in front.
7. Finish with an **Actuator health check** so a broken deploy is detected automatically.




[[CICD]]