# AMG Preconditioner example
# ---------------------------------------------------------------------
# J.W. Ruge and K. Stuben, Algebraic multigrid, in Multigrid Methods, 
#   vol. 3 of Frontiers in Applied Mathematics, SIAM, Philadelphia, PA, 
#   1987, pp. 73â€“130.  
# ---------------------------------------------------------------------

using UniversalNumbers
using AlgebraicMultigrid
import IterativeSolvers: cg

T = Takum{16}

A = poisson(T,100) # Creates a sample symmetric positive definite sparse matrix
ml = ruge_stuben(A) # Construct a Ruge-Stuben solver
p = aspreconditioner(ml)
c = cg(A, A*ones(100), Pl = p)
