# Compose Skill v0.10.0 Update — Design Spec

## Context

The upstream `ocaml-compose-dsl` binary has reached v0.10.0, while the compose skill in dong3 is at v0.7.0. Three upstream releases (v0.8.0, v0.9.0, v0.10.0) have accumulated significant new features. This update aligns the compose skill with the upstream binary.

### Upstream Changelog (v0.7.0 → v0.10.0)

**v0.8.0 (2026-03-26):**
- Lambda expressions (`\name -> expr`) with beta reduction
- String literals as first-class expressions
- Mixed positional/named call arguments (`call_arg = arg_key ":" value | seq_expr`)
- Literate mode (`--literate` flag) for checking `arrow`/`arr` code blocks in Markdown

**v0.9.0 (PR #29):**
- **BREAKING:** `let` bindings require explicit `in` keyword (`let x = expr in body`)
- Parenthesized groups accept `let...in` (`(let x = a in x)`)
- Migration hint error for old `let` syntax (without `in`)

**v0.10.0 (PRs #30, #31, #32):**
- Unit value expression and type: `()` as value, `()` as type name in annotations
- `f()` produces `[Positional Unit]` (not empty args)
- Semicolon `;` statement separator: `a >>> b; c >>> d`
- `program = expr list` — multiple independent pipelines in one file
- `let`, `loop`, `in` are now reserved words (excluded from `ident`)
- Parser rewritten with Menhir + sedlex (better error messages, no user-facing syntax change)

## Approach

**Upstream sync:** use the upstream README's EBNF as source of truth. Rewrite `dsl-grammar.md` to match. Expand SKILL.md with new sections but keep it concise — detailed grammar stays in `references/`. Skill version jumps to v0.10.0 to align with upstream binary.

If SKILL.md grows too large, offload detail into `references/` and let the LLM discover it.

## Design

### 1. File Structure

```
plugins/compose/skills/compose/
  SKILL.md                              # Entry point — concise, core concepts + workflow
  README.md                             # User-facing docs
  references/
    dsl-grammar.md                      # Full EBNF + combinator table (rewrite from upstream)
  examples/
    (existing .arr files)               # Some updated to use let/lambda where appropriate
    lambda.arr                          # NEW
    let-binding.arr                     # NEW
    unit-type.arr                       # NEW
    multi-statement.arr                 # NEW
  scripts/
    install.sh                          # No change (already fetches latest)
```

### 2. SKILL.md Changes

#### Prerequisites / Version Check

- Change minimum version from `v0.7.0` to `v0.10.0`

#### Core Concepts — Arrow Combinators Table

Add to existing table:

| Syntax | Meaning |
|--------|---------|
| `\x -> expr` | Lambda — parameterized workflow fragment |
| `let x = expr in body` | Let binding — name a workflow fragment |
| `()` | Unit — no-input value or trigger |
| `;` | Statement separator — multiple independent pipelines |

#### Core Concepts — New Section: Abstraction

Position: after Type Annotations, before Workflow.

Content covers lambda and let as **abstraction tools for organizing complex workflows** — not as reduction targets. Key points:

- Lambda: `\name -> hello(to: name) >>> respond` — parameterized workflow fragment
- Multi-param lambda: `\trigger, fix -> loop(trigger >>> (pass ||| fix))`
- Let: `let review = ... in phase1 >>> phase2` — name and reuse workflow fragments
- `let` requires `in` to delimit scope
- `let...in` works inside parentheses: `(let x = a in x)`
- Reserved words: `let`, `loop`, `in` cannot be used as identifiers
- Named and positional arguments can be freely mixed in calls

Example:

```
let review = \trigger, fix ->
  loop(trigger >>> (pass ||| fix))
in
let phase1 = gather >>> review(check?, rework) in
let phase2 = build >>> review(test?, fix) in
phase1 >>> phase2
```

#### Core Concepts — New Section: Statements

- `;` separates independent pipelines: `planning >>> commit; implementation >>> branch >>> commit`
- Trailing semicolon is optional
- Semicolons are not allowed inside parentheses

#### Core Concepts — New Section: Unit

- `()` as a value expression: represents "no input" or "trigger"
- `()` as a type name in annotations: `:: () -> Server`, `:: Input -> ()`
- `f()` produces `[Positional Unit]`, not an empty argument list

#### Type Annotations

Add that `()` is a valid type name alongside identifiers.

#### Workflow — Validate Structure

Add literate mode after existing file validation:

```bash
ocaml-compose-dsl --literate README.md
```

Explain: use `arrow` or `arr` as the code fence language tag. Any Markdown file can be a literate Arrow document.

#### Common Patterns

Add 1-2 patterns using let/lambda (e.g., the `review` abstraction above).

#### Additional Resources — Examples

Update the list to include the four new `.arr` files.

### 3. references/dsl-grammar.md — Full Rewrite

Replace the entire file with the upstream EBNF grammar, adapted for the compose skill context:

```ebnf
program     = { ";" } , [ stmt , { ";" , { ";" } , stmt } , { ";" } ] ;
stmt        = let_expr | pipeline ;
let_expr    = "let" , ident , "=" , seq_expr , "in" , stmt ;
lambda      = "\" , ident , { "," , ident } , "->" , seq_expr ;
pipeline    = seq_expr ;
seq_expr    = alt_expr , ">>>" , seq_expr | lambda | alt_expr ;
alt_expr    = par_expr , "|||" , alt_expr | par_expr ;
par_expr    = typed_term , ( "***" | "&&&" ) , par_expr | typed_term ;
typed_term  = term , [ "::" , type_expr ] ;
type_expr   = type_name , "->" , type_name ;
type_name   = ident | "(" , ")" ;
term        = ident , [ "(" , [ call_args ] , ")" ] , [ "?" ]
            | string , [ "?" ]
            | "(" , ")" , [ "?" ]
            | "loop" , "(" , seq_expr , ")"
            | "(" , stmt , ")" ;
call_args   = call_arg , { "," , call_arg } ;
call_arg    = arg_key , ":" , value | seq_expr ;
arg_key     = ident | "in" ;
...
```

Plus: combinator table (including `;`, `\`, `let...in`, `()`), node design section, examples, structural rules, warnings.

### 4. New Example Files

**`lambda.arr`:**
- Basic lambda: `\name -> hello(to: name) >>> respond`
- Multi-param: `\trigger, fix -> loop(trigger >>> (pass ||| fix))`
- As positional arg: `let v = some_pipeline in push(remote: origin, v)`

**`let-binding.arr`:**
- Named workflow fragments with `let...in`
- Nested lets
- `let` inside parentheses: `(let x = a in x)`
- Multi-phase workflow composition using let

**`unit-type.arr`:**
- `()` as standalone value
- `() >>> start_server :: () -> Server`
- `f()` semantics
- `()` in type annotations

**`multi-statement.arr`:**
- `;`-separated independent pipelines
- Trailing semicolon
- Real-world example: planning + implementation as separate statements

### 5. Existing Example Updates

**Candidates for let/lambda introduction:**

- **`frontend-project.arr`** (230 lines) — repeated pipeline fragments → extract with let/lambda
- **`ci-pipeline.arr`** — build steps → name with let
- **`test-fix-loop.arr`** — loop body → parameterize with lambda
- **`update-skill-from-upstream.arr`** — reorganize with let, reflect actual session workflow (see section 7)

**Leave unchanged:**
- `data-pipeline.arr`, `resilient-fetch.arr`, `numeric-literals.arr`, `unicode-identifiers.arr`, `mixed-par-fanout.arr`, `question-operator.arr`, `type-annotations.arr` — these demonstrate basic syntax and work as foundation examples
- OSINT examples — domain-specific, no benefit from abstraction

### 6. Version Bumps and Metadata

| File | Field | Old | New |
|------|-------|-----|-----|
| `marketplace.json` | compose version | `0.7.0` | `0.10.0` |
| `SKILL.md` | Version Check text | `v0.7.0` | `v0.10.0` |

`plugin.json` has no version field — no change. `install.sh` already fetches latest — no change.

### 7. update-skill-from-upstream.arr Rewrite

Rewrite to reflect what we actually did in this session, using let/lambda to organize phases:

**New elements:**
- `let fetch_upstream = \repo -> ...` — abstract the fetch+extract pattern (used twice)
- `let` to name each phase
- Phase 1: add `fetch_prs` (we used `gh pr view` to understand new features)
- Phase 3: add `update(target: "CLAUDE.md")` — repo root CLAUDE.md also needs updating
- Phase 4: clearer split between "update old examples with new syntax" and "add new examples"
- Phase 5: add `--literate` validation for SKILL.md/README arrow blocks
- Phase 6: minimum version → `v0.10.0`
- Potentially use `;` to separate independent phases

### 8. README.md Updates

- "What it does" — add lambda/let abstraction, literate mode, multi-statement
- Arrow Combinators table — add `\`, `let...in`, `()`, `;`
- Examples — add a short demo of lambda/let
- Install section — no change

### 9. CLAUDE.md (repo root) Updates

- Compose description: add `let...in`, `\` (lambda), `;`, `()` to the Arrow combinators list
- Version reference: `v0.10.0`

## Out of Scope

- Changes to `install.sh` (already fetches latest)
- Changes to `plugin.json` (no version field)
- New OSINT examples
- Type checker implementation (upstream has none, annotations remain documentation-only)
