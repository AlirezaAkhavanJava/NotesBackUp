

Here's the core idea: separate **depth** from **clarity**. Most people conflate "explain simply" with "explain shallowly," which makes the AI skip details. You want the opposite — full depth, delivered through good scaffolding (analogies, structure, progressive complexity), not through omission.

## A prompt template that works

```
Teach me [topic/concept] at an advanced/intermediate level. Requirements:

1. Don't oversimplify or skip details — I want the real depth,
   including edge cases, "why it works this way," and how it
   connects to related concepts.
2. But make it maximally clear: use analogies, concrete examples,
   and build from a mental model before diving into mechanics.
3. Structure it progressively: start with the core intuition,
   then formal/technical detail, then nuances/gotchas/advanced use.
4. Use code examples where relevant (I'm learning Java/Spring Boot).
5. At the end, give me 1-2 questions to test if I actually
   understood it, not just recognized it.
```

## Why each piece matters

- **"Don't oversimplify" is load-bearing.** Without it, AI models default to shallow explanations when you say "explain simply" — that phrase alone triggers watered-down answers.
- **Asking for intuition before formalism** is how good teachers actually work — you get the "why" before the "how," so the technical details land on something instead of floating.
- **Requesting edge cases / gotchas explicitly** — this is the part people usually leave out, and it's exactly the part that makes an explanation feel "advanced" instead of tutorial-level.
- **Testing questions at the end** force the transition from "this made sense while reading" to "I can actually use this," which is a different thing.

## A shorter version for everyday use

If typing the full template each time is friction, a compressed version works almost as well:

> "Explain [X] — full depth, no dumbing down, but build the intuition first so it's actually clear. Include gotchas/edge cases. I'm learning Java/Spring Boot, so use that context where it helps."

## One more lever: tell it your current level precisely

"Intermediate to advanced" is a bit vague for the AI to calibrate against. It helps more to say something like "I understand Java's OOP basics and Spring's DI, but I've never dealt with proxies/AOP" — naming what you already know is often more useful than naming a difficulty tier, because it tells the AI exactly where to start building from rather than guessing.


[[Ai]]