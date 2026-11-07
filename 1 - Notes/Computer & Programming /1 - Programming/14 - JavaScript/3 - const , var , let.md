

### `var`

Old JavaScript. Mostly a historical artifact.

- **Function-scoped**, not block-scoped
    
- **Hoisted** and initialized to `undefined`
    
- Can be **redeclared** (this is bad)
    

```js
if (true) {
  var x = 10;
}
console.log(x); // 10  ← leaked out
```

Use case:  
**None** in modern code. Only when reading legacy code or forced by ancient environments.

---

### `let`

Modern, sane variable.

- **Block-scoped**
    
- Hoisted but in **Temporal Dead Zone** (cannot be used before declaration)
    
- **Reassignable**
    
- Cannot be redeclared in same scope
    

```js
let count = 1;
count = 2; // ok

if (true) {
  let y = 5;
}
// y ❌ not defined
```

Use when:

- Value **will change**
    
- Loop counters, state, reassigned variables
    

---

### `const`

Same scope rules as `let`, but stricter.

- **Block-scoped**
    
- **Must be initialized**
    
- **Cannot be reassigned**
    
- Objects/arrays are still **mutable**
    

```js
const user = { name: "Ethan" };
user.name = "Alex"; // ok
user = {}; // ❌ error
```

Use when:

- Value **should not be reassigned**
    
- Defaults, configs, functions, imports
    
- **This should be your default choice**
    

---

### Real Rule (this matters)

1. Use **`const` by default**
    
2. Switch to **`let` only if reassignment is required**
    
3. **Never use `var`** unless trapped in legacy code
    

This rule prevents bugs before they exist.  
JavaScript rewards discipline and punishes laziness.



###### tags : [[1 - JavaScript]]