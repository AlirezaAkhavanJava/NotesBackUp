
**Prompt engineering** is the skill of writing instructions for an AI model (like Claude) so it reliably produces the output you actually want. A prompt is the input; engineering means designing it deliberately and improving it through testing, not guessing.

**Analogy:** Delegating to a very capable new colleague who knows a huge amount but knows _nothing about your situation_. If you say "make it better," you get a random guess. If you say who the audience is, what the goal is, what format you need, and show one good example, you get what you wanted. The model isn't reading your mind; it only has your words.

## Core idea

A language model predicts a useful response based on **everything in the prompt**. So the quality of the output is bounded by the clarity and context of the input. Vague in, vague out.

**Bad prompt:**

```
Write code for books.
```

**Good prompt:**

```
You are helping a beginner learn Spring Boot.
Write a REST controller for a Book resource (id, title, year)
with GET all, GET by id, and POST endpoints.
Use Java 21, constructor injection, and a record for Book.
Add a short comment above each method explaining what it does.
Return only the code, no extra explanation.
```

The second one states the role, the task, the constraints, and the output format.

## The main techniques

|Technique|What it means|Example|
|---|---|---|
|**Be clear and specific**|Say exactly what you want, including length, tone, format|"Explain in 5 bullet points"|
|**Give context**|Audience, purpose, background|"This is for a junior developer"|
|**Assign a role**|Sets the viewpoint and vocabulary|"Act as a senior code reviewer"|
|**Few-shot examples**|Show 1-3 input/output examples|Show the format you want, then ask for a new one|
|**Step-by-step reasoning**|Ask it to think before answering|"Work through this step by step"|
|**Structure with delimiters**|Separate instructions from data|Use `<code>...</code>` or triple backticks|
|**Specify the output format**|JSON, table, markdown|"Reply as JSON with keys `name`, `age`"|
|**Iterate**|Treat the first answer as a draft|"Shorter, and remove the jargon"|

## Few-shot example

```
Convert each sentence to a REST endpoint.

Sentence: "Get all users"
Endpoint: GET /users

Sentence: "Delete order number 7"
Endpoint: DELETE /orders/7

Sentence: "Create a new book"
Endpoint:
```

The examples teach the pattern better than a paragraph of explanation.

## Using it from code

When you build apps on top of an AI model, prompts become part of your program. Typically there are two parts: a **system prompt** (permanent rules and role) and a **user message** (the specific request).

```java
// Conceptual example: a request to an AI API
String systemPrompt = "You are a helpful assistant that answers only about Java.";
String userMessage  = "What is a record?";
// Both are sent to the API, which returns the model's reply as JSON.
```

This connects to what you learned earlier: it is just an HTTP call to a REST API, with the prompt inside the JSON body.

## Prompt engineering for coding (useful for you now)

- State your **versions and stack** ("Java 21, Spring Boot 3, Maven, Debian 13").
- Paste the **full error message**, not a description of it.
- Say what you **already tried**.
- Ask for **explanations, not just code**, so you learn instead of copy-pasting.
- Ask the model to **review its own answer** or list edge cases.

## Gotchas

- **It is not magic wording.** Old tricks like "take a deep breath" matter far less on modern models; clarity and context matter most.
- **Longer is not always better.** Include what is _relevant_; padding dilutes the instruction.
- **Models can be confidently wrong** (hallucination). Always verify code by running it and facts by checking sources.
- **Never put secrets in prompts** (API keys, passwords, private data), since prompts may be logged or sent to third parties.
- **Prompt injection:** if your app feeds untrusted text (a user's email, a web page) into a prompt, that text can contain hidden instructions that hijack the model. This is the AI equivalent of SQL injection, and it is why untrusted input must be treated carefully, just as in the security lesson.
- **Outputs vary:** the same prompt can give different answers each run, so test a prompt several times before trusting it.


[[Ai]]
[[Computer & Programming]]
[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]