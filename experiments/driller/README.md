# Example experiment - driller

This is an example experiment configuration to run the driller experiment (as described [here](https://www.internetsociety.org/sites/default/files/blogs-media/driller-augmenting-fuzzing-through-selective-symbolic-execution.pdf)).

## Caveats

The original driller experiments, and the Mechanical Phish, used a shared pool of driller workers.
This is much more efficient, but is more difficult to set up, so these experiments use a dedicated set of workers per binary.
This means that binaries that don't need drilling waste resources, and binaries that need it heavily are starved of resources.
