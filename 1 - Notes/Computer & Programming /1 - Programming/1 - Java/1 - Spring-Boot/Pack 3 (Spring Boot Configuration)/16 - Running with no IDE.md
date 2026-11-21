


With Maven you never compile files by hand. `./mvnw spring-boot:run` compiles whatever needs compiling and then starts your app. You can do all of it from inside LazyVim, with no `javac` and no separate IDE.

---

## 1. Run it

From the project root:

```bash
./mvnw spring-boot:run
```

If Maven is installed globally, `mvn spring-boot:run` does the same thing. Use `./mvnw` when the project has the wrapper, because it pins the Maven version for you.

You don't need `mvn clean package` for day-to-day work. `spring-boot:run` already runs the `compile` phase first, and Maven's compiler plugin detects changes and skips compiling when nothing changed. Use `mvn clean` only when you suspect stale files in `target/`.

---

## 2. Run it inside LazyVim

```bash
cd /path/to/project
nvim .
```

Open the built-in terminal with `Ctrl + /` and run `./mvnw spring-boot:run` there. The app keeps running in that terminal. Press `Ctrl + /` again to hide it, and `Ctrl + C` inside it to stop the app.

---

## 3. Optional: a keyboard shortcut

Add this to `~/.config/nvim/lua/config/keymaps.lua`, which is where LazyVim expects your own keymaps:

```lua
vim.keymap.set("n", "<leader>mr", function()
  vim.cmd("split | terminal ./mvnw spring-boot:run")
end, { desc = "Run Spring Boot" })
```

Press `<leader>mr` (Space, then `m`, then `r`) and a split opens running your app. The terminal starts in normal mode, so press `i` if you want to type in it.

The command runs in Neovim's current directory, so open `nvim` from the project root.

---

## 4. Optional: auto-restart with DevTools

Add Spring Boot DevTools:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

DevTools restarts the app when compiled classes in `target/classes` change. Neovim doesn't compile on save the way an IDE does, so saving a file isn't enough. Keep a second terminal and run this after you save:

```bash
./mvnw compile
```

DevTools sees the new classes and restarts the app quickly. Because the restart reloads only your own classes, it is usually much faster than a full `spring-boot:run`.






[[Spring Framework]]