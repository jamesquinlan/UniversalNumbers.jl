# Test Suite

1733 tests across 17 files, all run from `runtests.jl`. Counts below are from
2026-07-26 against vendored Universal `c34dc576`.

## Running the tests

**Full suite** (required before any commit):
```bash
julia --startup-file=no --project=. test/runtests.jl
```

**Single file** (faster iteration -- every file is self-contained and runnable
on its own):
```bash
julia --startup-file=no --project=. test/lns.jl
```

**One testset by name**, from a Julia session:
```julia
using UniversalNumbers, Test
include("test/runtests.jl")   # runs everything
```

## Test files

`runtests.jl` holds the core suite inline and then includes the rest, in this
order. Each row is one top-level testset.

| File | Testset | Tests | What it covers |
|---|---|---|---|
| `runtests.jl` | UniversalNumbers.jl | 755 | Core suite for every registered type -- see the breakdown below |
| `broadcasting.jl` | Broadcasting and Array Support | 10 | `rand`, `.+`, `sin.()`, in-place `.=`, array construction |
| `la.jl` | Linear Algebra -- cross-family | 45 | 2x2 and 3x3 tridiagonal solves across posit, cfloat, LNS, takum |
| `linalg_lu.jl` | Advanced Linear Algebra (LU) | 7 | LU decomposition and `\` for `Posit{32,2}` |
| `linalg_qr.jl` | QR Decomposition | 15 | Householder QR: square, overdetermined, and posit vs Float64 agreement |
| `lns.jl` | LNS Support | 14 | Log-domain arithmetic, math functions, and `\` for `LNS{16,5}` / `LNS{32,16}` |
| `math_linalg.jl` | UniversalNumbers Parametric Interface | 55 | Parametric spellings, custom types (`Posit{19,3}`), comparisons, matvec |
| `posits.jl` | Posit Support | 647 | The bulk of posit coverage: arithmetic, math, and edge cases per width |
| `printbits.jl` | Bit inspection (printbits / about) | 20 | Bit-field decoding for every registered type, including NaR |
| `takums.jl` | Takum Support | 8 | Arithmetic and `\` for `Takum{16}` |
| `rounding.jl` | Integer rounding | 16 | `trunc`/`floor`/`ceil`/`round` to `Integer` |
| `linalg_fallbacks.jl` | Dense LinearAlgebra Float64-image fallbacks | 5 | Dense ops that route through a Float64 image and back |
| `promotion_math_fallbacks.jl` | Mixed-type promotion (`_un_promote`) | 5 | Promotion between different Universal types |
| `promotion_math_fallbacks.jl` | Float64-round-trip math fallbacks | 8 | Math functions with no native C++ entry point |
| `rational_construction.jl` | Rational construction | 58 | `T(1//32)` for every type; regression for the v0.1.1 `MethodError` |
| `bfloat16_rounding.jl` | BF16 round-to-nearest-even cast (#4) | 14 | BF16 float cast rounds RNE instead of truncating (upstream #1134) |
| `quire_nar.jl` | Quire NaR propagation (#1226) | 51 | NaR through the quire returns NaR instead of aborting the process |

`benchmark.jl` is **not** part of the suite and is not included by
`runtests.jl`. It is a standalone performance comparison against Posits.jl and
Takums.jl, needing `BenchmarkTools`, `Posits`, and `Takums`. Run it directly:
```bash
julia --startup-file=no --project=. test/benchmark.jl
```

### What `runtests.jl` covers inline

| Testset | What it verifies |
|---|---|
| Posit{16,1} / {32,2} / {8,0} / {19,3} / {19,2} / {16,2} / {64,2} / {64,3} | Arithmetic per width, plus `sqrt`, `sin`, `cos`, `exp`, `log`, and useed reciprocal symmetry |
| CFloat{8,2} / {24,5} / {8,3} / {8,4} / {8,5} | Quarter and half precision, and the FP8 formats |
| FP8 aliases (E4M3, E3M4, E5M2) | Alias identity, construction, display |
| LNS{16,5}, LNS{32,16} | Log-domain arithmetic |
| Takum{N} | Arithmetic and math |
| Fixed{N,R} | Basic ops, modular wrap, absence of NaN/Inf, `nextfloat`/`prevfloat` |
| HFloat{N,ES} | IBM hex float arithmetic; no NaN/Inf; `nextfloat`/`prevfloat` |
| DFloat{N,ES} | IEEE 754-2008 decimal float arithmetic; no NaN/Inf |
| BF16 | Brain float arithmetic, NaN/Inf, `nextfloat`/`prevfloat` |
| DD (double-double) | ~106-bit arithmetic, constants, comparisons |
| Comparisons | `==`, `<`, `<=` across all type families |
| NaR (Not-a-Real) | Posit NaR semantics: absorbing, total order, negation |
| CFloat NaN and Inf | IEEE exception propagation |
| CFloat subnormals | Values between zero and `floatmin` |
| AbstractFloat behavior | Promotion, `zero`/`one`, `iszero`, `show` |
| nextfloat / prevfloat | Round-trip identity and boundary values |
| zero/one bit patterns | Compile-time constants checked against `ccall` results |
| hash, parse | Same value gives same hash, usable as `Dict` keys; `parse(T, s)` per type |
| printbits smoke test, about | No crash for any registered type; field labels and decoded values |
| LUT8 lookup tables | Table dimensions, arithmetic, Float64 conversion, `Fixed{8,4}` domain guard |
| Unregistered types | Informative error for out-of-registry combinations |
| LinearAlgebra (+ DD, + Fixed) | Matrix multiply and `dot` |
| Quire / fdp | Exact fused dot product: `fdp`, explicit `Quire`, `fma_product!`, `clear!`, `quire_bits`, accuracy against naive, error handling |
| Aqua quality assurance | Skipped unless run via `Pkg.test()` |

## Regression tests tied to a specific bug

Three files exist because something broke. Keep the issue number in the testset
name so the connection survives.

| File | Bug | Symptom before the fix |
|---|---|---|
| `rational_construction.jl` | this repo, v0.1.1 | `T(1//32)` raised `MethodError` from an ambiguous constructor |
| `bfloat16_rounding.jl` | this repo #4 / upstream #1134 | BF16 float cast truncated instead of rounding to nearest-even |
| `quire_nar.jl` | upstream #1226, PR #1228 | A NaR in the quire threw a C++ exception through the `extern "C"` bridge, so Julia died with SIGABRT and no message |

Note that `quire_nar.jl` fails **by killing the test process**, not by reporting
a red test. If a run stops partway with no summary, suspect an exception
escaping the C++ bridge.

## Adding tests

**New type or feature** -- add a testset to `runtests.jl` inside the top-level
`@testset "UniversalNumbers.jl"` block.

**Standalone scenario** (long-running, needs its own imports, or tied to one
bug) -- add `test/<topic>.jl`, append `include("<topic>.jl")` at the bottom of
`runtests.jl`, and add a row to the table above.

**Convention:**
- Each file starts with `using UniversalNumbers, Test` (plus extras such as
  `LinearAlgebra`).
- Top-level testsets use plain descriptive names: `@testset "My Feature" begin`.
- Use `atol` tolerances proportional to the type's precision; 8-bit types need
  `atol=0.1` or wider.
- Do not use `@test_broken` to paper over real failures -- fix the root cause or
  open an issue.
- When a test exists because of a specific bug, say so in a header comment and
  name the issue, so a later reader knows what would regress.
