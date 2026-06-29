# <img src="universalnumbers.svg" width="32" height="32" align="middle"/> UniversalNumbers.jl

[![CI](https://github.com/jamesquinlan/UniversalNumbers.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/jamesquinlan/UniversalNumbers.jl/actions/workflows/ci.yml)

Julia bindings for the [Stillwater Universal](https://github.com/stillwater-sc/universal)
C++ number-systems library. Exposes **posits**, **classic floats (cfloat)**,
**logarithmic number systems (LNS)**, **takums**, **IBM hex float (hfloat)**, and
**decimal float (dfloat)** as first-class Julia numbers that implement `AbstractFloat`
and compose with the standard library.


## Installation

```julia
pkg> add UniversalNumbers
```

Requires Julia ≥ 1.10. The pre-built bridge library is downloaded automatically via
`UniversalNumbers_jll`; no C++ compiler or CMake is needed.

### Docker (build from source)

A [`Dockerfile`](Dockerfile) builds the C++ bridge and a ready-to-use Julia
environment — no local C++ toolchain or Julia install needed:

```bash
docker build -t universalnumbers .
docker run --rm -it universalnumbers                                # Julia REPL with the package
docker run --rm -it universalnumbers julia --project=. test/runtests.jl   # run the test suite
```

## Quick start

```julia
using UniversalNumbers

a = Posit{16,1}(1.5)
b = Posit{16,1}(2.5)
a + b                        # Posit{16,1}(4.0)
sqrt(Posit{32,2}(2.0))       # Posit{32,2}(1.4142135623842478)
a + 2.5                      # promotes 2.5 -> Posit{16,1}: Posit{16,1}(4.0)

using LinearAlgebra
A = [Posit{32,2}(4) Posit{32,2}(1); Posit{32,2}(1) Posit{32,2}(3)]
b = [Posit{32,2}(1), Posit{32,2}(2)]
A \ b                        # solve Ax = b in posit arithmetic
```

## Supported types

Each type is a Julia `AbstractFloat` subtype backed by a specific Universal C++
template instantiation. The type parameters are always integers (no trailing
block-type argument needed from user code).

| Julia type | Universal C++ type | Bits | Notes |
|---|---|---|---|
| `Posit{8,0}` | `posit<8,0>` | 8 | LUT-accelerated |
| `Posit{8,1}` | `posit<8,1>` | 8 | LUT-accelerated |
| `Posit{8,2}` | `posit<8,2>` | 8 | LUT-accelerated |
| `Posit{12,1}` | `posit<12,1>` | 12 (16-bit word) | |
| `Posit{16,1}` | `posit<16,1>` | 16 | |
| `Posit{16,2}` | `posit<16,2>` | 16 | |
| `Posit{19,2}` | `posit<19,2>` | 19 (32-bit word) | |
| `Posit{19,3}` | `posit<19,3>` | 19 (32-bit word) | |
| `Posit{32,2}` | `posit<32,2>` | 32 | |
| `Posit{64,2}` | `posit<64,2>` | 64 | |
| `Posit{64,3}` | `posit<64,3>` | 64 | |
| `CFloat{8,2}` | `cfloat<8,2>` | 8 | LUT-accelerated |
| `CFloat{8,3}` | `cfloat<8,3>` | 8 | LUT-accelerated; alias `E3M4` |
| `CFloat{8,4}` | `cfloat<8,4>` | 8 | LUT-accelerated; alias `E4M3` |
| `CFloat{8,5}` | `cfloat<8,5>` | 8 | LUT-accelerated; alias `E5M2` |
| `CFloat{24,5}` | `cfloat<24,5>` | 24 (32-bit word) | |
| `LNS{16,5}` | `lns<16,5>` | 16 | multiply/divide exact in log domain |
| `LNS{32,16}` | `lns<32,16>` | 32 | multiply/divide exact in log domain |
| `Takum{8}` | `takum<8,3>` | 8 | LUT-accelerated; rbits=3 per standard |
| `Takum{16}` | `takum<16,3>` | 16 | rbits=3 per standard |
| `Takum{32}` | `takum<32,3>` | 32 | rbits=3 per standard |
| `Takum{64}` | `takum<64,3>` | 64 | rbits=3 per standard |
| `Fixed{8,4}` | `fixpnt<8,4>` | 8 | LUT-accelerated; 4 fractional bits; modular |
| `Fixed{16,8}` | `fixpnt<16,8>` | 16 | 8 fractional bits; modular |
| `Fixed{32,16}` | `fixpnt<32,16>` | 32 | 16 fractional bits; modular |
| `HFloat{6,7}` | `hfloat<6,7>` | 32 | IBM hfp32; no NaN/Inf |
| `HFloat{14,7}` | `hfloat<14,7>` | 64 | IBM hfp64; no NaN/Inf |
| `DFloat{7,6}` | `dfloat<7,6,BID>` | 32 | IEEE 754-2008 decimal32 |
| `DFloat{16,8}` | `dfloat<16,8,BID>` | 64 | IEEE 754-2008 decimal64 |
| `BF16` | `bfloat16` | 16 | Google Brain float; same exponent range as Float32 |
| `DD` | `dd` | 128 | double-double; ~31 decimal digits (~106 bits) |

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

All properties follow from the posit standard (useed = 2^(2^ES)); all registered types
are verified by the test suite.

- **Reciprocal symmetry**: `floatmin(T) * floatmax(T) == 1.0` exactly — every dynamic-range
  extreme has an exact reciprocal. IEEE `Float16` gives `floatmin * floatmax ≈ 4`.
- **Sign symmetry**: negation is 2's complement of the encoding; every value has an exact negation.
- **One zero, one NaR**: no `-0`, no `Inf`.
- **Tapered precision**: accuracy peaks near ±1 and tapers at the extremes.

| Type | useed | maxpos | minpos | minpos·maxpos |
|---|---|---|---|---|
| `Posit{8,0}` | 2 | 2^6 = 64 | 2^−6 ≈ 1.56e-2 | 1.0 |
| `Posit{8,1}` | 4 | 4^6 = 4096 | 4^−6 ≈ 2.44e-4 | 1.0 |
| `Posit{8,2}` | 16 | 16^6 ≈ 1.68e7 | 16^−6 ≈ 5.96e-8 | 1.0 |
| `Posit{12,1}` | 4 | 4^10 ≈ 1.05e6 | 4^−10 ≈ 9.54e-7 | 1.0 |
| `Posit{16,1}` | 4 | 4^14 ≈ 2.68e8 | 4^−14 ≈ 3.73e-9 | 1.0 |
| `Posit{16,2}` | 16 | 16^14 ≈ 7.21e16 | 16^−14 ≈ 1.39e-17 | 1.0 |
| `Posit{19,2}` | 16 | 16^17 ≈ 2.95e20 | 16^−17 ≈ 3.39e-21 | 1.0 |
| `Posit{19,3}` | 256 | 256^17 ≈ 8.71e40 | 256^−17 ≈ 1.15e-41 | 1.0 |
| `Posit{32,2}` | 16 | 16^30 ≈ 1.33e36 | 16^−30 ≈ 7.52e-37 | 1.0 |
| `Posit{64,2}` | 16 | 16^62 ≈ 4.52e74 | 16^−62 ≈ 2.21e-75 | 1.0 |
| `Posit{64,3}` | 256 | 256^62 ≈ 2.05e149 | 256^−62 ≈ 4.90e-150 | 1.0 |

## Known limitations and semantics

A few types behave in ways worth knowing before you rely on them:

- **`HFloat` and `DFloat` parameters count digits, not total bits.** `HFloat{N,ES}` has
  `N` = hex-fraction digits and `ES` = exponent bits, so `HFloat{6,7}` is a **32-bit** type
  (1 + 7 + 6×4 = 32). Likewise `DFloat{N,ES}` uses `N` = significand digits. This differs from
  `Posit`/`CFloat`/`LNS`, where the first parameter is the total bit width.
- **`HFloat`, `DFloat`, and `Fixed` have no NaN or Inf.** None reserve encodings for them, so
  `isnan(x)` and `isinf(x)` always return `false`, and there is no overflow sentinel.
- **`Fixed` is modular.** Arithmetic that exceeds the range wraps around (2's-complement
  modular) rather than saturating or producing Inf. `sqrt` of a negative and `log` of a
  non-positive `Fixed` value return `0` rather than raising an error.
- **`Takum` NaR is unordered.** Unlike posit NaR (which sorts below every real), `NaR < x` is
  `false` for all `x` under the takum standard, so comparisons against takum NaR follow
  IEEE-NaN-like ordering. See the NaR section above for posit behavior.
- **`DD` (double-double) steps are tiny.** `nextfloat(DD(1.0))` increments by ~2⁻¹⁰⁶, which is
  below `Float64` print precision, so it *displays* as `DD(1.0)` even though the stored value
  did change.

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

### Quire support — exact fused dot product

Posits carry an associated **quire**, a wide fixed-point accumulator that sums products
with no intermediate rounding. `fdp` uses it to compute an **exact fused dot product** —
every term is accumulated exactly and the result is rounded only once, at the end:

```julia
a = rand(Posit{32,2}, 1000)
b = rand(Posit{32,2}, 1000)

sum(a .* b)    # ordinary dot product: rounds after every * and +
fdp(a, b)      # quire: exact accumulation, one final rounding
```

For hand-rolled accumulation, build a `Quire` directly:

```julia
q = Quire(Posit{32,2})
for i in eachindex(a, b)
    fma_product!(q, a[i], b[i])   # q += a[i]*b[i], exactly
end
Posit{32,2}(q)                     # round once
```

The quire is **opt-in and posit-only** — ordinary posit arithmetic and dot products are
unchanged, so rounded and fused results can be compared in the same program. See
[`examples/quire.jl`](examples/quire.jl) for a worked accuracy comparison.

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
src/quire.jl                   Exact fused dot product (quire) for posits
test/runtests.jl               Test entry point
test/posits.jl                 Posit arithmetic, LA, adjacent-value tests
test/takums.jl                 Takum arithmetic tests
test/lns.jl                    LNS arithmetic tests
test/la.jl                     Cross-family linear algebra tests
test/printbits.jl              Bit-inspection tests
test/broadcasting.jl           Broadcasting and array tests
examples/linalog.jl            A few examples of linear algebra
examples/quire.jl              Quire vs naive dot product accuracy comparison
CONTRIBUTING.md                Adding types, building from source, JLL workflow
```

## Contributing

Contributions are welcome — bug reports, new type registrations, and build/CI
improvements. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full guide (adding a
type, the JLL build, and design notes).

**Building from source** is only needed for development — users get the pre-built bridge
library automatically via `UniversalNumbers_jll`. Prerequisites:

- Julia ≥ 1.10
- CMake ≥ 3.22
- A C++20 compiler (GCC 10+, Clang 12+, MSVC 2019+)

```bash
git clone https://github.com/jamesquinlan/UniversalNumbers.jl
cd UniversalNumbers.jl
cmake -S . -B build && cmake --build build   # builds build/libuniversal.so
julia --project=. test/runtests.jl           # run the test suite
```

When running from source the module loads `build/libuniversal.so` directly; the installed
package uses the JLL artifact instead. Registration with the Julia General registry and
[Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil) is handled by the maintainer —
please open build-related pull requests against this repository rather than submitting to
Yggdrasil directly.

## References and Citations (bibTeX)

```bibtex

@article{gustafson2017beating,
  title   = {Beating Floating Point at its Own Game: Posit Arithmetic},
  author  = {Gustafson, John L. and Yonemoto, Isaac},
  journal = {Supercomputing Frontiers and Innovations},
  volume  = {4},
  number  = {2},
  pages   = {71--86},
  year    = {2017}
}

@article{hunhold2024takum,
  title   = {Beating Posits at Their Own Game: Takum Arithmetic},
  author  = {Hunhold, Laslo},
  journal = {Next Generation Arithmetic (CoNGA)},
  year    = {2024},
  note    = {Lecture Notes in Computer Science, Springer}
}

@techreport{ieee754_2019,
  author      = {{IEEE}},
  title       = {{IEEE} Standard for Floating-Point Arithmetic},
  institution = {Institute of Electrical and Electronics Engineers},
  year        = {2019},
  number      = {IEEE Std 754-2019},
  month       = jul,
  doi         = {10.1109/IEEESTD.2019.8766229},
  pages       = {1--84}
}

@article{julia_lang,
  author  = {Jeff Bezanson and Alan Edelman and Stefan Karpinski and Viral B. Shah},
  title   = {Julia: A Fresh Approach to Numerical Computing},
  journal = {SIAM Review},
  year    = {2017}
}

@article{omtzigt2023universal,
  title={Universal Numbers Library: Multi-format Variable Precision Arithmetic Library},
  author={Omtzigt, E Theodore L and Quinlan, James},
  journal={Journal of Open Source Software},
  volume={8},
  number={83},
  pages={5072},
  year={2023}
}

@techreport{positstandard2022,
  title       = {Standard for Posit\textsuperscript{TM} Arithmetic (2022)},
  author      = {{Posit Working Group}},
  institution = {National Supercomputing Centre (NSCC) Singapore},
  year        = {2022},
  month       = {March}
}

@article{wang2019bfloat16,
  title={BFloat16: The secret to high performance on Cloud TPUs},
  author={Wang, Shibo and Kanwar, Pankaj},
  journal={Google Cloud Blog},
  volume={4},
  number={1},
  year={2019}
}

 


```

## License

MIT — see [`LICENSE`](LICENSE).

### Bundled third-party code

This package vendors the header-only [Stillwater Universal](https://github.com/stillwater-sc/universal)
library under [`deps/universal/`](deps/universal/), which provides the underlying
number-system implementations. Universal is distributed under the MIT License,
© 2017 Stillwater Supercomputing, Inc.; its license is retained at
[`deps/universal/LICENSE`](deps/universal/LICENSE) and provenance (the exact
vendored upstream commit) is recorded in
[`deps/universal/VENDORED.md`](deps/universal/VENDORED.md).
