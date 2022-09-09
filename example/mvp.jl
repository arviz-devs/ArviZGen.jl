module MinimumGenArviz

using Gen
using ArviZ
using GenArviZ

@gen function submodel()
    y ~ normal(0.0, 1.0)
    return y
end

@gen function model()
    x ~ normal(0.0, 1.0)
    y ~ normal(x, 1.0)
    z ~ submodel()
    return z
end

tr = simulate(model, ())

metadata, addrs, choices = GenArviZ.traverse(tr)

# Here, we go through the list of addresses and force them to be
# `Symbol` type.
addrs = map(v -> length(v) == 1 ? v[1] : Symbol(repr(v)), addrs)

# The end of result of this function should be a `NamedTuple`
# with elements that look like (addr => value).
prior_sample = NamedTuple(map(zip(addrs, choices)) do (addr, v)
    addr => collect(values(v))
end)

# TODO: The data is from the prior, it's not inference data.
#prior_inf_data = GenArviZ.encode_as_prior(prior_sample)
#posterior_inf_data = GenArviZ.encode_as_posterior(...)

# Here, we'll convert to a `NamedTuple`, which ArviZ
# `InferenceData` accepts.
inf_data = ArviZ.from_namedtuple(inf_data_compatible)

end # module
