# ArviZGen

A compatibility layer for using [ArviZ](https://arviz-devs.github.io/arviz/) visualization functionality with Gen traces.

This package currently only supports Gen models without hierarchical sub-models, or stochastic structure.

Specifically, this sort of model is supported:

```julia
@gen function model()
    x ~ normal(0.0, 1.0)
    y ~ normal(x, 1.0)
    return y
end
```

But this sort of model is not:

```julia
@gen function submodel()
    y ~ normal(0.0, 1.0)
    return y
end

@gen function model()
    x ~ normal(0.0, 1.0)
    y ~ normal(x, 1.0)
    z ~ submodel()
    return y
end
```

Neither is this one:

```julia
@gen function model()
    x ~ normal(0.0, 1.0)
    if x > 5.0
      z ~ submodel()
    else:
      y ~ normal(x, 1.0)
    return y
end
```
