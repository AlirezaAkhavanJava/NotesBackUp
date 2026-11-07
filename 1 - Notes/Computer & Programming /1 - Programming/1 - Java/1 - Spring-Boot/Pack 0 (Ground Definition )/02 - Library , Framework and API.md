


An **API** is a _contract_: a description of what you can call and what you get back. A **library** is a _collection of code_ you call when you need it. A **framework** is a _skeleton_ that calls **your** code at the right moments. These three words live at different levels, which is why they overlap so often. A library or framework always _has_ an API, but an API isn't code you add to your project, it's the rules for using it.

---

## The three, side by side

||API|Library|Framework|
|---|---|---|---|
|What it is|A contract (methods, inputs, outputs)|Reusable code you add|Reusable structure you plug into|
|Who calls whom|You call it|**You call the library**|**The framework calls you**|
|Size of commitment|None; it's just rules|Small; use what you want|Large; shapes your whole app|
|Example|`List.add(x)`, a REST endpoint|Jackson, Apache Commons, Log4j|Spring Boot, Hibernate|

---

## The key idea: who is in control?

**Library: you are in control.**

```java
String json = new ObjectMapper().writeValueAsString(user);  // you decide when
```

You write the program, and when you need JSON, you call Jackson. Jackson never runs unless you ask.

**Framework: the framework is in control.**

```java
@RestController
class UserController {
    @GetMapping("/users")
    List<User> all() { return service.findAll(); }   // Spring calls this
}
```

You never write the code that listens for HTTP requests. Spring Boot does that. You only fill in the _gaps_ (this method, for that URL), and Spring calls you when a request arrives. This flip is called **Inversion of Control**, the same idea you met with beans, and it's often summed up as: _"Don't call us, we'll call you."_

**API: just the contract.** `list.add(x)` is the API of the `List` interface. A REST URL like `GET /users` is an API too. An API doesn't tell you _how_ it works inside, only what to call and what you'll get.

---

## So why is Spring Boot a "framework"?

Because it holds the control. Spring starts the app, creates your objects (beans), wires them together, receives requests, and calls your controllers, services, and filters at the right time. Your code is a set of pieces that Spring assembles and runs. If you removed Spring, your classes would have nothing to start them.

---

## Then why is the "Collections Framework" called a framework?

This one is a naming quirk, and it's a fair thing to question. The Java Collections Framework is built in, you call it directly, and you stay in control: you decide when to `add`, `sort`, or `remove`. By the control test above, it behaves more like a **library**.

It earned the word "framework" for a different reason: it is a **unified architecture**. It gives you a shared set of interfaces (`Collection`, `List`, `Set`, `Map`), several implementations (`ArrayList`, `HashSet`, `HashMap`), and common algorithms (`Collections.sort`), all designed to fit together. You can swap `ArrayList` for `LinkedList` without changing the rest of your code, because everything follows the same contract. People used "framework" there to mean "a well-organized, extensible design," not "the thing that calls your code."

There is a small real overlap, though. When you implement `Comparable` or pass a `Comparator`, `Collections.sort` calls **your** method. That is a tiny taste of inversion of control, just far smaller than Spring's.

So the word has two meanings in practice:

- **Strict meaning (Spring):** it controls the flow and calls your code.
- **Loose meaning (Collections):** a coherent family of interfaces and classes designed to work together.

---

## Where it gets blurry

- Most real tools mix both. Spring Boot is a framework, but inside your controller you also call libraries (Jackson, Lombok).
- Every library and framework exposes an API, so "the Spring API" and "the Jackson API" are both correct phrases.
- Some projects are called "frameworks" mostly for marketing. The control test is the reliable one.

---

## Quick test you can use anywhere

Ask: **"Who decides when my code runs?"**

- _I do_ means a **library**.
- _It does_ means a **framework**.
- _It's just the list of methods and rules_ means an **API**.





[[Spring Framework]]