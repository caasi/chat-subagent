-- The ? operator marks a step as producing Either for ||| branching.
-- Only the "try" side gets ?. The fallback side does not.

-- Basic: node? feeding into |||
-- fetch(url: primary)? ||| fetch(url: mirror)

-- String? in a loop with ||| exit condition
-- loop(
--   generate >>> verify >>> "all tests pass"?
--   >>> (done ||| fix_and_retry)
-- )

-- Upstream in a >>> chain feeding |||
validate(schema: config)?
  >>> (apply(target: production) ||| rollback(to: previous))
