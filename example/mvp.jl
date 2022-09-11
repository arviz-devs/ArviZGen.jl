module MinimumArvizGen

using Gen
using ArviZ
using ArviZGen

@gen function model()
    x ~ normal(0.0, 1.0)
    y ~ normal(x, 1.0)
    return y
end

trs = [simulate(model, ()) for _ in 1 : 10]

_, addrs, choices = ArviZGen.traverse(trs)
println(addrs)
println(choices)

end # module
