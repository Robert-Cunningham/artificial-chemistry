function designed()

	physics = Physics(0, Dict(
		0 => programFromString(""),
		4 => programFromString("s>dus"),
		7 => programFromString("")
	))

	config = SimulationConfig(UInt(8), UInt(2^4), UInt(DEFAULT_MAX_STEPS) * 32, neverStop)

	worldmap = zeros(config.worldLen, config.worldLen)
	worldmap[10, 10] = 4
	worldmap[10, 11] = 7
	worldmap[11, 11] = 7
	worldmap[11, 10] = 7
	next = Dict() #zeros(config.worldLen, config.worldLen) #Dict()
	blockers = zeros(config.worldLen, config.worldLen)
	world = RealWorld(worldmap, next, blockers)


	designedSimulation = Simulation(config, world, physics, Cache(nothing), History(Dict()), newBooks(), randomName(), Set(), 0, 0, false, 0)

	return designedSimulation
end


d = designed()
# d.world.data[40, 20] = 50

for i in 0:300
	print(d.world.data[10, 10])
	println(d.world.data[12, 12])
	timestep(d)
	saveDistribution(d)
	saveHistory(d)
end

saveToDisk(d, "histories4/designed3.mp4")
# save("images/test.png", worldToImage(d.world, colors, 3))