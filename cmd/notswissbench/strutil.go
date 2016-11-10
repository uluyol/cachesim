package main

import (
	"strconv"
	"strings"
)

func Int64Join(s []int64, sep string) string {
	ss := make([]string, len(s))
	for i, e := range s {
		ss[i] = strconv.FormatInt(e, 10)
	}
	return strings.Join(ss, sep)
}

func Float64Join(s []float64, sep string) string {
	ss := make([]string, len(s))
	for i, e := range s {
		ss[i] = strconv.FormatFloat(e, 'g', -1, 64)
	}
	return strings.Join(ss, sep)
}
