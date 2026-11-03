

An API (Application Programming Interface) is the way one piece of software asks another piece of software to do something. It's the boundary where your code meets someone else's code. Everything else about APIs (REST, GraphQL, SDKs) is just a style or tool built on that idea.

---

## The problem it solves

Without APIs, to use someone else's service you'd have to understand their internals: their database, their code, their servers. Every change on their side would break you. An API gives you a simple, stable way to say "do this" without knowing _how_ it gets done.

---

## The restaurant analogy

|Restaurant|Software|
|---|---|
|Menu|**The API**: what you can ask for and what you'll get|
|Waiter|The communication layer (HTTP, function call)|
|Kitchen|The implementation: hidden, changeable|

You never enter the kitchen. You order from the menu. The kitchen can change recipes or ovens and you won't notice, as long as the menu works the same.

---

## Breaking down the name

- **Application**: a program or service
- **Programming**: used by _code_, not humans
- **Interface**: the meeting point between two things

---

## Where you already use APIs

- **Language:** `len("hello")` returns `5`
- **Operating system:** open a file, allocate memory
- **Web:** `GET https://api.github.com/users/octocat` returns JSON
- **Hardware:** a camera driver exposes `take_photo()`
- **Third-party:** Stripe (payments), Twilio (SMS), Google Maps

---

## What an API defines

Operations, inputs, outputs, formats (JSON, XML), errors, and rules (auth, rate limits, versioning). That's why an API is a **contract**: _"Send me X in this format, and I promise Y, or error Z."_

---

## How a web API works

1. **Client sends a request:** `GET /users/42`
2. **Server processes it:** finds the user, checks permissions
3. **Server responds:** `200 OK` with `{ "id": 42, "name": "Ada" }`

The client never learns whether the server uses Postgres, MongoDB, or a spreadsheet.

---

## Two distinctions worth remembering

**API vs. UI:** same service, two doors. The UI is for humans (buttons, screens). The API is for code (endpoints, data formats).

**API vs. implementation:** the API is the public, stable promise. The implementation is private and replaceable. Swap the database but keep the API, and every client keeps working.

---

## Why APIs matter

Abstraction (hide complexity), reusability (build once, use everywhere), modularity (swap parts), collaboration (teams work against a shared contract), security (expose only what's needed), and ecosystems (others can build on your platform).

---

**One-line summary:** an API is a menu for software: it says what you can order and what you'll get, while the kitchen stays hidden.

[[Spring Framework]]
[[API]]