function Base.getindex(w::RealWorld, y::IntW, x::IntW)
	return w.data[y + 1, x + 1]
end

function Base.setindex!(w::RealWorld, value, y::IntW, x::IntW)
	# w.next[x, y] = max(get(w.next, (x, y), 0), value) # max strategy
	w.data[y + 1, x + 1] = value # direct strategy
	# w.next[x, y] = get(w.next, (x, y), 0) + value - w.data[y+1, x+1] # sum strategy

	#nexts = get(w.next, (x, y), [])
	#push!(nexts, new)
	#w.next[(x, y)] = nexts

	# w.next[(x, y)] = max(old, new)
	# w.balance += min(old, new)
	#push!(w.next, (x, y, value))
end

function commitChanges(w::RealWorld)
	return # direct strategy
	#for (x, y, value) in sort(w.next, by=x -> x[3])
	for ((x, y), value) in w.next
		w.data[y + 1, x + 1] = IntS(value) # max strategy
		# w.data[y + 1, x + 1] = clamp(w.data[y + 1, x + 1] + value, 0, SPECIES_LEN-1) # sum strategy
	end
	w.next = Dict()
end


function expMat(config::SimulationConfig, intended_mean)
	negative = intended_mean < 0

	if intended_mean == 0
		return zeros(config.worldLen, config.worldLen)
	end

	#d = Exponential(abs(intended_mean))
	#start = Int.(clamp!(round.(rand(d, config.worldLen, config.worldLen)), 0, config.speciesLen - 1))
	start = rand(0:config.speciesLen - 1, config.worldLen, config.worldLen)
	true_mean = sum(start) / config.worldLen / config.worldLen

	return negative ? -1 * start : start
end

function randWorld(config::SimulationConfig) 
	# start = rand(0:config.speciesLen-1, config.worldLen, config.worldLen)
	intended_mean = 0.4
	start = IntS.(expMat(config, intended_mean))

	noiseSize = 2^8
	noisescale = config.worldLen / noiseSize

	next = Dict()

	noise = gen_image(opensimplex2_2d(), h=config.worldLen, w=config.worldLen, xbounds=(-noisescale, noisescale), ybounds=(-noisescale, noisescale))
	# blocked = map(x -> red(x), noise) .< 0.1
	blocked = map(x -> red(x), noise) .< 0.0

	# for i in 1:config.worldLen
	# 	for inside in 0:3
	# 		blocked[inside + 1, i] = true
	# 		blocked[i, inside + 1] = true
	# 		blocked[i, config.worldLen - inside] = true
	# 		blocked[config.worldLen - inside, i] = true
	# 	end
	# end

	# save("images/blocked.png", blocked)

	# start = start .- (blocked .* start)

	#rand(Float64, config.worldLen, config.worldLen) .< .005
	return RealWorld(start, next, blocked)
	# return RealWorld(start, next)
end

function worldToImage(w::RealWorld, colors, upscale)::Matrix{ColorTypes.RGB{N0f8}}
	underlying = w.data .- w.blocked .* w.data + w.blocked .* 255
	# underlying = w.data
	out = map(x -> colors[x], reverse(underlying, dims=1))
	
	return kronecker(out, ones((upscale, upscale)))
end

# I want to see the first 1000 steps, then every other 500, then every third 500, then every 1/4 500, etc.
# 1 2 4 6

function saveToDisk(s::Simulation, name::String)
	steps = sort(collect(keys(s.history.states)))
	# VideoIO.save(name, imap(step -> worldToImage(s.history.states[step], colors, 4), steps), framerate=30, encoder_options=(crf=10, preset="medium"))
	colors = generateColors()
	VideoIO.save(name, (worldToImage(s.history.states[step], colors, 3) for step in steps), framerate=15, encoder_options=(crf=25, preset="medium")) # TODO 20 -> 3

	# d = mktempdir(d -> begin
	# 	for step in steps
	# 		save("$d/$(step).png", worldToImage(s.history.states[step], colors, 1))
	# 	end

	# 	run(`ffmpeg -framerate 30 -i $d/%d.png -c:v libx264 -crf 18 -pix_fmt yuv420p -y -filter_complex "scale=iw*4:-2" -sws_flags neighbor $name`)
	# end)
end