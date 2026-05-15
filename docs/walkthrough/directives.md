## Conditional compilation via Compiler Directives

In very rare cases, it may be beneficial to only parse code if certain compiler flags are set.
In C/C++, this is done with macros like `#ifdef DEF_NAME ... #endif`.

You can achieve similar functionality in Paisley, where code will not be parsed if certain conditions aren't met at compile time.
In paisley, compiler directives start with `$` and continue until a line ending, `;` or `$`.
They cannot be used inside strings or expressions, but they can wrap expressions on the same line.

```
# Conditions can be chained with `and`, `or` and `()`.
$if (version >= 1.2.3 or build = desktop) and target = lua
...
$elif <expression>
...
$else
...
$end

# You can also warn or error at compile time if certain conditions aren't met
$if version < 1
$error "At least version 1.0.0 is required!"
$elif version >= 2
$warn "This might work in version 2.x.x, but we're not sure."
$else
$info "You've got the correct version :)"
$end
```

```
# This example uses the deprecated length operator if still supported.
# Otherwise, the `len()` function is used.
let array = {0:9}
let length = $if version >= 2$ {len(array)} $else$ {&array} $end$
print {length}
```

The following build flags are supported:
- `version`: The Paisley version at compile time, formatted as `X.Y.Z`.
- `build`: The build of Paisley that's being targeted. Valid values are `plasma` or `desktop`.
- `target`: The runtime that's being targeted. Valid values are `lua`, `c` or `cpp`.

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: [comments.md]
[next]: []
