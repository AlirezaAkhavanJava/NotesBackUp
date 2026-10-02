JavaScript (officially standardized as ECMAScript) is a versatile, high-level programming language with syntax influenced by C, Java, and other languages. As of December 2025, the current version is **ECMAScript 2025** (the 16th edition), which includes modern features like improved iterators, new Set methods, regex enhancements, and more.

### Basic Syntax Rules
- **Case-sensitive** — Keywords, variables, and identifiers are case-sensitive (e.g., `let` ≠ `Let`).
- **Statements** — End with semicolons (`;`), though Automatic Semicolon Insertion (ASI) often allows omission.
- **Comments**:
  - Single-line: `// Comment`
  - Multi-line: `/* Comment */`
- **Whitespace and line breaks** — Generally ignored, except for separating tokens.
- **Identifiers** — Variable/function names start with a letter, `_`, or `$`, followed by letters, digits, `_`, or `$`. No keywords allowed.

### Variables and Declarations
Use `let`, `const`, or `var` (avoid `var` in modern code due to scoping issues).

```javascript
let mutableVar = 42;      // Block-scoped, reassignable
const constant = "hello"; // Block-scoped, not reassignable
var oldStyle = true;      // Function-scoped (legacy)
```

### Data Types (Primitives)
- Number: `42`, `3.14`
- BigInt: `9007199254740991n`
- String: `"hello"` or `'world'` or `` `template ${expr}` ``
- Boolean: `true` / `false`
- Undefined: `undefined`
- Null: `null`
- Symbol: `Symbol('unique')`

Objects (non-primitive): `{ key: 'value' }`, arrays `[1, 2, 3]`, functions, etc.

### Operators
- Arithmetic: `+ - * / % **`
- Comparison: `==` (loose), `===` (strict), `!=`, `!==`, `>`, `<`, etc.
- Logical: `&& || ! ??` (nullish coalescing)
- Optional chaining: `obj?.prop?.()`
- Nullish coalescing: `value ?? default`

### Control Structures
```javascript
if (condition) {
  // code
} else if (another) {
  // code
} else {
  // code
}

switch (expr) {
  case 'value':
    // code
    break;
  default:
    // code
}

for (let i = 0; i < 10; i++) { /* loop */ }

for (let item of iterable) { /* iterate */ }

while (condition) { /* loop */ }

do { /* code */ } while (condition);
```

### Functions
```javascript
function named(param1, param2 = 'default') {
  return param1 + param2;
}

const arrow = (x) => x * 2;  // Concise arrow function

// Async
async function fetchData() {
  const data = await promise;
  return data;
}
```

### Objects and Arrays
```javascript
const obj = { key: 'value', method() { return this.key; } };

const arr = [1, 2, 3];
const [a, b] = arr;  // Destructuring
const { key } = obj;

arr.map(item => item * 2);
```

### Modern Features (ES2015+ / ECMAScript 2025)
- Classes: `class MyClass { constructor() {} method() {} }`
- Promises: `new Promise((resolve, reject) => ...)`
- Modules: `import { thing } from './module.js'; export default func;`
- Spread/Rest: `const newArr = [...oldArr, 4]; function func(...args) {}`
- New in ES2025: Enhanced iterators (e.g., `Iterator.from()`), Set operations (`set.union(otherSet)`), regex improvements (e.g., subexpression modifiers), `Float16Array`, etc.

For the most detailed and up-to-date reference, check the official MDN Web Docs: [JavaScript Reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference).

This covers the core syntax—JavaScript is flexible and dynamic, so practice with examples! If you have a specific aspect (e.g., async/await, regex), let me know for more details.


[[0 - Back-End]]