
**Hoisting** in JavaScript is a behavior where the JavaScript engine processes variable and function declarations during the compilation phase, making them available in their scope before the code is executed line-by-line. This gives the appearance that declarations are "moved" to the top of their scope (global or function/block), though in reality, they are allocated in memory early.

It's important to note that **only declarations are hoisted**, not initializations (assignments).

### Function Hoisting
- **Function declarations** are fully hoisted (both the name and the function body). You can call them before they appear in the code.

```javascript
sayHello(); // Works: "Hello!"

function sayHello() {
  console.log("Hello!");
}
```

- **Function expressions** (including arrow functions) are **not** hoisted in the same way. The variable is hoisted (if using `var`), but the assignment (the function) happens at runtime.

```javascript
sayHi(); // TypeError: sayHi is not a function (or undefined if var)

var sayHi = function() {
  console.log("Hi!");
};
```

### Variable Hoisting
- **`var`**: Declarations are hoisted and initialized with `undefined`.

```javascript
console.log(x); // undefined
var x = 5;
console.log(x); // 5
```

Equivalent to:
```javascript
var x; // hoisted
console.log(x); // undefined
x = 5;
```

- **`let` and `const`**: Declarations are hoisted but **not initialized**. Accessing them before the declaration line throws a **ReferenceError** due to the **Temporal Dead Zone (TDZ)**.

```javascript
console.log(y); // ReferenceError: Cannot access 'y' before initialization
let y = 10;
```

```javascript
console.log(z); // ReferenceError
const z = 20;
```

Classes are treated similarly to `let/const`: hoisted but in TDZ.

### Key Points and Best Practices
- Hoisting applies to the containing scope (function or block for `let/const`).
- It can lead to bugs if misunderstood (e.g., unexpected `undefined` with `var`).
- Modern JavaScript favors `let` and `const` over `var` to avoid hoisting pitfalls, thanks to block scoping and TDZ enforcing stricter declaration order.
- Always declare variables at the top of their scope to make intent clear.

This behavior stems from JavaScript's two-phase execution: creation/compilation (where hoisting occurs) followed by execution. For the latest details (as of 2025), refer to sources like MDN Web Docs.

##### Tags : [[1 - JavaScript]]