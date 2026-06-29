using UniversalNumbers
using SparseArrays
using LinearAlgebra
using IterativeSolvers
using IncompleteLU
using MatrixDepot

# NOTE: In some cases, it is necessary to provide the fully qualified type name
#   for the concrete type of the matrix elements, e.g. Posit{16,2,UInt16} instead
#   of Posit{16,2} to work with IterativeSolvers.jl, because the latter is an 
#   abstract type and cannot be used as a concrete element type for a sparse matrix.

T = Posit{16,2,UInt16};  # fully qualified "concrete" type name
A = SparseMatrixCSC{T, Int64}(matrixdepot(sp(6))); # = arc130 (Harwell-Boeing collection)
b = A*ones(T, size(A, 2)); 


x = jacobi(A, b, maxiter=100);
x = gauss_seidel(A, b, maxiter=100);
x = sor(A, b, 1.25, maxiter=100);
x = gmres(A, b, restart=50, abstol=1e-6, maxiter=100);
x = cg(A, b, maxiter=100)



# Example of mixing Abstract and concrete types for the matrix elements. 
T = Posit{16,2}                            # ABSTRACT eltype
A = SparseMatrixCSC{T,Int64}(sparse([4.0 1.0 0.0; 1.0 5.0 2.0; 0.0 2.0 6.0]))
b = A * ones(eltype(A), 3)
println("eltype(A) = ", eltype(A), "   eltype(b) = ", eltype(b))
x = gmres(A, b)



# ILU-preconditioned GMRES (IncompleteLU.jl). The preconditioner P supports
# ldiv!, so it can be passed as the left preconditioner Pl.
T = Posit{16,2,UInt16}
A = SparseMatrixCSC{T, Int64}(matrixdepot(sp(6)));
b = A * ones(T, size(A,1))
P = ilu(A; τ=0.1)                                    # drop tolerance; smaller -> stronger
x = gmres(A, b; Pl=P, maxiter=50, reltol=1e-8)
println("ILU Pl   resid = ", norm(Float64.(A)*Float64.(x) - Float64.(b)))
