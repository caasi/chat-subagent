-- Workflow: check upstream binary repo and align compose skill to match
-- Triggers: new release of ocaml-compose-dsl, grammar changes, new features
-- Covers: docs, examples, metadata (marketplace.json, plugin.json), review cycle

-- Phase 1: gather current state from upstream and local skill
-- Note: >>> binds looser than &&&, so each seq chain needs explicit grouping
(
  (fetch_release(repo: "caasi/ocaml-compose-dsl") -- ref: Bash("gh api repos/.../releases/latest")
    >>> extract(fields: [tag_name, body, assets])) -- release version, changelog, binary assets
  &&&
  (fetch_readme(repo: "caasi/ocaml-compose-dsl")  -- ref: Bash("gh api repos/.../contents/README.md")
    >>> extract(fields: [grammar, examples, usage])) -- new EBNF, examples, CLI flags
  &&&
  read(source: "skills/compose/SKILL.md")          -- ref: Read
  &&&
  read(source: "skills/compose/references/dsl-grammar.md") -- ref: Read
  &&&
  read(source: "skills/compose/README.md")         -- ref: Read
)
  -- Phase 2: diff upstream vs local, produce change list
  >>> diff(upstream: release_info, local: skill_files) -- ref: Agent("compare grammar, combinators, CLI flags, examples")
  >>> plan(changes: required_updates)                  -- ref: Agent("list what needs updating")

  -- Phase 3: apply doc and grammar updates in parallel
  >>> (
    update(target: "references/dsl-grammar.md", sections: [ebnf, combinators, examples, warnings]) -- ref: Edit
    ***
    update(target: "SKILL.md", sections: [version, combinators, workflow, patterns, warnings])      -- ref: Edit
    ***
    update(target: "README.md", sections: [combinators, loop_description])                          -- ref: Edit
  )

  -- Phase 4: update existing examples to new syntax + add new examples
  >>> (
    update_examples(dir: "examples/", action: migrate_syntax)  -- ref: Edit (e.g. replace evaluate with ? + |||)
    ***
    add_examples(dir: "examples/", for: new_features)          -- ref: Write (e.g. question-operator.arr)
  )
  >>> update(target: "SKILL.md", section: examples_list)       -- ref: Edit (add new entries, fix stale descriptions)

  -- Phase 5: validate all .arr files still parse
  >>> collect_arr_files(from: "skills/compose/examples/")      -- ref: Glob("**/*.arr")
  >>> validate_all(checker: "ocaml-compose-dsl")               -- ref: Bash("ocaml-compose-dsl *.arr")

  -- Phase 6: bump version and descriptions in metadata
  >>> (
    update(target: ".claude-plugin/marketplace.json", fields: [version, description]) -- ref: Edit
    ***
    update(target: "plugins/compose/.claude-plugin/plugin.json", fields: [description]) -- ref: Edit
  )

  -- Phase 7: verify binary version matches skill requirement
  >>> check_version(binary: "ocaml-compose-dsl", minimum: "0.6.1") -- ref: Bash("ocaml-compose-dsl --version")
