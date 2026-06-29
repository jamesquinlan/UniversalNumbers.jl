using UniversalNumbers
using Random

# ---------------------------------------------------------------------------
# Quire: exact fused dot product for posits
#
# A dot product sum(a .* b) normally rounds after every multiply AND every add.
# Over many terms those roundings accumulate.  The quire is Universal's exact
# accumulator: it sums the products with NO intermediate rounding and rounds
# exactly once, at the end.  It is posit-only and entirely opt-in -- ordinary
# posit arithmetic is unchanged, so we can compute both ways and compare.
# ---------------------------------------------------------------------------

Random.seed!(42)

T = Posit{32,2}
n = 2000
a = rand(T, n)
b = rand(T, n)

# --- WITHOUT the quire (rounds 2n times) ---
function naive_dot(a, b)
    s = zero(eltype(a))
    for i in eachindex(a, b)
        s += a[i] * b[i]
    end
    return s
end

# --- WITH the quire: (rounds once) ---
r_quire = fdp(a, b)  # = quire_dot(a, b)

# Mirror the C++ `q += quire_mul(pa,pb)`:
q = Quire(T)
for i in eachindex(a, b)
    fma_product!(q, a[i], b[i])   # no rounding
end


# Main
r_naive = naive_dot(a, b);
r_hand = T(q); # single round 
r_true = sum(BigFloat.(Float64.(a)) .* BigFloat.(Float64.(b)));

error_ratio = Float64(abs(Float64(r_naive) - r_true) / abs(Float64(r_quire) - r_true));
better = round(error_ratio, digits=1);

println("Posit{32,2} dot product of $n random terms")
println("  quire width : ", quire_bits(T), " bits (exact accumulator)")
println("  naive  : ", Float64(r_naive), "   |err| = ", abs(Float64(r_naive) - r_true))
println("  quire  : ", Float64(r_quire), "   |err| = ", abs(Float64(r_quire) - r_true))
println("  hand   : ", Float64(r_hand),  "   |err| = ", abs(Float64(r_hand)  - r_true))
println("  fdp matches hand-rolled quire? ", r_quire == r_hand)
print("quire error / naive error ≈ ",better, "× smaller")
