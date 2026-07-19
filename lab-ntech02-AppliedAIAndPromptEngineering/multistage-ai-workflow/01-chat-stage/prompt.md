# Stage 1 prompt (chat-based AI)

Paste this into any chat-based AI tool (ChatGPT, Gemini Chat, Claude.ai,
etc.). It asks for a structured **design spec**, not code: the output
should be usable as a build contract for stage 2, regardless of which
chat tool produced it.

```
I need a design spec for a single-page restaurant landing page. Invent a
restaurant concept (name, cuisine, vibe) and write a spec I can hand to a
developer, covering:

1. Restaurant concept: name, cuisine type, tone/personality in one or two
   sentences.
2. Page sections in order, each with: purpose, the actual copy to use
   (headlines, body text, button labels, not placeholders), and any
   content it needs (e.g. menu items with name/description/price).
3. Visual direction: a small color palette (with intent, not hex codes),
   typography pairing (heading style vs body style), and overall mood.
4. Non-functional requirements: mobile responsive, semantic HTML,
   accessible (alt text, form labels, contrast), no build tooling or
   external frameworks.
5. Anything explicitly out of scope (e.g. real payment processing, a
   backend).

Output as Markdown with headings. This will be implemented as a static
HTML/CSS/JS page with no backend, so don't ask for anything a backend
would be required for.
```

## Why this prompt is designed this way

- It asks for **content and intent**, not implementation: hex codes,
  markup, and code are deliberately left to stage 2, which is the AI
  actually writing the files. This keeps the contract at the right
  altitude for a chat tool with no code-execution environment.
- Bounding constraints (`no build tooling`, `no backend`) are stated up
  front so stage 2 isn't handed a spec it can't satisfy statically.
- The prompt is tool-agnostic: it only assumes a chat AI that can follow
  instructions and produce Markdown, so any provider works.
