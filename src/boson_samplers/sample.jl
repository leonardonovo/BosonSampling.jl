"""
    sample!(ev::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockSample}
    sample!(ev::Event{TIn,TOut}, loss::Real) where {TIn<:InputType, TOut<:FockSample}

Simulate a boson sampling experiment form a given [`Event`](@ref).
"""
function sample!(ev::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockSample}

    check_probability_empty(ev)

    if TIn == Distinguishable
        ev.output_measurement.s = ModeOccupation(classical_sampler(ev))
    elseif TIn == Bosonic
        ev.output_measurement.s = ModeOccupation(cliffords_sampler(ev))
    else
        error("not implemented")
    end

end

function sample!(ev::Event{TIn,TOut}, loss::Real) where {TIn<:InputType, TOut<:FockSample}

    check_probability_empty(ev)

    if TIn <: PartDist
        if TIn == OneParameterInterpolation
            ev.output_measurement.s = ModeOccupation(noisy_sampler(ev,loss))
        else
            error("model is not valid")
        end
    else
        error("not implemented")
    end
end

# define the sampling algorithm:
# the function sample! is modified to take into account
# the new measurement type
# this allows to keep the same syntax and in fact reuse
# any function that would have previously used sample!
# at no cost
function sample!(ev::Event{TIn, TOut}) where {TIn<:InputType, TOut <: DarkCountFockSample}

    # sample without dark counts
    ev_no_dark = Event(ev.input_state, FockSample(), ev.interferometer)
    sample!(ev_no_dark)
    sample_no_dark = ev_no_dark.output_measurement.s

    # now, apply the dark counts to "perfect" samples
    observe_dark_count(p) = Int(do_with_probability(p)) # 1 with probability p, 0 with probability 1-p
    dark_counts = [observe_dark_count(ev.output_measurement.p) for i in 1: ev.input_state.m]

    ev.output_measurement.s = sample_no_dark + dark_counts
end

function sample!(ev::Event{TIn, TOut}) where {TIn<:InputType, TOut <: RealisticDetectorsFockSample}

    # sample with dark counts but seeing all photons
    ev_dark = Event(ev.input_state, DarkCountFockSample(ev.output_measurement.p_dark), ev.interferometer)
    sample!(ev_dark)
    sample_dark = ev_dark.output_measurement.s

    # remove each of the readings with p_no_count
    for mode in 1:sample_dark.m
        if do_with_probability(ev.output_measurement.p_no_count)
            sample_dark.s[mode] = 0
        end
    end

    ev.output_measurement.s = sample_dark
end

"""
    scattershot_sampling(n::Int, m::Int; N=1000, interf=nothing)

Simulate `N` times a scattershot boson sampling experiment with `n` photons among `m` modes.
The interferometer is set to [`RandHaar`](@ref) by default.
"""
function scattershot_sampling(n::Int, m::Int; N=1000, interf=nothing)

    out_ = Vector{Vector{Int64}}(undef, N)
    in_ = Vector{Vector{Int64}}(undef, N)

    for i in 1:N
        input = Input{Bosonic}(ModeOccupation(random_occupancy(n,m)))
        interf == nothing ? F = RandHaar(m) : F = interf
        ev = Event(input, FockSample(), F)
        sample!(ev)

        in_[i] = input.r.state
        out_[i] = ev.output_measurement.s.state
    end

    joint = sort([[in_[i],out_[i]] for i in 1:N])
    res = counter(joint)

    k = collect(keys(res))
    k = reduce(hcat,k)'
    vals = collect(values(res))

    k1 = unique(k[:,1])
    k2 = unique(k[:,2])
    M = zeros(length(k1),length(k2))
    for i in 1:length(k1)
        for j in 1:length(k2)
            M[i,j] = res[[k1[i]',k2[j]']]
        end
    end

    k1 = [string(i) for i in k1]
    k2 = [string(i) for i in k2]
    heatmap(k1,k2,M')
end
