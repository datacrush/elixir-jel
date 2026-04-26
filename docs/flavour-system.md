## Jel.Flavour.System

Run arbitrary system commands and capture their output.

---

### Operators

#### `cmd`

Run a system command and return its stdout.

```json
{ "cmd": ["command", "arg1", "arg2", ...] }
```

- Evaluates all args before execution.
- Returns trimmed stdout as a string on exit code 0.
- Returns `null` on non-zero exit or error.

**Examples:**

```json
{ "cmd": ["echo", "hello"] }
{ "cmd": ["mix", "test"] }
{ "cmd": ["ls", "-la", "lib/"] }
```

---

### Usage

```elixir
Jel.eval(json, state, flavours: [Jel.Flavour.System])
```

### Context Generation

```elixir
Jel.Context.generate(flavours: [Jel.Flavour.System])
```
