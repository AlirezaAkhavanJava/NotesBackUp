
JavaScript has **dynamic typing**. Variables don’t have fixed types; values do.

### Variables

Three ways to declare variables:

- **`let`** → block-scoped, reassignable (modern default)
    
- **`const`** → block-scoped, NOT reassignable (use whenever possible)
    
- **`var`** → function-scoped, legacy, avoid it
    

```js
let age = 25;
const name = "Ethan";
// name = "Alex"; ❌ error
```

---

### Primitive Data Types (7)

Stored by value, immutable.

- **`number`** → integers & floats
    
    ```js
    let x = 10.5;
    ```
    
- **`string`** → text
    
    ```js
    let s = "hello";
    ```
    
- **`boolean`** → true / false
    
    ```js
    let ok = true;
    ```
    
- **`undefined`** → declared but not assigned
    
    ```js
    let a;
    ```
    
- **`null`** → intentional empty value
    
    ```js
    let b = null;
    ```
    
- **`symbol`** → unique identifiers (advanced)
    
- **`bigint`** → very large integers
    
    ```js
    let big = 123n;
    ```
    

---

### Reference Data Types (Objects)

Stored by reference, mutable.

- **Object**
    
- **Array**
    
- **Function**
    
- **Date**, **Map**, **Set**, etc.
    

```js
let user = { name: "Ethan" };
let nums = [1, 2, 3];
function add(a, b) { return a + b; }
```

---

### Type Checking

```js
typeof 10        // "number"
typeof "hi"      // "string"
typeof null      // "object"  ← historical bug
Array.isArray([]) // true
```

---

### Key Truths (no sugarcoating)

- JS will **coerce types** unless you stop it.
    
- `==` compares loosely (dangerous).
    
- `===` compares strictly (use this).
    

```js
"5" == 5   // true ❌
"5" === 5  // false ✅
```

JavaScript is flexible, not forgiving. Discipline beats magic every time.


##### Tags :[[1 - JavaScript]]