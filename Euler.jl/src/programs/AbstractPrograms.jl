
function checkWellFormed(source::String)
	open = 0
	for i in eachindex(source)
		token = source[i]

		if token == '['
			open += 1
		elseif token == ']'
			open -= 1
		end

		if open < 0
			return false
		end
	end

	return open == 0
end

randomSource() = randomSource(Random.default_rng())

function randomSource(rng::AbstractRNG)
	source = Random.randstring(['>', '<', '/', '^', ']', '[', 'u', 'd', '{', '}', 's'], 100)
	return checkWellFormed(source) ? source : randomSource()
end