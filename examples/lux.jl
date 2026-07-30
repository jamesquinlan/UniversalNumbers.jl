using UniversalNumbers

using Lux
using Zygote
using Optimisers
using Plots
using Random
using Distributions # toy data
using Statistics

T = BF16; #Posit{8,2,UInt8}
# Hyperparameters
n = 200 # number of samples
lr = T(0.01) # learning rate
layers = [1, 10, 10, 10, 1]

rng = Xoshiro(42)

# toy data
x = T.(rand(rng, Uniform(0.0, 2*pi), (1,n)))
xn = (x .- T(pi)) ./ T(pi) # normalize
noise = T.(rand(rng, Normal(0, 0.3), (1,n)))
y = sin.(x) .+ noise
scatter(Float32.(x[:]), Float32.(y[:]), label="F32")


model = Chain(
    [Dense(in => out, tanh) for (in, out) in zip(layers[1:end-2], layers[2:end-1])]...,
    Dense(layers[end-1] => layers[end], identity)
)
ps, ls = Lux.setup(rng, model); #
ps = Lux.fmap(a -> T.(a), ps); # cast Float32-initialized params to match input type T


y_pred, ls = model(xn, ps, ls)
scatter!(Float32.(x[:]), Float32.(y_pred[:]), label="initial prediction")


function loss(p, ls)
    y_pred, newls = model(xn, p, ls)
    mse = 0.5 * mean((y .- y_pred).^2) # mean squared error
    return mse, newls
end

function run(n_epochs; lr=lr, ps=ps, ls=ls, opt_st=Optimisers.setup(Adam(lr, (0.9, 0.9)), ps), print_every=100)
    history = zeros(typeof(lr), n_epochs)
    for epoch in 1:n_epochs
        (mse, ls), back = pullback(loss, ps, ls) # forward pass
        grad, _ = back((1.0, nothing)) # backward pass

        opt_st, ps = Optimisers.update(opt_st, ps, grad) # update the parameters

        history[epoch] = mse
        if epoch % print_every == 0
            println("Epoch: $epoch, Loss: $mse")
        end
    end
    return ps, ls, opt_st, history
end


n_epochs = 300
ps, ls, opt_st, history = run(n_epochs)
y_pred, ls = model(xn, ps, ls)

plot(history, label="loss", xlabel="Epochs", ylabel="Loss", title="Training Loss", yscale=:log10)

scatter(Float32.(x[:]), Float32.(y[:]), label="data")
scatter!(Float32.(x[:]), Float32.(y_pred[:]), label="prediction")
