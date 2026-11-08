

CI/CD stands for **Continuous Integration** and **Continuous Delivery** (or **Continuous Deployment**). It is a way of working where every change you push to Git is automatically built, tested, and, if everything passes, shipped toward your users. Instead of a person running commands by hand, a **pipeline** runs the same steps in the same order every time.

The idea is simple: **small changes, checked often, released often.** You don't wait three weeks, merge everything at once, and hope it works. You merge small pieces many times a day, and a robot tells you within minutes if something broke. CI/CD is a habit supported by tools, not a single tool.

---

## The three parts

The "CD" has two meanings, so it helps to separate all three.

|Term|What it means|Who presses the final button?|
|---|---|---|
|**Continuous Integration (CI)**|Every push is automatically built and tested, and everyone's code is merged into a shared branch often|Nobody, it is fully automatic|
|**Continuous Delivery**|After CI passes, the app is automatically packaged and made _ready_ to release|A human approves the release|
|**Continuous Deployment**|After CI passes, the app is automatically released to production|Nobody, it is fully automatic|

Think of a restaurant kitchen. CI is the cook tasting every dish as it is made. Continuous Delivery is the plated dish waiting at the pass, ready to go. Continuous Deployment is the dish going straight to the table with no one checking at the pass.

### Continuous Integration in detail

"Integration" means combining your code with your teammates' code. The rule of CI is to **integrate often**, at least daily, in small pieces.

Each time you push, the CI server does roughly this:

1. Checks out your code from Git.
2. Compiles it.
3. Runs the automated tests (unit tests, sometimes integration tests).
4. Runs checks such as code style and security scanning.
5. Reports **pass ✅ or fail ❌** back on your commit or pull request.

If it fails, fixing it becomes the team's top priority. A broken main branch blocks everyone, so teams keep it green.

### Continuous Delivery and Deployment in detail

Once the code is verified, the pipeline continues:

1. **Package** it into something runnable: a JAR, a WAR, or a Docker image.
2. **Store** that package in a registry (Docker Hub, GitHub Packages, Nexus).
3. **Deploy** it to a _staging_ environment, which is a copy of production, and run more tests there.
4. **Release** it to production, either after a human approval (Delivery) or automatically (Deployment).

The key idea is that the package is built **once** and the _same_ package moves through every environment. You never rebuild for production, so what you tested is exactly what you ship.

---

## What a pipeline looks like

```
git push
   │
   ▼
┌────────┐   ┌────────┐   ┌─────────┐   ┌──────────┐   ┌────────────┐   ┌────────────┐
│ Build  │ → │  Test  │ → │ Package │ → │  Deploy  │ → │ Deploy to  │
│        │   │        │   │ (Docker │   │ to       │   │ production │
│        │   │        │   │  image) │   │ staging  │   │ (approval) │
└────────┘   └────────┘   └─────────┘   └──────────┘   └────────────┘
 ◄──────── CI ────────►    ◄────────────── CD ───────────────────────►
```

If any box fails, the pipeline **stops there**. Broken code never reaches the next stage.

---

## A real example: Spring Boot with GitHub Actions

GitHub Actions is built into GitHub, so you don't need to install a server. You describe your pipeline in a YAML file inside your repository, at `.github/workflows/ci.yml`.

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Check out the code
        uses: actions/checkout@v4

      - name: Set up Java 21
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21
          cache: maven

      - name: Build and run tests
        run: mvn --batch-mode verify

      - name: Upload the JAR
        uses: actions/upload-artifact@v4
        with:
          name: app-jar
          path: target/*.jar
```

### Line-by-line walkthrough

**`name: CI`**: A label shown in the GitHub "Actions" tab. Purely cosmetic.

**`on:`**: The _trigger_. It answers "when should this pipeline run?"

- `push` to `main` runs it whenever someone pushes to the main branch.
- `pull_request` targeting `main` runs it whenever a PR is opened or updated, so you get a pass/fail result _before_ merging.

**`jobs:`**: A pipeline is made of one or more jobs. Jobs can run in parallel or in order. Here there is only one, `build-and-test`.

**`runs-on: ubuntu-latest`**: GitHub gives you a fresh, temporary Linux machine for this job. It is thrown away afterwards, so every run starts from a clean slate. That is why "it works on my machine" problems show up quickly: the pipeline machine knows nothing about your laptop.

**`steps:`**: The ordered list of things the job does.

**`uses: actions/checkout@v4`**: `uses` runs a ready-made, reusable action. This one downloads your repository onto the machine. Without it, the machine would be empty.

**`uses: actions/setup-java@v4`** with `with:`: Installs a JDK. `with` passes settings to the action: which Java distribution, which version, and `cache: maven`, which stores your downloaded dependencies so the next run is faster.

**`run: mvn --batch-mode verify`**: `run` executes a plain shell command. `mvn verify` compiles the code, runs your tests, and packages the JAR. `--batch-mode` turns off Maven's interactive output so logs stay clean. If any test fails, Maven exits with an error, the step turns red, and the pipeline stops.

**`upload-artifact`**: Saves the built JAR so you can download it, or so a later job can use it. An **artifact** is any file the pipeline produces and keeps.

### Adding the delivery part: build a Docker image

You can add a second job that runs only if the first one succeeded and only on `main`:

```yaml
  docker-image:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push the image
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: myname/myapp:${{ github.sha }}
```

- **`needs: build-and-test`** makes this job wait for the first job and skip itself if that job failed. This is how you chain stages.
- **`if: github.ref == 'refs/heads/main'`** means only code on `main` becomes an image. Feature branches are tested but not packaged.
- **`${{ secrets.DOCKER_USERNAME }}`** reads a secret you stored in your repository settings. **Never write passwords directly in the YAML file.** It lives in Git history, and anyone with repo access can read it.
- **`tags: myname/myapp:${{ github.sha }}`** tags the image with the exact commit ID. That way you always know which code is inside which image, and you can roll back to any older version.

A final step could SSH into your Debian server and run `docker pull` plus `docker run`. That is the deployment.

---

## Ways to release safely

Deploying automatically sounds scary, so teams use strategies to reduce the risk.

|Strategy|How it works|Good for|
|---|---|---|
|**Rolling**|Replace servers one at a time with the new version|Simple, no downtime|
|**Blue-green**|Run the new version (green) next to the old (blue), then switch all traffic at once|Instant rollback: just switch back|
|**Canary**|Send, say, 5% of users to the new version first, then increase|Catching problems with real traffic|
|**Feature flags**|Ship the code turned _off_, then enable it later with a switch|Separating "deploy" from "release"|

---

## Common tools

- **GitHub Actions**: built into GitHub, a good place to start.
- **GitLab CI/CD**: built into GitLab, also driven by a YAML file.
- **Jenkins**: self-hosted and very flexible, with a lot of plugins and more setup work.
- **Others**: CircleCI, Azure DevOps, Argo CD (for Kubernetes).

The concepts are identical across all of them. Learn one and the others will feel familiar.

---

## Good habits (and common mistakes)

- **Keep the pipeline fast.** Aim for under ten minutes. If it is slow, people stop waiting for it.
- **Fix a red build immediately.** A permanently broken pipeline gets ignored, and then it is useless.
- **Build once, deploy the same artifact everywhere.** Don't rebuild per environment.
- **Keep secrets in the secret store**, never in the repo.
- **Write real tests.** A pipeline with no tests only proves the code compiles. CI/CD is only as trustworthy as your tests.
- **Make the pipeline repeatable.** The same commit should produce the same result every time.

---

## A related concept in short: DevOps

**DevOps** is the culture and set of practices that bring development (writing code) and operations (running it) together so that one team owns the software from idea to production. CI/CD is one of its main tools, along with Infrastructure as Code (describing servers in files, such as Terraform) and monitoring. CI/CD is the _automation_; DevOps is the _mindset_ around it.

---

## Quick recap

1. **CI** means integrate often, with every push built and tested automatically.
2. **Continuous Delivery** means always keeping a release-ready package, with a human pressing the final button.
3. **Continuous Deployment** means the same, but fully automatic to production.
4. A **pipeline** is a chain of stages (build → test → package → deploy), and it stops at the first failure.
5. Build the artifact **once** and promote that same artifact through each environment.
6. Start small: a pipeline that just builds and tests your Spring Boot project on every push is already real CI.



[[CICD]]