# Compose Skill v0.11.0 Update — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the compose skill with upstream `ocaml-compose-dsl` v0.11.0 — adding epistemic operator conventions, new checker lint rules, and a debugging workflow example. Audit all existing examples for `branch` naming conflicts and epistemic naming opportunities.

**Architecture:** Documentation + examples update. No runtime code changes. The upstream README v0.11.0 Epistemic Conventions section is the source of truth for the five operator names and their conventions. SKILL.md gets new sections; dsl-grammar.md gets new warnings; existing examples are audited for lint compliance; one new example is created.

**Tech Stack:** `ocaml-compose-dsl` binary (v0.11.0) for validation, `gh` CLI for fetching upstream content.

**Spec:** `docs/superpowers/specs/2026-04-04-compose-v0110-update-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `plugins/compose/skills/compose/SKILL.md` | Version bump, epistemic conventions section, checker warnings |
| Modify | `plugins/compose/skills/compose/README.md` | Epistemic conventions subsection, example count, version |
| Modify | `plugins/compose/skills/compose/references/dsl-grammar.md` | Epistemic lint in structural rules + warnings |
| Modify | `plugins/compose/skills/compose/examples/multi-statement.arr` | Rename `branch(...)` → `git_branch(...)` |
| Modify | `plugins/compose/skills/compose/examples/test-fix-loop.arr` | Candidate: epistemic naming if semantically appropriate |
| Modify | `plugins/compose/skills/compose/examples/ci-pipeline.arr` | Audit for `branch` conflicts |
| Modify | `plugins/compose/skills/compose/examples/frontend-project.arr` | Audit for epistemic naming opportunities |
| Modify | `plugins/compose/skills/compose/examples/update-skill-from-upstream.arr` | Update to reflect v0.11.0 workflow |
| Audit | `plugins/compose/skills/compose/examples/osint-*.arr` (6 files) | Check for epistemic naming opportunities |
| Create | `plugins/compose/skills/compose/examples/epistemic-debugging.arr` | New: debugging workflow with all 5 epistemic operators |
| Modify | `.claude-plugin/marketplace.json` | Version `0.10.0` → `0.11.0` |
| Modify | `plugins/compose/.claude-plugin/plugin.json` | Description: add epistemic operators |
| Modify | `CLAUDE.md` | Compose description: version, plugin count, example count, epistemic |

---

### Task 0: Verify ocaml-compose-dsl v0.11.0

All validation steps depend on the v0.11.0 binary.

**Files:**
- Run: `~/.local/bin/ocaml-compose-dsl --version`

- [ ] **Step 1: Check current version**

```bash
ocaml-compose-dsl --version
```

Expected: output contains `0.11.0`. If it shows `0.10.0` or earlier, proceed to step 2.

- [ ] **Step 2: Upgrade if needed**

```bash
bash plugins/compose/skills/compose/scripts/install.sh
```

- [ ] **Step 3: Verify upgrade**

```bash
ocaml-compose-dsl --version
```

Expected: `0.11.0`.

- [ ] **Step 4: Quick smoke test — epistemic lint works**

```bash
echo 'branch >>> done' | ocaml-compose-dsl 2>&1
```

Expected: AST output on stdout, warning about `branch` without `merge` on stderr.

---

### Task 1: Update SKILL.md — checker warnings and epistemic conventions

**Files:**
- Modify: `plugins/compose/skills/compose/SKILL.md:188-195` (Checker Warnings section)
- Modify: `plugins/compose/skills/compose/SKILL.md:18` (version check)

- [ ] **Step 1: Update version check**

At `SKILL.md:18`, change:

```
This skill requires **v0.10.0** or later.
```

to:

```
This skill requires **v0.11.0** or later.
```

Also at `SKILL.md:24`, change:

```
If the output is lower than `0.10.0`
```

to:

```
If the output is lower than `0.11.0`
```

- [ ] **Step 2: Add epistemic lint warnings to Checker Warnings section**

After the two existing warning bullets (ending with `?` as operand of `|||`...) and before the "Warnings help catch structural oversights early." closing sentence, add:

```markdown
- `branch` without matching `merge` in the same statement — warns that an epistemic branch has no convergence point
- `leaf` without matching `check` in the same statement — suggests adding a verification step after the bounded reasoning zone
```

- [ ] **Step 3: Add Epistemic Conventions section after Checker Warnings**

Insert a new section after the "Warnings help catch structural oversights early." line and before "## Common Patterns":

```markdown

### Epistemic Conventions

Five identifier names serve as **epistemic operators** — cognitive role markers for human-LLM shared reasoning scaffolds, inspired by [λ-RLM](https://github.com/lambda-calculus-LLM/lambda-RLM). They are ordinary identifiers (not reserved words) matched by name only.

| Name | Intent | Common Pattern |
|------|--------|----------------|
| `gather` | Collect evidence/sub-questions before reasoning | `gather >>> leaf` |
| `branch` | Explore multiple candidate paths | `branch >>> ... >>> merge` |
| `merge` | Converge candidates into auditable artifact | `... >>> merge >>> check?` |
| `leaf` | High-cost reasoning zone — bounded sub-problem | `leaf >>> check?` |
| `check` | Verifiable validation step | `check? >>> (pass \|\|\| fix)` |

The checker lints two conventions: `branch` without `merge`, and `leaf` without `check`. These are warnings, not errors.

**Avoiding false positives:** If a node named `branch` means something else (e.g., git branching), rename it to avoid the lint — e.g., `git_branch(pattern: "feature/*")`.
```

- [ ] **Step 4: Add epistemic-debugging.arr to the example list**

After the `multi-statement.arr` entry and before the OSINT disclaimer paragraph, add:

```markdown
- **`examples/epistemic-debugging.arr`** — Systematic debugging workflow using all five epistemic operators: gather symptoms, branch hypotheses, merge evidence, leaf root-cause analysis, check fix verification
```

- [ ] **Step 5: Rename `branch` in the Statements inline example**

At `SKILL.md:108`, change:

```
  >>> branch(pattern: "feature/*") :: Code -> Branch
```

to:

```
  >>> git_branch(pattern: "feature/*") :: Code -> Branch
```

- [ ] **Step 6: Validate SKILL.md literate arrow blocks**

```bash
ocaml-compose-dsl --literate plugins/compose/skills/compose/SKILL.md
```

Expected: exit 0, no errors. Warnings about `?` without `|||` are acceptable in isolated snippet examples.

- [ ] **Step 7: Commit**

```bash
git add plugins/compose/skills/compose/SKILL.md
git commit -m "docs(compose): add epistemic conventions and update checker warnings for v0.11.0"
```

---

### Task 2: Update dsl-grammar.md — epistemic lint in structural rules and warnings

**Files:**
- Modify: `plugins/compose/skills/compose/references/dsl-grammar.md:399-423` (Structural Rules + Warnings)
- Modify: `plugins/compose/skills/compose/references/dsl-grammar.md:362` (Multi-Statement example)

- [ ] **Step 1: Rename `branch` in the Multi-Statement example**

At `dsl-grammar.md:362`, change:

```
  >>> branch(pattern: "feature/*") :: Code -> Branch
```

to:

```
  >>> git_branch(pattern: "feature/*") :: Code -> Branch
```

- [ ] **Step 2: Add epistemic lint to Structural Rules**

After the last existing bullet in the "validates" list (ending with "Semicolons separate top-level statements only"), add a new bullet:

```markdown
- Epistemic operator conventions — `branch`/`merge` pairing and `leaf`/`check` suggestion
```

- [ ] **Step 3: Add epistemic warnings to the Warnings section**

After the existing two warning bullets (at the end of the file), append:

```markdown
- `branch` without matching `merge` in the same statement — the epistemic branch has no convergence point
- `leaf` without matching `check` in the same statement — suggests adding a verification step after the bounded reasoning zone (suggestion, not warning)

The checker matches these five epistemic names (`gather`, `branch`, `merge`, `leaf`, `check`) by identifier name only — they are not reserved words and can be shadowed by `let` bindings. If a node named `branch` has non-epistemic meaning (e.g., git branching), rename it to avoid the lint: `git_branch(pattern: "feature/*")`.
```

- [ ] **Step 4: Validate dsl-grammar.md literate arrow blocks**

```bash
ocaml-compose-dsl --literate plugins/compose/skills/compose/references/dsl-grammar.md
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/compose/skills/compose/references/dsl-grammar.md
git commit -m "docs(compose): add epistemic lint rules to dsl-grammar.md warnings and structural rules"
```

---

### Task 3: Update README.md — epistemic conventions and version

**Files:**
- Modify: `plugins/compose/skills/compose/README.md`

- [ ] **Step 1: Add Epistemic Conventions subsection**

After the "Arrow Combinators" table (after `README.md:29`), add:

```markdown

## Epistemic Conventions

Five identifier names serve as cognitive role markers for structured reasoning workflows. The checker lints `branch` without `merge` and suggests `check` after `leaf`. See SKILL.md for full details.

| Name | Intent |
|------|--------|
| `gather` | Collect evidence before reasoning |
| `branch` | Explore multiple candidate paths |
| `merge` | Converge candidates into auditable artifact |
| `leaf` | High-cost reasoning zone — bounded sub-problem |
| `check` | Verifiable validation step |
```

- [ ] **Step 2: Update example count**

At `README.md:63`, change:

```
21 examples in `examples/`
```

to:

```
22 examples in `examples/`
```

- [ ] **Step 3: Update "What it does" list**

At `README.md:8`, after the warnings bullet, add:

```markdown
- Lints epistemic operator conventions (`branch`/`merge` pairing, `leaf`/`check` suggestion)
```

- [ ] **Step 4: Commit**

```bash
git add plugins/compose/skills/compose/README.md
git commit -m "docs(compose): add epistemic conventions to README.md"
```

---

### Task 4: Rename `branch` in multi-statement.arr

**Files:**
- Modify: `plugins/compose/skills/compose/examples/multi-statement.arr:8`

- [ ] **Step 1: Rename the node**

At `multi-statement.arr:8`, change:

```
  >>> branch(pattern: "feature/*") :: Code -> Branch
```

to:

```
  >>> git_branch(pattern: "feature/*") :: Code -> Branch
```

Note: `commit(branch: main)` on line 5 stays as-is — `branch` there is a named argument key, not a node name. The checker only lint-matches identifiers in pipeline position.

- [ ] **Step 2: Validate**

```bash
ocaml-compose-dsl plugins/compose/skills/compose/examples/multi-statement.arr
```

Expected: exit 0, no warnings about `branch` without `merge`.

- [ ] **Step 3: Commit**

```bash
git add plugins/compose/skills/compose/examples/multi-statement.arr
git commit -m "fix(compose): rename branch to git_branch in multi-statement.arr to avoid epistemic lint"
```

---

### Task 5: Audit and update existing examples

Run all 21 `.arr` files through the v0.11.0 checker, then review candidates for epistemic naming.

**Files:**
- Audit: all `.arr` files in `plugins/compose/skills/compose/examples/`
- Modify (candidates): `test-fix-loop.arr`, `ci-pipeline.arr`, `frontend-project.arr`, `update-skill-from-upstream.arr`

- [ ] **Step 1: Batch-validate all examples**

```bash
for f in plugins/compose/skills/compose/examples/*.arr; do
  echo "=== $f ==="
  ocaml-compose-dsl "$f" 2>&1 | tail --lines=3
  echo "exit: $?"
done
```

Expected: all exit 0. Note any warnings — especially `branch` without `merge` warnings that reveal naming conflicts we missed.

- [ ] **Step 2: Review `test-fix-loop.arr` for epistemic naming**

Current file uses `verify` terminology. The loop structure is:
```
edit >>> test >>> "all tests pass"? >>> (done ||| retry)
```

This is a test-fix loop, not an epistemic reasoning workflow. The `?` + `|||` pattern is about test pass/fail, not epistemic verification. **Decision: leave unchanged** unless the checker output in step 1 reveals issues.

- [ ] **Step 3: Review `ci-pipeline.arr`**

Current file:
```
let ci = (lint &&& test) >>> gate(require: [pass, pass]) in
ci >>> (build_linux *** build_macos) >>> upload
```

No `branch` node name. No epistemic reasoning semantics. **Decision: leave unchanged.**

- [ ] **Step 4: Review `frontend-project.arr`**

This 225-line file uses Chinese identifiers. Check for:
- Any node that might match `branch`/`merge`/`leaf`/`check`/`gather` (grep shows none)
- Semantic opportunities: the `審核` (review) pattern already uses `loop(提案? >>> (通過 ||| 修正))` which is a verification pattern but uses Chinese naming

**Decision: leave unchanged** — epistemic naming would conflict with the file's Chinese naming convention.

- [ ] **Step 5: Review `update-skill-from-upstream.arr`**

This file already uses `gather` as a let-bound name (line 16: `let gather = ...`). This is semantically correct — it gathers upstream release info and local files. The checker will now recognize `gather` as an epistemic operator name.

Check: does this trigger any lint warnings? `gather` alone (without specific pairing rules) should not warn. Verify in step 1 output.

Consider adding epistemic operators to the main pipeline if the v0.11.0 update workflow maps naturally:
- `gather` (already present) → `analyze` → `update_docs` → `update_examples` → `validate` → `bump_version` → `verify`
- `verify` at the end could become `check` — it verifies the binary version
- The `validate` step could use `check` semantics

**Decision: rename `verify` → `check`.** The file already uses `gather` correctly; adding `check` completes a natural epistemic pair. Also update the minimum version from `"0.10.0"` to `"0.11.0"`.

- [ ] **Step 6: Review OSINT examples (6 files)**

From the grep results, none of the 6 OSINT files contain `branch`, `gather`, `merge`, `leaf`, or `check` as identifiers. **Decision: leave unchanged.**

- [ ] **Step 7: Apply changes to `update-skill-from-upstream.arr`**

Rename `verify` → `check` and update version:

At `update-skill-from-upstream.arr:58-59`, change:

```
let verify =
  check_version(binary: "ocaml-compose-dsl", minimum: "0.10.0")
```

to:

```
let check =
  check_version(binary: "ocaml-compose-dsl", minimum: "0.11.0")
```

And at line 63, change:

```
gather >>> analyze >>> update_docs >>> update_examples >>> validate >>> bump_version >>> verify
```

to:

```
gather >>> analyze >>> update_docs >>> update_examples >>> validate >>> bump_version >>> check
```

Also update the minimum version from `"0.10.0"` to `"0.11.0"` to reflect this session.

- [ ] **Step 8: Re-validate changed examples**

```bash
ocaml-compose-dsl plugins/compose/skills/compose/examples/update-skill-from-upstream.arr
```

Expected: exit 0. May warn about `leaf` without `check` (since `gather` is present but no `leaf`/`check` pairing) — but `gather` alone should not trigger warnings.

- [ ] **Step 9: Commit**

```bash
git add plugins/compose/skills/compose/examples/update-skill-from-upstream.arr
git commit -m "fix(compose): audit examples for v0.11.0 epistemic lint compliance"
```

Note: only stage files actually changed. If `test-fix-loop.arr`, `ci-pipeline.arr`, `frontend-project.arr`, and OSINT examples were left unchanged per the audit, do not stage them.

---

### Task 6: Create `epistemic-debugging.arr`

**Files:**
- Create: `plugins/compose/skills/compose/examples/epistemic-debugging.arr`

- [ ] **Step 1: Write the example**

```arrow
-- Systematic debugging workflow using epistemic operators
-- All five operators: gather, branch, merge, leaf, check
-- Pattern: symptoms → hypotheses → evidence → diagnosis → fix → verify

let verify_fix = \target, suite ->
  loop(
    fix(target: target)
      >>> test(suite: suite)
      >>> check?
      >>> (pass ||| retry)
  )
in

-- Phase 1: Collect symptoms from multiple sources
let evidence =
  gather(from: [logs, metrics, traces])
    >>> (
      extract(type: errors) :: Logs -> Errors
      &&& extract(type: anomalies) :: Metrics -> Anomalies
      &&& extract(type: spans) :: Traces -> Spans
    )
in

-- Phase 2: Form and investigate hypotheses
let investigate =
  branch  -- explore multiple candidate causes
    >>> (
      hypothesis(name: "race condition", check: thread_safety)
      &&& hypothesis(name: "memory leak", check: heap_profile)
      &&& hypothesis(name: "config drift", check: env_diff)
    )
    >>> merge  -- converge into ranked diagnosis
in

-- Phase 3: Deep analysis and verified fix
let diagnose_and_fix =
  leaf(target: root_cause)  -- bounded deep-dive into top-ranked cause
    >>> write_fix(scope: minimal)
    >>> check?
    >>> (pass ||| escalate(to: senior_engineer))
in

-- Main pipeline
evidence
  >>> investigate
  >>> diagnose_and_fix
  >>> verify_fix(changed_module, regression)
```

- [ ] **Step 2: Validate**

```bash
ocaml-compose-dsl plugins/compose/skills/compose/examples/epistemic-debugging.arr
```

Expected: exit 0, no errors. Check stderr for epistemic warnings — `branch` and `merge` are both present so no warning expected. `leaf` and `check` are both present so no warning expected.

- [ ] **Step 3: Commit**

```bash
git add plugins/compose/skills/compose/examples/epistemic-debugging.arr
git commit -m "feat(compose): add epistemic-debugging.arr example with all five epistemic operators"
```

---

### Task 7: Update metadata and root CLAUDE.md

**Files:**
- Modify: `.claude-plugin/marketplace.json:22` (compose version)
- Modify: `plugins/compose/.claude-plugin/plugin.json:3` (description)
- Modify: `CLAUDE.md` (compose description paragraph starting with `**compose (v0.10.0):**`)
- Modify: `CLAUDE.md` (plugin count line: "containing three independent plugins")

- [ ] **Step 1: Bump marketplace.json version**

At `.claude-plugin/marketplace.json:22`, change:

```json
"version": "0.10.0"
```

to:

```json
"version": "0.11.0"
```

- [ ] **Step 2: Update plugin.json description**

At `plugins/compose/.claude-plugin/plugin.json:3`, change:

```json
"description": "Describe multi-step agent workflows using an Arrow-style DSL (>>>, ***, &&&, |||, ?, loop, \\, let...in, (), ;) and validate them structurally",
```

to:

```json
"description": "Describe multi-step agent workflows using an Arrow-style DSL (>>>, ***, &&&, |||, ?, loop, \\, let...in, (), ;) with epistemic operator conventions and structural validation",
```

- [ ] **Step 3: Update root CLAUDE.md compose description**

At `CLAUDE.md:36`, change the compose description paragraph to:

```
**compose (v0.11.0):** Uses an OCaml binary (`ocaml-compose-dsl`) for DSL validation. Install via `scripts/install.sh` (downloads to `~/.local/bin/`). Validate `.arr` files with `ocaml-compose-dsl pipeline.arr` or Markdown files with `ocaml-compose-dsl --literate doc.md`. Arrow combinators: `>>>` (sequential), `|||` (branch), `***` (parallel), `&&&` (fanout), `?` (question/branch), `loop()` (feedback). Abstraction: `\x -> expr` (lambda), `let x = expr in body` (let binding). Other syntax: `()` (unit), `;` (statement separator). Epistemic conventions: `gather`, `branch`, `merge`, `leaf`, `check` (cognitive role markers with lint support). Grammar spec in `references/dsl-grammar.md`, 22 examples in `examples/`.
```

- [ ] **Step 4: Fix plugin count in root CLAUDE.md**

In `CLAUDE.md`, find and change:

```
A Claude Code plugin marketplace (`caasi/dong3`) containing three independent plugins under `plugins/`.
```

to:

```
A Claude Code plugin marketplace (`caasi/dong3`) containing four independent plugins under `plugins/`.
```

Also in the directory tree (after the `kami/` line), add the missing fetch-tips line:

```
  fetch-tips/                       # Platform-specific fetch strategies
```

- [ ] **Step 5: Validate root CLAUDE.md literate arrow blocks (if any)**

```bash
ocaml-compose-dsl --literate CLAUDE.md 2>&1 || echo "No arrow blocks or validation issue"
```

Expected: exit 0 if arrow blocks exist, or a clear "no blocks" indication.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin/marketplace.json plugins/compose/.claude-plugin/plugin.json CLAUDE.md
git commit -m "chore(compose): bump version to 0.11.0 and update metadata descriptions"
```

---

### Task 8: Final validation sweep

Run the full checker across all examples and literate documents to catch any remaining issues.

**Files:**
- All `.arr` files and `.md` files with arrow blocks

- [ ] **Step 1: Validate all examples**

```bash
failed=0
for f in plugins/compose/skills/compose/examples/*.arr; do
  if ! ocaml-compose-dsl "$f" > /dev/null 2>&1; then
    echo "FAIL: $f"
    ocaml-compose-dsl "$f" 2>&1
    failed=1
  fi
done
if [ "$failed" -eq 0 ]; then echo "All examples pass"; fi
```

Expected: "All examples pass"

- [ ] **Step 2: Collect all warnings**

```bash
for f in plugins/compose/skills/compose/examples/*.arr; do
  warnings=$(ocaml-compose-dsl "$f" 2>&1 1>/dev/null)
  if [ -n "$warnings" ]; then
    echo "=== $f ==="
    echo "$warnings"
  fi
done
```

Review each warning. Ensure no unexpected `branch` without `merge` warnings remain (the only legitimate `branch` usage should be in `epistemic-debugging.arr` where `merge` is present, and in `update-skill-from-upstream.arr` where there is no `branch` node).

- [ ] **Step 3: Validate literate documents**

```bash
ocaml-compose-dsl --literate plugins/compose/skills/compose/SKILL.md
ocaml-compose-dsl --literate plugins/compose/skills/compose/references/dsl-grammar.md
ocaml-compose-dsl --literate plugins/compose/skills/compose/README.md
```

Expected: all exit 0.

- [ ] **Step 4: Verify example count matches docs**

```bash
count=$(ls -1 plugins/compose/skills/compose/examples/*.arr | wc -l | tr -d ' ')
echo "Example count: $count"
grep -n "examples in" plugins/compose/skills/compose/README.md
grep -n "examples in" CLAUDE.md
```

Expected: count is 22, both docs say "22 examples".

- [ ] **Step 5: Final commit (if any fixes needed)**

If any issues were found and fixed:

Stage only the specific files that were fixed, then commit:

```bash
git commit -m "fix(compose): address issues found in final v0.11.0 validation sweep"
```
