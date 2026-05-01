using CUDA

println("started")
world = CuArray(UInt64.([
	0, 0, 0, 0, 0,
	0, 1, 0, 0, 0,
	0, 0, 1, 0, 0,
	0, 3, 0, 0, 0,
	0, 0, 0, 0, 0,
]))

println("first cuda")

ones = CUDA.ones(UInt64, 25)

world_len = 2^12

println("and")

for i in 0:2000
	start = CUDA.rand(UInt8, world_len, world_len)
	s2 = CUDA.rand(UInt8, world_len, world_len)
	s3 = CUDA.rand(UInt8, world_len, world_len)
	s4 = CUDA.rand(UInt8, world_len, world_len)
	s5 = CUDA.rand(UInt8, world_len, world_len)
	and = CUDA.rand(UInt8, world_len, world_len)

	scratch = (start .& and .& s2 .& s3 .& s4 .& s5);
	CUDA.@allowscalar println(scratch[10000])
end


println("done")