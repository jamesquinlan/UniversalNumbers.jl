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