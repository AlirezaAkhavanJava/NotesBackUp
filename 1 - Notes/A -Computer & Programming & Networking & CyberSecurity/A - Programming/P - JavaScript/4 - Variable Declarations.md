
**JavaScript variable declarations** define _how a name is bound to a value_ and _how long that binding lives_. There are only **three**, and they are not equals.

---

### `var` — legacy, leaky, dangerous

- **Function-scoped** (ignores blocks)
    
- **Hoisted** and initialized to `undefined`
    
- **Redeclarable**
    
- Causes silent bugs
    

```js
var x = 1;
var x = 2; // allowed ❌

if (true) {
  var y = 10;
}
console.log(y); // 10 (leaked)
```

Use today: **never** (except legacy code).

---

### `let` — modern, controlled

- **Block-scoped**
    
- Hoisted but in **Temporal Dead Zone**
    
- **Reassignable**
    
- No redeclaration in same scope
    

```js
let count = 1;
count = 2;

if (true) {
  let a = 5;
}
// a ❌
```

Use when:

- Value **must change**
    
- Loop variables, counters, mutable state
    

---

### `const` — modern, safest default

- **Block-scoped**
    
- Must be initialized
    
- **Not reassignable**
    
- Objects/arrays are still mutable
    

```js
const nums = [1, 2];
nums.push(3); // ok
nums = [];    // ❌
```

Use when:

- Value should **never be rebound**
    
- Configs, functions, imports, references
    

---

### Scope comparison (truth table)

```js
{
  var   a = 1; // function scope
  let   b = 2; // block scope
  const c = 3; // block scope
}
```

---

### The only rule you need

- **Default → `const`**
    
- **Need reassignment → `let`**
    
- **`var` → don’t**
    

JavaScript doesn’t stop you from doing dumb things.  
These rules stop you from _accidentally_ doing them.

##### Tags : [[1 - JavaScript]]