
function saveHistory(sim::Simulation)
	if savedStep(sim.steps)
		sim.history.states[sim.steps] = deepcopy(sim.world)
	end
end

function getDistribution(sim::Simulation)
	dist::Dict{IntS, UInt} = Dict()
	for i in CartesianIndices(sim.world.data)
		dist[sim.world.data[i]] = get(dist, sim.world.data[i], 0) + 1
	end
	
	return dist
end

function saveDistribution(sim::Simulation)
	sim.books.distribution[sim.steps] = getDistribution(sim)
end

function isLogStep(step::Int, base::Int)
	isapprox(log2(step)/log2(base), round(log2(step)/log2(base)))
end

using SHA

function isEpochStep(step::Int)
	incr = 300
	epoch = round(step / incr)
	every_k = round(epoch^(2/3))

	hash = sha256(string(epoch))

	val = hash[1] + hash[2] * 256 + hash[3] * 256^2

	return val % every_k == 0
end

function savedStep(step::Int)
	if step <= 500
		return true
	end

	if isEpochStep(step)
		return true
	end

	return false
end

function klStop(s::Simulation)
	if s.steps >= 100 && isLogStep(s.steps, 10)
		return kldiv(s) < .01
	else
		return false
	end
end


function shouldContinue(s::Simulation)
	if s.config.shouldStop(s)
		return false
	end

	if s.looped
		return false
	end

	if s.steps >= s.config.maxSteps
		return false
	end

	return true
end

function movementRatio(h::History)
	return sum(abs.(h.states[MOVEMENT_STEP].data - h.states[MOVEMENT_STEP + 1].data)) / 255 / prod([size(h.states[0].data)...])
end

function mostlyStill(h::History)
	movement_ratio = movementRatio(h)
	return movement_ratio < .1 #&& movement_ratio > .02
end

function toArray(d::SpeciesDist, speciesLen)
	out::Vector{UInt} = []
	for s in 0:speciesLen-1
		push!(out, get(d, s, 0))	
	end
	out
end

function speciesDistsToBlock(s::Simulation)
	data = permutedims(hcat([toArray(s.books.distribution[i], s.config.speciesLen) for i in 0:length(s.books.distribution)-1]...))
	return data
end

function smear_dist(s::Simulation, moment_pct, width_pct)
	block = speciesDistsToBlock(s)
	total_iters = size(block, 1)
	target_start = max(total_iters * (moment_pct - width_pct), 0)
	target_end = min(total_iters * (moment_pct + width_dist), total_iters)

	dist = sum(block[target_start:target_end, :], dims=1) .+ 1

	normed = dist / sum(dist)

	return normed
end

function kldiv(s::Simulation)
	block = speciesDistsToBlock(s)

	iters = size(block, 1)
	chunks = 10
	chunk_size = UInt(floor(iters / chunks))
	summary_dists = [sum(block[(chunk_size * k + 1):(chunk_size * (k + 1)), :], dims=1) for k in 0:chunks-1]

	last_checked = summary_dists[4] .+ 1
	modern = summary_dists[10] .+ 1

	kld = kldivergence(last_checked / sum(last_checked), modern / sum(modern))
	println("$(s.name): kld $(kld)")

	return kld
end

function plotTsne(s::Simulation)
	data = speciesDistsToBlock(s)
	dataf = data / mean(data)
	tsne_out = tsne(dataf, 2, 0)
	tsne_colors = [convert(RGB{N0f8}, HSL{Float64}(s / size(dataf, 1) * 360, 1, .5)) for s in 1:size(dataf, 1)]
	scatter(tsne_out[:, 1], tsne_out[:, 2], color=tsne_colors)
end