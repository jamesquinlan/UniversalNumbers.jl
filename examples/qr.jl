# QR factorization and least-squares-style solves for sparse UniversalNumbers
#
# Requires MatrixDepot.jl (one-time install):
#   julia --project=examples -e 'using Pkg; Pkg.instantiate()'
#
# Run from the project root:
#   julia --project=examples examples/qr.jl
#
# QR.jl provides four entry points (all in the UniversalNumbers.QR module):
#   qr           - explicit factors (Q, R) with Q*R = A       [sparse]
#   qr_givens    - low-level Givens primitive (lazy Rotation) [sparse]
#   qr_solve     - solve A x = b without ever forming Q       [sparse]
#   qr_householder - dense path; Q is a Vector of reflectors  [dense]


using UniversalNumbers
using LinearAlgebra
using SparseArrays
using MatrixDepot

# Functions are called fully qualified as UniversalNumbers.QR.<name>.
# (A bare `using UniversalNumbers.QR` would clash with LinearAlgebra.QR.)

# Select number type here
T = Posit{32,2}

# ID = 6 is arc130 from the Harwell-Boeing collection
A = SparseMatrixCSC{T, Int64}(matrixdepot(sp(6)))
b = A * ones(T, size(A, 1))
n = size(A, 1)


# qr(A)
#
# Returns a named tuple (; Q, R) with an explicit orthogonal Q (a plain Matrix)
# and an UpperTriangular R, in the conventional orientation Q*R = A.
# Use this when you want the factors themselves.  Solve via x = R \ (Q' * b).
Q, R = UniversalNumbers.QR.qr(A);
x = R \ (Q' * b)
println("qr:        ||A x - b|| = ", norm(Float64.(A) * Float64.(x) - Float64.(b)))


# qr_givens(A)
#
# Low-level Givens primitive.  Returns (Qrot, R) where Qrot is a LAZY
# LinearAlgebra.Rotation satisfying adjoint(Qrot)*R = A (NOT Q*R = A).
# Materialise an explicit Q only if you need it:
Qrot, Rg = UniversalNumbers.QR.qr_givens(A);
Qexplicit = lmul!(adjoint(Qrot), Matrix{T}(I, n, n));   # now Qexplicit * Rg = A
println("qr_givens: ||QR - A|| = ",
        norm(Float64.(Qexplicit) * Float64.(Matrix(Rg)) - Float64.(A)))


# qr_solve(A, b)
#
# Solve A x = b via a Givens QR WITHOUT ever forming Q: each rotation is applied
# to b as it is applied to R, then a single back-substitution x = R \ (G b).
# This is the efficient choice for large sparse systems (no dense n-by-n Q), and
# it sidesteps the lazy Rotation, whose adjoint is unreliable for these types.
xs = UniversalNumbers.QR.qr_solve(A, b)
println("qr_solve:  ||A x - b|| = ", norm(Float64.(A) * Float64.(xs) - Float64.(b)))


# qr_householder(A)
#
# Dense path.  Returns (Qh, Rh) where Qh is a Vector{HouseholderReflection};
# Qh * X applies Q and Qh' * X applies its transpose (overloaded *), so the
# reflectors never need to be materialised.  Qh * Rh reconstructs A.
Adense = Matrix(A);
Qh, Rh = UniversalNumbers.QR.qr_householder(Adense);
println("qr_householder: ||Q R - A|| = ",
        norm(Float64.(Qh * Rh) - Float64.(Adense)))
