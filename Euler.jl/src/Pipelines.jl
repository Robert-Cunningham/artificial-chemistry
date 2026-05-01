struct Pipeline
	stages
end

struct Stage
	log_copies::Int
	log_world_len::Int
	log_steps::Int
end

stage1 = Stage(0, 5, 100) # does it do more like "something" or more like "nothing"