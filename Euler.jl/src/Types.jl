abstract type Program end

abstract type World end

mutable struct RealWorld <: World
	data::Array{IntS, 2}	
	next::Dict{Tuple{IntW, IntW}, IntS} # location -> value, priority.
	blocked::Array{UInt8, 2}
end

struct Physics
	id::UInt
	laws::Dict{IntS, Program}
end

struct SimulationConfig
	speciesLen::UInt
	worldLen::UInt
	maxSteps::UInt
	shouldStop::Function
end

struct Cache
	programCache
end

struct History
	states::Dict{Int, RealWorld}
end

SpeciesDist = Dict{IntS, UInt}
struct Books
	distribution::Dict{UInt, SpeciesDist}
end


function newBooks()
	return Books(Dict())
end

mutable struct Simulation
	const config::SimulationConfig
	const world::RealWorld
	const physics::Physics
	const cache::Cache
	const history::History
	const books::Books
	const name::String
	const seen::Set
	steps::Int
	updates::Int
	looped::Bool
	balance::Int
end

neverStop(s::Simulation) = false

newConfig(speciesLen::UInt, worldLen::UInt, maxSteps::UInt, shouldStop::Function) = SimulationConfig(speciesLen, worldLen, maxSteps, shouldStop)

newConfig(speciesLen::UInt, worldLen::UInt, maxSteps::UInt) = newConfig(speciesLen, worldLen, maxSteps, neverStop)
