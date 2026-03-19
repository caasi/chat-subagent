-- Workflow: iteratively fix code until tests pass
loop(
  edit(target: code, change: fix)     -- ref: Edit
    >>> test(suite: relevant)         -- ref: Bash("npm test")
    >>> evaluate(criteria: all_pass)  -- exit loop when all tests green
)
