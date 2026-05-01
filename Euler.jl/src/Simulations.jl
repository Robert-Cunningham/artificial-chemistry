function setupSimulation(config::SimulationConfig)
	phys = randomPhysics(config)
	world = randWorld(config)
	cache = Cache(nothing)
	books = newBooks()
	history = History(Dict())

	Simulation(config, world, phys, cache, history, books, randomName(), Set(), 0, 0, false, 0)
end

function setupSimulationWithPhysics(config::SimulationConfig, seed::UInt)
	world = randWorld(config)
	phys = physicsFromSeed(config, seed)
	cache = Cache(nothing)
	books = newBooks()
	history = History(Dict())

	Simulation(config, world, phys, cache, history, books, randomName(), Set(), 0, 0, false, 0)
end

function newSimulation(config::SimulationConfig, phys::Physics, world::World)
end

function runFamily(sims)
	live = collect(eachindex(sims))
	count = 0
	while length(live) > 0
		for i in live
			s = sims[i]	

			count += 1

			saveDistribution(s)
			saveHistory(s)
			timestep(s)

			if count % 1000 == 0
				println("count: $(count)")
			end

			if !shouldContinue(s)
				live = filter(x -> x != i, live)
				println("Removed from simulation $(i)");
				if s.steps == s.maxSteps
					saveToDisk(s, "histories-new/k-$(i).mp4")
				end
			end
		end
	end
end

function runSimulation(s::Simulation)
	while shouldContinue(s)
		saveDistribution(s)
		saveHistory(s)
		timestep(s)
	end

	return s
end

function timestep(sim::Simulation)
	if (sim.balance == 0)
		sim.balance = sim.config.worldLen * sim.config.worldLen # * sim.config.speciesLen / 8
	end

	idxs = collect(Iterators.product(0:sim.config.worldLen-1, 0:sim.config.worldLen-1))
	shuffle!(idxs)

	for (x, y) in idxs
	# for x::IntW=0:sim.config.worldLen-1, y::IntW=0:sim.config.worldLen-1
		# randX = rand(0:sim.config.worldLen-1)::IntW
		# randY = rand(0:sim.config.worldLen-1)::IntW
		randX, randY = x, y

		# species = sim.world[y, x]
		# program = sim.physics.laws[species]
		# program.execute(sim, (x, y))
		species = sim.world[randY, randX]
		program = sim.physics.laws[species]
		program.execute(sim, (randX, randY))
		sim.updates += 1
	end

	commitChanges(sim.world)


	blocked_updates = sim.world.blocked .* sim.world.data
	sim.world.data = sim.world.data .- blocked_updates

	# doBalance(sim)

	#for i=0:1
	addNoise = false
	if addNoise
		if (rand(0:10) <= 1 && sim.steps >= 256)
			randX = rand(0:sim.config.worldLen-1)::IntW
			randY = rand(0:sim.config.worldLen-1)::IntW
			sim.world[randY, randX] = (sim.world[randY, randX] + rand(0:s.config.speciesLen-1)) % s.config.speciesLen
			#sim.world[rand(0:WORLD_LEN-1)::IntW, rand(0:WORLD_LEN-1)::IntW] -= 1
		end
	end

	loopCheck(sim)
end

function getRandomLiveLoc(sim::Simulation)
	randX = rand(0:sim.config.worldLen-1)::IntW
	randY = rand(0:sim.config.worldLen-1)::IntW

	if sim.world.blocked[randY + 1, randX + 1] != 0
		return getRandomLiveLoc(sim::Simulation)
	end

	return (randY, randX)
end

function doBalance(sim::Simulation)
	already = sum(sim.world.data)
	required_change = sim.balance - convert(Int, sum(sim.world.data))
	# println("original $(sim.balance), now: $(already), upcoming_change $(required_change)")

	# mean_change_reqd = required_change / WORLD_LEN * WORLD_LEN
	# update = expMat(sim.config, abs(mean_change_reqd))

	# if mean_change_reqd < 0
	# 	sim.world.data -= update
	# else
	# 	sim.world.data += update
	# end

	iters = 0

	while required_change != 0
		iters += 1

		# if required_change % 10000 == 0
		# 	println("required change $required_change")
		# end
		randY, randX = getRandomLiveLoc(sim)

		currentVal = sim.world.data[randY + 1, randX + 1]
		required_change = sim.balance - convert(Int, sum(sim.world.data))

		if required_change > 0
			availableUp = (sim.config.speciesLen - 1) - currentVal
			incr = rand(0:availableUp)
			sim.world.data[randY + 1, randX + 1] += incr
			# required_change -= incr

			if iters > 1e7
				println("$(randX), $(randY), in $(incr), val: $(currentVal), rc $(required_change), au $(availableUp), sum: $(sum(sim.world.data))")
			end
		else

			availableDown = currentVal
			decr = rand(0:availableDown)
			sim.world.data[randY + 1, randX + 1] -= decr
			# required_change += decr
			if iters > 1e7
				println("(2) $(randX), $(randY), dc $(decr), val: $(currentVal), rc $(required_change), au $(availableDown), sum: $(sum(sim.world.data)), balance: $(sim.balance)")
			end
		end

	end

	# required_change = sim.balance - convert(Int, sum(sim.world.data))
	# println("afterwards: original $(sim.balance), now: $(sum(sim.world.data)), not yet done change $(required_change)")

end

function loopCheck(sim::Simulation)
	h = hash(sim.world.data)
	sim.steps += 1
	if h in sim.seen
		sim.looped = true
	end
	push!(sim.seen, h)
end

function generateColors()
	colors = Dict(s => convert(RGB{N0f8}, HSL{Float64}((s % 9)/9 * 360, (s % 5) / 5, .5)) for s in 0:255)
	colors[255] = RGB{N0f8}(0, 0, 0)
	return colors
end