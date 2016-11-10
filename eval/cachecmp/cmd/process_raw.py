#!/usr/bin/env python3

import collections
import sys

localHashed = sys.argv[1]

def add_data(data, f):
	local_data = collections.defaultdict(list)
	for line in f:
		if line.startswith("CumProbs:"):
			vstrs = line.split()[1].split(",")
			for i in range(len(vstrs)):
				local_data["CumProb"].append((i, float(vstrs[i])))
		elif line.startswith("CumReqs:"):
			vs = [float(s) for s in line.split()[1].split(",")]
			vmax = float(max(vs))
			vs = [v/vmax for v in vs]
			for i in range(len(vs)):
				local_data["Req"].append((i, float(vs[i])))
		elif line.startswith("SectionCumProbs:"):
			split = line.split()
			section = split[1]
			vstrs = split[2].split(",")
			for i in range(len(vstrs)):
				local_data["SectionCumProbs." + section].append((i, float(vstrs[i])))
	local_data["CumProb"].sort(key=lambda r: r[1])
	index_map = {}
	for i in range(len(local_data["CumProb"])):
		index_map[local_data["CumProb"][i][0]] = str(i)
	for label, rs in local_data.items():
		for r in rs:
			data.append((index_map[r[0]], label, r[1]))

records = []

with open(localHashed) as f:
	add_data(records, f)

for r in records:
	print("%s,%s,%s" % r)
