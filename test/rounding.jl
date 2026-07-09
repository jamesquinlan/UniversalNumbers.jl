using UniversalNumbers
using Test

# Rounding to an integer type routes through Float64 (Base.trunc/floor/ceil/round
# with a `Type{<:Integer}` first argument). Use 16- and 32-bit posits, whose
# precision near 2.7 is ample for unambiguous results.
@testset "Integer rounding (trunc/floor/ceil/round to Integer)" begin
    for T in (Posit{16,1}, Posit{32,2})
        x = T(2.7)
        @test trunc(Int, x) == 2
        @test floor(Int, x) == 2
        @test ceil(Int, x)  == 3
        @test round(Int, x) == 3

        y = T(-2.7)
        @test trunc(Int, y) == -2
        @test floor(Int, y) == -3
        @test ceil(Int, y)  == -2
        @test round(Int, y) == -3
    end
end
