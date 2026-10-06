using UniversalNumbers
using Test

# typemax/typemin (issue #7): the top and bottom of each type's order, never NaN/NaR.
# Families that encode ±Inf return ±Inf (like Float64); the rest return ±floatmax.
# Fixed is two's complement, so typemin is the sign-bit-only pattern (like typemin(Int8)).

const INF_TYPES = (
    CFloat{8,2}, CFloat{8,3}, CFloat{8,4}, CFloat{8,5}, CFloat{24,5},
    E3M4, E4M3, E5M2, DFloat{7,6}, DFloat{16,8}, BF16, DD,
)
const FINITE_TYPES = (
    Posit{8,0}, Posit{8,1}, Posit{8,2}, Posit{12,1}, Posit{16,1}, Posit{16,2},
    Posit{32,2}, Posit{19,3}, Posit{19,2}, Posit{64,2}, Posit{64,3},
    Takum{8}, Takum{16}, Takum{32}, Takum{64},
    LNS{16,5}, LNS{32,16}, HFloat{6,7}, HFloat{14,7},
)
const FIXED_TYPES = (Fixed{8,4}, Fixed{16,8}, Fixed{32,16})

@testset "typemax / typemin" begin
    @testset "±Inf -- $T" for T in INF_TYPES
        @test typemax(T) isa UniversalNumber
        @test isinf(typemax(T)) && typemax(T) > 0
        @test isinf(typemin(T)) && typemin(T) < 0
        @test typemax(T) > floatmax(T)
        @test typemin(T) < -floatmax(T)
    end

    @testset "±floatmax -- $T" for T in FINITE_TYPES
        @test typemax(T) == floatmax(T)
        @test typemin(T) == -floatmax(T)
        @test !isnan(typemax(T)) && !isnan(typemin(T))
    end

    @testset "two's complement range -- $T" for T in FIXED_TYPES
        @test typemax(T) == floatmax(T)
        @test typemin(T) < -floatmax(T)
        @test nextfloat(typemin(T)) == -floatmax(T)
    end

    @testset "BF16 matches Float32" begin
        @test typemax(BF16).data == 0x7F80
        @test typemin(BF16).data == 0xFF80
        @test Float32(typemax(BF16)) == typemax(Float32)
        @test Float32(typemin(BF16)) == typemin(Float32)
    end

    @testset "Fixed values" begin
        @test Float64(typemin(Fixed{8,4}))   == -8.0
        @test Float64(typemin(Fixed{16,8}))  == -128.0
        @test Float64(typemin(Fixed{32,16})) == -32768.0
    end

    @testset "typemax bounds a reduction" begin
        for T in (Posit{16,1}, Takum{16}, BF16, Fixed{16,8})
            xs = T.([3.0, -2.0, 0.5])
            @test reduce(min, xs; init = typemax(T)) == T(-2.0)
            @test reduce(max, xs; init = typemin(T)) == T(3.0)
        end
    end
end
