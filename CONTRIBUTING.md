# Contributing to UniversalNumbers.jl

## Prerequisites

- Julia ≥ 1.9
- CMake ≥ 3.22
- A C++20 compiler (GCC 10+, Clang 12+, MSVC 2019+)

The Universal headers are vendored in `deps/`; no separate Universal installation is needed.

## Building from source

```bash
git clone https://github.com/jamesquinlan/UniversalNumbers.jl
cd UniversalNumbers.jl
cmake -S . -B build && cmake --build build   # produces build/libuniversal.so
julia --project=. test/runtests.jl           # run the test suite
```

The Julia module loads `build/libuniversal.so` directly when running from source.
In the installed package, `UniversalNumbers_jll` supplies the pre-built library instead.

## Running tests

```bash
julia --project=. test/runtests.jl        # full suite
julia --project=. test/test_printbits.jl  # bit-inspection demo
julia --project=. test/test_la.jl         # linear algebra demo
```

## Adding a new type — worked example

This section walks through adding `CFloat{23,7}` (a 32-bit classic float with 7 exponent
bits and subnormals enabled) as a complete, concrete example. Every other type follows
the same four-step pattern.

### Step 1: determine the C++ type and interface type

Look up or derive the C++ template instantiation for the type you want.

**`CFloat{23,7}`:**
- C++ type: `sw::universal::cfloat<32, 7, uint32_t, true, false, false>`
  - `32` = total bits, `7` = exponent bits, `uint32_t` = block type
  - `true, false, false` = hasSubnormals, hasMaxExpValues, isSaturating (standard IEEE defaults)
- Total bits = 32, so `IT = uint32_t`, `StorageT = UInt32`

**Choosing IT (interface type):** IT must match `sizeof(CppType)`. Use the table:

| Total bits | `IT` (C++) | `StorageT` (Julia) |
|---|---|---|
| 1–8 | `uint8_t` | `UInt8` |
| 9–16 | `uint16_t` | `UInt16` |
| 17–32 | `uint32_t` | `UInt32` |
| 33–64 | `uint64_t` | `UInt64` |

For most types, IT equals the block type. The exception is multi-word types where the
C++ block type is smaller than the total size (e.g. `hfp64` is 64 bits but uses
`uint32_t` blocks — IT must be `uint64_t`). See the design note at the end of this section.

**Choose a C symbol name** — the convention is `<family><nbits>_<param>`:
- `cfloat32_7` for `CFloat{23,7}` (using nbits=32, exponent=7)

### Step 2: register on the C++ side

Open `src/libuniversal_wrapper.cpp` and add one line to `TYPE_REGISTRY_FULL`:

```cpp
#define TYPE_REGISTRY_FULL \
    X(posit8_0,    uint8_t,  sw::universal::posit<8, 0, uint8_t>) \
    ...
    X(cfloat16_5,  uint16_t, sw::universal::cfloat<16, 5, uint16_t, true, false, false>) \
    X(cfloat32_7,  uint32_t, sw::universal::cfloat<32, 7, uint32_t, true, false, false>) \   // ← new
    ...
```

That single line causes the X-macro to stamp out all ~20 `extern "C"` bridge functions
(`cfloat32_7_from_double`, `cfloat32_7_add`, `cfloat32_7_sqrt`, `cfloat32_7_sin`, …)
automatically — no other C++ changes needed.

**Template parameter reference by family:**

| Family | C++ template | Extra params |
|---|---|---|
| `Posit` | `sw::universal::posit<nbits, es, bt>` | none |
| `CFloat` | `sw::universal::cfloat<nbits, es, bt, hasSubnormals, hasMaxExpValues, isSaturating>` | three bools; standard = `true, false, false` |
| `LNS` | `sw::universal::lns<nbits, rbits, bt>` | none |
| `Takum` | `sw::universal::takum<nbits, rbits, bt>` | rbits=3 fixed by standard |
| `Fixed` | `sw::universal::fixpnt<nbits, rbits, sw::universal::Modulo, bt>` | arithmetic mode; use `sw::universal::Modulo` |
| `HFloat` | `sw::universal::hfloat<ndigits, es, bt>` | ndigits = hex fraction digits |
| `DFloat` | `sw::universal::dfloat<ndigits, es, sw::universal::DecimalEncoding::BID, bt>` | encoding hardcoded to BID |

### Step 3: register on the Julia side

Open `src/UniversalNumbers.jl` and add one tuple to the appropriate registry constant.

**For `CFloat{23,7}`**, add to `TYPE_REGISTRY`:

```julia
const TYPE_REGISTRY = [
    (:Posit,  8,  0,  "posit8_0",   UInt8),
    ...
    (:CFloat, 16, 5,  "cfloat16_5", UInt16),
    (:CFloat, 23, 7,  "cfloat32_7", UInt32),   # ← new  (P1=N=23, P2=ES=7)
    ...
]
```

Tuple layout: `(TypeSymbol, P1, P2, CPrefix, StorageT)`

- `TypeSymbol` — `:Posit`, `:CFloat`, `:LNS`, `:HFloat`, `:DFloat`, `:Fixed`
- `P1` — first user-visible parameter (N for Posit/CFloat/LNS/Fixed, ndigits for HFloat/DFloat)
- `P2` — second user-visible parameter (ES, R, rbits, etc.)
- `CPrefix` — the C symbol name from Step 2 (e.g. `"cfloat32_7"`)
- `StorageT` — Julia unsigned type matching IT from Step 1

**For `Takum`**, add to `TAKUM_REGISTRY` instead:

```julia
const TAKUM_REGISTRY = [
    (8,  "takum8",  UInt8),    # ← new
    (16, "takum16", UInt16),
    (32, "takum32", UInt32),
]
```

Tuple layout: `(N, CPrefix, StorageT)`.

**For `DD`** (double-double), do not use either registry — see the special-case note below.

### Step 4: rebuild and verify

```bash
# Rebuild the shared library
cmake --build build

# Quick smoke test
julia --project=. -e '
    include("src/UniversalNumbers.jl")
    using .UniversalNumbers
    x = CFloat{23,7}(1.5)
    println(x)                          # CFloat{23,7}(1.5)
    println(x + CFloat{23,7}(0.5))     # CFloat{23,7}(2.0)
    println(sqrt(CFloat{23,7}(2.0)))   # CFloat{23,7}(1.4142135...)
    printbits(x)
'

# Full test suite — must still pass
julia --project=. test/runtests.jl
```

### Step 5: update documentation

- **`README.md`**: add a row to the Supported types table
- **`STATUS.md`**: add a row to the Current Registry table
- **`DIARY.md`**: add a dated entry describing what was added and any design decisions

### Design note: multi-word types

Some Universal types store their bits across multiple block words. For example,
`hfloat<14,7,uint32_t>` (hfp64) is 64 bits total but uses two `uint32_t` blocks
internally. The bridge macro parameter `IT` is separate from the C++ block type so
the `memcpy` spans the full value:

```cpp
// sizeof(hfloat<14,7,uint32_t>) == 8 bytes, so IT = uint64_t (not uint32_t)
X(hfp64, uint64_t, sw::universal::hfloat<14, 7, uint32_t>)
```

On the Julia side, `StorageT = UInt64` must match IT. The rule: IT is the smallest
standard integer type whose `sizeof` equals `sizeof(CppType)`. For fixpnt and posit,
using a matching block type (e.g. `uint16_t` for a 16-bit type) avoids multi-word
storage entirely.

### Design note: non-template types (DD)

`dd` (double-double) is a fixed C++ class with no template parameters. Its storage is
exactly 16 bytes (`double hi, lo`). We bridge it using `__uint128_t` as IT on the C++
side and Julia's `UInt128` as StorageT:

```cpp
X(dd, __uint128_t, sw::universal::dd)
```

`dd.hpp` already includes its own `manipulators.hpp` — do not add a separate
`#include <universal/number/dd/manipulators.hpp>` in the wrapper (ODR error).

On the Julia side, `DD` is declared as a plain struct (no type parameters) and all its
methods are written in a direct `let` block rather than the `@eval` loop used for
parametric types. The `TYPE_REGISTRY` and `TAKUM_REGISTRY` are not used for `DD`.

**Negation bit position:** `memcpy` on little-endian x86_64 places `dd.hi` (at C++ offset 0)
into bits 0–63 of the `UInt128`. The sign bit of `hi` is therefore bit 63, not bit 127.
Negation uses `data ⊻ (UInt128(1) << 63)`.

### Types not yet wrapped

| Type | Reason deferred |
|---|---|
| `qd` (quad-double) | 32-byte storage (`double x[4]`); no 32-byte Julia `Unsigned` type. Would need a custom bridge (pointer-based or `NTuple`). |
| `rational` | Missing `color_print` (no `printbits`) and `operator++`/`--` (no `nextfloat`/`prevfloat`). Name conflicts with `Base.Rational`; would use `Frac{N}` if added. |
| `ereal` | Variable-length heap storage (`std::vector<double>`); incompatible with the fixed-`sizeof` memcpy bridge. Requires a pointer/handle-based ABI. |
| `integer` | Semantically an integer, not a float; subtyping `AbstractFloat` would be incorrect. |

## Updating vendored Universal headers

The Universal headers live in `deps/universal/include/`. To update from upstream:

```bash
# Sync your fork, pull locally, then copy the relevant number-system subdirectory
cp -r ~/path/to/universal/include/sw/universal/number/<family>/ \
      deps/universal/include/sw/universal/number/<family>/
cmake --build build
julia --project=. test/runtests.jl
```

Two files in `deps/` intentionally diverge from upstream and should be preserved
when re-vendoring `takum/`:
- `takum/math/functions/classify.hpp` — adds `#include <cmath>` and predicate-based
  `fpclassify` (upstream uses a `long double` cast)
- `takum/math/functions/minmax.hpp` — NaR symmetry guards in `min`/`max`

## Building the JLL (Phase 2)

The pre-built library is distributed as `UniversalNumbers_jll` built with
[BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

```bash
# From the BinaryBuilder environment
julia build_tarballs.jl --target x86_64-linux-gnu
```

Target platforms: `x86_64-linux-gnu`, `aarch64-linux-gnu`, `x86_64-apple-darwin`,
`aarch64-apple-darwin`, `x86_64-w64-mingw32`.

After a new JLL is published to the binary cache, bump the `[compat]` entry for
`UniversalNumbers_jll` in `Project.toml` and update `src/UniversalNumbers.jl` to
load from the JLL artifact path instead of `build/libuniversal.so`.
