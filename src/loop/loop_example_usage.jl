begin
    using Revise

    using BosonSampling
    using Plots
    using ProgressMeter
    using Distributions
    using Random
    using Test
    using ArgCheck
    using StatsBase
    using ColorSchemes
    using Interpolations
    using Dierckx
    using LinearAlgebra
    using PrettyTables
    using LaTeXStrings
    using JLD
    using AutoHashEquals
    using LinearRegression
    using DataStructures
    using Parameters
    using UnPack

end

# note: just go to the bottom for a minimum usage, the first two blocks are kept as intermediary building blocks to this abstract usage for debugging purposes

begin
    ### 2d HOM without loss but with ModeList example ###

    n = 2
    m = 2
    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(ModeOccupation([1,1])) # detecting bunching, should be 0.5 in probability if there was no loss
    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    circuit = LosslessCircuit(2)
    interf = BeamSplitter(1/sqrt(2))
    target_modes = ModeList([1,2], m)

    add_element!(circuit, interf, target_modes)

    ev = Event(i,o, circuit)
    compute_probability!(ev)

    ### one d ex ##

    n = 1
    m = 1

    function lossy_line_example(η_loss)

        circuit = LossyCircuit(1)
        interf = LossyLine(η_loss)
        target_modes = ModeList([1],m)

        add_element_lossy!(circuit, interf, target_modes)
        circuit

    end

    lossy_line_example(0.9)

    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    i = Input{Bosonic}(to_lossy(first_modes(n,m)))
    o = FockDetection(to_lossy(first_modes(n,m)))

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_line_example(transmission))
        @show compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end

    print(output_proba)

    plot(transmission_amplitude_loss_array, output_proba)
    ylabel!("p no lost")
    xlabel!("transmission amplitude")

    ### the same with autoconversion of the input and output dimensions ###

    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(first_modes(n,m))

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_line_example(transmission))
        @show compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end


    ### 2d HOM with loss example ###

    n = 2
    m = 2
    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(ModeOccupation([2,0])) # detecting bunching, should be 0.5 in probability if there was no loss
    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    function lossy_bs_example(η_loss)

        circuit = LossyCircuit(2)
        interf = LossyBeamSplitter(1/sqrt(2), η_loss)
        target_modes = ModeList([1,2],m)

        add_element_lossy!(circuit, interf, target_modes)
        circuit

    end

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_bs_example(transmission))
        compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end

    @test output_proba ≈ [0.0, 5.0000000000000016e-5, 0.0008000000000000003, 0.004049999999999998, 0.012800000000000004, 0.031249999999999993, 0.06479999999999997, 0.12004999999999996, 0.20480000000000007, 0.32805, 0.4999999999999999]


    ### building the loop ###

    n = 3
    m = n

    i = Input{Bosonic}(first_modes(n,m))

    η = 1/sqrt(2) .* ones(m-1)
    # 1/sqrt(2) .* [1,0] #ones(m-1) # see selection of target_modes = [i, i+1] for m-1
    # [1/sqrt(2), 1] #1/sqrt(2) .* ones(m-1) # see selection of target_modes = [i, i+1] for m-1

    η_loss = 1. .* ones(m-1)

    circuit = LosslessCircuit(m)

    for mode in 1:m-1

        interf = BeamSplitter(η[mode])#LossyBeamSplitter(η[mode], η_loss[mode])
        #target_modes_in = ModeList([mode, mode+1], circuit.m_real)
        #target_modes_out = ModeList([mode, mode+1], circuit.m_real)

        target_modes_in = ModeList([mode, mode+1], m)
        target_modes_out = target_modes_in
        add_element!(circuit, interf, target_modes_in, target_modes_out)

    end


    ############## lossy_target_modes needs to be changed, it need to take into account the size of the circuit rather than that of the target modes


    #outputs compatible with two photons top mode
    o1 = FockDetection(ModeOccupation([2,1,0]))
    o2 = FockDetection(ModeOccupation([2,0,1]))

    o_array = [o1,o2]

    p_two_photon_first_mode = 0

    for o in o_array
        ev = Event(i,o, circuit)
        @show compute_probability!(ev)
        p_two_photon_first_mode += ev.proba_params.probability
    end

    p_two_photon_first_mode

    o3 = FockDetection(ModeOccupation([3,0,0]))
    ev = Event(i,o3, circuit)
    @show compute_probability!(ev)

    ### loop with loss and types ###

    begin
        n = 3
        m = n

        i = Input{Bosonic}(first_modes(n,m))

        η = 1/sqrt(2) .* ones(m-1)
        η_loss_bs = 0.9 .* ones(m-1)
        η_loss_lines = 0.9 .* ones(m)
        d = Uniform(0, 2pi)
        ϕ = rand(d, m)

    end

    circuit = LossyLoop(m, η, η_loss_bs, η_loss_lines, ϕ).circuit

    o1 = FockDetection(ModeOccupation([2,1,0]))
    o2 = FockDetection(ModeOccupation([2,0,1]))

    o_array = [o1,o2]

    p_two_photon_first_mode = 0

    for o in o_array
        ev = Event(i,o, circuit)
        @show compute_probability!(ev)
        p_two_photon_first_mode += ev.proba_params.probability
    end

    p_two_photon_first_mode

    o3 = FockDetection(ModeOccupation([3,0,0]))
    ev = Event(i,o3, circuit)
    @show compute_probability!(ev)

     Event(i,o3, circuit)
    compute_probability!(ev)

end

begin

    ### sampling ###
    begin
        n = 3
        m = n

        i = Input{Bosonic}(first_modes(n,m))

        η = 1/sqrt(2) .* ones(m-1)
        η_loss_bs = 0.9 .* ones(m-1)
        η_loss_lines = 0.9 .* ones(m)
        d = Uniform(0, 2pi)
        ϕ = rand(d, m)

    end

    circuit = LossyLoop(m, η, η_loss_bs, η_loss_lines, ϕ).circuit


    p_dark = 0.01
    p_no_count = 0.1

    o = FockSample()
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

    o = DarkCountFockSample(p_dark)
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

    o = RealisticDetectorsFockSample(p_dark, p_no_count)
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

end

###### sample with a new circuit each time ######

# have a look at the documentation for the parameters and functions
get_sample_loop(LoopSamplingParameters(n = 10, input_type = Distinguishable))
