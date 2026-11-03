

A contract is an agreement about how two parties interact: what each side promises, what each expects, and what happens when something goes wrong. In software it's usually not legally enforceable, but tests, types, and schemas enforce it. Whenever someone says "an API is a contract," this is what they mean.

---

## The problem it solves

Imagine a frontend team and a backend team working without a contract. The frontend guesses the response shape and the backend changes a field name on Friday. The app breaks and everyone argues over who was wrong. A contract makes the expectations explicit, so there's a single source of truth to check against.

---

## The deck analogy

You hire a contractor to build a deck: 10x12 feet, pressure-treated wood, $5,000, and if it's wrong, they fix it for free. The contract doesn't say which saw they use or what music they play.

**A contract says _what_, never _how_.** The "how" is the implementation, and it's private.

---

## What's inside a contract

|Part|Question it answers|
|---|---|
|Inputs|What can I send?|
|Outputs|What will I get back?|
|Preconditions|What must be true _before_ the call?|
|Postconditions|What will be true _after_?|
|Invariants|What never changes?|
|Errors|What can go wrong, and how is it signaled?|
|Guarantees|Timing, ordering, idempotency, caching|
|Versioning|How are changes announced?|

---

## Two examples

**A function:**

```python
def divide(a: float, b: float) -> float: ...
```

- Precondition: `b != 0`
- Postcondition: returns `a / b`
- Error: `ZeroDivisionError` if `b == 0`

**An API endpoint:** `GET /users/{id}`

- Needs `Authorization: Bearer <token>`
- `200` returns `{ id, name, email }`
- `404` means user not found, `401` means bad or missing token
- Response is cacheable for 60 seconds

The server could use Postgres, MongoDB, or a text file. The client never knows or cares.

---

## The key rule: contract vs. implementation

- **Contract** = public and stable
- **Implementation** = private and free to change

Change the implementation and nobody notices. Change the contract and you may break every client.

|Breaking change|Safe change|
|---|---|
|Remove a response field|Add an optional response field|
|Change a type (`int` to `string`)|Add a new endpoint|
|Rename an endpoint|Add an optional request parameter|
|Change a status code||
|Make an optional parameter required||

A good way to remember this: _removing or changing breaks things, adding doesn't._

---

## How formal can a contract be?

- **Informal:** READMEs, Slack messages
- **Semi-formal:** types, docstrings
- **Formal:** OpenAPI, JSON Schema, Protobuf, GraphQL SDL, Pact

Formal contracts are machine-readable, so tools can generate docs, client SDKs, mock servers, tests, and server stubs from them. That enables **contract-first development**: write the contract first, then both teams build against it in parallel.

---

## Related idea: Design by Contract

Bertrand Meyer created this method for the Eiffel language. Each function has preconditions, postconditions, and invariants, and blame is clear:

- Precondition violated → **caller's bug**
- Postcondition violated → **function's bug**

---

## Why it matters (in one glance)

Teams work independently, frontend and backend can build in parallel against a mock, you can test that an implementation honors the contract, you can predict what breaks clients, and you can swap implementations freely.

---

## Don't confuse it with

- **Smart contracts** (blockchain): self-executing programs, a different thing
- **Legal contracts**: enforceable between people or companies

---

**One-line summary:** a contract is the public promise at the boundary between two pieces of software, and the implementation behind it can change freely as long as the promise holds.




[[Spring Framework]]
