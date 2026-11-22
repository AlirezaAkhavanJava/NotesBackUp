
JavaScript is a dynamically typed, prototype-based scripting language originally built to make web pages interactive, but it has since grown into a general-purpose language that runs almost everywhere: in browsers, on servers (via Node.js), on mobile apps, and even on microcontrollers. Where Java is compiled ahead of time, statically typed, and runs on the JVM, JavaScript is interpreted (today, usually JIT-compiled) at runtime by an engine like V8 (Chrome, Node.js) or SpiderMonkey (Firefox), and it checks types as the program runs rather than before it runs. That single difference — static vs dynamic typing, checked at compile time vs runtime — is the root of a lot of what makes JavaScript feel so different from Java day to day.

It was created in 1995 by Brendan Eich in about ten days for Netscape Navigator, which explains some of its famously odd design quirks (type coercion rules, `==` vs `===`, and so on — more on that below). Despite the name, it has no real relationship to Java; the name was a marketing decision at the time.

## Variables and dynamic typing

In Java, a variable's type is fixed at declaration and enforced by the compiler:

```java
int count = 5;
count = "five"; // compile error
```

In JavaScript, a variable is just a named reference — it can hold any type, and that can change:

```javascript
let count = 5;
count = "five"; // totally legal
```

Declaration keywords: `let` and `const` (modern, block-scoped) and the older `var` (function-scoped, mostly avoided in new code). `const` means the _binding_ can't be reassigned — not that the value is immutable:

```javascript
const arr = [1, 2, 3];
arr.push(4);     // fine — mutating the array, not reassigning arr
arr = [5, 6];    // error — arr itself can't be reassigned
```

Because types aren't checked until runtime, JavaScript will often try to _coerce_ values rather than fail — this is one of its most notorious behaviors:

```javascript
console.log(1 + "1");    // "11"  — number coerced to string, then concatenated
console.log(1 == "1");   // true  — loose equality coerces types before comparing
console.log(1 === "1");  // false — strict equality checks type AND value, no coercion
```

As a rule of thumb: always prefer `===` and `!==` over `==` and `!=`, unless you deliberately want coercion.

## Functions are first-class values

This is a bigger conceptual shift coming from Java than it might look. In JavaScript, a function is a value, just like a number or a string — you can store it in a variable, pass it as an argument, or return it from another function.

```javascript
function greet(name) {
    return "Hello, " + name;
}

const sayHi = greet;          // storing a function in a variable
console.log(sayHi("Ethan"));  // "Hello, Ethan"

function applyTwice(fn, value) {
    return fn(fn(value));
}
console.log(applyTwice(x => x * 2, 3)); // 12
```

That `x => x * 2` is an **arrow function** — a compact anonymous function syntax, roughly analogous to a Java lambda (`x -> x * 2`), but usable anywhere an ordinary function could go, not just where a functional interface is expected.

## Objects and prototype-based "OOP"

This is probably the single biggest structural difference from Java. Java's object model is **class-based**: a class is a blueprint, and objects are instances of it, with inheritance resolved through a fixed class hierarchy decided at compile time. JavaScript's object model is **prototype-based**: every object has an internal link to another object (its _prototype_), and when you access a property that isn't found on the object itself, the engine walks up the prototype chain looking for it.

```javascript
const animal = {
    speak() { return "..."; }
};

const dog = Object.create(animal); // dog's prototype is animal
dog.speak = function() { return "Woof"; };

console.log(dog.speak());      // "Woof" — found directly on dog
console.log(dog.toString);     // found further up the prototype chain
```

Modern JavaScript added `class` syntax, which looks like Java but is really just a cleaner way of writing the same prototype mechanics underneath:

```javascript
class Animal {
    speak() { return "..."; }
}

class Dog extends Animal {
    speak() { return "Woof"; }
}

console.log(new Dog().speak()); // "Woof"
```

So `class` and `extends` exist and read very familiarly if you're coming from Java — just know that under the hood, it's prototype delegation, not a separate inheritance mechanism, and `extends Animal` really means "Dog's prototype chain includes Animal."

## Asynchronous execution — the event loop

This is the feature that most distinguishes JavaScript from Java in practice, especially given your experience with Java's `Thread`/`ExecutorService` model. JavaScript (in both the browser and Node.js) is **single-threaded** — there's one call stack, and only one piece of your JS code runs at any given instant. There's no `Thread` class, no `synchronized`, no race conditions between two pieces of _your_ JS code.

So how does it handle slow operations like network requests or file reads without freezing everything? Through the **event loop**: slow operations are handed off to the runtime (the browser or Node's C++ layer), and when they finish, a callback is queued to run later, once the call stack is empty.

```javascript
console.log("1");

setTimeout(() => {
    console.log("2");
}, 0);

console.log("3");

// Output: 1, 3, 2
// Even with a 0ms delay, the callback waits for the current
// call stack to finish before it can run.
```

Early async code used nested callbacks, which got messy ("callback hell"). The modern solution is the **Promise** — an object representing a value that will eventually be available — and `async`/`await`, which lets asynchronous code be written with the visual shape of synchronous code:

```javascript
async function getUser(id) {
    const response = await fetch(`/api/users/${id}`); // pauses here without blocking the thread
    const user = await response.json();
    return user;
}
```

`await` doesn't block the single thread the way a Java thread might block on I/O — it suspends just that function, lets the event loop keep handling other work, and resumes the function once the awaited Promise resolves.

## Where it runs

- **Browser**: the original home of JavaScript, where it manipulates the DOM (the page's structure) to make pages interactive, handles user events (clicks, input), and talks to servers.
- **Node.js**: a runtime built on Chrome's V8 engine that lets JavaScript run outside the browser — on a server, in a CLI tool, anywhere. This is what let JavaScript become a full backend language (its rough equivalent to you writing a Spring Boot backend in Java).

## A related concept, briefly: TypeScript

TypeScript is a superset of JavaScript that adds a static type system on top — closer to what you're used to from Java. You write TypeScript, declare types, and a compiler checks them and then compiles the code down to plain JavaScript before it runs anywhere. It doesn't change JavaScript's runtime behavior at all; it only adds compile-time safety on top of it.


[[Computer Science]]