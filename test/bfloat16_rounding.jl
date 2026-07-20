using UniversalNumbers
using Test

# bfloat16 float-conversion rounding. Upstream Stillwater Universal changed the
# float -> bfloat16 cast from truncation to round-to-nearest, ties-to-even (RNE),
# matching TPU/Intel hardware (upstream #1134). These tests pin the RNE behavior
# so a regression back to truncation would fail.
#
# bfloat16 keeps the top 16 bits of a Float32 (sign + 8 exp + 7 fraction); the
# step between adjacent values near 1.0 is 2^-7 = 0.0078125, and near 0.27 it is
# 2^-9 = 0.001953125. Truncation always rounds toward zero (the lower neighbor);
# RNE picks the nearest, breaking exact ties toward the even significand.

@testset "BF16 round-to-nearest-even cast (#4)" begin
    # Reported example: rounds UP to the nearer bf16. Truncation would have given
    # the lower neighbor 0.267578125.
    @test Float64(BF16(0.2691408770292272)) == 0.26953125

    # Neighbors of 1.0: lo = 1.0, hi = 1.0078125 (one bf16 step up).
    lo, hi = 1.0, 1.0 + 2.0^-7

    # More than half a step above lo -> rounds UP (truncation would give lo).
    @test Float64(BF16(1.0 + 3 * 2.0^-9)) == hi
    # Less than half a step above lo -> rounds DOWN to lo.
    @test Float64(BF16(1.0 + 1 * 2.0^-9)) == lo
    # Exact midpoint -> ties to even; lo has the even significand, so it wins.
    @test Float64(BF16(1.0 + 2.0^-8)) == lo

    # RNE is nearest: the error never exceeds half a bfloat16 ulp.
    for x in (0.1, 3.14159, 2.718281828, 100.4, 0.0073, 0.2691408770292272)
        b = Float64(BF16(x))
        halfulp = 2.0^(exponent(Float32(x)) - 8)
        @test abs(b - x) <= halfulp * (1 + 1e-9)
    end

    # NaN must be preserved, not collapse to Inf (part of the same upstream fix).
    @test isnan(BF16(NaN))
    @test !isinf(BF16(NaN))
    @test isinf(BF16(Inf))
    @test !isnan(BF16(Inf))
end
