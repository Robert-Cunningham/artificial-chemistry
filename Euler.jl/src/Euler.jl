module Euler

using Random
using Images
# using ImageShow
# using Profile
# using InteractiveUtils
# using PProf
# using Traceur
# using BenchmarkTools

using StaticArrays
using Parameters
using ThreadedIterables
using Kronecker
using VideoIO
using CoherentNoise
using TSne
using Plots
using Clustering
using StatsBase
using Distributions

println("starting")
include("./Base.jl")
include("./Types.jl")
include("./programs/AbstractPrograms.jl")
include("./util/Utils.jl")
include("./util/nouns.jl")
include("./programs/InterpretedPrograms.jl")
include("./programs/CompiledPrograms.jl")
include("./Worlds.jl")
include("WorldCheckpoints.jl")
include("./Simulations.jl")
include("./Search.jl")
include("./IntelligentDesign.jl")
include("./programs/ProgramsTest.jl")

# @code_native program.execute(s, (3, 5))

# @trace program.execute(s, (3, 5))
# @btime program.execute($(randWorld(config)), (3, 5)) seconds=5 #300ns

#@btime execute($(setupSimulation()), $(program), (3, 5)) seconds=5 #21 us

end # module Euler