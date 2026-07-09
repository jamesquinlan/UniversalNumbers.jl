using UniversalNumbers
using LinearAlgebra
using Test

# These dense operations have no native generic path for UniversalNumber element
# types, so the package falls back to the Float64 image of the matrix. The tests
# confirm the fallbacks dispatch and match the Float64 result.
@testset "Dense LinearAlgebra Float64-image fallbacks" begin
    T = Posit{32,2}
    A = T.([4.0 1.0; 1.0 3.0]) # symmetric positive definite
    Af = Float64.(A)

    @test eigen(A).values ≈ eigen(Af).values
    @test svd(A).S        ≈ svd(Af).S
    @test cholesky(A).U   ≈ cholesky(Af).U
    @test cond(A)         ≈ cond(Af)
    @test cond(A, 1)      ≈ cond(Af, 1)
end
