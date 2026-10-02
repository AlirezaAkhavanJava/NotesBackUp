
An **API** is a set of rules that lets one piece of software talk to another. The acronym stands for **Application Programming Interface**.

Let's unpack that:

- **Application** — a program or service.
- **Programming** — it's used by code, not directly by humans.
- **Interface** — a boundary where two things meet and interact.

So an API is the **interface** through which your code interacts with someone else's code.

## The core idea: a menu, not a kitchen

Think of a restaurant. You don't walk into the kitchen and start cooking. You look at a **menu**, choose an item, tell the waiter, and receive your food.

- The **menu** is the API. It lists what you can ask for and what you'll get.
- The **waiter** is the communication layer.
- The **kitchen** is the implementation — the internals you never see.

You don't need to know the recipes, the oven temperature, or the brand of pans. You just need to know how to order. That's what an API gives you: a stable, simple way to request something without knowing how it's done.

## APIs are everywhere

You've already used APIs, probably today:

- **Language APIs** — `len("hello")` in Python returns `5`. You don't know how it counts characters; you just call it.
- **Operating system APIs** — opening a file, allocating memory, drawing a window.
- **Web APIs** — `GET https://api.github.com/users/octocat` returns JSON about a GitHub user.
- **Hardware APIs** — a camera driver exposes functions like `take_photo()`.
- **Third-party APIs** — Stripe for payments, Twilio for SMS, Google Maps for directions.

## What an API defines

A well-designed API specifies:

- **Operations** — what you can do (functions, methods, endpoints)
- **Inputs** — what data you must provide
- **Outputs** — what data you'll get back
- **Formats** — JSON, XML, binary, etc.
- **Errors** — what can go wrong and how it's signaled
- **Rules** — authentication, rate limits, versioning

In other words, an API is a **contract**: "If you send me X in this format, I promise to return Y or an error Z."

## How a web API works

Most modern web APIs use HTTP. The pattern is always:

1. **Client sends a request** — e.g., `GET /users/42`
2. **Server processes it** — looks up the user, checks permissions
3. **Server sends a response** — e.g., `200 OK` with JSON `{ "id": 42, "name": "Ada" }`

The client doesn't know if the server uses Postgres, MongoDB, or a spreadsheet. It only sees the API.

## API vs. UI

- **UI (User Interface)** is for humans: buttons, screens, gestures.
- **API (Application Programming Interface)** is for code: functions, endpoints, data formats.

Same underlying service, two different doors.

## API vs. implementation

- The **API** is the public promise — stable, documented, versioned.
- The **implementation** is the private machinery — changeable, hidden, replaceable.

If you swap the database but keep the API the same, every client keeps working. That's the power of separating them.

## Why APIs matter

1. **Abstraction** — hide complexity.
2. **Reusability** — build once, use everywhere.
3. **Modularity** — swap parts without rewriting everything.
4. **Collaboration** — teams can work independently against a shared contract.
5. **Security** — expose only what's necessary.
6. **Ecosystems** — third parties can build on your platform.

## TL;DR

An API is a defined way for software to interact. It's a contract that says what you can ask for, how to ask, and what you'll get back — without revealing how it works inside. Web APIs do this over HTTP, usually with JSON. Everything else — REST, GraphQL, SDKs — is just a style or tool for building and using APIs.



[[0 - Spring Framework]]