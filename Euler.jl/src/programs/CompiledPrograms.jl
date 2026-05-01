abstract type AbstractTape end

const LOG_SCRATCH_LEN = 4
const SCRATCH_LEN::UInt = 2^LOG_SCRATCH_LEN

const LOG_WORLD_LEN = 8 #7 is good
const DEFAULT_WORLD_LEN::IntW = 2^LOG_WORLD_LEN

const LOG_SPECIES_LEN = 6
const DEFAULT_SPECIES_LEN::IntS = 2^LOG_SPECIES_LEN

const LOG_MAX_STEPS = 13
const DEFAULT_MAX_STEPS::UInt = 2^LOG_MAX_STEPS

struct DictTape <: AbstractTape
	data::Dict
end

struct ArrayTape3 <: AbstractTape 
	data::MVector{Int64(SCRATCH_LEN), IntS}
end

function Base.getindex(t::DictTape, index)
	return get(t.data, index, 0)
end

function Base.getindex(t::ArrayTape3, index)
	return t.data[index + 1]
end

function Base.setindex!(t::ArrayTape3, value, index)
	t.data[index + 1] = value
end

function newTape()
	return ArrayTape3(zeros(MVector{Int64(SCRATCH_LEN), IntS}))
end

function decrMod(val, mod)
	return (val + mod - 1) & (mod - 1)
end

function incrMod(val, mod)
	return (val + mod + 1) & (mod - 1)
end

# rotate x, y by dir * 90 degrees around ox, oy
function rotate(x, y, ox, oy, dir, mod)
	# Translate point to origin
	x -= ox
	y -= oy

	# Rotate based on the dir value
	if dir == 1  # 90 degrees counterclockwise
		x, y = -y, x
	elseif dir == 2  # 180 degrees
		x, y = -x, -y
	elseif dir == 3  # 270 degrees counterclockwise, or 90 degrees clockwise
		x, y = y, -x
	end

	# Translate back
	x += ox
	y += oy

	return x & (mod -1), y & (mod - 1)
end




# balance is the sum of what's on the scratch tape right now.

# export_left is how many more tiles this entity can place after. 
# We check it whenver we interact with the outside world; if we don't have enough points left, silently fail.

instructions = [
# ('<', :MoveLeft, :(:(x = mod1(x - 1, wx)))),
# ('>', :MoveRight, :(:(x = mod1(x + 1, wx)))),
# ('/', :MoveDown, :(:(y = mod1(y - 1, wy)))),
# ('^', :MoveUp, :(:(y = mod1(y + 1, wy)))),

# ('<', :MoveLeft, :(:(x = x > 1 ? x - 1 : wx))),
# ('>', :MoveRight, :(:(x = x < wx ? x + 1 : 1))),
# ('/', :MoveDown, :(:(y = y > 1 ? y - 1 : wy))),
# ('^', :MoveUp, :(:(y = y < wy ? y + 1 : 1))),

('<', :MoveLeft, :(:(x = decrMod(x, s.config.worldLen)))),
('>', :MoveRight, :(:(x = incrMod(x, s.config.worldLen)))),
('/', :MoveDown, :(:(y = decrMod(y, s.config.worldLen)))),
('^', :MoveUp, :(:(y = incrMod(y, s.config.worldLen)))),

('{', :MoveScratchLeft, :(:(scratchPosition = incrMod(scratchPosition, SCRATCH_LEN)))),
('}', :MoveScratchRight, :(:(scratchPosition = decrMod(scratchPosition, SCRATCH_LEN)))),

('u', :IncreaseScratchValue, :(:( scratch[scratchPosition] = incrMod(scratch[scratchPosition], s.config.speciesLen);))),

('d', :DecreaseScratchValue, :(:( scratch[scratchPosition] = decrMod(scratch[scratchPosition], s.config.speciesLen);))),

# ('c', :CopyScratch, :(:(scratch[scratchPosition] = w[y, x]; balance -= w[y, x]; w[y, x] = 0; ))),
# ('p', :PasteScratch, :(:(w[y, x] = scratch[scratchPosition]; balance += scratch[scratchPosition]; scratch[scratchPosition] = 0))),
# ('c', :CopyScratch, :(:(
# 	(nx, ny) = rotate(x, y, ox, oy, dir, s.config.worldLen);
# 	scratch[scratchPosition] = w[ny, nx];
# ))), # unbalanced
# ('p', :PasteScratch, :(:(
# 	(nx, ny) = rotate(x, y, ox, oy, dir, s.config.worldLen);
# 	w[ny, nx] = scratch[scratchPosition];
# ))), # unbalanced
('s', :SwapScratch, :(:(
	(nx, ny) = rotate(x, y, ox, oy, dir, s.config.worldLen);
	tmp = scratch[scratchPosition];
	scratch[scratchPosition] = w[ny, nx];
	w[ny, nx] = tmp;
))), # unbalanced


# ('s', :CopyScratch, :(:(
# 	# if scratch is zero and w is 3...
# 
# 	# cost is -3
# 	# export_left goes to 3.
# 
# 	export_cost = Int.(scratch[scratchPosition]) - Int.(w[y, x]); # how much are we adding to the world by removing w[y, x] and putting in scratch?
# 	if export_left >= export_cost
# 		export_left -= export_cost
# 		tmp = scratch[scratchPosition];
# 		scratch[scratchPosition] = w[y, x];
# 		w[y, x] = tmp;
# 	end
# ))),

# ('[', :LoopStart, :(:(while get(scratch, scratchPosition, 1) != 1 && (iterations += 1) <= 100 end))),
('[', :LoopStart, :(:(while true end))),
(']', :LoopEnd, :(:())),
]

#const loopSuffix = :(if (get(scratch, scratchPosition, 1) == 1 || (iterations += 1) > 100) break end)
const loopSuffix = :(if (scratch[scratchPosition] == 1 || (iterations += 1) > 10) break end)
const info = :(println("x: $(x), y: $(y), w[y, x]: $(w[y, x]), sp: $(scratchPosition), sc: $(scratch)."))

const escape = :(iterations += 1)

const suffix = :(
)

tokenToSymbol = Dict()
for (token, symbol, command) in instructions
	@eval begin
		struct $symbol end
		function parseInstr(::$symbol) 
			return $command
		end
		$tokenToSymbol[$token] = $symbol()
	end
end

# Compiled functions map (s, (x, y)) -> void

# Map a program to its function.
function compile(source::String)
	compiled = quote
		function(s::Simulation, (x, y)::Tuple{IntW, IntW})
			w = s.world
			config = s.config

			dir = s.updates % 4

			ox, oy = x, y;

			scratch = newTape()
			scratchPosition = 0
			iterations = 0
			balance = 0 # balance is the total matter inside this working area.
			spare = 0 # spare is the amount of matter in the tape register for incr and decr.
			export_left = 0

		end
	end

	body = last(last(compiled.args).args).args

	loops = []

	target = body

	for token in source

		instr = tokenToSymbol[token]
		expr = parseInstr(instr)

		target = isempty(loops) ? body : last(last(loops).args).args

		if instr isa LoopStart
			push!(loops, expr)
		elseif instr isa LoopEnd
			push!(target, loopSuffix)
			finishedLoop = pop!(loops)
			target = isempty(loops) ? body : last(last(loops).args).args
			push!(target, finishedLoop)
		else
			push!(target, expr)
		end
	end

	push!(target, suffix)

	return compiled
end

# parseInstr3(::LoopStart) = :(while get(scratch, scratchPosition, 1) != 0 end)
# parseInstr3(::IncreaseScratchValue) = :(println("random instruction"))
# parseInstr3(::LoopEnd) = :()

# parseInstr3(LoopStart())

struct CompiledProgram <: Program
	source::String
	execute::Function
end

function compiledProgramFromString(source::String)
	return CompiledProgram(source, eval(compile(source)))
end

function randomCompiledProgram(rng::AbstractRNG) 
	source = randomSource(rng)
	compiledProgramFromString(source)
end

randomProgram() = randomProgram(default_rng())

function randomProgram(rng::AbstractRNG)
	randomCompiledProgram(rng)
end

function programFromString(source::String)
	compiledProgramFromString(source)
end