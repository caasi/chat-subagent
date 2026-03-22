-- Workflow: iteratively fix code until tests pass
loop(
  edit(target: code, change: fix)     -- ref: Edit
    >>> test(suite: relevant)         -- ref: Bash("npm test")
    >>> "all tests pass"?
    >>> (done ||| retry)              -- exit loop on pass, retry on fail
)
