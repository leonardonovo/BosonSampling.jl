### first, a simple bayesian estimator ###

# for the theory, see 1904.12318 page 3

confidence(χ) = χ == Inf ? 1. : χ/(1+χ)

function update_confidence(event, p_q, p_a, χ)

    χ *= p_q(event)/p_a(event)
    χ

end


"""
    compute_confidence(events,p_q, p_a)

A bayesian confidence estimator: return the probability that the null hypothesis
Q is right compared to the alternative hypothesis A.
"""
function compute_confidence(events,p_q, p_a)

    confidence(compute_χ(events,p_q, p_a))
end

"""
    compute_confidence_array(events, p_q, p_a)

Return an array of the probabilities of H being true as we process more and
more events.
"""
function compute_confidence_array(events, p_q, p_a)

    χ_array = [1.]

    for event in events
        push!(χ_array, update_confidence(event, p_q, p_a, χ_array[end]))
    end

    confidence.(χ_array)

end

function compute_χ(events, p_q, p_a)
    χ = 1.
    for event in events
        χ = update_confidence(event, p_q, p_a, χ)
    end
    χ
end

"""
    certify!(b::Bayesian)

Updates all probabilities associated with a `Bayesian` `Certifier`.
"""
function certify!(b::Union{Bayesian, BayesianPartition})

    b.probabilities = compute_confidence_array(b.events, b.null_hypothesis.f, b.alternative_hypothesis.f)
    b.confidence = b.probabilities[end]

end

function certify!(fb::FullBunching)

    p_full_bos =
    p_full_dist =

    bunched_events =
    p_full_observed =

    #use statistical test to give confidence, comparing means

end

"""
    p_B(event::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockDetection}

Outputs the probability that a given `FockDetection` would have if the `InputType` was `Bosonic` for this event.
"""
function p_B(event::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockDetection}

    interf = event.interferometer
    r = event.input_state.r
    input_state = Input{Bosonic}(r)
    output_state = event.output_measurement

    event_H = Event(input_state, output_state, interf)
    compute_probability!(event_H)

    event_H.proba_params.probability

end

"""
    p_D(event::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockDetection}

Outputs the probability that a given `FockDetection` would have if the `InputType` was `Distinguishable` for this event.
"""
function p_D(event::Event{TIn, TOut}) where {TIn<:InputType, TOut <: FockDetection}

    interf = event.interferometer
    r = event.input_state.r
    input_state = Input{Distinguishable}(r)
    output_state = event.output_measurement

    event_A = Event(input_state, output_state, interf)
    compute_probability!(event_A)

    event_A.proba_params.probability

end

# """
#     compute_probability!(b::BayesianPartition)
#
# Updates all probabilities associated with a `BayesianPartition` `Certifier`.
# """
# function compute_probability!(b::BayesianPartition)
#
#     b.probabilities = compute_confidence_array(b.events, b.null_hypothesis.f, b.alternative_hypothesis.f)
#     b.confidence = b.probabilities[end]
#
# end

"""
    number_of_samples(evb::Event{TIn, TOut}, evd::Event{TIn, TOut}; p_null = 0.95, maxiter = 10000) where {TIn <:InputType, TOut <:PartitionCountsAll}

Outputs the number of samples required to attain a confidence that the null hypothesis (underlied by the parameters sent in `evb`) is true compared the alternative (underlied by `evd`) through a bayesian partition sample.

Note that this gives a specific sample - this function should be averaged over many trials to obtain a reliable estimate.
"""
function number_of_samples(evb::Event{TIn1, TOut}, evd::Event{TIn2, TOut}; p_null = 0.95, maxiter = 10000) where {TIn1 <:InputType,TIn2 <:InputType, TOut <:PartitionCountsAll}

    # need to sample from one and then do the treatment as usual
    # here we sample from pb

    # compute the probabilities if they are not already known
    for ev_theory in [evb,evd]
        ev_theory.proba_params.probability == nothing ? compute_probability!(ev_theory) : nothing
    end

    pb = evb.proba_params.probability
    ib = evb.input_state
    interf = evb.interferometer

    p_partition_B(ev) = p_partition(ev, evb)
    p_partition_D(ev) = p_partition(ev, evd)

    p_q = HypothesisFunction(p_partition_B)
    p_a = HypothesisFunction(p_partition_D)

    χ = 1

    for n_samples in 1:maxiter

        ev = Event(ib,PartitionCount(wsample(pb.counts, pb.proba)), interf)

        χ = update_confidence(ev, p_q.f, p_a.f, χ)

        if confidence(χ) >= p_null
            return n_samples
            break
        end
    end

    @warn "number of iterations reached, confidence(χ) = $(confidence(χ))"
    return nothing

end
