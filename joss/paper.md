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

`UniversalNumbers.jl` brings "next-generation" computer-arithmetic formats to Julia [@bezanson2017julia] through bindings to the Stillwater **Universal** C++ library [@omtzigt2023universal].
Over thirty types are instantiated, spanning eight number-system families: (1) posits [@gustafson2017beating], (2) logarithmic number systems (LNS), (3) takums [@hunhold2024takum], (4) fixed-point, (5) IBM hexadecimal floats, (6) IEEE-754 [@ieee2019standard] floats with a configurable-width classic floats (`cfloat`, including 8-bit formats such as E4M3), (7) bfloat16 [@bfloat16], and (8) double-double [@briggs1998dd].


Each type is an `AbstractFloat` subtype of Julia's `Real` type (see URL).
The package supports the full arithmetic and elementary-function interface, and works with most the Julia standard library `SparseArrays` and most `LinearAlgebra` functionality.
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

