## Jel.Flavour.Git

Interact with a git repository. Covers exploration, inspection, and committing changes.

---

### Operators

#### `git.log`

Show recent commits.

```json
{ "git.log": [n] }
{ "git.log": ["path", n] }
```

- Returns commit hashes and messages, one per line.
- Optional `path` scopes results to commits touching that file.
- Returns `null` if no history.
- Equivalent to: `git log --oneline -n n` or `git log --oneline -n n -- path`

```json
{ "git.log": [10] }
{ "git.log": ["lib/jel/core.ex", 5] }
```

---

#### `git.diff`

Show changes between refs or between a ref and the working tree.

```json
{ "git.diff": ["ref"] }
{ "git.diff": ["ref1", "ref2"] }
```

- Single ref diffs against the working tree.
- Two refs diffs between them.
- Returns unified diff as a string.
- Returns `null` on error.
- Equivalent to: `git diff ref` or `git diff ref1 ref2`

```json
{ "git.diff": ["HEAD"] }
{ "git.diff": ["HEAD~1", "HEAD"] }
```

---

#### `git.blame`

Show who last modified each line in a range.

```json
{ "git.blame": ["path", line, context] }
```

- Returns annotated lines showing commit hash, author, and content.
- Uses the same `line ± context` window convention as `file.context`.
- Equivalent to: `git blame -L from,to path`

```json
{ "git.blame": ["lib/jel/core.ex", 45, 5] }
```

---

#### `git.show`

Show full details of a commit including its diff.

```json
{ "git.show": ["ref"] }
```

- Returns commit metadata and diff as a string.
- Returns `null` if ref not found.
- Equivalent to: `git show ref`

```json
{ "git.show": ["HEAD"] }
{ "git.show": ["a1b2c3d"] }
```

---

#### `git.status`

Show the working tree status.

```json
{ "git.status": [] }
```

- Returns current branch, staged and unstaged changes.
- Equivalent to: `git status`

---

#### `git.branches`

List all local and remote branches.

```json
{ "git.branches": [] }
```

- Returns branch names one per line, current branch prefixed with `*`.
- Equivalent to: `git branch -a`

---

#### `git.checkout`

Switch to a branch, or create and switch to a new one.

```json
{ "git.checkout": ["branch"] }
{ "git.checkout": ["branch", true] }
```

- Pass `true` as the second arg to create the branch if it does not exist.
- Returns `null` on failure.
- Equivalent to: `git checkout branch` or `git checkout -b branch`

```json
{ "git.checkout": ["main"] }
{ "git.checkout": ["feat/my-feature", true] }
```

---

#### `git.add`

Stage a file for commit.

```json
{ "git.add": ["path"] }
```

- Returns git output on success.
- Returns `null` on failure.
- Equivalent to: `git add path`

```json
{ "git.add": ["lib/my_module.ex"] }
```

---

#### `git.commit`

Commit staged changes with a message.

```json
{ "git.commit": ["message"] }
```

- Returns git output on success.
- Returns `null` on failure.
- Equivalent to: `git commit -m message`

```json
{ "git.commit": ["feat: add new operator"] }
```

---

### Typical Workflow

```json
{ "git.checkout": ["feat/my-change", true] }
{ "file.write": ["lib/my_module.ex", "..."] }
{ "git.add": ["lib/my_module.ex"] }
{ "git.commit": ["feat: implement my change"] }
```

---

### Usage

```elixir
Jel.eval(json, state, flavours: [Jel.Flavour.Git])
```

### Context Generation

```elixir
Jel.Context.generate(flavours: [Jel.Flavour.Git])
```
