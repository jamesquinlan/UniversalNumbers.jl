# Vendored Universal headers — provenance

The header-only [Stillwater Universal](https://github.com/stillwater-sc/universal)
library is vendored here (copied, not a submodule). It is MIT-licensed; the
upstream license is retained in `LICENSE` alongside this file.

- **Source chain:** github.com/stillwater-sc/universal (upstream)
  → github.com/jamesquinlan/universal (fork)
  → local clone → copied into `include/` here.
- **Current snapshot:** commit `ba587e3d2541845adcda3f0b94831f651764fa8f`
  (upstream main as of 2026-07-17; vendored 2026-07-20). Change affecting wrapped types:
  bfloat16 float-cast now rounds to nearest-even instead of truncating, and preserves NaN
  (upstream #1134). Everything else new in this range is number systems we do not wrap
  (efloat, elreal) plus docs/tests, so only bfloat16 behavior changed for us.
- **Previous snapshot:** commit `321409d6b6e2c98ae1ceb5894118960feffc8e75`
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
