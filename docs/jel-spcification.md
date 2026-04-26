## ⭐ JEL Core v0.3 — Spec (with variadic operators)

**Goal:** Tiny, portable, JSON-encoded expression language.
**Host-agnostic. Domain-agnostic. Flavors sit on top.**

### 1. Values and Result Type

Every JEL Core expression evaluates to exactly one of:

- `boolean`
- `number`
- `string`
- `null`

Never arrays, objects, functions.

---

### 2. Expression Shapes

A JEL Core expression is one of:

1. **Literal**

   ```json
   42
   "hello"
   true
   false
   null
   ```

2. **Path lookup**

   ```json
   { "get": "a.b.c" }
   ```

3. **Operator expression**

   ```json
   { "op": [ expr1, expr2, ... ] }
   ```

Where:

- `"op"` is one of the defined operators below.
- The value **must** be an array (possibly empty).
- No additional keys are allowed in that object in Core.

---

### 3. Path Semantics (`get`)

Expression:

```json
{ "get": "a.b.0.c" }
```

- Split by `"."` into `["a", "b", "0", "c"]`.

- Start from the provided `state`.

- For each segment:
  - If `state == null` → result is `null`.
  - If segment is an integer-like string (e.g. `"0"`):
    - If `state` is an array and index in range → descend.
    - Else → `null`.

  - Else (string segment):
    - If `state` is an object/map and key exists → descend.
    - Else → `null`.

- If you complete all segments → result is the final value.

- Any failure along the way → `null`.

No exceptions, no errors, no special-casing.

---

### 4. Truthiness

Used only by boolean ops.

**Falsey:**

- `false`
- `null`
- `0`
- `""` (empty string)

**Truthy:**

- `true`
- any non-zero number
- any non-empty string

---

### 5. Operators

#### 5.1 Boolean

All return **boolean**.

##### `&&` — logical AND (variadic, short-circuit)

Shape:

```json
{ "&&": [expr1, expr2, ..., exprN] }
```

Semantics:

- Evaluate left-to-right with short-circuit.
- Identity: `&&([]) = true`.
- For `[x]`, result is `truthiness(x)`.

More precisely:

- Empty list → `true`.
- Non-empty: evaluate each expr:
  - If any evaluates to falsey → result `false` (and stop).
  - Otherwise → `true`.

Wrong shape (non-array) → `null`.

##### `||` — logical OR (variadic, short-circuit)

Shape:

```json
{ "||": [expr1, expr2, ..., exprN] }
```

Semantics:

- Evaluate left-to-right with short-circuit.
- Identity: `||([]) = false`.
- For `[x]`, result is `truthiness(x)`.

More precisely:

- Empty list → `false`.
- Non-empty: evaluate each expr:
  - If any evaluates to truthy → result `true` (and stop).
  - Otherwise → `false`.

Wrong shape → `null`.

##### `!` — logical NOT (unary only)

Shape:

```json
{ "!": [expr] }
```

- Evaluate `expr`.
- Return `!truthiness(expr)` (boolean).
- Wrong arity (0 or >1 args, or non-array) → `null`.

---

#### 5.2 Comparison Operators (binary only)

All return **boolean**.

Allowed:

- `==`
- `!=`
- `>`
- `>=`
- `<`
- `<=`

Shape:

```json
{ "==": [left, right] }
```

or any of the others with exactly **two** args.

Rules:

- If the args array is not length 2 → `null`.
- Evaluate both sides first.
- Type rules:
  - `==` / `!=`:
    - Numbers: numeric equality.
    - Strings: string equality.
    - Booleans: boolean equality.
    - `null == null` → `true`.
    - Any other type mismatch → `false`.

  - Ordering ops (`>`, `>=`, `<`, `<=`):
    - Only valid for numbers.
    - If either side is non-numeric → `false`.

---

#### 5.3 Arithmetic Operators

Return **number** on success, `null` on error.

Allowed:

- `+` (variadic)
- `*` (variadic)
- `-` (variadic, left fold, no identity)
- `/` (variadic, left fold, no identity)
- `%` (binary only)

##### `+` — sum (variadic)

```json
{ "+": [expr1, expr2, ..., exprN] }
```

- Identity: `+([]) = 0`.
- Each expr must evaluate to a number; otherwise → `null`.
- Result is sum of all evaluated numbers.

##### `*` — product (variadic)

```json
{ "*": [expr1, expr2, ..., exprN] }
```

- Identity: `*([]) = 1`.
- Each expr must evaluate to a number; otherwise → `null`.
- Result is product.

##### `-` — subtraction (variadic left fold)

```json
{ "-": [expr1, expr2, ..., exprN] }
```

- If `args` is empty or length 1 → `null`.
- Evaluate first as initial accumulator.
- Each remaining expr must be a number; otherwise → `null`.
- Result: `((expr1 - expr2) - expr3) ...`.

##### `/` — division (variadic left fold)

```json
{ "/": [expr1, expr2, ..., exprN] }
```

- If `args` is empty or length 1 → `null`.
- Evaluate first as initial accumulator.
- Each remaining expr must be a number:
  - If any evaluated divisor is 0 → `null`.
  - Any non-number → `null`.

- Result: `((expr1 / expr2) / expr3) ...`.

##### `%` — modulo (binary)

```json
{ "%": [left, right] }
```

- If `args` length != 2 → `null`.
- Both must be numbers, `right != 0`:
  - Otherwise → `null`.

- Result: remainder.

---

### 6. Error / Invalid Cases

- Unknown operator → `null`.
- Wrong arity (except variadic ops as defined) → `null`.
- Non-array arg list → `null`.
- Type mismatches for arithmetic → `null`.
- Division/modulo by zero → `null`.
- Path resolution failure → `null`.
- Comparison type mismatch → `false` (as per rules above).

Interpreter implementations _must not throw_ for Core; they must collapse to `null`/`false` per above.
