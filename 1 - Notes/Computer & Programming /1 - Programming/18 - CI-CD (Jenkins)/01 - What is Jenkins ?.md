

Jenkins is a free, open-source **automation server**. You install it on a machine (your own laptop, a Debian server, a container), connect it to your Git repositories, and tell it what to do whenever your code changes: build, test, package, deploy. It is the most widely used self-hosted tool for running the CI/CD pipelines you just learned about.

In the CI/CD lesson, GitHub Actions ran your pipeline on a machine that GitHub gave you. Jenkins is the same idea, except **you own the machine**. That means more control and more flexibility, but also more setup and maintenance. Jenkins is written in Java and runs as a normal Java application, so it should feel familiar to you as a Spring Boot developer.

---

## How Jenkins is organized

Before the code, you need the vocabulary. Jenkins has a small set of core pieces.

|Piece|What it is|Everyday comparison|
|---|---|---|
|**Controller** (older name: master)|The main Jenkins server: web UI, scheduling, configuration, stored history|The manager who hands out work|
|**Agent** (older name: node/slave)|A machine that actually runs the jobs|The workers|
|**Executor**|One slot on an agent for running one job at a time|One desk per worker|
|**Job / Project**|A configured piece of work (for example "build my Spring app")|A task card|
|**Pipeline**|A job described as code, with stages and steps|A recipe|
|**Build**|One run of a job (build #1, #2, #3...)|One time you cooked the recipe|
|**Workspace**|The folder on the agent where the code is checked out and built|The kitchen counter|
|**Plugin**|An add-on that gives Jenkins new abilities (Git, Docker, Slack...)|An app you install|
|**Artifact**|A file a build produces and keeps, such as a JAR|The finished dish|

### Controller and agents

A small setup runs everything on the controller itself. A bigger setup keeps the controller as a coordinator only, and sends the real work to agents:

```
            ┌──────────────────────┐
 git push → │  Jenkins controller  │   (UI, schedule, history)
            └─────────┬────────────┘
         ┌────────────┼─────────────┐
         ▼            ▼             ▼
   ┌──────────┐ ┌──────────┐  ┌──────────┐
   │ Agent 1  │ │ Agent 2  │  │ Agent 3  │
   │ Linux    │ │ Windows  │  │ Docker   │
   └──────────┘ └──────────┘  └──────────┘
```

This is useful when you need different environments. You could build your Java project on a Linux agent and test a Windows-only tool on a Windows agent, both from one Jenkins.

---

## How Jenkins finds out your code changed

Jenkins has to learn about each push somehow. There are two ways:

1. **Webhook (best).** GitHub or GitLab sends a message to Jenkins the moment you push, and Jenkins starts right away.
2. **Polling.** Jenkins asks the repository every few minutes, "anything new?" This is simpler, but slower and wasteful.

Your Jenkins must be reachable from the internet for webhooks to work. That is a common stumbling block when Jenkins runs only on your laptop.

---

## The Jenkinsfile: your pipeline as code

Years ago you built Jenkins jobs by clicking through forms in the web UI. That is hard to review and impossible to version. The modern way is a text file named **`Jenkinsfile`** that lives in the root of your repository, next to your `pom.xml`. Because it is in Git, your pipeline is versioned, reviewed in pull requests, and travels with the code.

Here is a pipeline for a Spring Boot project:

```groovy
pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk   'JDK-21'
    }

    environment {
        IMAGE_NAME = 'myname/myapp'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                sh 'mvn --batch-mode clean verify'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Docker Image') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        docker build -t $IMAGE_NAME:$BUILD_NUMBER .
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $IMAGE_NAME:$BUILD_NUMBER
                    '''
                }
            }
        }
    }

    post {
        success { echo 'Pipeline finished successfully' }
        failure { echo 'Pipeline failed' }
    }
}
```

### Line-by-line walkthrough

**`pipeline { ... }`**: Everything lives inside this block. It tells Jenkins you are using the _declarative_ syntax, which is the structured, beginner-friendly style.

**`agent any`**: "Run this on any available agent." You could instead say `agent { label 'linux' }` to pick a specific machine, or `agent { docker { image 'maven:3.9-eclipse-temurin-21' } }` to run the whole pipeline inside a clean container.

**`tools { maven ...; jdk ... }`**: Asks Jenkins to provide a specific Maven and JDK. The names (`Maven-3.9`, `JDK-21`) must match what you registered in _Manage Jenkins → Tools_. Jenkins puts them on the PATH for the run.

**`environment { IMAGE_NAME = ... }`**: Defines variables available to every step. It works like environment variables in your shell.

**`stages { stage('...') { steps { ... } } }`**: A pipeline is a list of **stages**, and each stage is a list of **steps**. Stages are the boxes you see in the Jenkins visual view, so name them clearly. If a stage fails, later stages are skipped.

**`checkout scm`**: Downloads the repository, at the exact commit that triggered the build. `scm` means "the source control this Jenkinsfile came from," so you never write the URL twice.

**`sh 'mvn --batch-mode clean verify'`**: `sh` runs a shell command (on Windows agents you would use `bat`). Same Maven command as in your GitHub Actions file. A non-zero exit code fails the stage.

**`post { always { junit '...' } }`**: A `post` block runs after a stage or the whole pipeline. `always` means "whether it passed or failed." The `junit` step reads Maven's test result files and shows them as a nice test report with trends inside Jenkins. Other conditions you can use: `success`, `failure`, `unstable`, `changed`.

**`archiveArtifacts ... fingerprint: true`**: Saves the JAR with the build so you can download it later. The fingerprint lets Jenkins track which builds used the same file.

**`when { branch 'main' }`**: A condition. This stage runs only for `main`, so feature branches get built and tested but do not create Docker images.

**`withCredentials([...])`**: Jenkins has a built-in **credentials store** (_Manage Jenkins → Credentials_). This step loads the Docker Hub username and password into temporary variables for the block only. Jenkins also **masks** them in the log output. As with GitHub Actions, never hardcode secrets in the Jenkinsfile.

**`$BUILD_NUMBER`**: A variable Jenkins provides automatically (1, 2, 3...). Using it as the image tag means every build produces a uniquely named image. Others include `$BRANCH_NAME`, `$GIT_COMMIT` and `$WORKSPACE`.

**The final `post { ... }`**: Runs after all stages, which is a good place for notifications (email, Slack) when a build fails.

---

## Two pipeline styles, and two job types

You will see two syntaxes in tutorials:

||Declarative|Scripted|
|---|---|---|
|Starts with|`pipeline { ... }`|`node { ... }`|
|Style|Structured, fixed sections|Free-form Groovy code|
|Best for|Almost everything, easier to read|Complex logic and loops|

Start with declarative.

Jenkins also has different **job types**. The most important ones:

- **Pipeline**: runs one Jenkinsfile for one branch.
- **Multibranch Pipeline**: scans your repository, finds every branch and pull request that has a Jenkinsfile, and creates a job for each automatically. This is the one most teams use.
- **Freestyle**: the old click-through form style. Fine for quick experiments, but avoid it for real projects.

---

## Installing Jenkins on your Debian 13 machine

There are two common ways.

**1. As a system package.** Jenkins publishes its own apt repository. The overall shape is: install a JDK, add Jenkins' repository and signing key, `apt install jenkins`, then `systemctl enable --now jenkins`. Jenkins listens on port **8080**. Follow the official instructions on jenkins.io for the exact key and repository lines, because the signing key is rotated from time to time.

**2. In Docker**, since you already know Docker:

```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

- `-p 8080:8080` is the web UI (the port mapping you learned earlier).
- `-p 50000:50000` is the port agents use to connect to the controller.
- `-v jenkins_home:/var/jenkins_home` is a **volume**. All your jobs, plugins and settings live in `/var/jenkins_home`. Without the volume, deleting the container deletes everything.
- `jenkins/jenkins:lts` is the _Long-Term Support_ release, the stable line. Prefer LTS over the weekly releases.

On first start, open `http://localhost:8080`. Jenkins asks for an **initial admin password**, which it prints in the logs and also stores in `/var/jenkins_home/secrets/initialAdminPassword`. Then choose "Install suggested plugins" and create your admin user.

---

## Plugins: Jenkins' big strength and big weakness

Jenkins itself is small. Almost everything (Git, Docker, Pipeline, Slack, SonarQube) comes from **plugins**, and there are well over a thousand. This is why Jenkins can integrate with nearly anything.

The downside is real:

- Plugins need regular **updates**, and some are abandoned.
- Outdated plugins are a common **security risk**.
- Plugin version conflicts can break your setup.

So keep plugins to what you actually use, and update Jenkins and its plugins regularly.

---

## Security basics

Jenkins can run arbitrary commands on your machine, so it is a high-value target. At minimum:

- **Never leave it open to the internet without login.** Enable authentication and role-based permissions.
- **Run it behind HTTPS**, for example with the Nginx reverse proxy you have been learning about.
- **Store secrets in the credentials store**, never in the Jenkinsfile.
- **Do not build on the controller.** Run jobs on agents when possible, so a malicious build cannot take over the manager.
- **Keep Jenkins and plugins updated.**

---

## Jenkins vs GitHub Actions

||Jenkins|GitHub Actions|
|---|---|---|
|Hosting|You run it yourself|GitHub runs it for you|
|Setup effort|Higher|Very low|
|Cost|Software is free, you pay for the servers and your time|Free tier, then paid minutes|
|Flexibility|Extremely high, runs anywhere, even offline networks|Good, tied to GitHub|
|Maintenance|You update, back up and secure it|GitHub does|
|Config file|`Jenkinsfile` (Groovy)|YAML in `.github/workflows`|

Choose Jenkins when you need full control, a private network, or already work in a company that uses it. Choose GitHub Actions when you want to start quickly on GitHub. The concepts (stages, steps, artifacts, secrets, triggers) are the same, so learning one makes the other easy.

---

## A related concept in short: Groovy

Jenkinsfiles are written in **Groovy**, a language that runs on the JVM and looks like a relaxed version of Java: optional semicolons, string interpolation (`"Build ${env.BUILD_NUMBER}"`), and simple lists and maps. You can use Java libraries from it. You do not need to learn Groovy deeply. Declarative pipelines use only a small slice of it.

---

## Quick recap

1. Jenkins is a **self-hosted automation server** that runs your CI/CD pipelines.
2. A **controller** coordinates, **agents** do the work, and **executors** are the slots on agents.
3. Your pipeline lives in a **`Jenkinsfile`** in the repository, split into **stages** and **steps**.
4. **Webhooks** start builds instantly when you push, and polling is the slower fallback.
5. **Plugins** give Jenkins its power, but they need updates and care.
6. Secrets belong in the **credentials store**, accessed with `withCredentials`.
7. Compared with GitHub Actions: more control and more work.




[[CICD]]