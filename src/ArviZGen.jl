module ArviZGen

using Gen

export traverse

#####
# Traverse a trace, and flatten it.
# Return a flatten list of addresses,
# and a flat list of values at those addresses.
#####

# A new interface which users can implement for their `T::Trace`
# type to extract serializable arguments.
function get_serializable_args(tr::T) where T <: Gen.Trace
    return Gen.get_args(tr)
end

struct ZeroCost{T}
    data::T
end

function unbox(zc::ZeroCost{T}) where {T}
    return zc.data
end

function traverse!(flat::Vector, typeset::Set, par::Tuple, chm::Gen.ChoiceMap)
    for (k, v) in get_values_shallow(chm)
        push!(typeset, typeof(v))
        push!(flat, ((par..., k), ZeroCost(v)))
    end

    for (p, sub) in get_submaps_shallow(chm)
        traverse!(flat, typeset, (par..., p), sub)
    end
end

function second(x)
    return x[2]
end

function traverse(chm::Gen.ChoiceMap)
    typeset = Set(Type[])
    flat = Tuple{Any,ZeroCost}[]
    for (k, v) in get_values_shallow(chm)
        push!(typeset, typeof(v))
        push!(flat, ((k,), ZeroCost(v)))
    end
    for (par, sub) in get_submaps_shallow(chm)
        traverse!(flat, typeset, (par,), sub)
    end
    ts = collect(typeset)
    addrs = map(first, flat)
    vs = map(second, flat)
    sparse = map(vs) do v
        v = unbox(v)
        (; (typeof(v) <: t ? Symbol(t) => v : Symbol(t) => missing for t in ts)...)
    end
    return addrs, sparse
end

function traverse(tr::Gen.Trace)
    ret = get_retval(tr)
    args = get_serializable_args(tr)
    score = get_score(tr)
    gen_fn = repr(get_gen_fn(tr))
    addrs, choices = traverse(get_choices(tr))
    metadata = (; gen_fn, score, ret, args)
    return metadata, addrs, choices
end

end # module
