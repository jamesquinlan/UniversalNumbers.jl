# quire_nar.jl -- NaR handling in the quire (regression for the SIGABRT crash).
#
# Before upstream Universal PR #1228 (issue #1226), feeding a NaR operand to the
# quire threw sw::universal::operand_is_nar unconditionally.  The throw escaped
# our extern "C" bridge, hit std::terminate, and killed the Julia process with
# SIGABRT and no error message.  A NaR reaching a fused dot product is ordinary
# in an iterative solver (a zero pAp gives alpha = rz/0 = NaR), so this was easy
# to trigger: examples/gurleen/pcg.jl died at iteration 11.
#
# Upstream now gives the quire a sticky NaR state and gates the range exceptions
# behind QUIRE_THROW_ARITHMETIC_EXCEPTION, which posit.hpp forwards from
# POSIT_THROW_ARITHMETIC_EXCEPTION (set to 0 in src/libuniversal_wrapper.cpp).
# NaR now propagates as a value, matching scalar posit arithmetic.
#
# Every @test here would have ABORTED the process before that fix, so a
# regression shows up as a dead test run rather than a red test.

using UniversalNumbers, Test

@testset "Quire NaR propagation (#1226)" begin
    # Exercise every storage width the bridge macro stamps out: the quire
    # functions are generated per type, so a regression could hit just one.
    for T in (Posit{8,0}, Posit{16,1}, Posit{32,2}, Posit{64,2})
        nar = T(0) / T(0)
        @test isnan(nar)                        # precondition: division gives NaR

        # fma_product! with a NaR operand returns instead of aborting, and the
        # quire resolves to NaR rather than to a finite value.
        q = Quire(T)
        fma_product!(q, nar, one(T))
        @test isnan(T(q))

        # ... in either argument position
        q2 = Quire(T)
        fma_product!(q2, one(T), nar)
        @test isnan(T(q2))

        # The state is sticky: later finite products cannot resurrect a NaR
        # accumulator, which is what NaR absorption means for scalar posits too.
        fma_product!(q, T(2), T(3))
        @test isnan(T(q))

        # clear! resets it, so a Quire stays reusable after a NaR.
        clear!(q)
        @test !isnan(T(q))
        @test iszero(T(q))
        fma_product!(q, T(2), T(3))
        @test T(q) == T(6)

        # The batch kernel (NAME##_fdp, a single ccall over the whole vector)
        # is a separate C++ path from fma_product!, so check it independently.
        @test isnan(fdp([nar, one(T)], [one(T), one(T)]))
        @test isnan(fdp([one(T), one(T)], [nar, one(T)]))
        @test isnan(fdp([nar], [nar]))
        @test isnan(quire_dot([nar], [one(T)]))          # alias goes the same way

        # A NaR anywhere in the vector poisons the result, wherever it sits.
        v = fill(one(T), 8)
        w = fill(one(T), 8)
        w[end] = nar
        @test isnan(fdp(v, w))
    end

    # Exactness is unaffected: the NaR path must not perturb ordinary results.
    @test fdp(Posit{32,2}[1, 2, 3], Posit{32,2}[4, 5, 6]) == Posit{32,2}(32)

    # The original failure mode, in miniature: a CG-style update where the
    # step length goes NaR and then flows into the next fused dot product.
    let T = Posit{16,1}
        p     = fill(one(T), 4)
        pAp   = zero(T)                 # breakdown: search direction is A-orthogonal
        alpha = one(T) / pAp            # NaR
        @test isnan(alpha)
        p = alpha .* p                  # NaR spreads through the direction vector
        @test isnan(fdp(p, p))          # the call that used to abort the process
    end
end
