# UniversalNumbers.jl

Julia bindings for the [Stillwater Universal](https://github.com/stillwater-sc/universal)
C++ number-systems library. Exposes **posits**, **classic floats (cfloat)**,
**logarithmic number systems (LNS)**, **takum**, **IBM hex float (hfloat)**, and
**decimal float (dfloat)** as first-class Julia numbers that implement `AbstractFloat`
and compose with the standard library.

## Installation

```julia
pkg> add UniversalNumbers
```

Requires Julia ≥ 1.9. The pre-built bridge library is downloaded automatically via
`UniversalNumbers_jll`; no C++ compiler or CMake is needed.

## Quick start

```julia
using UniversalNumbers

a = Posit{16,1}(1.5)
b = Posit{16,1}(2.5)
a + b                        # Posit{16,1}(4.0)
sqrt(Posit{32,2}(2.0))      # Posit{32,2}(1.4142135623842478)
a + 2.5                      # promotes 2.5 → Posit{16,1}: Posit{16,1}(4.0)

using LinearAlgebra
A = [Posit{32,2}(4) Posit{32,2}(1); Posit{32,2}(1) Posit{32,2}(3)]
b = [Posit{32,2}(1), Posit{32,2}(2)]
A \ b                        # solve Ax = b in posit arithmetic
```

## Supported types

Each type is a Julia `AbstractFloat` subtype backed by a specific Universal C++
template instantiation. The type parameters are always integers (no trailing
block-type argument needed from user code).

| Julia type | Universal C++ type | Total bits | Notes |
|---|---|---|---|
| `Posit{8,0}` | `posit<8, 0>` | 8 | |
| `Posit{16,1}` | `posit<16, 1>` | 16 | |
| `Posit{32,2}` | `posit<32, 2>` | 32 | |
| `Posit{19,2}` | `posit<19, 2>` | 19 (in 32-bit word) | |
| `Posit{19,3}` | `posit<19, 3>` | 19 (in 32-bit word) | |
| `CFloat{8,2}` | `cfloat<8, 2>` | 8 | quarter precision |
| `CFloat{8,3}` | `cfloat<8, 3>` | 8 | |
| `CFloat{8,4}` | `cfloat<8, 4>` | 8 | |
| `CFloat{16,5}` | `cfloat<16, 5>` | 16 | half precision |
| `LNS{16,5}` | `lns<16, 5>` | 16 | |
| `LNS{32,16}` | `lns<32, 16>` | 32 | |
| `Takum{8}` | `takum<8, 3>` | 8 | rbits=3 fixed by standard |
| `Takum{16}` | `takum<16, 3>` | 16 | rbits=3 fixed by standard |
| `Takum{32}` | `takum<32, 3>` | 32 | rbits=3 fixed by standard |
| `HFloat{6,7}` | `hfloat<6, 7>` | 32 | IBM hfp32; no NaN/Inf |
| `HFloat{14,7}` | `hfloat<14, 7>` | 64 | IBM hfp64; no NaN/Inf |
| `DFloat{7,6}` | `dfloat<7, 6, BID>` | 32 | IEEE 754-2008 decimal32 |
| `DFloat{16,8}` | `dfloat<16, 8, BID>` | 64 | IEEE 754-2008 decimal64 |
| `DD` | `dd` | 128 | double-double; ~106 significand bits |

Using an unregistered combination raises an informative error:

```julia
julia> Posit{24,1}(1.0)
ERROR: Posit{24, 1} is not instantiated in the registry. Please add it to
UniversalNumbers.TYPE_REGISTRY and rebuild.
```

To request a new type, open an issue or see [CONTRIBUTING.md](CONTRIBUTING.md).

## AbstractFloat behavior

All types implement the full `AbstractFloat` interface:

- **Construction** from any `Real`: `Posit{16,1}(1.5)`, `CFloat{8,2}(2)`, `LNS{16,5}(pi)`
- **Conversion back**: `Float64(x)`, `Float32(x)`
- **Arithmetic**: `+`, `-`, `*`, `/`, unary `-`, `abs`
- **Math functions**: `sqrt`, `sin`, `cos`, `exp`, `log` — computed in the native number
  system by Universal's C++ math library; rounding is determined by the type's parameters
- **Comparisons**: `==`, `<`, `<=` use Universal's native operators — exact, no float round-trip
- **Promotion**: mixed expressions like `p + 2.5` or `2 * p` convert the standard number
  into the universal type; the computation happens in posit/cfloat/LNS/takum arithmetic
- **Constants**: `zero`, `one`, `eps`, `floatmin`, `floatmax`
- **Predicates**: `iszero`, `isnan`, `isinf`
- **Adjacent values**: `nextfloat(x)` / `prevfloat(x)` via Universal's `++`/`--` operators
- **Random generation**: `rand(Posit{16,1})`, `rand(Posit{16,1}, 4, 4)`
- **Broadcasting**: full `.` syntax — `sin.(A)`, `A .+ 1.0`

The raw bit encoding is always accessible as `x.data`.

## NaR: how posits handle "not a real"

Posits have no `Inf` and no signed zero; instead they reserve one encoding `100...0`
called **NaR** (Not-a-Real). Its semantics differ from IEEE NaN:

```julia
julia> n = Posit{16,1}(NaN)     # NaN converts to NaR
Posit{16,1}(NaN)

julia> isnan(n)
true

julia> n == n                    # NaR == NaR is TRUE (IEEE NaN: false)
true

julia> n < Posit{16,1}(-1e6)    # NaR sorts below every real
true

julia> isnan(n + Posit{16,1}(1.0))   # NaR is absorbing
true

julia> isnan(sqrt(Posit{16,1}(-1.0)))  # invalid ops produce NaR
true
```

`-NaR` is NaR (its own 2's complement); `Posit{16,1}(NaN).data == 0x8000`.

## Posit number-system properties

All follow from the posit standard with useed = 2^(2^es); verified by the test suite.

- **Reciprocal symmetry**: `floatmin(T) * floatmax(T) == 1.0` exactly — every dynamic-range
  extreme has an exact reciprocal. IEEE `Float16` gives `floatmin * floatmax ≈ 4`.
- **Sign symmetry**: negation is 2's complement of the encoding; every value has an exact negation.
- **One zero, one NaR**: no `-0`, no `Inf`.
- **Tapered precision**: accuracy peaks near ±1 and tapers at the extremes.

| Type | useed | maxpos | minpos | minpos·maxpos |
|---|---|---|---|---|
| `Posit{8,0}` | 2 | 2^6 = 64 | 2^−6 ≈ 0.016 | 1.0 |
| `Posit{16,1}` | 4 | 4^14 ≈ 2.68e8 | 4^−14 ≈ 3.73e-9 | 1.0 |
| `Posit{32,2}` | 16 | 16^30 ≈ 1.33e36 | 16^−30 ≈ 7.52e-37 | 1.0 |
| `Posit{19,3}` | 256 | 256^17 ≈ 8.71e40 | 256^−17 ≈ 1.15e-41 | 1.0 |

## Linear algebra

All types compose with Julia's `LinearAlgebra` — computations run entirely in the chosen
number system:

```julia
using UniversalNumbers, LinearAlgebra

A = [Posit{16,1}(1.0) Posit{16,1}(2.0);
     Posit{16,1}(3.0) Posit{16,1}(4.0)]
v = [Posit{16,1}(1.0), Posit{16,1}(1.0)]

A * v          # [Posit{16,1}(3.0), Posit{16,1}(7.0)]
dot(v, v)      # Posit{16,1}(2.0)
lu(A)          # LU decomposition in posit arithmetic
det(A)         # Posit{16,1}(-2.0)
```

This makes it straightforward to study how alternative number systems behave in real
numerical kernels — e.g. compare a `Posit{16,1}` matrix factorization against
`Float16`/`Float32` baselines.

**Note on LNS:** logarithmic numbers quantize in the log domain, so products and quotients
are exact while values like `1.5` are stored as the nearest representable power-of-two
fraction. This is inherent to the number system.

## Bit-level inspection

`printbits(x)` prints the raw encoding with ANSI colors identifying each field:

```julia
julia> printbits(Posit{16,1}(1.5))
Posit{16,1}(1.5)  0|10|0|1000000000000
S sign  R regime  E exponent  f fraction

julia> printbits(Takum{16}(1.5))
Takum{16}(1.5)  0|1|000|  |10000000000
S sign  D direction  R regime  C characteristic  M mantissa
```

Field coloring by family:

| Color | Posit | CFloat | LNS | Takum | Fixed | HFloat | DFloat |
|---|---|---|---|---|---|---|---|
| Red | sign | sign | sign | sign | — | sign | sign |
| Yellow | regime | — | — | regime | — | — | combination |
| Cyan | exponent | exponent | integer | characteristic | integer (incl. sign) | exponent | combination |
| Magenta | fraction | fraction | fraction | mantissa | fraction | hex-fraction | significand |
| Green | — | — | — | direction (D) | — | — | — |

## Project layout

```
src/UniversalNumbers.jl        Julia module (parametric types, ccall dispatch)
src/libuniversal_wrapper.cpp   C ABI bridge (compiled into UniversalNumbers_jll)
test/runtests.jl               Test suite
test/test_printbits.jl         Bit-inspection demo
test/test_la.jl                Linear algebra demo
docs/parametric-types.md       Design note: parametric type system
CONTRIBUTING.md                Adding types, building from source, JLL workflow
ROADMAP.md                     Phase 1 (local) / Phase 2 (JLL + General Registry)
```

## License

MIT — see [`LICENSE`](LICENSE).
