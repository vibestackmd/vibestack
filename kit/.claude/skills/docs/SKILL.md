---
name: docs
description: Capture conversation learnings into docs and clean up the docs folder
user_invocable: true
---

# Docs Update

Capture important information from the current conversation and ensure the docs folder stays clean and accurate.

## Steps

### 1. Gather context

- Review the current conversation for learnings, decisions, architectural changes, new features, removed features, or insights worth preserving.
- Read the project's CLAUDE.md (or equivalent project instructions file) to understand the project structure and conventions.
- List all files in the `docs/` directory to understand what exists.

### 2. Capture new information

For each piece of new information from the conversation:

- **Find the right home.** Search existing docs for the most relevant file and section. Prefer adding to an existing doc over creating a new one.
- **If no good home exists**, create a new doc only if the topic is substantial enough to warrant one. Use a clear, descriptive filename.
- **Write concisely.** Match the tone and style of the existing docs. State facts and decisions, not the discussion that led to them. Avoid filler and preamble.
- **Include the "why."** When documenting a decision or removal, briefly note the reasoning so future readers understand the context.

### 3. Clean up and consolidate

Scan every file in `docs/` for:

- **Stale references** — features, config fields, files, functions, or components that no longer exist in the codebase. Grep the source code to verify before removing.
- **Incorrect counts or names** — unit test counts, filter counts, enum variants, file paths, function signatures that have drifted from reality.
- **Redundancy** — information duplicated across multiple docs. Consolidate into the canonical location and remove or link from the other.
- **Dead links** — references to files or sections that no longer exist.
- **Outdated examples** — command examples, config snippets, or code samples that reference removed nodes, old flag names, or deprecated workflows.

For each issue found:
- Verify against the actual codebase (grep/read the source) before making changes.
- Remove stale content cleanly — don't leave orphaned headers, empty sections, or dangling list items.
- If a section becomes empty after cleanup, remove the section header too.

### 4. Also check the project instructions file

Apply the same cleanup to CLAUDE.md (or equivalent). This file is loaded into every conversation, so accuracy matters most here:

- Verify file paths, function names, and module descriptions match the current code.
- Verify command examples still work.
- Remove references to deleted features, nodes, or config fields.
- Keep it concise — CLAUDE.md should be a quick reference, not a detailed guide. Move lengthy explanations to docs/.

### 5. Feynman clarity pass

Review everything you wrote or updated and apply a clarity pass:

- **Lead with plain language.** The first sentence of each section should make sense to a non-technical reader. State what the thing does and why it matters before any technical detail.
- **Introduce jargon on first use.** The first time a technical term appears, briefly explain it in parentheses or a short clause.
- **Layer the complexity.** Start simple, then go deeper. Wide shot first, then close-up.
- **Use analogy where it helps.** Compare non-obvious concepts to everyday things — but don't force analogies where the text is already clear.
- **Short sentences, short paragraphs.** If a sentence has more than one comma, consider splitting it. If a paragraph is more than 4-5 lines, break it up.
- **Active voice.** "The order is placed" → "The bot places an order." Name the actor.
- **Keep all technical depth.** Don't remove formulas, config details, or implementation notes — just make sure each one is preceded by a plain-English explanation.

If a section is already clear and accurate, leave it alone. This pass is for improving what needs it, not rewriting everything.

### 6. Summary

After all changes, provide a brief summary of:
- What new information was captured and where
- What stale content was removed or updated
- Any docs that were consolidated or restructured
- Any sections where clarity was improved

## Guidelines

- **Verify before removing.** Always grep the codebase to confirm something is actually gone before deleting its documentation. Docs about historical incidents or past decisions should generally be preserved as-is.
- **Preserve history.** Incident logs, postmortems, and changelog-style docs describe what happened at a point in time. Don't update these to match current state — they're historical records.
- **Don't over-document.** If something is obvious from the code, it doesn't need a doc. Focus on decisions, architecture, non-obvious behavior, and operational knowledge.
- **Keep structure flat.** Prefer fewer, well-organized files over many small ones. A doc with clear headers is easier to maintain than a folder of fragments.
