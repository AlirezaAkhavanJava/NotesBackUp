

## The simple definition

A **contract** is an agreement between two parties about how they will interact. It says:

- What each side promises to provide
- What each side expects to receive
- What rules must be followed
- What happens when something goes wrong

In law, a contract is enforceable. In software, a contract is a **precise, shared set of expectations** — usually not legally enforceable, but technically enforceable through tests, types, schemas, and tooling.

## The legal analogy

A legal contract between a company and a contractor might say:

- **You (contractor)** will build a deck.
- **I (client)** will pay you $5,000.
- The deck will be 10x12 feet, using pressure-treated wood.
- If it rains, the deadline extends by one day.
- If the deck is the wrong size, you fix it for free.

Notice it doesn't say *how* you build the deck — what tools, what brand of saw, what music you listen to. It only specifies the **interface** and the **behavior**.

A software contract works the same way. It says *what* will happen, not *how* it will be done internally.

## What a software contract contains

Depending on the context, a contract can include:

- **Inputs** — what data is accepted, and in what format
- **Outputs** — what data is returned, and in what format
- **Preconditions** — what must be true before the call
- **Postconditions** — what will be true after the call
- **Invariants** — what never changes
- **Errors** — what can go wrong and how it's signaled
- **Guarantees** — timing, ordering, idempotency, consistency
- **Versioning** — how changes will be communicated

## A function contract

```python
def divide(a: float, b: float) -> float:
    ...
```

The contract might be:

- **Precondition:** `a` and `b` are numbers.
- **Precondition:** `b != 0`.
- **Postcondition:** returns `a / b`.
- **Error:** raises `ZeroDivisionError` if `b == 0`.
- **Guarantee:** does not modify its inputs.

The implementation could use a CPU, a GPU, a lookup table, or a quantum computer. As long as it honors the contract, callers don't care.

## An API contract

In the REST context, the contract for an endpoint might be:

```
GET /users/{id}
```

- **Request:** `id` is an integer in the path.
- **Auth:** requires `Authorization: Bearer <token>`.
- **Success 200:** returns JSON `{ "id": int, "name": string, "email": string }`.
- **Error 404:** if no user exists, returns `{ "error": "User not found" }`.
- **Error 401:** if the token is missing or invalid.
- **Guarantee:** the response is cacheable for 60 seconds.

That's the contract. The server might store users in Postgres, MongoDB, or a text file. The client doesn't know and doesn't need to know.

## Formal vs. informal contracts

Contracts exist on a spectrum:

| Type | Examples |
|------|----------|
| **Informal** | README docs, wiki pages, verbal agreements, Slack messages |
| **Semi-formal** | TypeScript types, docstrings, comments |
| **Formal** | OpenAPI/Swagger, JSON Schema, Protobuf, GraphQL SDL, WSDL, Pact |

Formal contracts are powerful because machines can read them. From an OpenAPI spec, you can automatically generate:

- Documentation
- Client SDKs
- Mock servers
- Validation tests
- Server stubs

That's why "contract-first" development is popular: you write the contract, then both teams build against it in parallel.

## Contract vs. implementation

This is the most important distinction:

- **Contract** = the promise, the interface, the behavior. Public and stable.
- **Implementation** = the code, the database, the algorithms. Private and changeable.

If you change the implementation but keep the contract, nobody notices. If you change the contract, you risk breaking every client — that's a **breaking change**.

Examples of breaking changes in a REST API:

- Removing a field from a response
- Changing a field's type (`int` → `string`)
- Renaming an endpoint
- Changing a status code
- Making an optional parameter required

Examples of non-breaking changes:

- Adding a new optional field to a response
- Adding a new endpoint
- Adding a new optional request parameter

## Design by Contract

There's a formal programming methodology called **Design by Contract**, invented by Bertrand Meyer for the Eiffel language. It treats every function as a contract with:

- **Preconditions** — what the caller must guarantee
- **Postconditions** — what the function must guarantee
- **Invariants** — what the object must always satisfy

If a precondition is violated, it's the caller's bug. If a postcondition is violated, it's the function's bug. This makes responsibility explicit.

## Why contracts matter

1. **Decoupling** — Teams can work independently.
2. **Parallel development** — Frontend and backend can start at the same time using a mock.
3. **Testing** — You can verify that an implementation honors its contract.
4. **Compatibility** — You can reason about what will break clients.
5. **Communication** — A single source of truth beats a thousand Slack messages.
6. **Replaceability** — You can swap out implementations without rewriting callers.

## A note on other meanings

- **Smart contracts** (blockchain) are a different thing: self-executing code on a blockchain. They're called "contracts" but they're really programs.
- **Legal contracts** are enforceable agreements between people or companies.

In software and APIs, "contract" almost always means the **interface and behavioral agreement** between two pieces of software.

## TL;DR

A contract is an agreement about how two parties will interact. In software, it specifies inputs, outputs, behavior, errors, and guarantees — without revealing the implementation. When I said "an API is a contract," I meant: the client promises to send valid requests, the server promises to respond in a defined way, and neither needs to know the other's internals. The contract is the boundary.



[[Spring Framework]]