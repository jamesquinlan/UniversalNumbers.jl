using UniversalNumbers
using Test

# Regression test for the Rational-constructor ambiguity (fixed v0.1.1):
# T(a//b) used to throw MethodError because our (f::Real) constructor collided
# with Base's (::Type{T})(x::Rational) where T<:AbstractFloat (rational.jl:162).
# The fix mirrors that Base method per-type, so T(a//b) behaves like the standard
# float rational cast.

# One representative concrete type from each registered family, plus the two
# UnionAll spellings to confirm the parametric front-end works too.
const RATIONAL_TYPES = (
    Posit{8,1}, CFloat{8,4}, LNS{16,5}, Takum{16},
    Fixed{16,8}, HFloat{6,7}, DFloat{7,6}, DD, BF16,
)

@testset "Rational construction" begin
    @testset "no ambiguity / correct value -- $T" for T in RATIONAL_TYPES
        # The bug: this used to throw. Now it must build without error.
        @test T(1//32) isa T

        # Powers of two are exact in every family, so the rational cast must land
        # on the identical bits as the equivalent Float64 cast.
        @test T(1//32).data == T(0.03125).data
        @test T(1//2).data  == T(0.5).data
        @test T(3//2).data  == T(1.5).data

        # General value: agrees with the Base-style algorithm (compute the ratio in
        # T), which is exactly what the fix implements.
        P = promote_type(T, Int)
        @test T(1//10).data == convert(T, convert(P, 1) / convert(P, 10)).data

        # Sign is carried through.
        @test T(-1//2).data == T(-0.5).data
    end

    # UnionAll front-end (Posit{8,1} etc.) resolves to the same concrete result.
    @testset "UnionAll spelling" begin
        @test Posit{8,1}(1//32).data  == Posit{8,1,UInt8}(1//32).data
        @test Takum{16}(3//2).data    == Takum{16,UInt16}(3//2).data
    end

    # Rational{S} for the common integer element types dispatches cleanly.
    @testset "Rational element types" begin
        @test Posit{16,1}(Int32(1)//Int32(32)).data == Posit{16,1}(1//32).data
        @test BF16(true//true).data == BF16(1.0).data
        # NOTE: Rational{BigInt} is intentionally not exercised. It hits a
        # pre-existing non-convergence in promote_type(<:UniversalNumber, BigInt)
        # that predates this fix and is out of scope here; calling it raises a
        # StackOverflowError rather than returning a value.
    end
end
