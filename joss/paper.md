---
title: 'UniversalNumbers.jl: Next-generation computer arithmetic in Julia'
tags:
  - Julia
  - computer arithmetic
  - posit
  - floating-point
  - number systems
  - numerical analysis
  - reproducibility
authors:
  - name: James Quinlan
    orcid: 0000-0002-2628-1651
    affiliation: 1
  - name: Michael Arciero
    orcid: 0009-0000-9107-6171
    affiliation: 1
affiliations:
  - name: University of Southern Maine, USA  
    index: 1
date: 22 June 2026
bibliography: paper.bib
---

# Summary

`UniversalNumbers.jl` [@quinlan_2026_21462151] brings "next-generation" computer-arithmetic formats to Julia [@bezanson2017julia] through bindings to the Stillwater **Universal** C++ library [@omtzigt2023universal].
Over thirty types are instantiated, spanning eight number-system families: (1) posits [@gustafson2017beating], (2) logarithmic number systems (LNS), (3) takums [@hunhold2024takum], (4) fixed-point, (5) IBM hexadecimal floats (HFP) [@IBM1964], (6) IEEE-754 [@ieee2019standard] floats with a configurable-width classic floats (`cfloat`, including 8-bit formats such as E4M3), (7) bfloat16 [@bfloat16], and (8) double-double [@Bailey_dd,@briggs1998dd].


Each type is an `AbstractFloat` subtype of Julia's `Real` type, which in turn is a subtype of `Number` (i.e.,  `julia> print_tree(Number)`).
The package supports the full arithmetic and elementary-function interface, and works with many the Julia  libraries including `SparseArrays` and most of `LinearAlgebra` functionality.
A type such as `Posit{16,2}` or `Takum{32}` can be dropped into existing code, so the numerical behavior of an algorithm can be studied across many formats from one program.

Each value is stored in a packed machine word, for example a `UInt16` for a 16-bit posit, so arrays are unboxed.
The underlying C symbols are cached, so scalar operations avoid per-call lookup.
The bridge library ships as a precompiled binary artifact, so users obtain working arithmetic without a C++ toolchain.
The package is registered in the Julia General registry, while its binary dependency, UniversalNumbers_jll, is registered in Yggdrasil, so installation follows the standard `Pkg.add` workflow used for any other Julia package.

# Statement of Need

Research into computer arithmetic beyond IEEE-754's `Float16`/`Float32`/`Float64` has grown rapidly.
This research is motivated by greater accuracy per bit, larger dynamic range, reproducibility, lower energy, and memory cost.
Evaluating these claims often involves experimentation: running numerical algorithms such as linear solves, iterative refinement, ODE integration, and optimization in a potential format, then measuring accuracy, conditioning sensitivity, and failure modes.
The same settings also support mixed-precision algorithm development.

The Universal library is comprehensive and well tested, but written in C++ with template metaprogramming.
Using it requires compiling C++, managing template instantiations, and rebuilding to try a new format or experiment.
This is a barrier for the two audiences that most need these number systems: numerical analysts prototyping algorithms, and students and educators learning how floating point and its alternatives behave.

`UniversalNumbers.jl` removes that barrier by exposing Universal's formats inside Julia.
They can be used at the REPL and used in conjunction with several packages in Julia's  ecosystem.
Switching arithmetic type is a one-line type change rather than a recompilation.
Comparing `Posit{16,2}`, `Takum{16}`, and `Float16` on the same ill-conditioned linear system is a short script.

The package is well suited for:

- **Experimentation with next-generation arithmetic.** A format can be subjected to realistic workloads, including the package's worked examples of sparse LU/QR, mixed-precision iterative refinement, Krylov and stationary iterative solvers, and algebraic-multigrid preconditioning. One can observe, for instance, how a low-precision factorization drives iterative refinement to working-precision accuracy [@carson2018accelerating], or how Krylov methods respond to low-precision rounding differently from stationary iterations [@hunhold2025evaluation].

- **Education.** Every value carries its exact format and can be inspected bit-by-bit with `printbits` and `about`. Instructors can demonstrate rounding, dynamic range, subnormals, and NaR/NaN semantics interactively, without the overhead of a compiled C++ project.

By pairing Universal's arithmetic kernels with Julia's multiple dispatch and `LinearAlgebra`/`SparseArrays` integration [@bezanson2017julia], `UniversalNumbers.jl` turns a C++ library into a rapid-prototyping platform for computer-arithmetic research and education.

The Julia ecosystem already offers single-format packages: `BFloat16s.jl` [@bfloat16s_jl] for bfloat16, `Posits.jl` [@posits_jl] and `SoftPosits.jl` [@softposits] for posits, `Takums.jl` [@takums_jl] for takums, and `Microfloats.jl` [@microfloats_jl] for 8-bit minifloats.
Each has its own interface and conventions.
`UniversalNumbers.jl` consolidates these formats behind a single `AbstractFloat` interface, so one dependency provides functionality equivalent to several of them.
It also adds formats that no existing Julia package provides: configurable `cfloat`, logarithmic, fixed-point, IBM hexadecimal, decimal, and double-double.


The nine supported families and their registered instantiations are summarized below.
Each entry is a concrete `AbstractFloat` subtype backed by a specific Universal C++ template.

| Family | Julia type | Description | Registered instances |
|--------|-------------|------------|----------------------|
| Posit | `Posit{N,ES}` | tapered-precision unum (Type III) | `{8,0}`, `{8,1}`, `{8,2}`, `{12,1}`, `{16,1}`, `{16,2}`, `{19,2}`, `{19,3}`, `{32,2}`, `{64,2}`, `{64,3}` |
| Classic float | `CFloat{N,ES}` | configurable IEEE-style float | `{8,2}`, `{8,3}`, `{8,4}`, `{8,5}`, `{24,5}` |
| Logarithmic | `LNS{N,R}` | logarithmic number system | `{16,5}`, `{32,16}` |
| Takum | `Takum{N}` | tapered logarithmic format | `8`, `16`, `32`, `64` |
| Fixed-point | `Fixed{N,R}` | modular fixed-point | `{8,4}`, `{16,8}`, `{32,16}` |
| IBM hex float | `HFloat{N,ES}` | base-16 hexadecimal float | `{6,7}` (hfp32), `{14,7}` (hfp64) |
| Decimal float | `DFloat{N,ES}` | IEEE 754-2008 decimal | `{7,6}` (decimal32), `{16,8}` (decimal64) |
| Brain float | `BF16` | bfloat16 | single type |
| Double-double | `DD` | compensated, ~106-bit significand | single type |

The 8-bit formats are accelerated with precomputed lookup tables.
Standard machine-learning FP8 aliases `E4M3`, `E3M4`, and `E5M2` are provided for the corresponding `CFloat{8,·}` types.
Requesting an unregistered instantiation raises an informative error pointing to the type registry.

Beyond the types themselves, the package provides:

- **Full numeric interface**: arithmetic, comparison, `sqrt`, elementary and transcendental functions, `nextfloat`/`prevfloat`, `eps`/`floatmin`/`floatmax`, rounding, parsing, hashing, and promotion with built-in `Real` types.
- **Linear algebra**: dense and sparse matrix arithmetic; LU and QR (including a Givens solve that never forms `Q`); `\`; and Float64-image fallbacks for `eigen`, `svd`, `cholesky`, and `cond` where no native generic path exists.
- **Exact fused dot product (quire)**: for posits, the package exposes Universal's *quire*, a wide fixed-point accumulator that sums products with no intermediate rounding and rounds once at the end. It is a native binding to Universal's `quire<posit<N,ES>>` rather than a Julia re-implementation, so it preserves the library's speed. `fdp(a, b)` (alias `quire_dot`) computes an exact fused dot product, and an explicit `Quire` accumulator supports hand-rolled accumulation. The quire is opt-in: ordinary posit arithmetic is unaffected, so rounded and fused results can be compared in one program.
- **Interoperability** with mulitple Julia registry packages including: `IterativeSolvers.jl` and `AlgebraicMultigrid.jl` (for example, preconditioned GMRES) for concrete-element-type matrices.
- **Inspection tools** `printbits` and `about`, which show the colorized bit-level encoding and decoded fields of any value.

# Examples

```julia
using UniversalNumbers, LinearAlgebra

for T in (Float64, Posit{16,2}, Takum{16})
    A = T[4 1; 1 3]
    b = A * ones(T, 2)
    x = A \ b
    println(T, ": residual = ", norm(Float64.(A*x - b)))
end
```

The same algorithm runs unchanged across formats, so accuracy comparisons reduce to iterating over a list of types.

The fused dot product illustrates the kind of accuracy study the package enables.
For posits, `fdp` accumulates products in the quire without intermediate rounding:

```julia
using UniversalNumbers
a = rand(Posit{32,2}, 2000) 
b = rand(Posit{32,2}, 2000)
s_naive = sum(a .* b)   		# rounds after every multiply and add
s_quire = fdp(a, b)     		# exact accumulation, rounds once
```

In a representative experiment (2000 random `Posit{32,2}` terms; see `examples/quire.jl`), the fused dot product reduces the error of the dot product by about 337× relative to the naively rounded sum.
The residual contains only the single final rounding to `Posit{32,2}`.

# Acknowledgements

We thank E. Theodore L. Omtzigt and the Stillwater Universal contributors for the underlying C++ arithmetic library, and Laslo Hunhold for the Takum reference implementation and the sparse LU/QR routines adapted in this package.

# References

