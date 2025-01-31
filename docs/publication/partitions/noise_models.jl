using BosonSampling
using Plots


###### checking if linear around bosonic ######

# in Totally Destructive Many-Particle Interference
# they claim that around the bosonic case, when p_bos = 0
# the perturbation is linear and proportional to p_d
# we believe this is false

n = 8
m = n

interf = Fourier(m)

ib = Input{OneParameterInterpolation}(first_modes(n,m),1)
id = Input{OneParameterInterpolation}(first_modes(n,m),0)

# write a suppressed event
state = zeros(Int, n)
state[1] = n - 1
state[2] = 1
state = ModeOccupation(state)
o = FockDetection(state)

evb = Event(ib, o, interf)
evd = Event(id, o, interf)

events = [evb, evd]

for event in events
    compute_probability!(event)
end

p_b = evb.proba_params.probability
p_d = evd.proba_params.probability

function p(x)

    i = Input{OneParameterInterpolation}(first_modes(n,m),x)
    ev = Event(i, o, interf)
    compute_probability!(ev)

    ev.proba_params.probability

end

p_claim(x) = n*(1-x)* p_d

x_array = [x for x in range(0.9,1,length = 100)]
p_x_array = p.(x_array)
p_claim_array = p_claim.(x_array)

plt = plot(x_array, p_x_array, label = "p_x")
plot!(x_array, p_claim_array, label = "p_claim")
title!("Fourier, n = $(n)")

savefig(plt, "src/certification/images/check_dittel_approximation_fourier_n=$(n).png")


###### checking if the prediction about partition expansion is right ######


n = 8
m = n
n_subsets = 2
count_index = Int(n/2) + 1 ### event we look at

interf = RandHaar(m)

ib = Input{OneParameterInterpolation}(first_modes(n,m),1)
i(x) = Input{OneParameterInterpolation}(first_modes(n,m),x)

part = equilibrated_partition(m, n_subsets)
o = PartitionCountsAll(part)

function proba_partition(x, count_index)

    this_ev = Event(i(x), o, interf)
    compute_probability!(this_ev)

    this_ev.proba_params.probability.proba[count_index]

end

this_ev = Event(i(x), o, interf)
compute_probability!(this_ev)

this_ev.proba_params.probability.proba[count_index]



x_array = collect(range(0.8, 1, length = 100))

plot(x_array, proba_partition.(x_array, count_index))
