using UniversalNumbers
using Test
using LinearAlgebra
using Random

@testset "UniversalNumbers.jl" begin

    # -----------------------------------------------------------------------
    # Posit arithmetic
    # -----------------------------------------------------------------------
    @testset "Posit{16,1} arithmetic" begin
        a = Posit{16,1}(1.5)
        b = Posit{16,1}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 1.6666667 atol = 1e-4
        @test Float64(-a) == -1.5
        @test Float64(abs(Posit{16,1}(-2.5))) == 2.5
    end

    @testset "Posit{32,2} arithmetic & math" begin
        a = Posit{32,2}(1.5)
        b = Posit{32,2}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(sqrt(Posit{32,2}(4.0))) == 2.0
        @test Float64(sin(Posit{32,2}(0.0))) == 0.0
        @test Float64(sin(Posit{32,2}(1.5707963))) ≈ 1.0 atol = 1e-6
        @test Float64(cos(Posit{32,2}(0.0))) == 1.0
        @test Float64(exp(Posit{32,2}(0.0))) == 1.0
        @test Float64(log(Posit{32,2}(1.0))) == 0.0
    end

    @testset "Posit{8,0} and Posit{19,3}" begin
        @test Float64(Posit{8,0}(1.0) + Posit{8,0}(2.0)) == 3.0
        @test Float64(Posit{19,3}(1.5) + Posit{19,3}(2.5)) == 4.0
    end

    @testset "Posit{19,2}" begin
        a, b = Posit{19,2}(1.5), Posit{19,2}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-4
        @test Float64(-a) == -1.5
        @test Float64(sqrt(Posit{19,2}(4.0))) == 2.0
        @test Float64(exp(Posit{19,2}(0.0))) == 1.0
        @test Float64(log(Posit{19,2}(1.0))) == 0.0
        @test isnan(Posit{19,2}(NaN))
        @test !isnan(Posit{19,2}(1.0))
    end

    @testset "Posit{16,2} arithmetic (standard posit16)" begin
        a, b = Posit{16,2}(1.5), Posit{16,2}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 5e-4   # es=2 -> 11 frac bits near 1; ULP ≈ 4.9e-4
        @test Float64(-a) == -1.5
        @test Float64(abs(Posit{16,2}(-2.5))) == 2.5
        @test Float64(sqrt(Posit{16,2}(4.0))) == 2.0
        @test Float64(sin(Posit{16,2}(0.0))) == 0.0
        @test Float64(exp(Posit{16,2}(0.0))) == 1.0
        @test Float64(log(Posit{16,2}(1.0))) == 0.0
        @test isnan(Posit{16,2}(NaN))
        @test !isnan(Posit{16,2}(1.0))
        # useed = 2^(2^2) = 16; reciprocal symmetry
        lo, hi = Float64(floatmin(Posit{16,2})), Float64(floatmax(Posit{16,2}))
        @test lo * hi == 1.0
    end

    # -----------------------------------------------------------------------
    # CFloat arithmetic
    # -----------------------------------------------------------------------
    @testset "CFloat{8,2} (quarter) and CFloat{24,5}" begin
        @test Float64(CFloat{8,2}(1.0) + CFloat{8,2}(2.0)) == 3.0
        @test Float64(CFloat{24,5}(1.5) + CFloat{24,5}(2.5)) == 4.0
        @test Float64(sqrt(CFloat{24,5}(4.0))) == 2.0
        @test Float64(-CFloat{8,2}(1.5)) == -1.5
    end

    @testset "CFloat{8,3} / CFloat{8,4} / CFloat{8,5} (FP8 formats)" begin
        # E3M4 = CFloat{8,3}: 3 exponent bits, 4 mantissa bits
        @test Float64(CFloat{8,3}(1.0) + CFloat{8,3}(2.0)) ≈ 3.0 atol = 0.1
        @test Float64(CFloat{8,3}(1.5) * CFloat{8,3}(2.0)) ≈ 3.0 atol = 0.1
        @test Float64(-CFloat{8,3}(1.5)) ≈ -1.5 atol = 0.1
        @test CFloat{8,3}(1.0) < CFloat{8,3}(2.0)
        @test CFloat{8,3}(2.0) == CFloat{8,3}(2.0)
        # E4M3 = CFloat{8,4}: 4 exponent bits, 3 mantissa bits
        @test Float64(CFloat{8,4}(1.0) + CFloat{8,4}(2.0)) ≈ 3.0 atol = 0.1
        @test Float64(CFloat{8,4}(4.0) / CFloat{8,4}(2.0)) ≈ 2.0 atol = 0.1
        @test Float64(-CFloat{8,4}(1.5)) ≈ -1.5 atol = 0.1
        @test CFloat{8,4}(1.0) < CFloat{8,4}(2.0)
        # E5M2 = CFloat{8,5}: 5 exponent bits, 2 mantissa bits
        @test Float64(CFloat{8,5}(1.0) + CFloat{8,5}(2.0)) ≈ 3.0 atol = 0.1
        @test Float64(CFloat{8,5}(4.0) / CFloat{8,5}(2.0)) ≈ 2.0 atol = 0.1
        @test Float64(-CFloat{8,5}(1.5)) ≈ -1.5 atol = 0.5
        @test CFloat{8,5}(1.0) < CFloat{8,5}(2.0)
    end

    @testset "FP8 aliases (E4M3, E3M4, E5M2)" begin
        # Aliases are identical types -- not wrappers
        @test E4M3 === CFloat{8,4}
        @test E3M4 === CFloat{8,3}
        @test E5M2 === CFloat{8,5}
        # Construction via alias works exactly like the CFloat{N,ES} form
        @test E4M3(1.5) == CFloat{8,4}(1.5)
        @test E3M4(1.5) == CFloat{8,3}(1.5)
        @test E5M2(1.5) == CFloat{8,5}(1.5)
        # Arithmetic through alias name
        @test Float64(E4M3(1.0) + E4M3(1.0)) ≈ 2.0 atol = 0.1
        @test Float64(E3M4(2.0) * E3M4(2.0)) ≈ 4.0 atol = 0.1
        @test Float64(E5M2(4.0) / E5M2(2.0)) ≈ 2.0 atol = 0.1
        # Display uses CFloat{N,ES} form (aliases are transparent)
        @test string(E4M3(1.5)) == "CFloat{8,4}(1.5)"
        @test string(E3M4(1.5)) == "CFloat{8,3}(1.5)"
        @test string(E5M2(1.5)) == "CFloat{8,5}(1.5)"
    end

    # -----------------------------------------------------------------------
    # LNS arithmetic
    # -----------------------------------------------------------------------
    @testset "LNS{16,5} (logarithmic)" begin
        @test Float64(LNS{16,5}(1.5) * LNS{16,5}(2.0)) ≈ 3.0 rtol = 0.02
        @test Float64(LNS{16,5}(4.0) / LNS{16,5}(2.0)) ≈ 2.0 rtol = 0.02
        @test Float64(-LNS{16,5}(1.5)) ≈ -1.5 rtol = 0.02
    end

    @testset "LNS{32,16} arithmetic" begin
        @test Float64(LNS{32,16}(1.5) * LNS{32,16}(2.0)) ≈ 3.0 rtol = 0.01
        @test Float64(LNS{32,16}(4.0) / LNS{32,16}(2.0)) ≈ 2.0 rtol = 0.01
        @test Float64(LNS{32,16}(1.0) + LNS{32,16}(1.0)) ≈ 2.0 rtol = 0.01
        @test Float64(LNS{32,16}(3.0) - LNS{32,16}(1.0)) ≈ 2.0 rtol = 0.01
        @test Float64(-LNS{32,16}(1.5)) ≈ -1.5 rtol = 0.01
        @test Float64(sqrt(LNS{32,16}(4.0))) ≈ 2.0 rtol = 0.01
        @test Float64(exp(LNS{32,16}(0.0))) ≈ 1.0 rtol = 0.01
        @test Float64(log(LNS{32,16}(1.0))) ≈ 0.0 atol = 0.01
    end

    # -----------------------------------------------------------------------
    # Comparisons
    # -----------------------------------------------------------------------
    @testset "Comparisons" begin
        @test Posit{16,1}(1.5) < Posit{16,1}(2.5)
        @test Posit{16,1}(2.5) <= Posit{16,1}(2.5)
        @test Posit{16,1}(-1.0) < Posit{16,1}(1.0)
        @test Posit{16,1}(2.0) == Posit{16,1}(2.0)
        @test CFloat{8,2}(1.0) < CFloat{8,2}(2.0)
        @test LNS{16,5}(1.0) < LNS{16,5}(2.0)
        @test Takum{16}(1.0) < Takum{16}(2.0)
        @test Takum{16}(2.0) == Takum{16}(2.0)
        @test Fixed{16,8}(1.0) < Fixed{16,8}(2.0)
        @test Fixed{16,8}(2.0) == Fixed{16,8}(2.0)
        @test HFloat{6,7}(1.0) < HFloat{6,7}(2.0)
        @test DD(1.5) < DD(2.5)
        @test DD(2.0) == DD(2.0)
    end

    # -----------------------------------------------------------------------
    # NaR (Not-a-Real)
    # -----------------------------------------------------------------------
    @testset "NaR (Not-a-Real)" begin
        for T in (Posit{8,0}, Posit{16,1}, Posit{16,2}, Posit{32,2},
                  Posit{19,3}, Posit{19,2}, Posit{64,2}, Posit{64,3})
            n = T(NaN)
            @test isnan(n)
            @test !isnan(T(1.0))
            # posit semantics: NaR == NaR is TRUE (unlike IEEE NaN)
            @test n == n
            # NaR sorts below every real value (posit total order)
            @test n < T(-1.0e6)
            @test n < T(0.0)
            @test n <= n
            # NaR is its own negation and is absorbing in arithmetic
            @test isnan(-n)
            @test isnan(n + T(1.0))
            @test isnan(n * T(2.0))
            @test isnan(n / T(2.0))
            @test isnan(sqrt(T(-1.0)))
        end
        # NaR is the single bit pattern 100...0
        @test Posit{16,1}(NaN).data == 0x8000
        @test Posit{32,2}(NaN).data == 0x80000000
    end

    # -----------------------------------------------------------------------
    # AbstractFloat interface
    # -----------------------------------------------------------------------
    @testset "AbstractFloat behavior" begin
        @test Float64(zero(Posit{16,1})) == 0.0
        @test Float64(one(Posit{16,1})) == 1.0
        @test iszero(Posit{16,1}(0.0))
        @test !iszero(Posit{16,1}(1.0))
        # mixed arithmetic promotes the standard number to the posit
        @test Posit{16,1}(1.5) + 2.5 == Posit{16,1}(4.0)
        @test 2 * Posit{16,1}(1.5) == Posit{16,1}(3.0)
        @test Posit{16,1}(2.0) == 2.0
        @test Posit{32,2}(0.5) < 1
        # show
        @test string(Posit{16,1}(1.5)) == "Posit{16,1}(1.5)"
        @test string(Takum{16}(1.5))   == "Takum{16}(1.5)"
        @test string(DD(1.5))          == "DD(1.5)"
    end

    # -----------------------------------------------------------------------
    # Posit symmetry (dynamic range)
    # -----------------------------------------------------------------------
    @testset "Posit symmetry (dynamic range)" begin
        for (T, nbits, es) in (
                (Posit{8,0},   8,  0),
                (Posit{16,1},  16, 1),
                (Posit{16,2},  16, 2),
                (Posit{32,2},  32, 2),
                (Posit{19,3},  19, 3),
                (Posit{19,2},  19, 2),
                (Posit{64,2},  64, 2),
                (Posit{64,3},  64, 3))
            lo, hi = Float64(floatmin(T)), Float64(floatmax(T))
            useed = 2.0^(2^es)
            @test lo * hi == 1.0
            @test hi == useed^(nbits - 2)
            @test Float64(-T(hi)) == -hi
            @test Float64(-T(lo)) == -lo
        end
    end

    # -----------------------------------------------------------------------
    # Takum arithmetic
    # -----------------------------------------------------------------------
    @testset "Takum{N} arithmetic" begin
        # 8-bit takum (very low precision -- only verify basic sanity)
        @test Float64(Takum{8}(1.0) + Takum{8}(1.0)) ≈ 2.0 atol = 0.1
        @test Float64(-Takum{8}(1.5)) ≈ -1.5 atol = 0.1
        @test isnan(Takum{8}(NaN))
        @test !isnan(Takum{8}(1.0))
        # 16-bit
        a = Takum{16}(1.5)
        b = Takum{16}(2.5)
        @test Float64(a + b) ≈ 4.0   atol = 1e-3
        @test Float64(a - b) ≈ -1.0  atol = 1e-3
        @test Float64(a * b) ≈ 3.75  atol = 1e-3
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-3
        @test Float64(-a) ≈ -1.5     atol = 1e-4
        @test Float64(sqrt(Takum{16}(4.0))) ≈ 2.0 atol = 1e-3
        @test Float64(sin(Takum{16}(0.0))) ≈ 0.0 atol = 1e-3
        @test Float64(exp(Takum{16}(0.0))) ≈ 1.0 atol = 1e-3
        # 32-bit
        @test Float64(Takum{32}(3.14159)) ≈ 3.14159 atol = 1e-4
        @test Float64(Takum{32}(1.5) + Takum{32}(2.5)) ≈ 4.0 atol = 1e-5
        # 64-bit
        @test Float64(Takum{64}(1.5) + Takum{64}(2.5)) ≈ 4.0   atol = 1e-12
        @test Float64(Takum{64}(1.5) * Takum{64}(2.5)) ≈ 3.75  atol = 1e-12
        @test Float64(Takum{64}(2.5) / Takum{64}(1.5)) ≈ 5.0/3.0 atol = 1e-12
        @test Float64(sqrt(Takum{64}(4.0))) ≈ 2.0  atol = 1e-12
        @test Float64(sin(Takum{64}(0.0)))  ≈ 0.0  atol = 1e-12
        @test Float64(exp(Takum{64}(0.0)))  ≈ 1.0  atol = 1e-12
        @test Float64(log(Takum{64}(1.0)))  ≈ 0.0  atol = 1e-12
        @test isnan(Takum{64}(NaN))
        @test !isnan(Takum{64}(1.0))
        # NaR -- takum analogue of NaN
        @test isnan(Takum{16}(NaN))
        @test !isnan(Takum{16}(1.0))
    end

    # -----------------------------------------------------------------------
    # Fixed-point arithmetic
    # -----------------------------------------------------------------------
    @testset "Fixed{N,R} arithmetic" begin
        # Fixed{16,8}: 16 total bits, 8 fractional -> step = 1/256
        a, b = Fixed{16,8}(1.5), Fixed{16,8}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1/256
        @test Float64(-a) == -1.5
        @test Float64(abs(Fixed{16,8}(-2.5))) == 2.5
        # Fixed{32,16}: 32 bits, 16 fractional -> step = 1/65536
        @test Float64(Fixed{32,16}(1.5) + Fixed{32,16}(2.5)) == 4.0
        @test Float64(Fixed{32,16}(10.0) * Fixed{32,16}(3.0)) == 30.0
        @test Float64(Fixed{32,16}(7.0) - Fixed{32,16}(3.0)) == 4.0
        @test Float64(Fixed{32,16}(6.0) / Fixed{32,16}(2.0)) == 3.0
    end

    @testset "Fixed{N,R} modular wrap" begin
        # Fixed{8,4}: 8 bits, 4 fractional -> 4-bit signed integer part
        # max = 7.9375, min = -8.0, step = 1/16
        # 7 + 1 = 8 -> wraps to -8 (two's complement, Modulo)
        @test Float64(Fixed{8,4}(7.0) + Fixed{8,4}(1.0)) == -8.0
        # -8 - 1 = -9 -> wraps to +7
        @test Float64(Fixed{8,4}(-8.0) - Fixed{8,4}(1.0)) == 7.0
        # Fixed{16,8}: max integer part is 127 (7-bit signed); 127 + 1 wraps to -128
        @test Float64(Fixed{16,8}(127.0) + Fixed{16,8}(1.0)) == -128.0
    end

    @testset "Fixed{N,R} no NaN/Inf" begin
        for T in (Fixed{8,4}, Fixed{16,8}, Fixed{32,16})
            @test !isnan(T(1.0))
            @test !isinf(T(1.0))
            @test iszero(T(0.0))
            @test Float64(zero(T)) == 0.0
            @test Float64(one(T)) == 1.0
        end
    end

    @testset "Fixed{N,R} nextfloat/prevfloat" begin
        x = Fixed{16,8}(1.5)
        @test nextfloat(x) > x
        @test prevfloat(x) < x
        @test prevfloat(nextfloat(x)) == x
        @test nextfloat(prevfloat(x)) == x
        # step size for Fixed{16,8} is 1/256
        @test Float64(nextfloat(Fixed{16,8}(1.0)) - Fixed{16,8}(1.0)) ≈ 1/256 atol = 1e-10
    end

    # -----------------------------------------------------------------------
    # HFloat (IBM hex float)
    # -----------------------------------------------------------------------
    @testset "HFloat{N,ES} arithmetic" begin
        # HFloat{6,7} = hfp32 (32-bit IBM hex float)
        a, b = HFloat{6,7}(1.5), HFloat{6,7}(2.5)
        @test Float64(a + b) ≈ 4.0 atol = 1e-5
        @test Float64(a - b) ≈ -1.0 atol = 1e-5
        @test Float64(a * b) ≈ 3.75 atol = 1e-5
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-5
        @test Float64(-a) ≈ -1.5 atol = 1e-8
        @test Float64(abs(HFloat{6,7}(-2.5))) ≈ 2.5 atol = 1e-5
        @test Float64(sqrt(HFloat{6,7}(4.0))) ≈ 2.0 atol = 1e-5
        @test Float64(exp(HFloat{6,7}(0.0))) ≈ 1.0 atol = 1e-5
        @test Float64(log(HFloat{6,7}(1.0))) ≈ 0.0 atol = 1e-5
        # HFloat{14,7} = hfp64 (64-bit IBM hex float)
        a64, b64 = HFloat{14,7}(1.5), HFloat{14,7}(2.5)
        @test Float64(a64 + b64) ≈ 4.0 atol = 1e-10
        @test Float64(a64 * b64) ≈ 3.75 atol = 1e-10
        @test Float64(-a64) ≈ -1.5 atol = 1e-12
        @test Float64(sqrt(HFloat{14,7}(2.0))) ≈ sqrt(2.0) atol = 1e-10
    end

    @testset "HFloat{N,ES} no NaN/Inf" begin
        for T in (HFloat{6,7}, HFloat{14,7})
            @test !isnan(T(1.0))
            @test !isinf(T(1.0))
            @test iszero(T(0.0))
            @test Float64(one(T)) == 1.0
        end
    end

    @testset "HFloat{N,ES} nextfloat/prevfloat" begin
        x = HFloat{6,7}(1.5)
        @test nextfloat(x) > x
        @test prevfloat(x) < x
        @test prevfloat(nextfloat(x)) == x
    end

    # -----------------------------------------------------------------------
    # DFloat (IEEE 754-2008 decimal float)
    # -----------------------------------------------------------------------
    @testset "DFloat{N,ES} arithmetic" begin
        # DFloat{7,6} = decimal32
        a, b = DFloat{7,6}(1.5), DFloat{7,6}(2.5)
        @test Float64(a + b) ≈ 4.0 atol = 1e-5
        @test Float64(a - b) ≈ -1.0 atol = 1e-5
        @test Float64(a * b) ≈ 3.75 atol = 1e-5
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-4
        @test Float64(-a) ≈ -1.5 atol = 1e-6
        @test Float64(abs(DFloat{7,6}(-2.5))) ≈ 2.5 atol = 1e-5
        @test Float64(sqrt(DFloat{7,6}(4.0))) ≈ 2.0 atol = 1e-4
        # DFloat{16,8} = decimal64
        a64, b64 = DFloat{16,8}(1.5), DFloat{16,8}(2.5)
        @test Float64(a64 + b64) ≈ 4.0 atol = 1e-10
        @test Float64(a64 * b64) ≈ 3.75 atol = 1e-10
        @test Float64(-a64) ≈ -1.5 atol = 1e-12
        @test Float64(sqrt(DFloat{16,8}(4.0))) ≈ 2.0 atol = 1e-10
    end

    @testset "DFloat{N,ES} no NaN/Inf" begin
        for T in (DFloat{7,6}, DFloat{16,8})
            @test !isnan(T(1.0))
            @test !isinf(T(1.0))
            @test iszero(T(0.0))
            @test Float64(one(T)) == 1.0
        end
    end

    # -----------------------------------------------------------------------
    # BF16 (Google Brain float16)
    # -----------------------------------------------------------------------
    @testset "BF16 arithmetic" begin
        a, b = BF16(1.5), BF16(2.5)
        @test Float64(a + b) ≈ 4.0 atol = 1e-2
        @test Float64(a - b) ≈ -1.0 atol = 1e-2
        @test Float64(a * b) ≈ 3.75 atol = 1e-2
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-2
        @test Float64(-a) ≈ -1.5 atol = 1e-3
        @test Float64(abs(BF16(-2.5))) ≈ 2.5 atol = 1e-3
        @test Float64(sqrt(BF16(4.0))) ≈ 2.0 atol = 1e-2
        @test BF16(1.0) < BF16(2.0)
        @test BF16(2.0) == BF16(2.0)
        @test iszero(BF16(0.0))
        @test Float64(one(BF16)) == 1.0
        @test Float64(zero(BF16)) == 0.0
    end

    @testset "BF16 NaN and Inf" begin
        @test isnan(BF16(NaN))
        @test !isnan(BF16(1.0))
        @test isinf(BF16(Inf))
        @test isinf(BF16(-Inf))
        @test !isinf(BF16(1.0))
        # BF16 has same exponent range as Float32; very large Float32 fits
        @test Float64(BF16(3.4e38)) > 1e38
    end

    @testset "BF16 nextfloat/prevfloat" begin
        x = BF16(1.5)
        @test nextfloat(x) > x
        @test prevfloat(x) < x
        @test prevfloat(nextfloat(x)) == x
    end

    # -----------------------------------------------------------------------
    # Edge cases: CFloat IEEE exceptions and subnormals
    # -----------------------------------------------------------------------
    @testset "CFloat NaN and Inf" begin
        # CFloat{24,5} = half precision (IEEE-style with subnormals)
        @test isnan(CFloat{24,5}(NaN))
        @test !isnan(CFloat{24,5}(1.0))
        @test isinf(CFloat{24,5}(Inf))
        @test isinf(CFloat{24,5}(-Inf))
        @test !isinf(CFloat{24,5}(1.0))
        # NaN arithmetic is absorbing
        n = CFloat{24,5}(NaN)
        @test isnan(n + CFloat{24,5}(1.0))
        @test isnan(n * CFloat{24,5}(2.0))
        # Inf arithmetic
        inf = CFloat{24,5}(Inf)
        @test isinf(inf + CFloat{24,5}(1.0))
        @test isinf(inf * CFloat{24,5}(2.0))
        # Same for 8-bit
        @test isnan(CFloat{8,2}(NaN))
        @test isinf(CFloat{8,2}(Inf))
    end

    @testset "CFloat subnormals" begin
        # CFloat{24,5}: min normal ≈ 6.1e-5; subnormals exist between 0 and floatmin
        T = CFloat{24,5}
        @test floatmin(T) > zero(T)
        # prevfloat of floatmin is a subnormal (positive, less than floatmin)
        subnorm = prevfloat(floatmin(T))
        @test subnorm > zero(T)
        @test subnorm < floatmin(T)
        @test !isnan(subnorm)
        @test !isinf(subnorm)
        # nextfloat of zero is the smallest subnormal
        tiny = nextfloat(zero(T))
        @test tiny > zero(T)
        @test tiny < floatmin(T)
    end

    @testset "Posit{64,3} arithmetic" begin
        a, b = Posit{64,3}(1.5), Posit{64,3}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-14
        @test Float64(-a) == -1.5
        @test Float64(sqrt(Posit{64,3}(2.0))) ≈ sqrt(2.0) atol = 1e-14
        @test isnan(Posit{64,3}(NaN))
        lo, hi = Float64(floatmin(Posit{64,3})), Float64(floatmax(Posit{64,3}))
        @test lo * hi == 1.0
    end

    @testset "Posit{64,2} arithmetic" begin
        a, b = Posit{64,2}(1.5), Posit{64,2}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-14
        @test Float64(-a) == -1.5
        @test Float64(sqrt(Posit{64,2}(2.0))) ≈ sqrt(2.0) atol = 1e-14
        @test Float64(sin(Posit{64,2}(0.0))) == 0.0
        @test Float64(exp(Posit{64,2}(0.0))) == 1.0
        @test isnan(Posit{64,2}(NaN))
        lo, hi = Float64(floatmin(Posit{64,2})), Float64(floatmax(Posit{64,2}))
        @test lo * hi == 1.0
    end

    # -----------------------------------------------------------------------
    # DD (double-double)
    # -----------------------------------------------------------------------
    @testset "DD (double-double) arithmetic" begin
        a, b = DD(1.5), DD(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 5.0/3.0 atol = 1e-14
        @test Float64(-a) == -1.5
        @test Float64(abs(DD(-2.5))) == 2.5
        @test Float64(sqrt(DD(4.0))) == 2.0
        @test Float64(sqrt(DD(2.0))) ≈ sqrt(2.0) atol = 1e-14
        @test Float64(exp(DD(0.0))) ≈ 1.0 atol = 1e-14
        @test Float64(log(DD(1.0))) ≈ 0.0 atol = 1e-14
    end

    @testset "DD constants and precision" begin
        @test iszero(DD(0.0))
        @test Float64(one(DD)) == 1.0
        @test Float64(zero(DD)) == 0.0
        # DD carries ~106 significand bits; round-trips through Float64 faithfully
        x = DD(3.14159265358979323846)
        @test Float64(x) ≈ 3.14159265358979323846 atol = 1e-15
        # nextfloat increments by ~2^-106; Float64 conversion rounds back to same value
        @test Float64(nextfloat(DD(1.0))) == 1.0
    end

    @testset "DD comparisons" begin
        @test DD(1.5) < DD(2.5)
        @test DD(2.0) <= DD(2.0)
        @test DD(2.0) == DD(2.0)
        @test DD(-1.0) < DD(0.0)
    end

    # -----------------------------------------------------------------------
    # printbits smoke test
    # -----------------------------------------------------------------------
    @testset "printbits smoke test" begin
        # Each call is a separate @test to avoid mixed-type array promotion.
        # Output goes to stdout (expected during test runs).
        @test (printbits(Posit{16,1}(1.5));  true)
        @test (printbits(Posit{16,2}(1.5));  true)
        @test (printbits(Posit{8,0}(1.0));   true)
        @test (printbits(Posit{32,2}(1.5));  true)
        @test (printbits(Posit{19,2}(1.5));  true)
        @test (printbits(Posit{64,2}(1.5));  true)
        @test (printbits(Posit{64,3}(1.5));  true)
        @test (printbits(CFloat{8,2}(1.0));  true)
        @test (printbits(CFloat{8,3}(1.0));  true)
        @test (printbits(CFloat{8,4}(1.0));  true)
        @test (printbits(CFloat{8,5}(1.0));  true)
        @test (printbits(CFloat{24,5}(1.5)); true)
        @test (printbits(LNS{16,5}(2.0));    true)
        @test (printbits(LNS{32,16}(2.0));   true)
        @test (printbits(Takum{8}(1.0));     true)
        @test (printbits(Takum{16}(1.5));    true)
        @test (printbits(Takum{32}(1.5));    true)
        @test (printbits(Takum{64}(1.5));    true)
        @test (printbits(Fixed{8,4}(1.5));   true)
        @test (printbits(Fixed{16,8}(1.5));  true)
        @test (printbits(Fixed{32,16}(1.5)); true)
        @test (printbits(HFloat{6,7}(1.5));  true)
        @test (printbits(HFloat{14,7}(1.5)); true)
        @test (printbits(DFloat{7,6}(1.5));  true)
        @test (printbits(DFloat{16,8}(1.5)); true)
        @test (printbits(DD(1.5));           true)
        @test (printbits(BF16(1.5));         true)
    end

    # -----------------------------------------------------------------------
    # about function
    # -----------------------------------------------------------------------
    @testset "about function" begin
        # about(x, io) writes decoded fields to io; printbits always goes to stdout.
        _buf(x) = (buf = IOBuffer(); about(x, buf); String(take!(buf)))

        # Smoke: no errors for any registered type
        @test (_buf(Posit{16,1}(1.5));  true)
        @test (_buf(Posit{16,2}(1.5));  true)
        @test (_buf(Posit{32,2}(1.5));  true)
        @test (_buf(Posit{64,2}(1.5));  true)
        @test (_buf(Posit{64,3}(1.5));  true)
        @test (_buf(CFloat{8,2}(1.0));  true)
        @test (_buf(CFloat{24,5}(1.5)); true)
        @test (_buf(BF16(1.5));          true)
        @test (_buf(LNS{16,5}(2.0));    true)
        @test (_buf(LNS{32,16}(2.0));   true)
        @test (_buf(Fixed{16,8}(1.5));  true)
        @test (_buf(Takum{16}(1.5));    true)
        @test (_buf(Takum{32}(1.5));    true)
        @test (_buf(Takum{64}(1.5));    true)
        @test (_buf(DD(1.5));            true)
        @test (_buf(HFloat{6,7}(1.5));  true)
        @test (_buf(DFloat{7,6}(1.5));  true)

        # Posit{16,1}: field labels and decoded values
        let out = _buf(Posit{16,1}(1.5))
            @test occursin("sign:", out)
            @test occursin("regime:", out)
            @test occursin("exponent:", out)
            @test occursin("fraction:", out)
            @test occursin("scale:", out)
            @test occursin("value:", out)
            @test occursin("k = 0", out)
            @test occursin("1 + 0.5 = 1.5", out)
            @test occursin("1.5", out)
        end

        # Posit special values
        let out = _buf(Posit{16,1}(NaN))
            @test occursin("NaR", out)
        end
        let out = _buf(Posit{16,1}(0.0))
            @test occursin("0 (exact)", out)
        end

        # Posit{32,2}: useed_exp = 4 for ES=2
        let out = _buf(Posit{32,2}(1.5))
            @test occursin("k = 0", out)
            @test occursin("2^4", out)
            @test occursin("1.5", out)
        end

        # CFloat{24,5}: biased exponent decode and fraction
        let out = _buf(CFloat{24,5}(1.5))
            @test occursin("sign:", out)
            @test occursin("exponent:", out)
            @test occursin("fraction:", out)
            @test occursin("value:", out)
            @test occursin("15 − 15 = 0", out)
            @test occursin("1 + 0.5 = 1.5", out)
        end
        let out = _buf(CFloat{24,5}(NaN))
            @test occursin("NaN", out)
            @test occursin("all-ones", out)
        end
        let out = _buf(CFloat{24,5}(Inf))
            @test occursin("all-ones", out)
            @test occursin("Inf", out)   # isnan/isinf delegates to C bridge
        end

        # BF16: 8-bit exponent, bias=127
        let out = _buf(BF16(1.5))
            @test occursin("sign:", out)
            @test occursin("exponent:", out)
            @test occursin("127", out)
            @test occursin("1.5", out)
        end
        let out = _buf(BF16(NaN))
            @test occursin("NaN", out)
        end
        let out = _buf(BF16(Inf))
            @test occursin("Inf", out)
        end

        # LNS: log₂ decomposition
        let out = _buf(LNS{16,5}(2.0))
            @test occursin("log", out)
            @test occursin("integer:", out)
            @test occursin("fraction:", out)
            @test occursin("2.0", out)
        end

        # Fixed: integer + fraction
        let out = _buf(Fixed{16,8}(1.5))
            @test occursin("integer:", out)
            @test occursin("fraction:", out)
            @test occursin("two's complement", out)
            @test occursin("1.5", out)
        end

        # DD: hi/lo components
        let out = _buf(DD(1.5))
            @test occursin("hi:", out)
            @test occursin("lo:", out)
            @test occursin("1.5", out)
            @test occursin("106", out)
        end

        # Takum: sign and direction bits
        let out = _buf(Takum{16}(1.5))
            @test occursin("sign:", out)
            @test occursin("direction:", out)
            @test occursin("1.5", out)
        end
    end

    # -----------------------------------------------------------------------
    # nextfloat / prevfloat
    # -----------------------------------------------------------------------
    @testset "nextfloat / prevfloat" begin
        for T in (Posit{8,0}, Posit{8,1}, Posit{8,2}, Posit{12,1},
                  Posit{16,1}, Posit{16,2}, Posit{32,2}, Posit{19,2},
                  Posit{64,2}, Posit{64,3}, Takum{16}, Takum{32}, Takum{64})
            x = T(1.5)
            nx = nextfloat(x)
            px = prevfloat(x)
            @test nx > x
            @test px < x
            @test prevfloat(nextfloat(x)) == x
            @test nextfloat(prevfloat(x)) == x
            @test nextfloat(zero(T)) == floatmin(T)
            @test prevfloat(floatmin(T)) == zero(T)
            @test nextfloat(T(-1.5)) > T(-1.5)
        end
        # nextfloat past maxpos produces NaR for posits
        @test isnan(nextfloat(floatmax(Posit{16,1})))
        @test isnan(nextfloat(floatmax(Posit{16,2})))
        @test isnan(nextfloat(floatmax(Posit{32,2})))
        @test isnan(nextfloat(floatmax(Posit{64,2})))
        @test isnan(nextfloat(floatmax(Posit{64,3})))
    end

    # -----------------------------------------------------------------------
    # Registry error messages
    # -----------------------------------------------------------------------
    @testset "Unregistered types raise a helpful error" begin
        @test_throws ErrorException Posit{24,1}(1.0)
        @test_throws ErrorException CFloat{32,8}(1.0)
        @test_throws ErrorException Takum{4}(1.0)    # Takum{8} is now registered
        @test_throws ErrorException Fixed{64,32}(1.0)
    end

    # -----------------------------------------------------------------------
    # Linear algebra
    # -----------------------------------------------------------------------
    @testset "LinearAlgebra" begin
        A = [Posit{16,1}(1.0) Posit{16,1}(2.0);
             Posit{16,1}(3.0) Posit{16,1}(4.0)]
        v = [Posit{16,1}(1.0), Posit{16,1}(1.0)]
        res = A * v
        @test Float64(res[1]) == 3.0
        @test Float64(res[2]) == 7.0
        @test Float64(dot(v, v)) == 2.0
    end

    @testset "LinearAlgebra with DD" begin
        A = [DD(1.0) DD(2.0); DD(3.0) DD(4.0)]
        v = [DD(1.0), DD(1.0)]
        res = A * v
        @test Float64(res[1]) ≈ 3.0 atol = 1e-14
        @test Float64(res[2]) ≈ 7.0 atol = 1e-14
    end

    @testset "LinearAlgebra with Fixed" begin
        A = [Fixed{32,16}(1.0) Fixed{32,16}(2.0); Fixed{32,16}(3.0) Fixed{32,16}(4.0)]
        v = [Fixed{32,16}(1.0), Fixed{32,16}(1.0)]
        res = A * v
        @test Float64(res[1]) == 3.0
        @test Float64(res[2]) == 7.0
    end

    # -----------------------------------------------------------------------
    # zero / one bit patterns (ccall-free fast paths)
    # -----------------------------------------------------------------------
    @testset "zero/one bit patterns" begin
        # Posit: zero = all-zero bits; one = bit N-2 set (independent of ES)
        @test zero(Posit{8,0}).data   == UInt8(0)
        @test zero(Posit{16,1}).data  == UInt16(0)
        @test zero(Posit{16,2}).data  == UInt16(0)
        @test zero(Posit{32,2}).data  == UInt32(0)
        @test zero(Posit{64,2}).data  == UInt64(0)
        @test one(Posit{8,0}).data    == UInt8(0x40)       # bit 6
        @test one(Posit{16,1}).data   == UInt16(0x4000)    # bit 14
        @test one(Posit{16,2}).data   == UInt16(0x4000)    # bit 14 (ES doesn't shift it)
        @test one(Posit{32,2}).data   == UInt32(0x40000000) # bit 30
        @test one(Posit{64,2}).data   == UInt64(1) << 62
        @test one(Posit{64,3}).data   == UInt64(1) << 62
        # All zero/one values are numerically correct
        for T in (Posit{8,0}, Posit{16,1}, Posit{16,2}, Posit{32,2},
                  Posit{64,2}, Posit{64,3})
            @test Float64(zero(T)) == 0.0
            @test Float64(one(T))  == 1.0
            @test iszero(zero(T))
            @test !iszero(one(T))
        end
        # CFloat: one = bias << fracbits (bias = 2^(ES-1)-1)
        @test one(CFloat{8,2}).data   == UInt8(0x20)   # bias=1, fracbits=5
        @test one(CFloat{8,4}).data   == UInt8(0x38)   # bias=7, fracbits=3
        @test one(CFloat{24,5}).data  == UInt32(0x3C0000) # bias=15, fracbits=18
        for T in (CFloat{8,2}, CFloat{8,3}, CFloat{8,4}, CFloat{8,5}, CFloat{24,5})
            @test Float64(zero(T)) == 0.0
            @test Float64(one(T))  == 1.0
        end
        # LNS: one = all-zero bits (log₂(1.0)=0 -> int=0, frac=0, sign=0)
        @test one(LNS{16,5}).data  == UInt16(0)
        @test one(LNS{32,16}).data == UInt32(0)
        @test Float64(one(LNS{16,5}))  == 1.0
        @test Float64(zero(LNS{16,5})) == 0.0   # zero uses ccall (zero bits ≠ 0.0 for LNS)
        # Fixed: one = 1 << R (R = fractional bits = P2)
        @test one(Fixed{8,4}).data   == UInt8(1) << 4
        @test one(Fixed{16,8}).data  == UInt16(1) << 8
        @test one(Fixed{32,16}).data == UInt32(1) << 16
        for T in (Fixed{8,4}, Fixed{16,8}, Fixed{32,16})
            @test Float64(zero(T)) == 0.0
            @test Float64(one(T))  == 1.0
        end
        # BF16: one = 0x3F80 (exp=127=bias, frac=0)
        @test one(BF16).data  == UInt16(0x3F80)
        @test zero(BF16).data == UInt16(0)
        @test Float64(one(BF16))  == 1.0
        @test Float64(zero(BF16)) == 0.0
        # Takum and DD: zero-bits = 0.0 (one keeps ccall)
        for T in (Takum{8}, Takum{16}, Takum{32}, Takum{64})
            @test Float64(zero(T)) == 0.0
            @test Float64(one(T))  == 1.0
            @test iszero(zero(T))
        end
        @test Float64(zero(DD)) == 0.0
        @test Float64(one(DD))  == 1.0
    end

    # -----------------------------------------------------------------------
    # hash
    # -----------------------------------------------------------------------
    @testset "hash" begin
        # Same value -> same hash
        for T in (Posit{16,1}, Posit{16,2}, Posit{64,2}, Posit{64,3},
                  CFloat{24,5}, Takum{16}, Takum{64})
            @test hash(T(1.5)) == hash(T(1.5))
            @test hash(T(0.0)) == hash(T(0.0))
        end
        @test hash(BF16(1.5)) == hash(BF16(1.5))
        @test hash(DD(1.5))   == hash(DD(1.5))
        # Different values -> different hashes (extremely unlikely to collide)
        @test hash(Posit{16,1}(1.5)) != hash(Posit{16,1}(2.5))
        @test hash(Takum{16}(1.5))   != hash(Takum{16}(2.5))
        # Usable as Dict keys
        d = Dict(Posit{16,1}(1.5) => :a, Posit{16,1}(2.5) => :b)
        @test d[Posit{16,1}(1.5)] == :a
        @test d[Posit{16,1}(2.5)] == :b
        d2 = Dict(Takum{64}(1.0) => 1, Takum{64}(2.0) => 2)
        @test d2[Takum{64}(1.0)] == 1
        @test d2[Takum{64}(2.0)] == 2
    end

    # -----------------------------------------------------------------------
    # parse
    # -----------------------------------------------------------------------
    @testset "parse" begin
        @test parse(Posit{16,1}, "1.5")  == Posit{16,1}(1.5)
        @test parse(Posit{16,2}, "1.5")  == Posit{16,2}(1.5)
        @test parse(Posit{64,2}, "1.5")  == Posit{64,2}(1.5)
        @test parse(Posit{64,3}, "2.5")  == Posit{64,3}(2.5)
        @test parse(Posit{32,2}, "-2.5") == Posit{32,2}(-2.5)
        @test parse(CFloat{24,5}, "1.5") == CFloat{24,5}(1.5)
        @test parse(LNS{16,5},  "2.0")   == LNS{16,5}(2.0)
        @test parse(Fixed{16,8}, "1.5")  == Fixed{16,8}(1.5)
        @test parse(Takum{16},   "1.5")  == Takum{16}(1.5)
        @test parse(Takum{64},   "1.5")  == Takum{64}(1.5)
        @test parse(BF16, "1.5")         == BF16(1.5)
        @test parse(DD,   "1.5")         == DD(1.5)
        # zero and negative values
        @test parse(Posit{16,1}, "0.0")  == zero(Posit{16,1})
        @test Float64(parse(Posit{16,2}, "-1.5")) == -1.5
        # UnionAll form also works
        @test parse(Posit{16,2}, "3.0")  == Posit{16,2}(3.0)
        @test parse(Takum{64},   "3.0")  == Takum{64}(3.0)
    end

    # -----------------------------------------------------------------------
    # LUT8: lookup tables built for all 8-bit types
    # -----------------------------------------------------------------------
    @testset "LUT8 lookup tables" begin
        # All 7 tables are populated in __init__
        for cp in UniversalNumbers._LUT8_CPREFIXES
            @test haskey(UniversalNumbers._LUT8, cp)
        end

        # Spot-check table dimensions (256×256 binary, 256 unary, 256 float64)
        lut = UniversalNumbers._LUT8["posit8_0"]
        @test size(lut.add)   == (256, 256)
        @test length(lut.abs_)  == 256
        @test length(lut.to_f64) == 256

        # Structural checks: zero + zero = zero for all 8-bit types
        for T in (Posit{8,0}, CFloat{8,2}, CFloat{8,3}, CFloat{8,4}, CFloat{8,5},
                  Fixed{8,4}, Takum{8})
            z = zero(T)
            @test (z + z) == z
            @test (z - z) == z
            @test Float64(z) == 0.0
        end

        # Arithmetic results match reference: Posit{8,0}
        let T = Posit{8,0}
            a = T(1.0);  b = T(0.5)
            @test Float64(a + b) ≈ 1.5  atol = 0.1
            @test Float64(a - b) ≈ 0.5  atol = 0.1
            @test Float64(a * b) ≈ 0.5  atol = 0.1
            @test Float64(a / b) ≈ 2.0  atol = 0.1
            @test a > b
            @test b < a
            @test a >= a
            @test b <= a
            @test a == a
        end

        # Float64 conversion via LUT
        for T in (Posit{8,0}, CFloat{8,4}, Takum{8})
            for v in (-1.0, 0.0, 0.5, 1.0, 2.0)
                x = T(v)
                @test Float64(x) ≈ v  atol = 0.5
            end
        end

        # Math functions via LUT: sqrt(1.0) == 1.0 and sqrt(4.0) ≈ 2.0
        for T in (Posit{8,0}, CFloat{8,4}, Takum{8})
            @test Float64(sqrt(T(1.0))) ≈ 1.0  atol = 0.2
        end

        # nextfloat / prevfloat from LUT
        let T = Posit{8,0}
            x = T(1.0)
            @test nextfloat(x) > x
            @test prevfloat(x) < x
        end

        # Fixed{8,4}: sqrt on negative is guarded (returns 0, no crash)
        @test Fixed{8,4}(sqrt(Fixed{8,4}(-1.0))).data == 0x00
    end

    # -----------------------------------------------------------------------
    # Quire: exact fused dot product (posit-only)
    # -----------------------------------------------------------------------
    @testset "Quire / fdp (fused dot product)" begin
        # exact small case (integer-valued: no rounding anywhere)
        a = Posit{32,2}[1, 2, 3]
        b = Posit{32,2}[4, 5, 6]
        @test Float64(fdp(a, b)) == 32.0        # 1·4 + 2·5 + 3·6
        @test quire_dot(a, b) == fdp(a, b)       # alias

        # fdp matches hand-rolled Quire accumulation
        q = Quire(Posit{32,2})
        for i in eachindex(a, b)
            fma_product!(q, a[i], b[i])
        end
        @test Posit{32,2}(q) == fdp(a, b)

        # clear! resets the accumulator to zero
        @test Float64(Posit{32,2}(clear!(q))) == 0.0

        # quire width: 2^ES·(4N−8) + capacity(30)
        @test quire_bits(Posit{32,2}) == 510

        # concrete element type (Posit{32,2,UInt32}) also works
        ca = [Posit{32,2}(1.0), Posit{32,2}(2.0)]
        @test eltype(ca) === Posit{32,2,UInt32}
        @test Float64(fdp(ca, ca)) == 5.0        # 1 + 4

        # 8-bit posit (LUT-backed storage path)
        @test Float64(fdp(Posit{8,2}[1, 2], Posit{8,2}[1, 1])) == 3.0

        # accuracy: the quire (one rounding) is at least as accurate as the
        # naively rounded dot product against a high-precision reference
        Random.seed!(20260628)
        x = rand(Posit{32,2}, 200)
        y = rand(Posit{32,2}, 200)
        naive = zero(Posit{32,2})
        for i in eachindex(x, y)
            naive += x[i] * y[i]
        end
        ref = sum(BigFloat(Float64(x[i])) * BigFloat(Float64(y[i])) for i in eachindex(x, y))
        @test abs(Float64(fdp(x, y)) - ref) <= abs(Float64(naive) - ref)

        # error handling
        @test_throws DimensionMismatch fdp(Posit{32,2}[1, 2], Posit{32,2}[1])
        @test_throws ErrorException fdp([1.0, 2.0], [3.0, 4.0])   # non-posit
    end

end

include("broadcasting.jl")
include("la.jl")
include("linalg_lu.jl")
include("linalg_qr.jl")
include("lns.jl")
include("math_linalg.jl")
include("posits.jl")
include("printbits.jl")
include("takums.jl")
include("rounding.jl")
include("linalg_fallbacks.jl")

# ---------------------------------------------------------------------------
# Aqua.jl quality assurance. Aqua is a test-only dependency ([extras]), so this
# block is guarded: `julia --project=. test/runtests.jl` still runs when Aqua is
# not in the base environment; it runs the checks under `Pkg.test()`.
# `ambiguities=false` skips the known, benign parametric-constructor vs. Base
# ambiguities (tracked in dev/TODO.md); all other checks run (stale deps,
# deps/compat, piracy, undefined exports, project extras).
# ---------------------------------------------------------------------------
if isempty(VERSION.prerelease)   # skip on nightly, where Aqua may not precompile
    try
        @eval using Aqua
        @testset "Aqua quality assurance" begin
            Aqua.test_all(UniversalNumbers; ambiguities = false)
        end
    catch err
        err isa ArgumentError || rethrow()
        @info "Aqua not installed here; skipping QA tests (run via `Pkg.test()` to include them)."
    end
end
