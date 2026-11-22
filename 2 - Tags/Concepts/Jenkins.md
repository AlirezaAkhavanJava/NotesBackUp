

Jenkins is a self-hosted, open-source **automation server** used to build **CI/CD pipelines** — the process of automatically building, testing, and deploying code every time it changes. Instead of a developer manually running `mvn package`, running tests, SSHing into a server, and deploying a JAR by hand, Jenkins watches your repository, picks up changes, and runs that entire sequence automatically and consistently every single time. The value isn't just saving typing — it's eliminating "works on my machine" problems by running the exact same steps in the exact same environment for every change, and catching broken builds or failing tests immediately instead of discovering them in production.

Jenkins itself doesn't build or test anything — it orchestrates other tools (Maven/Gradle, your test suite, Docker, SSH, deployment scripts) according to instructions you give it. Think of it as a scheduler and runner that executes a defined sequence of steps whenever a trigger (a Git push, a schedule, a manual click) fires.

## The core building blocks

**Job / Project** — a single configured task in Jenkins, e.g. "build and test my-spring-app." Everything in Jenkins happens inside a job.

**Pipeline** — the modern way to define a job: a sequence of **stages**, each containing **steps**, written as code (a `Jenkinsfile`) rather than clicked together in the UI. This is what you'll use for any real Spring Boot project.

**Jenkinsfile** — a text file, checked into your Git repository alongside your code, that defines the pipeline. Because it lives in version control, your build process is versioned and reviewable just like your app code.

**Agent** — the machine (or container) that actually executes the pipeline's steps. Jenkins has a **controller** (the main server, scheduling and managing everything) and one or more **agents** (where the actual work runs) — on a small setup these are often the same machine.

**Trigger** — what causes a pipeline to run: a webhook from GitHub/GitLab on push, a cron-style schedule, or a manual "Build Now" click.

## A Jenkinsfile for a Spring Boot project

```groovy
pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk 'JDK-25'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/you/your-spring-app.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    sudo systemctl stop your-spring-app
                    cp target/your-spring-app.jar /opt/your-spring-app/app.jar
                    sudo systemctl start your-spring-app
                '''
            }
        }
    }

    post {
        failure {
            echo 'Build failed — check the logs above.'
        }
        success {
            echo 'Deployed successfully.'
        }
    }
}
```

This is a **declarative pipeline** (the `pipeline { stages { ... } }` structure) — the standard, more readable way to write Jenkinsfiles today. An older style, **scripted pipeline**, uses raw Groovy code with more flexibility but less structure; you'll almost always want declarative unless you hit a limitation it can't express.

The `post` block matters in production: it lets you react to the pipeline's outcome regardless of which stage failed — sending a Slack/email notification, cleaning up temp files, or rolling back a deployment.

## How a pipeline run actually flows

1. A developer pushes to the `main` branch.
2. A **webhook** fires from GitHub/GitLab to Jenkins, telling it a change happened.
3. Jenkins checks out the repo on an agent, reads the `Jenkinsfile`, and runs each stage in order.
4. If any stage's command exits with a non-zero status, the pipeline stops and is marked **failed** — later stages don't run.
5. On success, you end up with a tested, packaged, deployed application with zero manual steps.

## Parallelizing and securing the pipeline

Stages can run in parallel when they don't depend on each other — e.g., running unit tests and a static analysis tool simultaneously instead of sequentially:

```groovy
stage('Quality Checks') {
    parallel {
        stage('Unit Tests') {
            steps { sh 'mvn test' }
        }
        stage('Static Analysis') {
            steps { sh 'mvn checkstyle:check' }
        }
    }
}
```

Secrets (database passwords, deploy keys, API tokens) should never be hardcoded in the Jenkinsfile — Jenkins has a **Credentials store** for this, referenced in the pipeline instead of written as plain text:

```groovy
environment {
    DB_PASSWORD = credentials('prod-db-password')
}
```

## A related concept, briefly

**CI vs CD** is worth separating explicitly, since Jenkins handles both but they're distinct ideas: **Continuous Integration (CI)** is the practice of frequently merging code changes and automatically building/testing them to catch problems early. **Continuous Deployment/Delivery (CD)** is the practice of automatically (or with one manual approval) shipping those tested changes to production. Jenkins is the tool; CI/CD is the practice the tool exists to implement.

[[CICD]]