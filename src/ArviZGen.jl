module ArviZGen

using Gen

export traverse

#####
# Traverse a trace, and flatten it.
# Return a flatten list of addresses,
# and a flat list of values at those addresses.
#####

function traverse!(flat::Vector, par::Tuple, chm::Gen.ChoiceMap)
    for (k, v) in get_values_shallow(chm)
        push!(flat, ((par..., k), v))
    end
    for (p, sub) in get_submaps_shallow(chm)
        traverse!(flat, (par..., p), sub)
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
    flat = Any[]
    for (k, v) in get_values_shallow(chm)
        push!(flat, ((k,), v))
    end
    for (par, sub) in get_submaps_shallow(chm)
        traverse!(flat, (par,), sub)
    end
    addrs = map(first, flat)
    vs = map(second, flat)
    return addrs, vs
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

function traverse(trs::Vector{T}) where T <: Gen.Trace
    vs = map(trs) do tr
        traverse(tr)
    end
    metadata = map(x -> x[1], vs)
    addrs = map(x -> x[2], vs)
    choices = map(x -> x[3], vs)
    return metadata, vcat(unique(addrs)...), mapreduce(permutedims, vcat, choices)
end

end # module
