CI/CD stands for Continuous Integration / Continuous Delivery (or Continuous Deployment).

It's a software development practice that automates building, testing, and delivering your application whenever you change your code.

In simple terms: instead of manually building, testing, and deploying your Spring Boot application every time you make changes, CI/CD does much of that work automatically.

## 1. CI — Continuous Integration

CI means automatically integrating and validating code changes.

Imagine you're working on a Spring Boot project.

You:

1. Write a new feature.
    
2. Commit your changes.
    
3. Push your code to GitHub.
    
4. An automated pipeline starts running.
    

The pipeline might:

- Compile your Java code.
    
- Run unit tests.
    
- Run integration tests.
    
- Check code quality.
    
- Build your JAR file.
    

If something fails, you get notified.

Example:

You push this code:

```
@Service
public class GreetingService {

    public String greet() {
        return "Hello, Alireza!";
    }
}
```

GitHub automatically runs your tests to verify that your application still works.

## 2. CD — Continuous Delivery / Deployment

CD has two meanings:

Continuous Delivery

Your application is automatically built and prepared for deployment, but deploying it to production requires manual approval.

Continuous Deployment

Your application is automatically deployed to production whenever changes pass all pipeline checks.

## 3. How CI/CD works

Write Java Code

Spring Boot application

Git Commit & Push

Upload changes to GitHub

CI

Continuous Integration

- Compile application
    
- Run automated tests
    
- Build JAR
    

CD

Continuous Delivery / Deployment

- Prepare deployment artifact
    
- Deploy application to server
    
- Run application
    

## 4. Popular CI/CD tools

|Tool|Purpose|
|---|---|
|GitHub Actions|Automate workflows directly in GitHub|
|Jenkins|Self-hosted automation server|
|GitLab CI/CD|CI/CD integrated into GitLab|
|Docker|Package applications into containers|
|Argo CD|Kubernetes continuous delivery|

## 5. A practical example for your Spring Boot projects

You can use GitHub Actions + Maven + Docker.

For example, create this file in your project:

```
.github/
    workflows/
        ci.yml
```

A basic CI workflow:

```
name: Spring Boot CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'temurin'

      - name: Build and test
        run: mvn clean verify
```

Now, whenever you push code to `main` or create a pull request targeting `main`, GitHub Actions runs your Maven build and tests.

My recommendation: Learn GitHub Actions first. It's a practical way to understand CI/CD without having to configure and maintain your own Jenkins server.

The next useful topic is learning how to build a complete CI/CD pipeline for a Spring Boot application using GitHub Actions, Docker, and PostgreSQL.