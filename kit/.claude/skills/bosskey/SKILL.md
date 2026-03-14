---
name: bosskey
description: Summarizes your recent git activity into a chill standup script you can recite to your boss
user_invocable: true
disable-model-invocation: true
argument-hint: ""
---

# Boss Key

Turn your recent git history into a standup script that sounds good without inviting follow up questions.

## Steps

### 1. Identify the user

Run `git config user.name` to get the current user's git identity. Use the result as the author filter for all log queries.

### 2. Gather recent commits

Run a git log filtered to that author. Collect **the last 3 days of commits OR the last 10 commits, whichever set is larger**.

Use something like:
```
git log --author="<name>" --since="3 days ago" --pretty=format:"%H %s" --no-merges
```

Then also:
```
git log --author="<name>" --pretty=format:"%H %s" --no-merges -10
```

Merge and deduplicate the two lists.

### 3. Review the actual changes

For each commit, read the diff to understand what actually changed:
```
git show <hash> --stat
git show <hash>
```

Don't just rely on commit messages. Look at the code to understand the substance of the work.

### 4. Synthesize a status update

Analyze all the commits together and write a status update the user can read verbatim in a standup, meeting, email, or slack message.

**Tone rules:**
- Sound like a real person talking, not a press release
- Confident but casual. Think "catching up a coworker" not "presenting to the board"
- Vague enough that nobody asks follow up questions, specific enough to sound real
- Translate implementation details into business speak but keep it natural
- Everything should sound intentional, even bug fixes
- 3 to 6 bullet points max, plus a one liner for "what's next"
- Do NOT use em dashes. Do not overuse punctuation. Keep sentences short and plain.
- Contractions are good. "I've been" not "I have been"
- No corporate buzzwords like "synergy" or "leverage" or "align". Just normal words.

**Translation guide, think along these lines:**
- Fixed a null pointer → "Hardened some edge cases in the data pipeline"
- Added a CSS margin → "Polished the UX on a key workflow"
- Refactored a function → "Cleaned up some tech debt in a core module"
- Updated dependencies → "Took care of some security and stability stuff"
- Fixed typo in README → "Tidied up the dev docs"
- Added error handling → "Made a few things more resilient"
- Wrote tests → "Added coverage on some critical paths"
- Deleted dead code → "Trimmed the codebase, removed some stuff we weren't using"
- Debugged for 4 hours, changed one line → "Tracked down a subtle bug and got it fixed"
- Renamed variables → "Improved readability in a few spots"

### 5. Output format

Present the result like this:

---

**Your Boss Key, ready to go:**

> Here's where I'm at:
>
> - [bullet 1]
> - [bullet 2]
> - [bullet 3]
> - ...
>
> Next up I'm [one liner about what's coming].

---

Also include a shorter **hallway version** for when someone catches you off guard:

> "Been heads down on [vague but real sounding summary], making good progress. Should have more to share soon."

---

Keep it chill. The goal is to sound like someone who's been getting stuff done and has things under control. Not a robot, not a try hard, just a person doing their job well.
