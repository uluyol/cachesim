#!/usr/bin/env python3

import sys

sum = float(0)
for line in sys.stdin:
	sum += float(line)

print(sum)
