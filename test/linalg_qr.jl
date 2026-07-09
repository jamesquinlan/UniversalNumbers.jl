using UniversalNumbers
using LinearAlgebra
using SparseArrays
using Test

const QRmod = UniversalNumbers.QR

@testset "QR Decomposition" begin

    atol_f64 = 1e-12
    atol_p32 = 1e-4

    # ------------------------------------------------------------------
    # 1. Float64 dense: basic correctness
    # ------------------------------------------------------------------
    @testset "qr_householder Float64 3x3" begin
        A = [4.0  3.0 -1.0;
             0.0  2.0  2.0;
             3.0  1.0  5.0]
        Q, R = QRmod.qr_householder(A)

        @test istriu(R)

        # Q * R reconstructs A
        @test norm(Q * R - A) < atol_f64

        # Orthogonality: Q * I gives Q as a dense matrix; Q^T Q ≈ I
        Qm = Q * Matrix{Float64}(I, 3, 3)
        @test norm(Qm' * Qm - I) < atol_f64
    end

    @testset "qr_householder Float64 4x3 overdetermined" begin
        A = [1.0 2.0 3.0;
             4.0 5.0 6.0;
             7.0 8.0 0.0;
             1.0 0.0 1.0]
        Q, R = QRmod.qr_householder(A)

        @test istriu(R)
        @test norm(Q * R - A) < atol_f64
    end

    @testset "qr_householder Float64 identity" begin
        A = Matrix{Float64}(I, 4, 4)
        Q, R = QRmod.qr_householder(A)
        @test istriu(R)
        @test norm(Q * R - A) < atol_f64
    end

    # ------------------------------------------------------------------
    # 2. Posit{32,2} dense matrix
    # ------------------------------------------------------------------
    @testset "qr_householder Posit{32,2} 3x3" begin
        T = Posit{32, 2}
        vals = [4.0  3.0 -1.0;
                0.0  2.0  2.0;
                3.0  1.0  5.0]
        A = T.(vals)
        Q, R = QRmod.qr_householder(A)

        @test istriu(R)

        # Reconstruction via Q * R (uses the custom HouseholderReflection * method)
        recon = Q * R
        @test norm(Float64.(recon) - vals) < atol_p32
    end

    # ------------------------------------------------------------------
    # 3. Solve (uses qr_householder internally)
    # ------------------------------------------------------------------
    @testset "QR.solve Float64 3x3" begin
        A = [2.0 1.0 0.0;
             1.0 3.0 1.0;
             0.0 1.0 2.0]
        b = [5.0, 10.0, 7.0]
        n = size(A, 1)
        x = QRmod.solve(A, b, collect(1:n), collect(1:n))
        @test norm(A * x - b) < atol_f64
    end

    @testset "QR.solve Posit{32,2} 3x3" begin
        T = Posit{32, 2}
        Avals = [2.0 1.0 0.0;
                 1.0 3.0 1.0;
                 0.0 1.0 2.0]
        bvals = [5.0, 10.0, 7.0]
        A = T.(Avals)
        b = T.(bvals)
        n = size(A, 1)
        x = QRmod.solve(A, b, collect(1:n), collect(1:n))
        @test norm(Avals * Float64.(x) - bvals) < atol_p32
    end

    # ------------------------------------------------------------------
    # 4. Sparse QR via qr_givens: structure checks
    # ------------------------------------------------------------------
    @testset "qr_givens Float64 sparse 4x4 structure" begin
        Adense = [4.0 1.0 0.0 0.0;
                  1.0 3.0 1.0 0.0;
                  0.0 1.0 2.0 1.0;
                  0.0 0.0 1.0 3.0]
        A = sparse(Adense)

        Q, R = QRmod.qr_givens(A)

        # R should be upper triangular
        @test istriu(Matrix(R))

        # Reconstruction: A = Q^T R (Givens accumulate as QA=R so A=Q^TR)
        Rm = Matrix(R)
        recon = lmul!(Q, copy(Rm))          # Q * R = R_final_check
        recon_AT = lmul!(adjoint(Q), copy(Rm))  # Q^T R should = A
        @test norm(recon_AT - Adense) < 1e-10
    end

    # ------------------------------------------------------------------
    # 5. LinearAlgebra.qr dispatch on sparse UniversalNumber matrix
    # ------------------------------------------------------------------
    @testset "LinearAlgebra.qr dispatch Posit{32,2} sparse structure" begin
        T = Posit{32, 2}
        Adense = T.([4.0 1.0 0.0;
                     1.0 3.0 1.0;
                     0.0 1.0 2.0])
        A = sparse(Adense)
        F = qr(A)

        # R is upper triangular
        @test istriu(Matrix(F.R))

        # Reconstruction: A = Q R
        QR_recon = Float64.(Matrix(F.Q)) * Float64.(Matrix(F.R))   # Float64 matmul; Posit Q has no lmul!
        @test norm(QR_recon - Float64.(Adense)) < atol_p32
    end

end
