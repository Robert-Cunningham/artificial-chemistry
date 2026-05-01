total_attempts = 100000

pipe = [
	# newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^5), UInt(2^7), neverStop),
	newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^6), UInt(2^9), neverStop)
	newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^6), UInt(2^11), neverStop)
	newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^7), UInt(2^12), neverStop) # e
	newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^8), UInt(2^12), klStop) # this is good
	newConfig(UInt(DEFAULT_SPECIES_LEN), UInt(2^8), UInt(2^14), klStop)
]


function executeMultirun()
	Threads.@threads for i in 1:total_attempts #49 seconds for 100
		seed = randomPhysicsSeed()

		for (pipeIndex, config) in enumerate(pipe)
			if pipeIndex != 1
				println("[$i] Beginning stage $pipeIndex...")
			end

			s = setupSimulationWithPhysics(config, seed);
			Base.invokelatest(runSimulation, s);

			formattedN = lpad(seed, 12, "0")
			println("[$(formattedN)] (stage $pipeIndex) done after $(s.steps) steps.")

			if s.steps >= s.config.maxSteps && pipeIndex >= 2
				saveToDisk(s, "histories4/o-$(pipeIndex)-$(seed).mp4")
			end

			if s.looped || kldiv(s) < 0.01
				break
			end
		end
	end
end

executeMultirun()