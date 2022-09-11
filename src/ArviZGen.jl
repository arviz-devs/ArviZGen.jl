module ArviZGen

using Gen

export traverse

#####
# Traverse a trace, and flatten it.
# Return a flatten list of addresses,
# and a flat list of values at those addresses.
#####

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

"""
    traverse(chm::Gen.ChoiceMap)

Walks a `chm :: Gen.ChoiceMap`, and returns a `Tuple`, whose
first element is a flat list of addresses in the choice map, and whose
second element is a list of `NamedTuple` instances (in the same order as the
addresses), with key the type of the choice map value at the corresponding
address, and value the value.
"""
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

"""
    traverse(tr::Gen.Trace)

Similar to `traverse(chm::Gen.ChoiceMap)`, but returns a `Tuple` with 3 elements,
whose first element is inference metadata from the `tr::Gen.Trace`.

The other elements are the same as `traverse(chm::Gen.ChoiceMap)`.
"""
function traverse(tr::Gen.Trace)
    ret = get_retval(tr)
    args = get_args(tr)
    score = get_score(tr)
    gen_fn = repr(get_gen_fn(tr))
    addrs, choices = traverse(get_choices(tr))
    metadata = (; gen_fn, score, ret, args)
    return metadata, addrs, choices
end

end # module
