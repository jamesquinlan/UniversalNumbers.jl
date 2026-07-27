# Vendored Universal headers — provenance

The header-only [Stillwater Universal](https://github.com/stillwater-sc/universal)
library is vendored here (copied, not a submodule). It is MIT-licensed; the
upstream license is retained in `LICENSE` alongside this file.

- **Source chain:** github.com/stillwater-sc/universal (upstream)
  → github.com/jamesquinlan/universal (fork)
  → local clone → copied into `include/` here.
- **Current snapshot:** commit `c34dc576` (upstream main as of 2026-07-25; vendored
  2026-07-26). Change affecting wrapped types: the quire no longer throws in a no-throw
  build (upstream #1226, PR #1228). It gained a sticky `_nar` state that propagates through
  accumulation and resolves to the scalar's native NaR, plus a new
  `QUIRE_THROW_ARITHMETIC_EXCEPTION` macro that each number system's umbrella header
  forwards its own policy to. Since `src/libuniversal_wrapper.cpp:16` sets
  `POSIT_THROW_ARITHMETIC_EXCEPTION 0`, the quire is now non-throwing for us, which fixes a
  SIGABRT that killed the Julia process on a NaR operand.
  Also in this range: upstream **deleted `include/sw/blas` entirely** (PRs #1212, #1215,
  "Phase 4 removal"), along with `sw/numeric/containers`, `sw/universal/dnn`, and
  `quantization/qsnr.hpp`. We never included any of them, so the build is unaffected. This
  is why the vendored file count drops 1119 -> 1015.
- **Previous snapshot:** commit `ba587e3d2541845adcda3f0b94831f651764fa8f`
  (upstream main as of 2026-07-17; vendored 2026-07-20). bfloat16 float-cast rounds to
  nearest-even instead of truncating, and preserves NaN (upstream #1134).
- **Earlier:** commit `321409d6b6e2c98ae1ceb5894118960feffc8e75`
  (upstream main as of 2026-06-17; vendored 2026-06-17).
- **No local additions:** `CMakeLists.txt` points at `deps/universal/include/sw`,
  so Universal's own headers resolve directly — no symlinks needed.

## To re-sync with upstream

Set these two variables to wherever your clones live (any location — they need
not be siblings or under any particular directory):

```bash
UNIVERSAL=/path/to/universal           # clone of github.com/jamesquinlan/universal
PKG=/path/to/UniversalNumbers.jl       # this repository

# 1. sync the fork with upstream
git -C "$UNIVERSAL" fetch upstream && git -C "$UNIVERSAL" merge upstream/main

# 2. re-vendor the headers
rm -rf "$PKG/deps/universal/include" && mkdir "$PKG/deps/universal/include"
cp -r "$UNIVERSAL/include/." "$PKG/deps/universal/include/"

# 3. rebuild the bridge and run the tests
cmake --build "$PKG/build" && julia --startup-file=no --project="$PKG" "$PKG/test/runtests.jl"
```

Then update the **Current snapshot** commit hash above to
`git -C "$UNIVERSAL" rev-parse HEAD`.
