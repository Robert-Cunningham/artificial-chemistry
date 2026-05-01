# Agenda
* Choose a good chemistry
	* Define some set of tasks, and choose whichever chemistry allows them to be completed the fastest on average?

Once we know what the best chemistry is, allow it to evolve for a very long time. Insert some alien artifact, and check whether they decide to use it?

* First, need to see the emergence over time of a non-trivial replicator. 
	* To do this, we choose a law, and then check whether there's a single world that develops in a different way than usual.
* Then write a blog post about it.
* Then consider GPU-optimizing it.

# GPU Plan
Allocate a fixed-length tape. 
Each pixel holds a scratch index into a 5-long array of world size.

scratch[current] (owner == 5) * world
current += (owner == 5) * world

looping: done vector.