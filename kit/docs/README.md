# Docs

This folder is the project's living documentation. Every markdown file here serves three purposes:

1. **Human reference** — Lessons learned, architectural decisions, integration quirks, and incident postmortems that the team can read and search
2. **AI context** — A knowledge base that AI agents read to understand the project deeply without re-discovering everything from code
3. **Publishable docs** — Markdown with a `SUMMARY.md` table of contents, ready to build into a docs site (mdBook, Docusaurus, GitBook, etc.)

## Structure

```
docs/
  README.md          # This file — explains the docs convention
  SUMMARY.md         # Table of contents (required for doc site generators)
  index.md           # Landing page / project overview

  # Organize by topic — create subdirectories as the project grows
  architecture/      # System design, component docs, data flow
  integrations/      # External API references, SDK quirks, auth flows
  operations/        # Deployment, monitoring, runbooks
  incidents/         # Postmortems and incident reports
```

## When to Write a Doc

- You discover non-obvious behavior in an API or library (the kind of thing that wastes hours)
- You make an architectural decision and want to record the reasoning
- An incident happens and you want to capture what went wrong and what was fixed
- You research a topic (vendor comparison, performance analysis) and want to preserve the findings
- A subsystem is complex enough that future-you (or an AI agent) would benefit from a walkthrough

## How to Write a Doc

- **One topic per file.** Don't combine unrelated things.
- **Lead with context.** Start with what this is and why it matters, then get into details.
- **Include concrete examples.** Code snippets, config samples, API responses, error messages.
- **Record what surprised you.** The stuff that's not in the official docs is the most valuable.
- **Link to source.** Reference specific files, line numbers, or URLs when relevant.
- **Keep it current.** When code changes invalidate a doc, update or remove it. Stale docs are worse than no docs.

## SUMMARY.md

`SUMMARY.md` is the table of contents. Doc site generators (mdBook, etc.) use it to build navigation. Keep it updated when adding or removing docs.

```markdown
# Summary

[Home](index.md)

---

# Section Name

- [Doc Title](path/to/doc.md)
```

## Incident Reports

Name incident files with the date and a short description:

```
incidents/incident-YYYY-MM-DD-short-description.md
```

Include: what happened, timeline, root cause, what was fixed, and what to watch for going forward.

## For AI Agents

- **Read before you write.** Check `docs/` for existing context on the area you're working in. It may save you from re-learning hard-won lessons.
- **Write as you go.** When you discover something non-obvious during a task — an API quirk, a subtle bug pattern, a key design constraint — add it to the relevant doc or create a new one.
- **Update SUMMARY.md** whenever you add or remove a doc.
- **Don't duplicate CLAUDE.md.** CLAUDE.md is the quick-start reference. Docs are for deep dives. Link between them when something needs more detail.
