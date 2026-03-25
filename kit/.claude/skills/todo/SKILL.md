---
name: todo
description: Work through TODO.md tasks sequentially — read the file, pick up uncompleted items, and execute them according to the instructions in the file.
user_invocable: true
disable-model-invocation: true
argument-hint: "[number-of-tasks] or populate"
---

# TODO Runner

Read `TODO.md` and work through the task list — or repopulate it with the next most important tasks.

If `$ARGUMENTS` is `populate`, jump to the **Populate** section. Otherwise, follow the **Run Tasks** steps below.

---

## Populate

Analyze the codebase and repopulate TODO.md with the next set of highest-impact engineering tasks. If TODO.md doesn't exist, create it.

### 1. Understand what's been done

- Read `TODO.md` if it exists and note all completed (`[x]`) tasks — these represent work already done. Don't re-add them.
- Read the project's README, `docs/`, and any existing documentation for product goals, planned features, known limitations, and business context.
- Scan the codebase: config files, directory structure, test coverage, CI/CD setup, error handling patterns, auth, logging, etc.

### 2. Identify the next most important tasks

Think like a staff engineer driving a small startup toward a rock-solid production application. Every task should earn its place on the list.

**Prioritization order (adapt to what the project actually needs):**

1. **Security & data integrity** — Auth, input validation, secrets management, SQL injection prevention, CSRF protection. Anything that could lose user data or get you hacked.
2. **Core reliability** — Error handling, database migrations, transaction safety, graceful degradation. The app shouldn't crash or corrupt data under normal use.
3. **Testing** — Unit tests for business logic, integration tests for critical paths, E2E tests for key user flows. Enough coverage to deploy with confidence.
4. **CI/CD & deployment** — Automated build/test pipeline, staging environment, zero-downtime deploys. You need to ship fast without breaking things.
5. **Observability** — Logging, error tracking (Sentry etc.), uptime monitoring, basic alerting. You need to know when things break before users tell you.
6. **Performance & scalability** — Database indexing, query optimization, caching, connection pooling. Handle real traffic without falling over.
7. **User experience polish** — Loading states, error messages, edge cases, mobile responsiveness. The stuff that makes users trust your product.
8. **Developer experience** — Linting, type safety, dev environment setup, seed data. Makes the team faster for everything above.

### 3. Write the list

- If creating a new TODO.md, start with this header:
  ```
  # TODO

  AGENTS: When prompted, complete tasks from the list below. Before starting work, mark the item as pending `[~]` so parallel agents don't collide. After completion, mark it `[x]`. Start at the top unless the user specifies otherwise.

  ## Backlog
  ```
- Clear out completed tasks from the list (they're done — no need to keep them around).
- Preserve any uncompleted (`[ ]`) or in-progress (`[~]`) tasks that are still relevant — re-rank them alongside the new tasks.
- Add 10-20 new tasks, rank-ordered by impact.
- Each task should be specific and actionable — reference actual files, endpoints, or components. Not "improve security" but "add rate limiting to `/api/` routes in `src/middleware/`."
- Every item should be completable by a single engineer (or AI agent) in a reasonable scope of work.
- Don't list things that are already done well. Only gaps and improvements.
- Preserve the agent instructions header at the top of TODO.md.

### 4. Summary

Tell the user what you found and what the new priorities are. Call out the top 3-5 items and why they matter most right now.

---

## Run Tasks

### 1. Read TODO.md

- Read the project's `TODO.md` file.
- If it doesn't exist, create one by running the **Populate** section above first, then continue.
- Parse the task list. Understand the agent instructions at the top of the file — they define how you should handle tasks.

### 2. Identify work

- Find all uncompleted tasks: items marked `[ ]` (not `[x]` done, not `[~]` pending).
- If `$ARGUMENTS` is provided, treat it as the maximum number of tasks to work on in this session. Otherwise, work through all uncompleted tasks.
- If there are no uncompleted tasks, tell the user the list is clear and stop.

### 3. Work through tasks

For each task, in order from top to bottom:

1. **Claim it.** Update `TODO.md` to mark the item `[~]` (pending) before starting any work. This signals to parallel agents that it's taken.
2. **Understand it.** Read the task description carefully. If the task references files, features, or systems you're unfamiliar with, read the relevant code and docs first.
3. **Execute it.** Do the work described by the task. Use the full set of tools available — read files, edit code, run commands, search the codebase, whatever the task requires. Follow the project's conventions from CLAUDE.md.
4. **Verify it.** If the task involves code changes, run relevant tests or checks (`make test`, linting, type checking) to make sure nothing is broken. If a task is ambiguous about what "done" looks like, use your best judgment.
5. **Mark it done.** Update `TODO.md` to mark the item `[x]`.
6. **Move on.** Proceed to the next uncompleted task.

### 4. Summary

After completing all tasks (or the requested number), provide a brief summary:

- Which tasks were completed
- Any issues encountered or tasks that couldn't be fully completed
- Any follow-up tasks that should be added to the list

## Guidelines

- **Follow the file's own instructions.** The `TODO.md` header contains agent-specific instructions. Follow them.
- **Top to bottom.** Work tasks in order unless the user says otherwise.
- **One at a time.** Fully complete a task before moving to the next. Don't leave tasks half-done.
- **Stay focused.** Only do what the task says. Don't refactor surrounding code, add features, or "improve" things beyond the scope of the task.
- **If stuck, skip and note.** If a task is blocked (missing credentials, unclear requirements, depends on an incomplete task), mark it back to `[ ]`, add a brief note explaining the blocker, and move on.
- **Keep TODO.md clean.** Don't rewrite the file structure or instructions. Only change task checkboxes and add notes when necessary.
