
Zsh prompt isn’t configured to show your username or the full path. By default, Zsh just shows a simple `%` prompt unless you customize it. Here’s how to fix it:

1. **Edit your Zsh config**:
    

```bash
nano ~/.zshrc
```

2. **Set a nicer prompt** by adding this line at the end:
    

```bash
export PROMPT="%n@%m:%~%# "
```

Explanation:

- `%n` → your username (`ethan`)
    
- `%m` → hostname (`debian`)
    
- `%~` → current directory, shortened (`~/Downloads`)
    
- `%#` → `#` if root, `%` if normal user
    

3. **Apply changes**:
    

```bash
source ~/.zshrc
```

Now your prompt should look like:

```bash
ethan@debian:~/Downloads%
```

---

If you want **full absolute path** instead of `~/Downloads`, use `%d` instead of `%~`:

```bash
export PROMPT="%n@%m:%d%# "
```

---

[[2 - Core-concepts/Linux|Linux]]