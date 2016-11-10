# Project Layout
cmd/ contains code for different workload generators and cache types.
The tool was originally meant to be an actual benchmarking tool
but is no longer used for that purpose.
Precompiled binaries for macOS and Linux can be found in bin,
use bin/notswissbench.bash to auto-select the correct one.

eval contains different experiments.
hithist looks at the empiracle PMF/PDF under various configs.
cachecmp compares different caches under a wide variety of conditions.
Note that the cachecmp scripts assume that they will be run on a Linux cluster.

# Dependencies
* Go (only to build, prebuilt versions don't require anything)
* R (with ggplot2)
* Python 3
* Bash 4 (for some of the scripts in eval, this is newer than the default in macOS)

