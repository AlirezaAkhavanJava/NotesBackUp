**Semver** (Semantic Versioning) is a standard for versioning software so you can tell the type of changes just by looking at the version number. It’s structured as:

```
MAJOR.MINOR.PATCH
```

It's kinda weird to just name tags any old thing. We're developers, we like structure, sameness, and sometimes even bike-shedding.

["Semver"](https://semver.org/), or "Semantic Versioning", is a naming convention for versioning software. You've probably seen it around, it looks like this:


![[Pasted image 20251119164826.png]]

---

### 1. MAJOR version

- Incremented when you make **incompatible API changes**.
    
- Example: `1.4.2 → 2.0.0`
    
- Signals that users may need to change their code to adapt.
    

---

### 2. MINOR version

- Incremented when you add **backward-compatible features**.
    
- Example: `1.4.2 → 1.5.0`
    
- Existing code should still work without changes.
    

---

### 3. PATCH version

- Incremented for **backward-compatible bug fixes**.
    
- Example: `1.4.2 → 1.4.3`
    
- No new features, just fixes.
    

---

### Optional labels

- Pre-release: `1.4.0-alpha.1`, `1.4.0-beta.2`
    
- Build metadata: `1.4.0+20231119`
    

---

💡 Rule of thumb:

- **MAJOR** → breaks stuff
    
- **MINOR** → adds stuff
    
- **PATCH** → fixes stuff
    



###### Tags : [[0 - Git 🍋‍🟩]]