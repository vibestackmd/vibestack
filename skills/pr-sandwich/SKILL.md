---
name: pr-sandwich
description: Structure for writing pull request reviews, PR descriptions, issues, and comments on PRs or issues so they land well with both humans and AI agents. Open with something specific and genuinely good, put the substance in the middle ordered by severity, and close by naming the most plausible reason your own suggestion could be wrong. Use when submitting a PR review (gh pr review, approving, requesting changes), writing a PR description or body, opening an issue, or commenting on someone else's PR or issue. Skip it for trivial mechanical changes, clean approvals with no findings, security findings that must not be softened, and incident response.
user-invocable: true
---

# The PR sandwich

Three parts. Genuine opening, substantive middle, honest closing.

It exists because review feedback fails in two directions: it reads as an
attack, or it gets applied blindly. The opening fixes the first. The closing
fixes the second.

## 1. Open with something specific and true

One or two sentences naming something the author actually did well.

**It must be specific enough to prove you read the thing.** A specific
observation is evidence; generic praise is noise, and readers can tell the
difference instantly.

```
Good:  Reusing governance.proposals once you found coverage_receipt was
       unwritten in all 162 rows is the right call.
Bad:   Great work on this PR!
Bad:   Nice clean code.
```

Praise the substance, not the packaging. Complimenting the formatting when the
architecture is what matters reads as consolation.

**If there is genuinely nothing good, do not manufacture it.** Say something
honest and neutral instead: acknowledge that the problem is real, or that the
approach is a reasonable direction. Fake praise costs you credibility on every
review after this one.

## 2. The substance, ordered by severity

- **Lead with the most important finding.** Never bury a blocker under nits.
- **Be concrete.** File and line, the actual code, the actual consequence. "This
  could be a problem" is not a finding.
- **Say what breaks.** Name the failure: what input, what state, what wrong
  result. If you cannot describe the failure, you may not have one.
- **Separate severity explicitly.** Blocking, should-fix, and nit are different
  asks. Mark which is which so the author can triage.
- **Prefer few strong findings over an exhaustive list.** Three real issues get
  fixed. Fifteen mixed with style opinions get skimmed.

When asked for a single highest-value suggestion, prefer one that is **atomic**:
it stands alone, needs no other change, no migration, and no coordination.

## 3. Close by naming why you might be wrong

This is the part most reviewers skip, and it is what makes the structure work.

**Name the specific most plausible reason your suggestion is wrong**, then
invite correction. Not generic hedging. A concrete counter-hypothesis.

```
Good:  Entirely possible you're planning to reach these over FDW from the
       agent databases the way commons already is, in which case ignore this.
Bad:   Let me know if I'm off base here!
Bad:   Just my two cents, feel free to ignore.
```

The difference matters. A specific alternative shows you considered their
constraints and gives them a one-word way to dismiss it. Generic hedging just
makes the whole review sound unsure, including the parts you are certain about.

**Put the hedge at the end, attached to the specific claim.** Do not spray
uncertainty through the middle section. Confidence in the finding and humility
about the context are compatible, and mixing them turns strong findings to mush.

## Why this works for agents too

Increasingly the reader is another agent acting on your review.

An agent handed "do X" will do X. An agent handed "do X, unless Y is true, in
which case this is wrong" has an explicit branch to evaluate before acting. The
closing hedge is not politeness, it is a **guard condition** that prevents
confidently wrong changes from being applied mechanically.

This is the strongest argument for the structure and the reason to keep it even
when the reader is a machine.

## Where it applies

| Surface | Shape |
|---|---|
| **PR review summary** | Full sandwich. This is the primary case |
| **PR description you author** | What it does, why, then what you are least sure about and want scrutinised |
| **Issue you open** | What is wrong, evidence, then what you might be misreading |
| **Comment on someone's PR or issue** | Usually just the closing hedge. Opening praise on every comment is grating |
| **Inline line comments** | Skip the opening. Keep them short and specific |

The full three-part structure belongs on the **summary**, not on every inline
comment. Repeating it per line is the most common way to make this obnoxious.

## When to skip it

Do not force this. It is wrong at least as often as:

- **Nothing to flag.** Approve and say why in one line. A sandwich with no
  filling is padding.
- **Trivial or mechanical changes.** Dependency bumps, typo fixes, generated
  files. Just approve.
- **Security findings that must not be softened.** Still open with something
  true if you can, but state severity plainly and do not hedge the finding
  itself into deniability. An exploitable bug is not a matter of perspective.
- **Incident response or anything urgent.** Lead with the problem.
- **You are the author** responding on your own PR.
- **Terse output was explicitly requested**, like a checklist or a findings
  table.

## Choosing the review type

Match the GitHub review state to what you actually mean:

- **Comment** when raising something the author should weigh but which should
  not block them, or when you are not the owning reviewer
- **Request changes** when merging as-is would ship a defect
- **Approve** when it should merge, with nits marked as non-blocking

Reaching for "request changes" on a possible issue you are unsure about
overstates your confidence. That is what a comment review is for.
