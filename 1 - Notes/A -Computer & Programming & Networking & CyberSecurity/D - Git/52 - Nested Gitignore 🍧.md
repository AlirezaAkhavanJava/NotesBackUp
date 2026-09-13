
## **1. What is Nested `.gitignore`?**

A **nested `.gitignore`** is simply a `.gitignore` file placed inside a **subdirectory** of your repository. Its rules **apply only to that folder and its children**, not to the entire repo.

Think of it like having **local rules** for a specific part of your project, instead of a global ignore list.

---

## **2. How It Works**

Suppose your project looks like this:

```
/project
    /.gitignore       # global ignore rules
    /frontend
        /.gitignore   # nested ignore rules for frontend
    /backend
        /.gitignore   # nested ignore rules for backend
```

- **Root `.gitignore`** applies to the whole repo.
    
- **Nested `.gitignore`** in `frontend/` applies **only to frontend/**.
    
- Git merges the rules hierarchically:
    
    - First, it checks **nested `.gitignore`** rules in the folder of the file.
        
    - Then, it falls back to the **parent or root `.gitignore`** if no match.
        

---

## **3. Example**

Root `.gitignore`:

```
*.log
node_modules/
```

`frontend/.gitignore`:

```
dist/
*.env
```

Behavior:

- `backend/server.log` → ignored (matches root `*.log`)
    
- `frontend/node_modules/package.json` → ignored (matches root `node_modules/`)
    
- `frontend/dist/bundle.js` → ignored (matches nested `dist/`)
    
- `frontend/.env` → ignored (matches nested `*.env`)
    

---

## **4. Tips**

- Nested `.gitignore` is useful when **different subprojects have different build artifacts** or **env files**.
    
- If a file is already tracked by Git, **nested `.gitignore` cannot untrack it**. Use:
    

```bash
git rm --cached path/to/file
```

- Patterns are **relative to the folder containing the `.gitignore`**.
    

---

In short:

> **Root `.gitignore` = global rules**  
> **Nested `.gitignore` = folder-specific rules**




##### Tags : [[0 - Git 🍋‍🟩]]