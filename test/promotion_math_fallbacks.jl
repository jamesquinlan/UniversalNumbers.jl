using UniversalNumbers
using Test

# Coverage for two lightly-exercised areas of UniversalNumbers.jl:
#   1. _un_promote's mixed-width / equal-width branches (only the same-type path
#      was hit before), reached here through promote_type and mixed arithmetic.
#   2. Float64-round-trip fallbacks never compiled by the rest of the suite:
#      hypot, the two-argument atan, ldexp, and frexp.
@testset "Mixed-type promotion (_un_promote)" begin
    P16 = Posit{16,2,UInt16}
    P32 = Posit{32,2,UInt32}

    # Wider storage type wins, regardless of argument order.
    @test promote_type(P32, P16) === P32
    @test promote_type(P16, P32) === P32

    # Mixed-width arithmetic promotes to the wider type before computing.
    @test (P32(1.5) + P16(2.5)) isa P32
    @test Float64(P32(1.5) + P16(2.5)) ≈ 4.0

    # Equal storage width but different types -> Float64 fallback.
    @test promote_type(Posit{16,1,UInt16}, Posit{16,2,UInt16}) === Float64
end

@testset "Float64-round-trip math fallbacks" begin
    T = Posit{32,2,UInt32}

    @test Float64(hypot(T(3.0), T(4.0))) ≈ 5.0
    @test Float64(atan(T(1.0), T(1.0)))  ≈ atan(1.0, 1.0) atol = 1e-6
    @test Float64(ldexp(T(1.5), 3))      ≈ 12.0

    m, e = frexp(T(12.0))
    @test e isa Integer
    @test Float64(m) * 2.0^e ≈ 12.0

    @test signbit(T(-2.0)) === true
    @test signbit(T(2.0))  === false
    @test Float64(copysign(T(3.0), T(-1.0))) ≈ -3.0
end
