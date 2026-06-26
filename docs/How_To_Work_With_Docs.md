# How to work with the docs

The operating manual for this documentation set. Read it **before** adding, editing, moving, or deleting a
doc. The set follows the Firm's **SOP-13 — Progressive-disclosure documentation**; this file is the local,
scaled-down procedure.

---

## Rule 1 — Place a doc by what it is, not its filename

| Section | Holds | Pick this when the doc … |
|---------|-------|--------------------------|
| `01-overview/` | What lipost is and the model | Defines a concept, frames the tool, or argues for fit |
| `02-architecture/` | How it's built and why | Describes the file structure, a data location, the API/auth flow, or the bot's scheduling |
| `03-cli-reference/` | The command surface | Lists commands, flags, or config keys |

Add a new top-level numbered section only when a doc genuinely fits none of the above — not by reflex.

## Rule 2 — Keep the router thin

`CLAUDE.md` / `AGENTS.md` (kept byte-identical) is a *table of contents*, not a manual: the standing rules
plus a pointer table into `docs/`. If you're tempted to explain something there, write a doc and link it.

## Rule 3 — Every doc change triggers a cross-doc scan

Before committing, `grep -rln "<old-path-or-phrase>" docs/ CLAUDE.md AGENTS.md README.md bin/` for anything
your change renamed, moved, or invalidated, and fix every stale reference in the **same commit**. Update
[`Documentation_Table_Of_Contents.md`](Documentation_Table_Of_Contents.md) whenever a doc is added, removed,
or renamed.

## Rule 4 — Naming, length, and traversal

- **Filenames** are kebab-case ASCII (`single-file-design.md`). The two root index files stand out in
  TitleSnake_Case: `Documentation_Table_Of_Contents.md`, `How_To_Work_With_Docs.md`.
- **Length** ~100–400 lines; split above ~800. Many small focused docs beat a few long ones.
- **End every doc** with a short **"Read next" / "Cross-references"** block (2–5 links) so the corpus is
  traversable without returning to the index.

## Rule 5 — Docs are current state, shipped with the code

`docs/` describes what *is*. When the CLI surface, the runtime layout, the auth flow, or the bot mechanics
change in `bin/lipost`, update the affected docs **in the same commit** — and prune anything that went
stale. A doc out of sync with the code is worse than no doc. (The README is the human walkthrough; keep it
in sync too when behavior changes.)

---

## Checklist before committing doc changes

```
- [ ] Doc is in the right section (Rule 1)
- [ ] Router stayed thin (Rule 2)
- [ ] Cross-doc scan run; stale references fixed (Rule 3)
- [ ] Filename + length + "Read next" conventions met (Rule 4)
- [ ] TOC updated if a file was added/removed/renamed (Rule 4/5)
- [ ] Doc ships in the same commit as the code it describes (Rule 5)
```

---

## Cross-references

- [Documentation Table of Contents](Documentation_Table_Of_Contents.md) — what exists
- [`/CLAUDE.md`](../CLAUDE.md) / [`/AGENTS.md`](../AGENTS.md) — the thin router this set hangs off
- Full SOP: `~/code/me/org/sop/13-progressive-disclosure-docs.md` (inherited from the Firm apex)
