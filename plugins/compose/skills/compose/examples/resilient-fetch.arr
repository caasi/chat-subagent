-- Workflow: fetch from primary source, fall back to mirror on failure
(fetch(url: primary)? ||| fetch(url: mirror))  -- ref: WebFetch
  >>> transform(mapping: schema_v2)
  >>> write(dest: "output.json")              -- ref: Write
