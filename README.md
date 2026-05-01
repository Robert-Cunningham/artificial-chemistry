# Artificial Chemistry

This repository contains an experimental Julia artificial-chemistry simulator. It searches over random programmable cellular automata and looks for worlds whose dynamics stay interesting instead of immediately collapsing into noise, stasis, or short loops.

## What It Does

The simulator builds two-dimensional toroidal worlds whose cells contain integer atom/species values. A `Physics` object assigns each species a tiny program. Those programs can move around local space, update a scratch tape, loop, and swap values with the world.

The core experiment is:

1. Generate a random chemistry from a seed.
2. Generate a random starting world.
3. Compile each species program into Julia code.
4. Run the world forward for a staged sequence of simulation lengths.
5. Track snapshots and species distributions.
6. Keep or render runs that avoid obvious loops or settled behavior.

Julia is useful here because the generated programs can become optimized native code at runtime instead of being interpreted instruction by instruction.

## Repository Layout

- `Euler.jl/Project.toml` and `Euler.jl/Manifest.toml`: Julia environment and pinned dependency graph.
- `Euler.jl/src/Euler.jl`: package entry point and include list.
- `Euler.jl/src/Types.jl`: core world, physics, simulation, history, and bookkeeping types.
- `Euler.jl/src/programs/`: the small program language, compiler, interpreter, and tests/scratch code.
- `Euler.jl/src/Worlds.jl`: world storage, random world generation, rendering helpers, and video export.
- `Euler.jl/src/Simulations.jl`: setup and timestep execution.
- `Euler.jl/src/Search.jl`: staged random-chemistry search loop.
- `Euler.jl/src/IntelligentDesign.jl`: hand-designed chemistry experiment.
- `Euler.jl/src/util/`: name generation and seed-based physics helpers.
- `GPU.jl`: standalone CUDA scratch experiment; it is not part of the package environment.
- `Euler.jl/todo.md`: original project notes.

Generated videos, images, profiling output, partial transfer files, and editor/system files are intentionally ignored.
