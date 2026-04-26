## Jel.Flavour.File

Read and write files. Designed for codebase exploration and modification.

---

### Operators

#### `file.tree`

List all files under a path.

```json
{ "file.tree": ["path"] }
```

- Returns newline-separated file paths sorted alphabetically.
- Returns `null` if path not found.
- Equivalent to: `find path -type f | sort`

```json
{ "file.tree": ["lib/"] }
```

---

#### `file.grep`

Search for a pattern in files recursively.

```json
{ "file.grep": ["pattern", "path"] }
{ "file.grep": ["pattern", "path", "filter"] }
```

- Returns matching lines in `file:line:content` format.
- Returns `null` if no matches.
- Optional `filter` limits to files matching a glob e.g. `"*.ex"`.
- Equivalent to: `grep -rn pattern path` or `grep -rn --include=filter pattern path`

```json
{ "file.grep": ["defmodule", "lib/"] }
{ "file.grep": ["defmodule", "lib/", "*.ex"] }
```

---

#### `file.context`

Read lines around a specific line number.

```json
{ "file.context": ["path", line, context] }
```

- Returns lines from `line - context` to `line + context`, prefixed with line numbers.
- Clamps to file bounds automatically.
- Returns `null` if file not found.
- Equivalent to: `awk "NR>=from && NR<=to {print NR\": \"$0}" path`

```json
{ "file.context": ["lib/jel/core.ex", 45, 10] }
```

Pairs naturally with `file.grep` — grep returns `file:line:content`, extract the line number, pass to `file.context`.

---

#### `file.head`

Read the first n lines of a file.

```json
{ "file.head": ["path", n] }
```

- Returns the first `n` lines as a string.
- Returns `null` if file not found.
- Equivalent to: `head -n n path`

```json
{ "file.head": ["lib/jel/core.ex", 30] }
```

---

#### `file.write`

Write content to a file, creating or overwriting it.

```json
{ "file.write": ["path", "content"] }
```

- Returns the file path on success.
- Returns `null` on failure.

```json
{ "file.write": ["lib/my_module.ex", "defmodule MyModule do\nend\n"] }
```

---

#### `file.patch`

Apply a unified diff to an existing file.

```json
{ "file.patch": ["path", "diff"] }
```

- Writes the diff to a temp file, runs `patch`, cleans up regardless of outcome.
- Returns the file path on success.
- Returns `null` if the patch fails.
- Equivalent to: `patch path diff_file`

```json
{ "file.patch": [{"get": "path"}, {"get": "diff"}] }
```

---

### Usage

```elixir
Jel.eval(json, state, flavours: [Jel.Flavour.File])
```

### Context Generation

```elixir
Jel.Context.generate(flavours: [Jel.Flavour.File])
```
