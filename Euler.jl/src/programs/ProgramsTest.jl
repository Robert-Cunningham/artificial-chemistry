struct TestMatrix end

struct TestWorld3 <: World
	data::TestMatrix
end


Base.getindex(::TestMatrix, args...) = begin 
	println("Accessed $(args)")
	return 1
end
Base.size(::TestMatrix, args...) = return (config.worldLen, config.worldLen)

size(randWorld(config).data)

tw = TestWorld3(TestMatrix())

p = programFromString("[^c]")

#simulation = setupSimulation(config)

# testsim = Simulation(config, tw, Physics(Dict(1 => p)), Cache(nothing))
# 
# execute(testsim, p, (5, 5))
# 
# println("new")
# p.execute(testsim, (5, 5))
# 
# compile("[^c]")
# 
# execute()
# 