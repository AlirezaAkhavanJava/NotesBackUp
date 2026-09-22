
 If you're using **LazyVim + Maven**, you don't need to manually `javac` every file. Maven/Spring Boot handles compilation and only recompiles what changed.

### 1. Run Spring Boot directly

From your project's root directory:

```bash
./mvnw spring-boot:run
```

or, if Maven is installed globally:

```bash
mvn spring-boot:run
```

This is the simplest approach.

### 2. From LazyVim

Open the project:

```bash
cd /path/to/project
nvim .
```

Then open LazyVim's terminal:

```text
Ctrl + /
```

and run:

```bash
./mvnw spring-boot:run
```

Your application stays running in that terminal.

### 3. If you want a keyboard shortcut

You can configure LazyVim to run it with a key such as `<leader>r`.

Create:

```text
~/.config/nvim/lua/plugins/springboot.lua
```

```lua
return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>r",
        function()
          vim.cmd("split | terminal ./mvnw spring-boot:run")
      end,
        desc = "Run Spring Boot",
      },
    },
  },
}
```

Then:

```text
<leader>r
```

will open a terminal and execute the Spring Boot application.

### Important distinction

If by **"without needing to compile all files"** you mean you don't want to run:

```bash
mvn clean package
```

every time — **don't do that**.

Use:

```bash
./mvnw spring-boot:run
```

Maven's normal compile phase checks what's needed and compiles the project as necessary.

For development, you can also use **Spring Boot DevTools** so that changes can trigger automatic restarts:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
</dependency>
```

That gives you a much more IDE-like workflow while staying entirely inside LazyVim.


[[Java]]
[[Vim]]
[[1 - Maven 👻]]