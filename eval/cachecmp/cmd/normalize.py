#!/usr/bin/env python3

import sys

vmax = float("-inf")
vs = []
for line in sys.stdin:
	v = float(line)
	if v > vmax:
		vmax = v
	vs.append(v)

for v in vs:
	print(v/vmax)
