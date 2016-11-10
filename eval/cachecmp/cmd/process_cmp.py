#!/usr/bin/env python3

import sys

localHashed_txt = sys.argv[1]
global_txt = sys.argv[2]

def add_data(data, f, name):
	for line in f:
		if line.startswith("CumProbs:"):
			v = sum(float(s) for s in line.split()[1].split(","))
			data.append((name, "CumProb", v))
		elif line.startswith("CumReqs:"):
			v = sum(float(s) for s in line.split()[1].split(","))
			data.append((name, "Req", v))
		elif line.startswith("SectionCumProbs:"):
			split = line.split()
			section = split[1]
			v = sum(float(s) for s in split[2].split(","))
			data.append((name, "SectionCumProbs." + section, v))

records = []

with open(localHashed_txt) as f:
	add_data(records, f, "LocalHashed")

with open(global_txt) as f:
	add_data(records, f, "Global")

for r in records:
	print("%s,%s,%s" % r)
