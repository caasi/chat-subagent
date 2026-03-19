-- Workflow: read, transform, and output a data report
read(source: "data.csv")          -- ref: Read
  >>> parse(format: csv)          -- ref: Bash("csvtool")
  >>> filter(condition: "age > 18")
  >>> (count *** collect(fields: [email]))
  >>> format(as: report)          -- ref: Write
