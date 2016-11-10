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

# Playing around with caching
Run bin/notswissbench.bash lru-hitrate --help and look at the various options.
Ignore anything that is only used for connecting to a cassandra cluster,
that's part of the actual benchmarking part of this tool.

Below is an example run
```
$ bin/notswissbench.bash lru-hitrate --node-count 8 --cache-type localHashed --cache-size 30 --records 3000 --generator zipfian --ops 1000
HitRate: 254/1000 0.254000
CumReqs: 217,56,116,89,203,83,92,144
CumProbs: 0.021415270018621972,0.002793296089385475,0.021415270018621972,0.00558659217877095,0.09776536312849161,0.004655493482309125,0.022346368715083796,0.05679702048417132
SectionCumProbs: 0_3 0.01675977653631285,0.000931098696461825,0.000931098696461825,0.0037243947858473,0.020484171322160148,0.000931098696461825,0.013966480446927373,0.000931098696461825
SectionCumProbs: 1_3 0.0037243947858473,0.000931098696461825,0.01675977653631285,0.000931098696461825,0.054003724394785846,0.002793296089385475,0.0037243947858473,0.008379888268156424
SectionCumProbs: 2_3 0.000931098696461825,0.000931098696461825,0.0037243947858473,0.000931098696461825,0.023277467411545624,0.000931098696461825,0.004655493482309125,0.04748603351955307
```

# Dependencies
* Go (only to build, prebuilt versions don't require anything)
* R (with ggplot2)
* Python 3
* Bash 4 (for some of the scripts in eval, this is newer than the default in macOS)

