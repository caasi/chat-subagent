# Arrow DSL Grammar Reference

## EBNF

```ebnf
pipeline = seq_expr ;

seq_expr = alt_expr , ">>>" , seq_expr              (* sequential — infixr 1 *)
         | alt_expr ;
alt_expr = par_expr , "|||" , alt_expr              (* branch — infixr 2 *)
         | par_expr ;
par_expr = term , ( "***" | "&&&" ) , par_expr      (* parallel / fanout — infixr 3 *)
         | term ;

term     = node
         | "loop" , "(" , seq_expr , ")"            (* feedback loop *)
         | "(" , seq_expr , ")"                    (* grouping *)
         ;

node     = ident , [ "(" , [ args ] , ")" ] ;

args     = arg , { "," , arg } ;

arg      = ident , ":" , value ;

value    = string
         | ident
         | "[" , [ value , { "," , value } ] , "]"
         ;

ident    = ( letter | "_" ) , { letter | digit | "-" | "_" } ;

string   = '"' , { any char - '"' } , '"' ;

comment  = "--" , { any char - newline } ;
```

All operators are right-associative (matching Haskell Arrow fixity). Comments can appear after any term and are attached to the preceding node as purpose descriptions or reference tool annotations.

## Combinators

| Combinator | Syntax | Precedence | Type | Expands To |
|------------|--------|------------|------|------------|
| Sequential | `>>>` | infixr 1 | `Arrow a b → Arrow b c → Arrow a c` | Sequential tool calls |
| Branch | `\|\|\|` | infixr 2 | `Arrow a c → Arrow b c → Arrow (Either a b) c` | Fallback logic |
| Parallel | `***` | infixr 3 | `Arrow a b → Arrow c d → Arrow (a,c) (b,d)` | Multiple tool calls in one message |
| Fanout | `&&&` | infixr 3 | `Arrow a b → Arrow a c → Arrow a (b,c)` | Multiple tool calls, same input |
| Loop | `loop(expr)` | — | `Arrow (a,s) (b,s) → Arrow a b` | Retry / iterative refinement |
| Group | `(expr)` | — | Precedence grouping | No direct expansion |

`***` is right-associative: `a *** b *** c` types as `(A, (B, C))`.

## Node Design

Nodes describe **purpose**, not specific tools. Each node may include:

- **Name** — what this step accomplishes (required)
- **Arguments** — key-value parameters (optional)
- **Comment** — purpose description or reference tool annotation (optional, via `--`)

The agent expanding the pipeline decides which concrete tool to use based on the node's purpose and available tools. Reference tools in comments are hints, not constraints.

## Examples

### Sequential Pipeline

```
read(source: "data.csv")          -- read the data source
  >>> parse(format: csv)          -- structure raw data
  >>> filter(condition: "age > 18")
  >>> format(as: report)
```

### Parallel Composition

```
read(source: "data.csv")
  >>> parse(format: csv)
  >>> (count *** collect(fields: [email]))  -- parallel: count & collect
  >>> format(as: report)
```

### Fanout

```
(lint &&& test)
  >>> gate(require: [pass, pass])
  >>> (build_linux(profile: static) *** build_macos(profile: release))
  >>> upload(tag: "v0.1.0")
```

`&&&` feeds the same input to both sides. `***` feeds separate inputs to each side.

### Branch / Fallback

```
(fetch(url: endpoint)             -- try remote first
  ||| load(from: cache, key: k))  -- fall back to cache
  >>> transform(mapping: schema_v2)
  >>> write(dest: "output.json")
```

### Feedback Loop

```
loop(
  generate(artifact: code, from: spec)  -- produce code from spec
    >>> verify(method: test_suite)       -- run tests
    >>> evaluate(criteria: all_pass)     -- check pass/fail
)
```

### Cross-Agent Portability

The same node can be expanded differently by different agents:

```
read(source: "data.csv")

  Claude Code  →  Read tool
  shell agent  →  cat data.csv
  browser agent → fetch("/api/data.csv")
```

## Structural Rules

The checker validates **syntax structure** only:

- Balanced parentheses
- Valid operator usage and precedence
- Well-formed node definitions

The checker does NOT validate:

- Semantic compatibility between nodes
- Whether `***` branches eventually merge (data flow analysis)
- Whether `|||` branches both produce output
- Whether `loop` contains a termination condition
- Whether reference tools exist
- Tool parameter formats
- Anything requiring execution
