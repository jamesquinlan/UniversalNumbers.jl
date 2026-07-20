module UniversalNumbers

using Libdl
using LinearAlgebra
using Random
using SparseArrays
using UniversalNumbers_jll

include("LU.jl")
include("QR.jl")

# A locally built library (`build/libuniversal.*`) takes precedence when present,
# so wrapper/C++ changes can be tested without republishing the JLL. Installed
# users have no `build/`, so they load the precompiled `UniversalNumbers_jll` binary.
const LOCAL_LIB = joinpath(@__DIR__, "..", "build", "libuniversal." * Libdl.dlext)
const LIB_HANDLE = Ref{Ptr{Nothing}}(C_NULL)

_lib_path() = isfile(LOCAL_LIB) ? LOCAL_LIB : UniversalNumbers_jll.libuniversal

function __init__()
    LIB_HANDLE[] = dlopen(_lib_path())
    redirect_stderr(devnull) do
        _init_luts!()
    end
end

const SYM_CACHE = Dict{Symbol, Ptr{Nothing}}()

function get_sym(sym::Symbol)
    get!(SYM_CACHE, sym) do
        if LIB_HANDLE[] == C_NULL
            LIB_HANDLE[] = dlopen(_lib_path())
        end
        try
            dlsym(LIB_HANDLE[], sym)
        catch
            C_NULL
        end
    end
end

include("lut8.jl")

abstract type UniversalNumber <: AbstractFloat end

struct Posit{N, ES, BT<:Unsigned} <: UniversalNumber
    data::BT
    Posit{N,ES,BT}(bits::BT, ::Bool) where {N,ES,BT<:Unsigned} = new{N,ES,BT}(bits)
end

struct CFloat{N, ES, BT<:Unsigned} <: UniversalNumber
    data::BT
    CFloat{N,ES,BT}(bits::BT, ::Bool) where {N,ES,BT<:Unsigned} = new{N,ES,BT}(bits)
end

struct LNS{N, R, BT<:Unsigned} <: UniversalNumber
    data::BT
    LNS{N,R,BT}(bits::BT, ::Bool) where {N,R,BT<:Unsigned} = new{N,R,BT}(bits)
end

struct Takum{N, BT<:Unsigned} <: UniversalNumber
    data::BT
    Takum{N,BT}(bits::BT, ::Bool) where {N,BT<:Unsigned} = new{N,BT}(bits)
end

# Double-double: 
struct DD <: UniversalNumber
    data::UInt128
    DD(bits::UInt128, ::Bool) = new(bits)
end

struct Fixed{N, R, BT<:Unsigned} <: UniversalNumber
    data::BT
    Fixed{N,R,BT}(bits::BT, ::Bool) where {N,R,BT<:Unsigned} = new{N,R,BT}(bits)
end

# IBM hex float: N=ndigits, ES=exponent bits (7 for all standard variants).
# No NaN, no Inf -- isinf/isnan always return false.
struct HFloat{N, ES, BT<:Unsigned} <: UniversalNumber
    data::BT
    HFloat{N,ES,BT}(bits::BT, ::Bool) where {N,ES,BT<:Unsigned} = new{N,ES,BT}(bits)
end

# IEEE 754-2008 decimal float (BID encoding): N=ndigits, ES=exponent continuation bits.
struct DFloat{N, ES, BT<:Unsigned} <: UniversalNumber
    data::BT
    DFloat{N,ES,BT}(bits::BT, ::Bool) where {N,ES,BT<:Unsigned} = new{N,ES,BT}(bits)
end

# Google Brain float16: 1 sign + 8 exponent + 7 mantissa bits (same exponent range as Float32).
# Non-parametric on the C++ side (sw::universal::bfloat16); stored as UInt16.
struct BF16 <: UniversalNumber
    data::UInt16
    BF16(bits::UInt16, ::Bool) = new(bits)
end

const _LEGEND = Dict(
    :Posit  => "\e[31mS\e[0m sign  \e[33mR\e[0m regime  \e[36mE\e[0m exponent  \e[35mf\e[0m fraction",
    :CFloat => "\e[31mS\e[0m sign  \e[36mE\e[0m exponent  \e[35mf\e[0m fraction",
    :LNS    => "\e[31mS\e[0m sign  \e[36mi\e[0m integer  \e[35mf\e[0m fraction",
    :Takum  => "\e[31mS\e[0m sign  \e[32mD\e[0m direction  \e[33mR\e[0m regime  \e[36mC\e[0m characteristic  \e[35mM\e[0m mantissa",
    :DD     => "\e[31mS\e[0m sign  \e[36mE\e[0m exponent  \e[35mf\e[0m fraction  (hi component, then lo component)",
    :Fixed  => "\e[36mi\e[0m integer (MSB = sign)  \e[35mf\e[0m fraction",
    :HFloat => "\e[31mS\e[0m sign  \e[36mE\e[0m exponent  \e[35mf\e[0m hex-fraction",
    :DFloat => "\e[31mS\e[0m sign  \e[36mG\e[0m combination  \e[35mf\e[0m significand",
    :BF16   => "\e[31mS\e[0m sign  \e[36mE\e[0m exponent  \e[35mf\e[0m fraction",
)

const TYPE_REGISTRY = [
    (:Posit,  8,  0,  "posit8_0",   UInt8),
    (:Posit,  8,  1,  "posit8_1",   UInt8),
    (:Posit,  8,  2,  "posit8_2",   UInt8),
    (:Posit,  12, 1,  "posit12_1",  UInt16),
    (:Posit,  16, 1,  "posit16_1",  UInt16),
    (:Posit,  16, 2,  "posit16_2",  UInt16),
    (:Posit,  32, 2,  "posit32_2",  UInt32),
    (:Posit,  19, 3,  "posit19_3",  UInt32),
    (:Posit,  19, 2,  "posit19_2",  UInt32),
    (:Posit,  64, 2,  "posit64_2",  UInt64),
    (:Posit,  64, 3,  "posit64_3",  UInt64),
    (:CFloat, 8,  2,  "cfloat8_2",  UInt8),
    (:CFloat, 8,  3,  "cfloat8_3",  UInt8),
    (:CFloat, 8,  4,  "cfloat8_4",  UInt8),
    (:CFloat, 8,  5,  "cfloat8_5",  UInt8),
    (:CFloat, 24, 5,  "cfloat24_5", UInt32),
    (:LNS,    16, 5,  "lns16_5",    UInt16),
    (:LNS,    32, 16, "lns32_16",   UInt32),
    # Fixed: N=total bits, R=fractional bits (modular arithmetic, matching block type)
    (:Fixed, 8,  4,  "fixed8_4",   UInt8),
    (:Fixed, 16, 8,  "fixed16_8",  UInt16),
    (:Fixed, 32, 16, "fixed32_16", UInt32),
    # HFloat: N=ndigits, ES=exponent bits (7 for all IBM HFP standards)
    # hfp32: nbits=32 -> UInt32; hfp64: nbits=64 -> UInt64 (multi-word internally)
    (:HFloat, 6,  7,  "hfp32",      UInt32),
    (:HFloat, 14, 7,  "hfp64",      UInt64),
    # DFloat: N=ndigits, ES=exponent continuation bits (BID encoding)
    # decimal32: nbits=32 -> UInt32; decimal64: nbits=64 -> UInt64
    (:DFloat, 7,  6,  "decimal32",  UInt32),
    (:DFloat, 16, 8,  "decimal64",  UInt64),
]

for (TypeSym, P1, P2, CPrefix, StorageT) in TYPE_REGISTRY
    T  = :($(TypeSym){$P1, $P2, $StorageT})   # concrete type
    TU = :($(TypeSym){$P1, $P2})               # user-facing UnionAll

    StorageT_nbits = sizeof(StorageT) * 8
    use_lut = (StorageT == UInt8)

    # Negation expressions:
    neg_expr = if TypeSym == :Posit && P1 == StorageT_nbits
        :($T((~a.data + one($StorageT)), true))
    elseif TypeSym == :CFloat && P1 == StorageT_nbits
        :($T(a.data ⊻ ($StorageT(1) << ($P1 - 1)), true))
    elseif TypeSym == :Fixed
        :($T((~a.data + one($StorageT)), true))
    elseif TypeSym in (:HFloat, :DFloat)
        :($T(a.data ⊻ ($StorageT(1) << $(StorageT_nbits - 1)), true))
    else
        :($T(0.0) - a)
    end

    # zero: LNS all-zero bits = log₂(1.0) = 0 represents 1.0, not 0.0; must use ccall.
    # All other registered families: all-zero bits = 0.0.
    zero_expr   = TypeSym == :LNS ? :($T(0.0))           : :($T(zero($StorageT), true))
    iszero_expr = TypeSym == :LNS ? :(a == $T(0.0))      : :(a.data == zero($StorageT))

    one_expr = if TypeSym == :Posit
        :($T($StorageT(1) << ($P1 - 2), true))
    elseif TypeSym == :CFloat
        :($T($StorageT((1 << ($P2 - 1)) - 1) << ($P1 - 1 - $P2), true))
    elseif TypeSym == :LNS
        :($T(zero($StorageT), true))
    elseif TypeSym == :Fixed
        :($T($StorageT(1) << $P2, true))
    else
        :($T(1.0))
    end

    if use_lut
        arith_add  = :($T(_LUT8[$CPrefix].add[Int(a.data)+1, Int(b.data)+1], true))
        arith_sub  = :($T(_LUT8[$CPrefix].sub[Int(a.data)+1, Int(b.data)+1], true))
        arith_mul  = :($T(_LUT8[$CPrefix].mul[Int(a.data)+1, Int(b.data)+1], true))
        arith_div  = :($T(_LUT8[$CPrefix].div[Int(a.data)+1, Int(b.data)+1], true))
        cmp_eq     = :(_LUT8[$CPrefix].eq[Int(a.data)+1, Int(b.data)+1])
        cmp_lt     = :(_LUT8[$CPrefix].lt[Int(a.data)+1, Int(b.data)+1])
        cmp_le     = :(_LUT8[$CPrefix].le[Int(a.data)+1, Int(b.data)+1])
        math_abs   = :($T(_LUT8[$CPrefix].abs_[Int(a.data)+1], true))
        math_sqrt  = :($T(_LUT8[$CPrefix].sqrt_[Int(a.data)+1], true))
        math_sin   = :($T(_LUT8[$CPrefix].sin_[Int(a.data)+1], true))
        math_cos   = :($T(_LUT8[$CPrefix].cos_[Int(a.data)+1], true))
        math_exp   = :($T(_LUT8[$CPrefix].exp_[Int(a.data)+1], true))
        math_log   = :($T(_LUT8[$CPrefix].log_[Int(a.data)+1], true))
        nav_next   = :($T(_LUT8[$CPrefix].next_[Int(a.data)+1], true))
        nav_prev   = :($T(_LUT8[$CPrefix].prev_[Int(a.data)+1], true))
        pred_isnan = :(_LUT8[$CPrefix].isnan_[Int(a.data)+1])
        pred_isinf = :(_LUT8[$CPrefix].isinf_[Int(a.data)+1])
        conv_f64   = :(_LUT8[$CPrefix].to_f64[Int(x.data)+1])
    else
        arith_add  = :($T(ccall(get_sym(Symbol($(CPrefix * "_add"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_sub  = :($T(ccall(get_sym(Symbol($(CPrefix * "_sub"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_mul  = :($T(ccall(get_sym(Symbol($(CPrefix * "_mul"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_div  = :($T(ccall(get_sym(Symbol($(CPrefix * "_div"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        cmp_eq     = :(ccall(get_sym(Symbol($(CPrefix * "_eq"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        cmp_lt     = :(ccall(get_sym(Symbol($(CPrefix * "_lt"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        cmp_le     = :(ccall(get_sym(Symbol($(CPrefix * "_le"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        math_abs   = :($T(ccall(get_sym(Symbol($(CPrefix * "_abs"))),  $(StorageT), ($(StorageT),), a.data), true))
        math_sqrt  = :($T(ccall(get_sym(Symbol($(CPrefix * "_sqrt"))), $(StorageT), ($(StorageT),), a.data), true))
        nav_next   = :($T(ccall(get_sym(Symbol($(CPrefix * "_next"))), $(StorageT), ($(StorageT),), a.data), true))
        nav_prev   = :($T(ccall(get_sym(Symbol($(CPrefix * "_prev"))), $(StorageT), ($(StorageT),), a.data), true))
        pred_isnan = :(ccall(get_sym(Symbol($(CPrefix * "_isnan"))), Bool, ($(StorageT),), a.data))
        pred_isinf = :(ccall(get_sym(Symbol($(CPrefix * "_isinf"))), Bool, ($(StorageT),), a.data))
        conv_f64   = :(ccall(get_sym(Symbol($(CPrefix * "_to_double"))), Float64, ($(StorageT),), x.data))
        math_sin = math_cos = math_exp = math_log = nothing   # defined below with NULL guard
    end

    @eval begin
        @inline function $T(f::Real)
            val = ccall(get_sym(Symbol($(CPrefix * "_from_double"))),
                        $(StorageT), (Float64,), Float64(f))
            return $T(val, true)
        end
        $T() = $T(0.0)

        @inline $(TU)(f::Real) = $T(Float64(f))
        $(TU)() = $T(0.0)

        # Rational: mirror Base's AbstractFloat rational cast (rational.jl:162) so
        # T(a//b) behaves like Float32(a//b) etc. Our promote_rule collapses
        # promote_type(T,S) to T, so the division runs in T. Resolves the
        # MethodError ambiguity with Base's method.
        @inline function $T(x::Rational{S}) where {S}
            P = promote_type($T, S)
            convert($T, convert(P, x.num) / convert(P, x.den))::$T
        end
        @inline $(TU)(x::Rational{S}) where {S} = $T(x)

        @inline Base.Float64(x::$T) = $conv_f64
        @inline Base.Float32(x::$T) = Float32(Float64(x))

        Base.convert(::Type{$T},      x::Real)    = $T(x)
        Base.convert(::Type{$TU},     x::Real)    = $T(Float64(x))
        Base.convert(::Type{Float64}, x::$T)      = Float64(x)
        Base.convert(::Type{Float32}, x::$T)      = Float32(x)

        @inline Base.:+(a::$T, b::$T) = $arith_add
        @inline Base.:-(a::$T, b::$T) = $arith_sub
        @inline Base.:*(a::$T, b::$T) = $arith_mul
        @inline Base.:/(a::$T, b::$T) = $arith_div
        @inline Base.:-(a::$T) = $neg_expr

        @inline Base.:(==)(a::$T, b::$T) = $cmp_eq
        @inline Base.:<(a::$T, b::$T)    = $cmp_lt
        @inline Base.:<=(a::$T, b::$T)   = $cmp_le

        @inline Base.abs(a::$T)    = $math_abs
        Base.isnan(a::$T)          = $pred_isnan
        Base.isinf(a::$T)          = $pred_isinf
        @inline Base.iszero(a::$T) = $iszero_expr
        @inline Base.sqrt(a::$T)   = $math_sqrt

        @inline Base.nextfloat(a::$T) = $nav_next
        @inline Base.prevfloat(a::$T) = $nav_prev

        @inline Base.zero(::Type{$T})  = $zero_expr
        @inline Base.one(::Type{$T})   = $one_expr
        Base.eps(::Type{$T})           = $T(ccall(get_sym(Symbol($(CPrefix * "_eps"))), $(StorageT), (), ), true)
        Base.floatmin(::Type{$T})      = $T(ccall(get_sym(Symbol($(CPrefix * "_min"))), $(StorageT), (), ), true)
        Base.floatmax(::Type{$T})      = $T(ccall(get_sym(Symbol($(CPrefix * "_max"))), $(StorageT), (), ), true)

        @inline Base.zero(::Type{$TU}) = zero($T)
        @inline Base.one(::Type{$TU})  = one($T)
        Base.eps(::Type{$TU})          = eps($T)
        Base.floatmin(::Type{$TU})     = floatmin($T)
        Base.floatmax(::Type{$TU})     = floatmax($T)

        # Map UnionAll (Posit{32,2}) and concrete (Posit{32,2,UInt32}) to concrete.
        _concretetype(::Type{$T})  = $T
        _concretetype(::Type{$TU}) = $T

        Base.conj(x::$T) = x
        Base.real(x::$T) = x
        Base.imag(x::$T) = zero($T)

        Base.hash(x::$T, h::UInt) = hash(x.data, h)
        Base.parse(::Type{$T},  s::AbstractString) = $T(parse(Float64, s))
        Base.parse(::Type{$TU}, s::AbstractString) = $T(parse(Float64, s))

        Base.show(io::IO, x::$T) = get(io, :compact, false) ?
            print(io, Float64(x)) :
            print(io, $(string(TypeSym)), "{", $P1, ",", $P2, "}(", Float64(x), ")")

        function printbits(x::$T)
            print($(string(TypeSym)), "{", $P1, ",", $P2, "}(", Float64(x), ")  ")
            flush(stdout)
            ccall(get_sym(Symbol($(CPrefix * "_printbits"))), Cvoid, ($(StorageT),), x.data)
            println()
            println(_LEGEND[$(QuoteNode(TypeSym))])
        end

        Random.Sampler(::Type{<:AbstractRNG}, ::Type{$T},  n::Random.Repetition) = Random.SamplerType{$T}()
        Random.Sampler(::Type{<:AbstractRNG}, ::Type{$TU}, n::Random.Repetition) = Random.SamplerType{$T}()
        function Base.rand(rng::AbstractRNG, ::Random.SamplerType{$T})
            return $T(rand(rng, Float64))
        end
    end

    # sin/cos/exp/log: LUT for 8-bit; NULL-guarded ccall for wider types.
    if use_lut
        @eval begin
            @inline Base.sin(a::$T) = $math_sin
            @inline Base.cos(a::$T) = $math_cos
            @inline Base.exp(a::$T) = $math_exp
            @inline Base.log(a::$T) = $math_log
        end
    else
        # Call get_sym at invocation time -- never capture a Ptr at precompile time.
        @eval begin
            @inline function Base.sin(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_sin")))
                sym == C_NULL ? $T(sin(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.cos(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_cos")))
                sym == C_NULL ? $T(cos(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.exp(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_exp")))
                sym == C_NULL ? $T(exp(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.log(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_log")))
                sym == C_NULL ? $T(log(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
        end
    end
end

# Catch-all for unregistered two-parameter types
(::Type{Posit{N,ES}})(args...; kwargs...)  where {N,ES} = error("Posit{$N,$ES} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")
(::Type{CFloat{N,ES}})(args...; kwargs...) where {N,ES} = error("CFloat{$N,$ES} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")
(::Type{LNS{N,R}})(args...; kwargs...)     where {N,R}  = error("LNS{$N,$R} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")
(::Type{Fixed{N,R}})(args...; kwargs...)   where {N,R}  = error("Fixed{$N,$R} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")
(::Type{HFloat{N,ES}})(args...; kwargs...) where {N,ES} = error("HFloat{$N,$ES} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")
(::Type{DFloat{N,ES}})(args...; kwargs...) where {N,ES} = error("DFloat{$N,$ES} is not instantiated in the registry. Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.")


const TAKUM_REGISTRY = [
    (8,  "takum8",  UInt8),
    (16, "takum16", UInt16),
    (32, "takum32", UInt32),
    (64, "takum64", UInt64),
]

for (N, CPrefix, StorageT) in TAKUM_REGISTRY
    T  = :(Takum{$N, $StorageT})   # concrete type
    TU = :(Takum{$N})              # user-facing UnionAll
    use_lut = (StorageT == UInt8)

    if use_lut
        arith_add  = :($T(_LUT8[$CPrefix].add[Int(a.data)+1, Int(b.data)+1], true))
        arith_sub  = :($T(_LUT8[$CPrefix].sub[Int(a.data)+1, Int(b.data)+1], true))
        arith_mul  = :($T(_LUT8[$CPrefix].mul[Int(a.data)+1, Int(b.data)+1], true))
        arith_div  = :($T(_LUT8[$CPrefix].div[Int(a.data)+1, Int(b.data)+1], true))
        cmp_eq     = :(_LUT8[$CPrefix].eq[Int(a.data)+1, Int(b.data)+1])
        cmp_lt     = :(_LUT8[$CPrefix].lt[Int(a.data)+1, Int(b.data)+1])
        cmp_le     = :(_LUT8[$CPrefix].le[Int(a.data)+1, Int(b.data)+1])
        math_abs   = :($T(_LUT8[$CPrefix].abs_[Int(a.data)+1], true))
        math_sqrt  = :($T(_LUT8[$CPrefix].sqrt_[Int(a.data)+1], true))
        math_sin   = :($T(_LUT8[$CPrefix].sin_[Int(a.data)+1], true))
        math_cos   = :($T(_LUT8[$CPrefix].cos_[Int(a.data)+1], true))
        math_exp   = :($T(_LUT8[$CPrefix].exp_[Int(a.data)+1], true))
        math_log   = :($T(_LUT8[$CPrefix].log_[Int(a.data)+1], true))
        nav_next   = :($T(_LUT8[$CPrefix].next_[Int(a.data)+1], true))
        nav_prev   = :($T(_LUT8[$CPrefix].prev_[Int(a.data)+1], true))
        pred_isnan = :(_LUT8[$CPrefix].isnan_[Int(a.data)+1])
        pred_isinf = :(_LUT8[$CPrefix].isinf_[Int(a.data)+1])
        conv_f64   = :(_LUT8[$CPrefix].to_f64[Int(x.data)+1])
    else
        arith_add  = :($T(ccall(get_sym(Symbol($(CPrefix * "_add"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_sub  = :($T(ccall(get_sym(Symbol($(CPrefix * "_sub"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_mul  = :($T(ccall(get_sym(Symbol($(CPrefix * "_mul"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        arith_div  = :($T(ccall(get_sym(Symbol($(CPrefix * "_div"))), $(StorageT), ($(StorageT), $(StorageT)), a.data, b.data), true))
        cmp_eq     = :(ccall(get_sym(Symbol($(CPrefix * "_eq"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        cmp_lt     = :(ccall(get_sym(Symbol($(CPrefix * "_lt"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        cmp_le     = :(ccall(get_sym(Symbol($(CPrefix * "_le"))), Bool, ($(StorageT), $(StorageT)), a.data, b.data))
        math_abs   = :($T(ccall(get_sym(Symbol($(CPrefix * "_abs"))),  $(StorageT), ($(StorageT),), a.data), true))
        math_sqrt  = :($T(ccall(get_sym(Symbol($(CPrefix * "_sqrt"))), $(StorageT), ($(StorageT),), a.data), true))
        nav_next   = :($T(ccall(get_sym(Symbol($(CPrefix * "_next"))), $(StorageT), ($(StorageT),), a.data), true))
        nav_prev   = :($T(ccall(get_sym(Symbol($(CPrefix * "_prev"))), $(StorageT), ($(StorageT),), a.data), true))
        pred_isnan = :(ccall(get_sym(Symbol($(CPrefix * "_isnan"))), Bool, ($(StorageT),), a.data))
        pred_isinf = :(ccall(get_sym(Symbol($(CPrefix * "_isinf"))), Bool, ($(StorageT),), a.data))
        conv_f64   = :(ccall(get_sym(Symbol($(CPrefix * "_to_double"))), Float64, ($(StorageT),), x.data))
        math_sin = math_cos = math_exp = math_log = nothing
    end

    @eval begin
        @inline function $T(f::Real)
            val = ccall(get_sym(Symbol($(CPrefix * "_from_double"))),
                        $(StorageT), (Float64,), Float64(f))
            return $T(val, true)
        end
        $T() = $T(0.0)

        @inline $(TU)(f::Real) = $T(Float64(f))
        $(TU)() = $T(0.0)

        # Rational: mirror Base's AbstractFloat rational cast (rational.jl:162) so
        # T(a//b) behaves like Float32(a//b) etc. Our promote_rule collapses
        # promote_type(T,S) to T, so the division runs in T. Resolves the
        # MethodError ambiguity with Base's method.
        @inline function $T(x::Rational{S}) where {S}
            P = promote_type($T, S)
            convert($T, convert(P, x.num) / convert(P, x.den))::$T
        end
        @inline $(TU)(x::Rational{S}) where {S} = $T(x)

        @inline Base.Float64(x::$T) = $conv_f64
        @inline Base.Float32(x::$T) = Float32(Float64(x))

        Base.convert(::Type{$T},      x::Real)    = $T(x)
        Base.convert(::Type{$TU},     x::Real)    = $T(Float64(x))
        Base.convert(::Type{Float64}, x::$T)      = Float64(x)
        Base.convert(::Type{Float32}, x::$T)      = Float32(x)

        @inline Base.:+(a::$T, b::$T) = $arith_add
        @inline Base.:-(a::$T, b::$T) = $arith_sub
        @inline Base.:*(a::$T, b::$T) = $arith_mul
        @inline Base.:/(a::$T, b::$T) = $arith_div
        Base.:-(a::$T) = $T(0.0) - a   # takum negation: defer to C bridge

        @inline Base.:(==)(a::$T, b::$T) = $cmp_eq
        @inline Base.:<(a::$T, b::$T)    = $cmp_lt
        @inline Base.:<=(a::$T, b::$T)   = $cmp_le

        @inline Base.abs(a::$T)    = $math_abs
        Base.isnan(a::$T)          = $pred_isnan
        Base.isinf(a::$T)          = $pred_isinf
        @inline Base.iszero(a::$T) = a.data == zero($StorageT)
        @inline Base.sqrt(a::$T)   = $math_sqrt

        @inline Base.nextfloat(a::$T) = $nav_next
        @inline Base.prevfloat(a::$T) = $nav_prev

        @inline Base.zero(::Type{$T})  = $T(zero($StorageT), true)
        @inline Base.one(::Type{$T})   = $T(1.0)
        Base.eps(::Type{$T})           = $T(ccall(get_sym(Symbol($(CPrefix * "_eps"))), $(StorageT), (), ), true)
        Base.floatmin(::Type{$T})      = $T(ccall(get_sym(Symbol($(CPrefix * "_min"))), $(StorageT), (), ), true)
        Base.floatmax(::Type{$T})      = $T(ccall(get_sym(Symbol($(CPrefix * "_max"))), $(StorageT), (), ), true)

        @inline Base.zero(::Type{$TU}) = zero($T)
        @inline Base.one(::Type{$TU})  = one($T)
        Base.eps(::Type{$TU})          = eps($T)
        Base.floatmin(::Type{$TU})     = floatmin($T)
        Base.floatmax(::Type{$TU})     = floatmax($T)

        # Map UnionAll (Posit{32,2}) and concrete (Posit{32,2,UInt32}) to concrete.
        _concretetype(::Type{$T})  = $T
        _concretetype(::Type{$TU}) = $T

        Base.conj(x::$T) = x
        Base.real(x::$T) = x
        Base.imag(x::$T) = zero($T)

        Base.hash(x::$T, h::UInt) = hash(x.data, h)
        Base.parse(::Type{$T},  s::AbstractString) = $T(parse(Float64, s))
        Base.parse(::Type{$TU}, s::AbstractString) = $T(parse(Float64, s))

        Base.show(io::IO, x::$T) = get(io, :compact, false) ?
            print(io, Float64(x)) :
            print(io, "Takum{", $N, "}(", Float64(x), ")")

        function printbits(x::$T)
            print("Takum{", $N, "}(", Float64(x), ")  ")
            flush(stdout)
            ccall(get_sym(Symbol($(CPrefix * "_printbits"))), Cvoid, ($(StorageT),), x.data)
            println()
            println(_LEGEND[:Takum])
        end

        Random.Sampler(::Type{<:AbstractRNG}, ::Type{$T},  n::Random.Repetition) = Random.SamplerType{$T}()
        Random.Sampler(::Type{<:AbstractRNG}, ::Type{$TU}, n::Random.Repetition) = Random.SamplerType{$T}()
        function Base.rand(rng::AbstractRNG, ::Random.SamplerType{$T})
            return $T(rand(rng, Float64))
        end
    end

    if use_lut
        @eval begin
            @inline Base.sin(a::$T) = $math_sin
            @inline Base.cos(a::$T) = $math_cos
            @inline Base.exp(a::$T) = $math_exp
            @inline Base.log(a::$T) = $math_log
        end
    else
        @eval begin
            @inline function Base.sin(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_sin")))
                sym == C_NULL ? $T(sin(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.cos(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_cos")))
                sym == C_NULL ? $T(cos(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.exp(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_exp")))
                sym == C_NULL ? $T(exp(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
            @inline function Base.log(a::$T)
                sym = get_sym(Symbol($(CPrefix * "_log")))
                sym == C_NULL ? $T(log(Float64(a))) : $T(ccall(sym, $(StorageT), ($(StorageT),), a.data), true)
            end
        end
    end
end

(::Type{Takum{N}})(args...; kwargs...) where {N} =
    error("Takum{$(N)} is not instantiated in the registry. Please add it to UniversalNumbers.TAKUM_REGISTRY and rebuild.")


# BF16
let CPrefix = "bfloat16"
    @eval begin
        @inline function BF16(f::Real)
            val = ccall(get_sym(Symbol($(CPrefix * "_from_double"))),
                        UInt16, (Float64,), Float64(f))
            BF16(val, true)
        end
        BF16() = BF16(0.0)

        # Rational cast mirroring Base rational.jl:162.
        @inline function BF16(x::Rational{S}) where {S}
            P = promote_type(BF16, S)
            convert(BF16, convert(P, x.num) / convert(P, x.den))::BF16
        end

        @inline Base.Float64(x::BF16) =
            ccall(get_sym(Symbol($(CPrefix * "_to_double"))), Float64, (UInt16,), x.data)
        @inline Base.Float32(x::BF16) = Float32(Float64(x))

        Base.convert(::Type{BF16},     x::Real)    = BF16(x)
        Base.convert(::Type{Float64},  x::BF16)    = Float64(x)
        Base.convert(::Type{Float32},  x::BF16)    = Float32(x)

        @inline Base.:+(a::BF16, b::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_add"))), UInt16, (UInt16, UInt16), a.data, b.data), true)
        @inline Base.:-(a::BF16, b::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_sub"))), UInt16, (UInt16, UInt16), a.data, b.data), true)
        @inline Base.:*(a::BF16, b::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_mul"))), UInt16, (UInt16, UInt16), a.data, b.data), true)
        @inline Base.:/(a::BF16, b::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_div"))), UInt16, (UInt16, UInt16), a.data, b.data), true)
        @inline Base.:-(a::BF16) = BF16(a.data ⊻ UInt16(0x8000), true)

        @inline Base.:(==)(a::BF16, b::BF16) = ccall(get_sym(Symbol($(CPrefix * "_eq"))), Bool, (UInt16, UInt16), a.data, b.data)
        @inline Base.:<(a::BF16, b::BF16)    = ccall(get_sym(Symbol($(CPrefix * "_lt"))), Bool, (UInt16, UInt16), a.data, b.data)
        @inline Base.:<=(a::BF16, b::BF16)   = ccall(get_sym(Symbol($(CPrefix * "_le"))), Bool, (UInt16, UInt16), a.data, b.data)

        @inline Base.abs(a::BF16)    = BF16(ccall(get_sym(Symbol($(CPrefix * "_abs"))),   UInt16, (UInt16,), a.data), true)
        Base.isnan(a::BF16)          = ccall(get_sym(Symbol($(CPrefix * "_isnan"))), Bool, (UInt16,), a.data)
        Base.isinf(a::BF16)          = ccall(get_sym(Symbol($(CPrefix * "_isinf"))), Bool, (UInt16,), a.data)
        @inline Base.iszero(a::BF16) = a.data == zero(UInt16)
        @inline Base.sqrt(a::BF16)   = BF16(ccall(get_sym(Symbol($(CPrefix * "_sqrt"))),  UInt16, (UInt16,), a.data), true)

        @inline Base.nextfloat(a::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_next"))), UInt16, (UInt16,), a.data), true)
        @inline Base.prevfloat(a::BF16) = BF16(ccall(get_sym(Symbol($(CPrefix * "_prev"))), UInt16, (UInt16,), a.data), true)

        @inline function Base.sin(a::BF16)
            sym = get_sym(Symbol($(CPrefix * "_sin")))
            sym == C_NULL ? BF16(sin(Float64(a))) : BF16(ccall(sym, UInt16, (UInt16,), a.data), true)
        end
        @inline function Base.cos(a::BF16)
            sym = get_sym(Symbol($(CPrefix * "_cos")))
            sym == C_NULL ? BF16(cos(Float64(a))) : BF16(ccall(sym, UInt16, (UInt16,), a.data), true)
        end
        @inline function Base.exp(a::BF16)
            sym = get_sym(Symbol($(CPrefix * "_exp")))
            sym == C_NULL ? BF16(exp(Float64(a))) : BF16(ccall(sym, UInt16, (UInt16,), a.data), true)
        end
        @inline function Base.log(a::BF16)
            sym = get_sym(Symbol($(CPrefix * "_log")))
            sym == C_NULL ? BF16(log(Float64(a))) : BF16(ccall(sym, UInt16, (UInt16,), a.data), true)
        end

        @inline Base.zero(::Type{BF16}) = BF16(zero(UInt16), true)
        @inline Base.one(::Type{BF16})  = BF16(0x3F80, true)   # IEEE-style: exp=127, frac=0 -> 1.0
        Base.eps(::Type{BF16})          = BF16(ccall(get_sym(Symbol($(CPrefix * "_eps"))), UInt16, (), ), true)
        Base.floatmin(::Type{BF16})     = BF16(ccall(get_sym(Symbol($(CPrefix * "_min"))), UInt16, (), ), true)
        Base.floatmax(::Type{BF16})     = BF16(ccall(get_sym(Symbol($(CPrefix * "_max"))), UInt16, (), ), true)

        Base.conj(x::BF16) = x
        Base.real(x::BF16) = x
        Base.imag(x::BF16) = zero(BF16)

        Base.hash(x::BF16, h::UInt) = hash(x.data, h)
        Base.parse(::Type{BF16}, s::AbstractString) = BF16(parse(Float64, s))

        Base.show(io::IO, x::BF16) = get(io, :compact, false) ?
            print(io, Float64(x)) :
            print(io, "BF16(", Float64(x), ")")

        function printbits(x::BF16)
            print("BF16(", Float64(x), ")  ")
            flush(stdout)
            ccall(get_sym(Symbol($(CPrefix * "_printbits"))), Cvoid, (UInt16,), x.data)
            println()
            println(_LEGEND[:BF16])
        end

        Random.Sampler(::Type{<:AbstractRNG}, ::Type{BF16}, n::Random.Repetition) = Random.SamplerType{BF16}()
        function Base.rand(rng::AbstractRNG, ::Random.SamplerType{BF16})
            return BF16(rand(rng, Float64))
        end
    end
end

# 
# DD: double-double (no template parameters; 16-byte storage via UInt128)
let CPrefix = "dd"
    @eval begin
        @inline function DD(f::Real)
            val = ccall(get_sym(Symbol($(CPrefix * "_from_double"))),
                        UInt128, (Float64,), Float64(f))
            DD(val, true)
        end
        DD() = DD(0.0)

        # Rational cast mirroring Base rational.jl:162; P collapses to DD, so the
        # ratio is computed at full double-double precision.
        @inline function DD(x::Rational{S}) where {S}
            P = promote_type(DD, S)
            convert(DD, convert(P, x.num) / convert(P, x.den))::DD
        end

        @inline Base.Float64(x::DD) =
            ccall(get_sym(Symbol($(CPrefix * "_to_double"))), Float64, (UInt128,), x.data)
        @inline Base.Float32(x::DD) = Float32(Float64(x))

        Base.convert(::Type{DD},      x::Real)    = DD(x)
        Base.convert(::Type{Float64}, x::DD)      = Float64(x)
        Base.convert(::Type{Float32}, x::DD)      = Float32(x)

        @inline Base.:+(a::DD, b::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_add"))), UInt128, (UInt128, UInt128), a.data, b.data), true)
        @inline Base.:-(a::DD, b::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_sub"))), UInt128, (UInt128, UInt128), a.data, b.data), true)
        @inline Base.:*(a::DD, b::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_mul"))), UInt128, (UInt128, UInt128), a.data, b.data), true)
        @inline Base.:/(a::DD, b::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_div"))), UInt128, (UInt128, UInt128), a.data, b.data), true)
        # Negation: flip sign bit of the hi double. memcpy puts dd.hi at offset 0
        # (little-endian), so sign bit of hi is bit 63 of the UInt128.
        @inline Base.:-(a::DD) = DD(a.data ⊻ (UInt128(1) << 63), true)

        @inline Base.:(==)(a::DD, b::DD) = ccall(get_sym(Symbol($(CPrefix * "_eq"))), Bool, (UInt128, UInt128), a.data, b.data)
        @inline Base.:<(a::DD, b::DD)    = ccall(get_sym(Symbol($(CPrefix * "_lt"))), Bool, (UInt128, UInt128), a.data, b.data)
        @inline Base.:<=(a::DD, b::DD)   = ccall(get_sym(Symbol($(CPrefix * "_le"))), Bool, (UInt128, UInt128), a.data, b.data)

        @inline Base.abs(a::DD)    = DD(ccall(get_sym(Symbol($(CPrefix * "_abs"))),   UInt128, (UInt128,), a.data), true)
        Base.isnan(a::DD)          = ccall(get_sym(Symbol($(CPrefix * "_isnan"))), Bool, (UInt128,), a.data)
        Base.isinf(a::DD)          = ccall(get_sym(Symbol($(CPrefix * "_isinf"))), Bool, (UInt128,), a.data)
        @inline Base.iszero(a::DD) = a.data == zero(UInt128)
        @inline Base.sqrt(a::DD)   = DD(ccall(get_sym(Symbol($(CPrefix * "_sqrt"))),  UInt128, (UInt128,), a.data), true)

        @inline Base.nextfloat(a::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_next"))), UInt128, (UInt128,), a.data), true)
        @inline Base.prevfloat(a::DD) = DD(ccall(get_sym(Symbol($(CPrefix * "_prev"))), UInt128, (UInt128,), a.data), true)

        @inline function Base.sin(a::DD)
            sym = get_sym(Symbol($(CPrefix * "_sin")))
            sym == C_NULL ? DD(sin(Float64(a))) : DD(ccall(sym, UInt128, (UInt128,), a.data), true)
        end
        @inline function Base.cos(a::DD)
            sym = get_sym(Symbol($(CPrefix * "_cos")))
            sym == C_NULL ? DD(cos(Float64(a))) : DD(ccall(sym, UInt128, (UInt128,), a.data), true)
        end
        @inline function Base.exp(a::DD)
            sym = get_sym(Symbol($(CPrefix * "_exp")))
            sym == C_NULL ? DD(exp(Float64(a))) : DD(ccall(sym, UInt128, (UInt128,), a.data), true)
        end
        @inline function Base.log(a::DD)
            sym = get_sym(Symbol($(CPrefix * "_log")))
            sym == C_NULL ? DD(log(Float64(a))) : DD(ccall(sym, UInt128, (UInt128,), a.data), true)
        end

        @inline Base.zero(::Type{DD}) = DD(zero(UInt128), true)
        @inline Base.one(::Type{DD})  = DD(1.0)
        Base.eps(::Type{DD})          = DD(ccall(get_sym(Symbol($(CPrefix * "_eps"))), UInt128, (), ), true)
        Base.floatmin(::Type{DD})     = DD(ccall(get_sym(Symbol($(CPrefix * "_min"))), UInt128, (), ), true)
        Base.floatmax(::Type{DD})     = DD(ccall(get_sym(Symbol($(CPrefix * "_max"))), UInt128, (), ), true)

        Base.conj(x::DD) = x
        Base.real(x::DD) = x
        Base.imag(x::DD) = zero(DD)

        Base.hash(x::DD, h::UInt) = hash(x.data, h)
        Base.parse(::Type{DD}, s::AbstractString) = DD(parse(Float64, s))

        Base.show(io::IO, x::DD) = get(io, :compact, false) ?
            print(io, Float64(x)) :
            print(io, "DD(", Float64(x), ")")

        function printbits(x::DD)
            print("DD(", Float64(x), ")  ")
            flush(stdout)
            ccall(get_sym(Symbol($(CPrefix * "_printbits"))), Cvoid, (UInt128,), x.data)
            println()
            println(_LEGEND[:DD])
        end

        Random.Sampler(::Type{<:AbstractRNG}, ::Type{DD}, n::Random.Repetition) = Random.SamplerType{DD}()
        function Base.rand(rng::AbstractRNG, ::Random.SamplerType{DD})
            return DD(rand(rng, Float64))
        end
    end
end


Base.promote_rule(::Type{T}, ::Type{S}) where {T<:UniversalNumber, S<:Real} = T

# Resolve a UnionAll element type (e.g. Posit{32,2}) to its concrete storage
# type. Registry entries define the per-type methods; this is the fallback.
_concretetype(::Type{T}) where {T<:UniversalNumber} = T

# Promotion of two UniversalNumber operands. Resolves UnionAll eltypes to
# concrete (else arithmetic results become Any) and picks the wider by bit-width.
# Symmetric, so promote_rule cannot recurse; Float64 only for same-width mixing.
function _un_promote(::Type{S}, ::Type{R}) where {S<:UniversalNumber, R<:UniversalNumber}
    Sc = _concretetype(S)
    Rc = _concretetype(R)
    Sc === Rc        && return Sc
    sizeof(Sc) > sizeof(Rc) && return Sc
    sizeof(Rc) > sizeof(Sc) && return Rc
    return Float64
end

Base.promote_rule(::Type{S}, ::Type{R}) where {S<:UniversalNumber, R<:UniversalNumber} =
    _un_promote(S, R)

# Render arrays with the type once in the header, bare values per entry
# (Julia 1.12 does not reliably pass :compact to element show).
function Base.show(io::IO, ::MIME"text/plain", v::AbstractArray{<:UniversalNumber})
    summary(io, v)
    isempty(v) && return
    println(io, ":")
    Base.print_matrix(IOContext(io, :compact => true), v)
end

# Pin result types for SparseArrays/LinearAlgebra allocation (promote_op);
# ccall-based arithmetic otherwise infers Any. Comparisons excluded.
for _op in (:matprod, :*, :+, :-, :/, :\)
    _f = _op === :matprod ? :(LinearAlgebra.matprod) : _op
    @eval Base.promote_op(::typeof($_f), ::Type{S}, ::Type{R}) where {S<:UniversalNumber, R<:UniversalNumber} =
        _un_promote(S, R)
end

# Float64 round-trip fallbacks for functions not in the C bridge.
for _fn in (:tan, :atan, :asin, :acos, :sinh, :cosh, :tanh, :asinh, :acosh, :atanh,
            :exp2, :exp10, :expm1, :log2, :log10, :log1p, :cbrt)
    @eval Base.$_fn(x::UniversalNumber) = typeof(x)($_fn(Float64(x)))
end
Base.atan(y::T, x::T) where {T <: UniversalNumber} = T(atan(Float64(y), Float64(x)))
Base.hypot(x::T, y::T) where {T <: UniversalNumber} = T(hypot(Float64(x), Float64(y)))
Base.signbit(x::UniversalNumber) = signbit(Float64(x))
Base.copysign(x::T, y::T) where {T <: UniversalNumber} = T(copysign(Float64(x), Float64(y)))
Base.ldexp(x::T, n::Integer) where {T <: UniversalNumber} = T(ldexp(Float64(x), n))
Base.frexp(x::T) where {T <: UniversalNumber} =
    let (m, e) = frexp(Float64(x)); (T(m), e); end
# exponent/significand: needed by the instance form eps(x) (e.g. via pinv).
Base.exponent(x::UniversalNumber)    = exponent(Float64(x))
Base.significand(x::T) where {T <: UniversalNumber} = T(significand(Float64(x)))
for _fn in (:floor, :ceil, :trunc)
    @eval Base.$_fn(x::T) where {T <: UniversalNumber} = T($_fn(Float64(x)))
end
Base.round(x::T, r::RoundingMode=RoundNearest) where {T <: UniversalNumber} =
    T(round(Float64(x), r))

# Integer-targeting forms: trunc(Int, x), floor(Int, x), etc.
# Required by LinearAlgebra internals (e.g. givensAlgorithm calls trunc(Integer, x)).
Base.trunc(::Type{T}, x::UniversalNumber) where {T<:Integer} = T(trunc(Float64(x)))
Base.floor(::Type{T}, x::UniversalNumber) where {T<:Integer} = T(floor(Float64(x)))
Base.ceil(::Type{T}, x::UniversalNumber)  where {T<:Integer} = T(ceil(Float64(x)))
Base.round(::Type{T}, x::UniversalNumber) where {T<:Integer} = T(round(Float64(x)))

# Integer exponentiation: Julia's default power_by_squaring disallows negative n
# for non-standard float types (e.g. LinearAlgebra.givens calls x^(-22)).
function Base.:^(x::T, n::Integer) where {T <: UniversalNumber}
    n >= 0 && return Base.power_by_squaring(x, n)
    one(T) / Base.power_by_squaring(x, -n)
end

# eigen / svd / cholesky / cond: no generic Julia path (svdvals! needs LAPACK);
# compute on the Float64 image. Decompositions stay Float64 (converting back
# would destroy resolution); cond returns a Float64 scalar.
LinearAlgebra.eigen(A::Matrix{T})    where {T <: UniversalNumber} = eigen(Float64.(A))
LinearAlgebra.svd(A::Matrix{T})      where {T <: UniversalNumber} = svd(Float64.(A))
LinearAlgebra.cholesky(A::Matrix{T}) where {T <: UniversalNumber} = cholesky(Float64.(A))
LinearAlgebra.cond(A::Matrix{T})            where {T <: UniversalNumber} = cond(Float64.(A))
LinearAlgebra.cond(A::Matrix{T}, p::Real)   where {T <: UniversalNumber} = cond(Float64.(A), p)

# Sparse cond on the Float64 image: the 2-norm needs SVD so it densifies; the
# 1- and Inf-norms stay sparse. Default p = Inf (Base has no 2-norm sparse cond).
function LinearAlgebra.cond(A::SparseMatrixCSC{<:UniversalNumber}, p::Real = Inf)
    p == 2 && return cond(Matrix(Float64.(A)), 2)
    return cond(Float64.(A), p)
end

# Sparse \: LU.lu is unpivoted, so take fill-reducing permutations p, q from
# UMFPACK on the Float64 image, then factor-and-solve PAS = A[p,q] in type T.
# (We do not override LinearAlgebra.lu: LU.lu returns a tuple, not a
# Factorization, so lu(A) \ b would have no dispatch.)
function Base.:\(A::SparseMatrixCSC{T}, b::AbstractVector) where {T<:UniversalNumber}
    Tc = _concretetype(T)
    F = lu(Float64.(A))
    return LU.solve(A, Vector{Tc}(b), F.p, F.q)
end

# Sparse QR lives in QR.jl; dense qr uses Julia's generic Householder path.

# FP8 named aliases (ML/AI industry-standard names for 8-bit float formats)
const E4M3 = CFloat{8,4}
const E3M4 = CFloat{8,3}
const E5M2 = CFloat{8,5}

export Posit, CFloat, LNS, Takum, Fixed, HFloat, DFloat, DD, BF16, UniversalNumber, printbits, about
export E4M3, E3M4, E5M2
export Quire, fdp, quire_dot, fma_product!, clear!, quire_bits

include("about.jl") # color bits
include("quire.jl") # exact fused-dot-product accumulator (posit-only)

end