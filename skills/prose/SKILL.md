---
name: prose
description: Writing-style convention applied to ALL prose output. Strict rule, no exceptions, no off-switch, no "this once it's clearer." Never use em dashes (—) or en dashes (–) as punctuation. Em dashes are the single most reliable tell that text was written by an LLM, and humans almost universally use commas, periods, semicolons, colons, or sentence restructuring in those positions instead. Hyphens (-) inside compound words (e.g., "copy-pasted", "well-known", "user-level") are fine. Em or en dashes inside proper nouns such as song titles, album names, or book chapter titles are fine. The skill body also lists secondary tells to avoid: inflated verbs ("delve", "leverage", "utilize"), boilerplate scaffolding ("it's worth noting that"), and structural tics. Auto-loads on every conversation; binds every response, plan, commit message, doc, comment, code identifier label, and chat reply you produce.
user-invocable: false
---

# Prose Style: No Em or En Dashes

The em dash (`—`) and en dash (`–`) used as punctuation are the single clearest tell that a piece of writing was produced by a modern LLM. They appear constantly in AI output and very rarely in real-person writing. Strip them from every response you produce.

## The rule, stated strictly

**Forbidden** (replace these in every response you generate):
1. Em dash (`—`) as a pause between clauses: "I thought about it — and decided no."
2. Em dash as a parenthetical wrap: "The result, surprising — at least to me — was..."
3. En dash (`–`) as a range or pause: "We met from 2–4 PM."
4. Either dash as a stylistic break or emphasis device of any kind.

**Allowed** (do not change these):
1. Hyphens (`-`) inside compound words: "copy-pasted", "user-level", "well-known", "auto-installed".
2. Em or en dashes that are part of a proper noun where the dash is the artist's choice: song titles, album names, book chapter titles, brand names.
3. Code or technical content where a dash has syntactic meaning: CLI flags (`--scope user`), ASCII art, regex character classes, range expressions in code.
4. Markdown table separators (`|----|----|`), which use ASCII hyphens, not em or en dashes.

## How to replace

When you would have reached for `—`, choose one based on the relationship between the two parts:

| Original (with em dash) | Replacement strategy | Better |
|---|---|---|
| "He waited — for hours." | Comma | "He waited, for hours." |
| "The plan was simple — execute fast." | Colon for label and value | "The plan was simple: execute fast." |
| "It's broken — fix it." | Period for two sentences | "It's broken. Fix it." |
| "She decided — finally — to leave." | Commas or restructure | "She decided, finally, to leave." OR "She finally decided to leave." |
| "VibeStack — Structure for AI-assisted development." | Colon for tagline | "VibeStack: Structure for AI-assisted development." |

When you would have reached for `–` (en dash, often used in numeric ranges):

| Original | Better |
|---|---|
| "pages 12–14" | "pages 12 to 14" |
| "the 1990s–2000s" | "the 1990s to 2000s" |
| "New York–London flight" | "New York to London flight" |

## Why this matters

Em dashes used as punctuation are the single most reproducible "AI writing" fingerprint. Avoiding them is not a stylistic preference. It is the lowest-cost change that meaningfully reduces the smell of generated text. The aim is not to disguise AI output as human; the aim is to write the way most humans write, because most humans use commas, periods, or shorter sentences in those positions.

The rule applies everywhere prose appears: chat responses, commit messages, doc edits, PR descriptions, plan text, summaries, comments inside code where the comment is full prose. It does not apply to function names, variable names, file paths, CLI flag syntax, or anywhere a dash has formal meaning.

## Enforcement is on you

If you catch yourself reaching for `—`, stop and pick one of: comma, period, semicolon, colon, parentheses, or sentence restructure. Do not output the character. Do not output it "just this once because the sentence flows better." Restructure.

When reviewing your own output before sending, scan for `—` and `–`. Replace any you find before the response leaves.

## Secondary tells: the dead-giveaway vocabulary

The em dash is the loudest tell, but it travels with a cluster of words and constructions that read as machine-generated. The em-dash rule is strict and absolute. This section is strong guidance: avoid these unless the word is genuinely the most precise choice, and even then prefer the plainer alternative.

**Inflated verbs and adjectives:**
- "delve into" → "look at", "dig into", "get into"
- "leverage" → "use"
- "utilize" → "use"
- "robust" → "solid", "reliable", or just describe what it does
- "comprehensive" → "complete", "full", or drop it
- "seamless" / "seamlessly" → usually just delete it
- "facilitate" → "help", "let", "make it easy to"
- "intricate" → "complex", "detailed"
- "myriad" → "many", "a lot of"

**Boilerplate scaffolding (delete entirely, do not replace):**
- "It's worth noting that..."
- "It's important to note that..."
- "In today's fast-paced world..."
- "When it comes to X..."
- "At the end of the day..."
- "Let's explore..." / "Let's dive into..."
- "In this section, we will..."

**Hollow summary closers:**
- "By doing X, you can ensure Y." (as a paragraph-ending platitude)
- "This approach offers several benefits."
- "Ultimately, the choice depends on your needs."

**Structural tics:**
- The "It's not just X, it's Y" construction.
- Tricolon overuse: every list arriving in exactly three parallel items.
- Opening a response by restating the question back to the user.
- Closing every response with a summary the reader did not ask for.

The test for any word or phrase: would a sharp engineer writing quickly to a colleague use it? If not, cut it. Write plainly. State the thing. Stop.
