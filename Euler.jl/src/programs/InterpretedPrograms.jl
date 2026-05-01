struct InterpretedProgram <: Program
	source::String
	execute::Function
end

function createJumpTable(source::String)
	out = Dict()
	queue = []
	for index in eachindex(source)
		token = source[index]
		if token == '['
			push!(queue, index)
		elseif token == ']'
			if length(queue) == 0
				return nothing
			end
			start = pop!(queue)
			stop = index
			out[stop] = start
		end
	end

	if length(queue) > 0
		return nothing
	end

	out
end


function executeInterpreted(s::Simulation, source::String, (x, y))
	jumpTable = createJumpTable(source)

	src = source

	w = s.world

	ox, oy = x, y

	config = s.config

	(wx, wy) = size(w.data)

	index = 1
	iterations = 0

	scratch = Dict()
	scratchPosition = 0

	while true
		#println((index, iterations, scratchPosition, scratch))
		i = src[index]
		#@debug "$((i, x, y))"
		if i == '>'
			#eval(parseInstr(MoveRight))
			x = mod1(x + 1, wx)
		elseif i == '<'
			x = mod1(x - 1, wx)
		elseif i == '^'
			y = mod1(y + 1, wy)
		elseif i == '/'
			y = mod1(y - 1, wy)
		elseif i == '+'
			#w.data[y, x] = mod1(w.data[y, x] + 1, config.speciesLen)
		elseif i == '-'
			#w.data[y, x] = mod1(w.data[y, x] - 1, config.speciesLen)
		elseif i == '}'
			scratchPosition += 1
		elseif i == '{'
			scratchPosition -= 1
		elseif i == 'u'
			scratch[scratchPosition] = mod1(get(scratch, scratchPosition, 1) + 1, config.speciesLen)
			#@debug "scratch[$(scratchPosition)] $(scratch)"
		elseif i == 'd'
			scratch[scratchPosition] = mod1(get(scratch, scratchPosition, 1) - 1, config.speciesLen)
			#@debug "scratch[$(scratchPosition)] $(scratch)"
		elseif i == 'c'
			scratch[scratchPosition] = w.data[y, x]
			# w.data[y, x] = 0
		elseif i == 'p'
			 w.data[y, x] = get(scratch, scratchPosition, 1)
			 # scratch[scratchPosition] = 0
			#@debug "scratch[$(scratchPosition)] $(scratch)"
		elseif i == ']' # jump if scratch nonzero
			#@debug "scratch[$(scratchPosition)] $(scratch)"
			if get(scratch, scratchPosition, 1) != 1 && (iterations += 1) <= 100
				#scratch[scratchPosition] = mod1(get(scratch, scratchPosition, 1) - 1, config.speciesLen)
				index = jumpTable[index]
			else
				# do nothing
			end
		elseif i == '['
			# do nothing
		end

		if index >= length(src)
			break
		end

		index += 1
	end
end

function interpretedProgramFromString(source::String)
	function execute(s::Simulation, (x, y)::Tuple{IntW, IntW})
		executeInterpreted(s, source, (x, y))
	end

	return InterpretedProgram(source, execute)
end

function randomInterpretedProgram() 
	source = randomSource()
	interpretedProgramFromString(source)
end
