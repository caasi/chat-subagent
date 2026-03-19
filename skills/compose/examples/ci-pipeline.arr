-- Workflow: lint + test in parallel (fanout), gate, build for multiple platforms, upload
(lint &&& test)
  >>> gate(require: [pass, pass])
  >>> (build_linux(profile: static) *** build_macos(profile: release))
  >>> upload(tag: "v0.1.0")       -- ref: Bash("gh release create")
