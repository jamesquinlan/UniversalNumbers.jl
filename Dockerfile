# Build-from-source image for UniversalNumbers.jl
#
# Compiles the C++ bridge (libuniversal) against the vendored Stillwater
# Universal headers, resolves and precompiles the Julia environment, and drops
# you into a project REPL with all number types ready. Useful for building from
# source (no host C++ toolchain needed on the host, since it lives in the image),
# reproducing CI, and for reviewers who want a one-command working environment.
#
#   docker build -t universalnumbers .
#   docker run --rm -it universalnumbers                                      # Julia REPL with the package
#   docker run --rm -it universalnumbers julia --project=. test/runtests.jl   # run the test suite
#
# Julia 1.10 is the minimum supported version (see Project.toml [compat]).
#
# For a lighter image that installs the PREBUILT package from the General
# registry (no C++ toolchain) and preloads the example packages, see
# Dockerfile.user. Use this Dockerfile to build and test from source; use
# Dockerfile.user to run examples and experiment.

FROM julia:1.10-bookworm

# C++ toolchain for the bridge library
RUN apt-get update \
 && apt-get install -y --no-install-recommends cmake g++ \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/UniversalNumbers.jl
COPY . .

# Build libuniversal.<ext>; the package loader looks for build/libuniversal.<ext>
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build --parallel

# Resolve and precompile the Julia environment
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Smoke-test: the bridge loads and arithmetic works
RUN julia --project=. -e 'using UniversalNumbers; @assert Float64(Posit{16,1}(1.5) + Posit{16,1}(2.5)) == 4.0; println("UniversalNumbers.jl ready")'

CMD ["julia", "--project=."]
