using UniversalNumbers
using LinearAlgebra
using SparseArrays
using Test

@testset "Advanced Linear Algebra (LU)" begin
    @testset "LU Decomposition (Posit{32, 2})" begin
        # 3x3 Matrix
        A = Posit{32, 2}.([
            4.0  1.0  2.0;
            1.0  5.0  3.0;
            2.0  3.0  6.0
        ])

        # Test basic Matrix operations first
        @test eltype(A) <: Posit{32, 2}

        # Attempt LU
        println("Attempting LU decomposition...")
        try
            F = lu(A)
            println("LU successful!")

            # Verify L * U ≈ P * A
            @test Float64.(F.L * F.U) ≈ Float64.(F.P * A) atol=1e-6
        catch e
            println("LU failed with error: ", e)
            rethrow(e)
        end
    end

    @testset "Solving Linear Systems" begin
        A = Posit{32, 2}.([
            4.0  1.0;
            1.0  3.0
        ])
        b = Posit{32, 2}.([1.0, 2.0])

        # Solve Ax = b using \ (which often uses LU)
        x = A \ b

        # Verify A * x ≈ b
        @test Float64.(A * x) ≈ Float64.(b) atol=1e-6
    end

    # Exercise the package's own sparse LU (UniversalNumbers.LU), which the generic
    # `lu`/`\` above does not reach. LU.lu is unpivoted and needs a nonzero diagonal,
    # so use a diagonally dominant SPD matrix (1D Laplacian).
    @testset "Custom sparse LU (UniversalNumbers.LU)" begin
        T = Posit{32,2}
        n = 25
        Af = spdiagm(-1 => -ones(n-1), 0 => 2.0 * ones(n), 1 => -ones(n-1))
        A  = T.(Af) # SparseMatrixCSC{Posit{32,2}, Int}
        b  = A * ones(T, n)

        L, U = UniversalNumbers.LU.lu(A)
        @test L isa LowerTriangular
        @test U isa UpperTriangular
        @test Float64.(L * U) ≈ Float64.(A) atol = 1e-4

        # Sparse solve routes through the custom LU solve path.
        x = A \ b
        @test norm(Float64.(x) .- 1.0) < 1e-4
    end
end
