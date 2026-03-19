-- Mixing *** and &&& share the same precedence (infixr 3).
-- Without grouping, the rightmost operator binds first:
--   a *** b &&& c  parses as  a *** (b &&& c)
--   a &&& b *** c  parses as  a &&& (b *** c)
-- Use explicit parentheses when the default binding is not what you want.

-- Without grouping: lint gets its own input, test and typecheck fanout on shared input
--   parses as: lint *** (test &&& typecheck)
lint *** test &&& typecheck
  >>> report(format: summary)
