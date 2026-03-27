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
- **Historical cruft** — any content that describes how things *used to* work, old approaches, or previous designs. See the rules below for how to handle this.

**Aggressively remove historical information.** Docs should describe how things work *now* and *why*, not how they used to work. Apply these rules:

- If a section says "we used to do X but now we do Y" — rewrite it as "we do Y because [reason]." Delete the reference to X entirely.
- If a past decision or incident encodes a lesson that the team is **strongly likely** to encounter again, keep the lesson — but reframe it as a current rule or guideline, not a historical narrative. Write "We do X because Y" not "We switched from A to X after incident Z."
- "Potentially" relevant history is not worth keeping. Only preserve lessons where there's a **strong likelihood** the team will hit the same situation again.
- If an entire doc has become historical (describes a removed feature, old architecture, completed migration), delete the file.
- If removing historical content leaves a doc too thin to justify its own file, merge the remaining content into a related doc and delete the file.

**Shrink the docs folder.** Every pass should aim to reduce or hold steady the number of files and total content. Combine small docs on related topics. Delete files that no longer carry weight. A lean, accurate docs folder is more valuable than a comprehensive but stale one.

For each issue found:
- Verify against the actual codebase (grep/read the source) before making changes.
- Remove stale content cleanly — don't leave orphaned headers, empty sections, or dangling list items.
- If a section becomes empty after cleanup, remove the section header too.

### 4. Update the README

The project README should always open with a **Commands** section listing the current Makefile targets. This is the first thing a developer (or agent) sees — make it immediately useful.

- **Read the Makefile** and extract all documented targets (those with `## comment` help strings).
- **Categorize** targets if there are more than ~6 (e.g., "Development", "Testing", "Deployment", "Release"). If fewer, a flat list is fine.
- **Order by relevance** — most-used commands first, within each category. Development and testing commands typically come before release and deployment.
- **Use a simple code block** for each command with a one-line description. Match the format already used in CLAUDE.md's Commands section.
- **Remove stale entries** — if a Makefile target was removed or renamed, update the README to match.
- **Keep it current** — every `/docs` pass should re-verify that the README commands match the actual Makefile. This is not optional.

If the README doesn't have a Commands section yet, add one at the top (after the project title/description).

### 5. Also check the project instructions file

Apply the same cleanup to CLAUDE.md (or equivalent). This file is loaded into every conversation, so accuracy matters most here:

- Verify file paths, function names, and module descriptions match the current code.
- Verify command examples still work.
- Remove references to deleted features, nodes, or config fields.
- Keep it concise — CLAUDE.md should be a quick reference, not a detailed guide. Move lengthy explanations to docs/.

### 6. Feynman clarity pass

Review everything you wrote or updated and apply a clarity pass:

- **Lead with plain language.** The first sentence of each section should make sense to a non-technical reader. State what the thing does and why it matters before any technical detail.
- **Introduce jargon on first use.** The first time a technical term appears, briefly explain it in parentheses or a short clause.
- **Layer the complexity.** Start simple, then go deeper. Wide shot first, then close-up.
- **Use analogy where it helps.** Compare non-obvious concepts to everyday things — but don't force analogies where the text is already clear.
- **Short sentences, short paragraphs.** If a sentence has more than one comma, consider splitting it. If a paragraph is more than 4-5 lines, break it up.
- **Active voice.** "The order is placed" → "The bot places an order." Name the actor.
- **Keep all technical depth.** Don't remove formulas, config details, or implementation notes — just make sure each one is preceded by a plain-English explanation.

If a section is already clear and accurate, leave it alone. This pass is for improving what needs it, not rewriting everything.

### 7. Summary

After all changes, provide a brief summary of:
- What new information was captured and where
- What stale content was removed or updated
- Any docs that were consolidated or restructured
- Any sections where clarity was improved

## Guidelines

- **Verify before removing.** Always grep the codebase to confirm something is actually gone before deleting its documentation.
- **Current state over history.** Docs describe how things work now and why. Remove historical narratives, old approaches, and "we used to" content. If a past lesson is strongly likely to recur, encode it as a present-tense rule — not a story.
- **Don't over-document.** If something is obvious from the code, it doesn't need a doc. Focus on decisions, architecture, non-obvious behavior, and operational knowledge.
- **Keep structure flat.** Prefer fewer, well-organized files over many small ones. A doc with clear headers is easier to maintain than a folder of fragments.
- **Trim every pass.** Aim to reduce or hold steady the total number of files and lines. Combine related docs, delete empty or historical ones. The docs folder should never just grow.
