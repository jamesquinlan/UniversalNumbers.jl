# Building from Source

## Installing Julia

The recommended way to install Julia is via **juliaup**, the official version manager:

```bash
# Linux / macOS
curl -fsSL https://install.julialang.org | sh

# Windows (PowerShell)
winget install --id Julialang.Juliaup -e
```

After installing juliaup, add Julia 1.11 (minimum required for the `[sources]` feature used in
`docs/Project.toml`; Julia 1.10 is sufficient for using the package itself):

```bash
juliaup add 1.11      # or: juliaup add release
juliaup default 1.11
```

Alternatively, download an installer directly from
[julialang.org/downloads](https://julialang.org/downloads).

Verify the installation:

```bash
julia --version       # should print julia version 1.11.x or later
```

## Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Julia | 1.10 | |
| CMake | 3.20 | |
| C++ compiler | GCC 10 / Clang 12 / MSVC 2019 | C++20 required |

The Universal headers are vendored in `deps/universal/include/` — no separate
Universal installation is needed.

## Quick build

```bash
git clone https://github.com/jamesquinlan/UniversalNumbers.jl
cd UniversalNumbers.jl

# Build the shared library
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel

# Verify
julia --startup-file=no --project=. test/runtests.jl
```

This produces `build/libuniversal.so` (Linux) or `build/libuniversal.dylib` (macOS),
which the Julia module loads via `__init__()`.

## Running examples

All example scripts are in `examples/`. Run them from the repo root with `--project=.`:

```bash
julia --project=examples examples/chebyshev.jl
julia --project=examples examples/lorenz.jl
```

The `--project=.` flag tells Julia to find `UniversalNumbers` in the local `Project.toml`.
After the package is registered in the General Registry, this flag will not be needed.

## Platform notes

**Linux:** CMake and g++ are available from the system package manager:
```bash
sudo apt-get install cmake g++       # Debian/Ubuntu
sudo dnf install cmake gcc-c++       # Fedora/RHEL
```

**macOS:** Install via Homebrew:
```bash
brew install cmake
```
The Apple Clang compiler included with Xcode supports C++20 from Xcode 12 onward.

**Windows:** Install Visual Studio 2019+ (with "Desktop development with C++" workload)
and CMake. Run the build from a Developer Command Prompt.

## Project layout

```
src/
  UniversalNumbers.jl        Julia module (type registry, ccall dispatch, LUT8)
  lut8.jl                    Precomputed 8-bit lookup tables (built in __init__)
  about.jl                   Pure-Julia bit-field decoder (printbits / about)
  libuniversal_wrapper.cpp   C ABI bridge compiled into the shared library
deps/
  universal/include/         Vendored Universal headers (header-only C++ library)
build/
  libuniversal.{so,dylib}    Built artifact (git-ignored)
test/
  runtests.jl                Main test suite (898 tests)
docs/
  src/                       Documenter.jl source pages
  make.jl                    Docs build script
CMakeLists.txt               Build definition
Project.toml                 Julia package manifest
```

## Adding a new type

Every registered type requires **two** changes and a rebuild.

### Step 1 — C++ side (`src/libuniversal_wrapper.cpp`)

Add one line to `TYPE_REGISTRY_FULL`:

```cpp
X(cfloat32_7, uint32_t, sw::universal::cfloat<32, 7, uint32_t, true, false, false>)
```

The X-macro stamps out all ~20 `extern "C"` bridge functions automatically.

**C++ template reference:**

| Family | C++ template | Notes |
|---|---|---|
| Posit | `posit<nbits, es, bt>` | |
| CFloat | `cfloat<nbits, es, bt, hasSubnormals, hasMaxExpValues, isSaturating>` | defaults: `true, false, false` |
| LNS | `lns<nbits, rbits, bt>` | |
| Takum | `takum<nbits, rbits, bt>` | rbits = 3 fixed by standard |
| Fixed | `fixpnt<nbits, rbits, Modulo, bt>` | use `sw::universal::Modulo` |
| HFloat | `hfloat<ndigits, es, bt>` | |
| DFloat | `dfloat<ndigits, es, BID, bt>` | encoding = `DecimalEncoding::BID` |

**Storage type selection** (`bt` / `IT`):

| Total bits | C++ `IT` | Julia `StorageT` |
|---|---|---|
| 1–8 | `uint8_t` | `UInt8` |
| 9–16 | `uint16_t` | `UInt16` |
| 17–32 | `uint32_t` | `UInt32` |
| 33–64 | `uint64_t` | `UInt64` |

For multi-word types (e.g. `hfp64` is 64 bits but uses `uint32_t` blocks), `IT` must be the
type whose `sizeof` matches `sizeof(CppType)` — `uint64_t` for hfp64.

### Step 2 — Julia side (`src/UniversalNumbers.jl`)

Add one tuple to `TYPE_REGISTRY` (or `TAKUM_REGISTRY` for Takum):

```julia
# TYPE_REGISTRY tuple: (TypeSymbol, P1, P2, CPrefix, StorageT)
(:CFloat, 23, 7, "cfloat32_7", UInt32)
```

### Step 3 — Rebuild and verify

```bash
cmake --build build

julia --project=. -e '
    using UniversalNumbers
    x = CFloat{23,7}(1.5)
    println(x + CFloat{23,7}(0.5))
    printbits(x)
'

julia --startup-file=no --project=. test/runtests.jl
```

### Step 4 — Update docs

- `README.md` — add a row to the Supported types table
- `docs/src/api.md` — add the combination to the registered list
- `docs/src/number-systems.md` — add or update the relevant family table

## Updating the vendored Universal headers

```bash
# Copy updated headers from a local Universal clone
cp -r ~/path/to/universal/include/sw/universal/number/<family>/ \
      deps/universal/include/sw/universal/number/<family>/

cmake --build build
julia --startup-file=no --project=. test/runtests.jl
```

Two files in `deps/` intentionally diverge from upstream and must be preserved:
- `takum/math/functions/classify.hpp` — adds `#include <cmath>` and predicate-based `fpclassify`
- `takum/math/functions/minmax.hpp` — NaR symmetry guards in `min`/`max`

## LUT8 — precomputed 8-bit tables

All nine UInt8-storage types (`Posit{8,0}`, `Posit{8,1}`, `Posit{8,2}`,
`CFloat{8,2}` through `CFloat{8,5}`, `Fixed{8,4}`, `Takum{8}`) use precomputed
lookup tables built once in `__init__()`.

Each table covers all 256 bit patterns exhaustively:
- Binary ops (`add`, `sub`, `mul`, `div`): 256 × 256 = 65 536 entries (UInt8)
- Unary ops (`abs`, `sqrt`, `sin`, `cos`, `exp`, `log`, `next`, `prev`): 256 entries
- Predicates (`isnan`, `isinf`): 256 Bool entries
- Conversion (`to_f64`): 256 Float64 entries

Total memory: ~500 KB per type × 7 types ≈ 3.5 MB, all in L3 cache.

The `Fixed{8,4}` table guards `sqrt` and `log` against out-of-domain inputs that the
C++ library throws on (negative sqrt, non-positive log).

## Building the documentation

```bash
julia --project=docs docs/make.jl
```

The generated site is written to `docs/build/`. Open `docs/build/index.html` in a browser
to preview locally.
