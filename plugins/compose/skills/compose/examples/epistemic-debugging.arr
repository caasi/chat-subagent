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
