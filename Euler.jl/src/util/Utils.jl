randomColor() = rand(RGB{N0f8})

physicsFromSeed(config::SimulationConfig, seed::UInt) = begin
	rng = MersenneTwister(seed)
	p = Physics(seed, Dict(IntS(i) => randomProgram(rng) for i in 0:config.speciesLen-1))
	p.laws[0] = programFromString("")
	return p
end

randomPhysics(config::SimulationConfig) = physicsFromSeed(config, randomPhysicsSeed())

function randomPhysicsSeed()
	rand(UInt) % 1_000_000_000_000
end


#worldToImage(w::RealWorld, colors) = imresize(map(x -> colors[x], reverse(w.data, dims=1)), ratio=4, nothing)

#worldToImage(w::RealWorld, colors) = map(x -> colors[x], reverse(w.data, dims=1))