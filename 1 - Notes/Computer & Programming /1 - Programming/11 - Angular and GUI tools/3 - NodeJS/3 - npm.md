
Think of **npm** as the **Maven of the JavaScript/Node.js world**.

Since you know Java, this comparison should make it click.

### Java world

You have:

```text
Java
  ↓
Maven
  ↓
pom.xml
  ↓
Dependencies
```

For example:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

Maven downloads the dependency and its transitive dependencies for you.

---

### Node.js world

You have:

```text
JavaScript
    ↓
Node.js
    ↓
npm
    ↓
package.json
    ↓
Dependencies
```

For example, a Node/Angular project might have:

```json
{
  "dependencies": {
    "rxjs": "^7.8.0"
  }
}
```

Then you run:

```bash
npm install
```

npm reads `package.json` and downloads the required packages.

They normally end up in:

```text
node_modules/
```

So:

```text
Maven                         npm
──────                        ───
pom.xml                  →    package.json
dependency              →    package
Maven Central           →    npm registry
mvn install             →    npm install
~/.m2                   →    ~/.npm
target/                 →    node_modules/
```

### What does npm actually do?

It's primarily a **package manager**.

You can use it to:

```bash
npm install express
```

Install a package.

```bash
npm uninstall express
```

Remove it.

```bash
npm update
```

Update dependencies.

```bash
npm install
```

Install everything defined by the project.

And:

```bash
npm run build
```

Run a project-defined script.

---

### One important thing

**npm is not Node.js.**

Think:

```text
Node.js
   │
   └── provides the JavaScript runtime

npm
   │
   └── manages JavaScript packages
```

And npm is normally installed **along with Node.js**.

So when you did:

```bash
nvm install 22.22.3
```

you installed Node.js 22.22.3, and that installation also gives you npm.

You can verify:

```bash
node --version
npm --version
```

For your Angular work, this relationship is the important one:

```text
NVM
 ↓
Node.js
 ↓
npm
 ↓
Angular CLI / Angular packages
 ↓
Your Angular application
```


[[1 - What is Node JS]]