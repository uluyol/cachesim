package main

import (
	"reflect"
	"sort"
	"testing"
)

func findCollisions(c *LocalHashedLRUCache, k int64, num int) []int64 {
	var collisions []int64
	kni := c.ni(k)
	for i := k + 1; len(collisions) < num; i++ {
		if c.ni(i) == kni {
			collisions = append(collisions, i)
		}
	}
	return collisions
}

func TestLocalHashedInferiorSanity(t *testing.T) {
	c := NewLocalHashedLRUCache(80, 8)
	t.Logf("localCap: %d", c.nodes[0].cap)
	collisions := findCollisions(c, 0, 79)
	testKeys := []int64{0}
	testKeys = append(testKeys, collisions...)
	gc := NewLRUCache(80)
	for _, k := range testKeys {
		c.Put(k)
		gc.Put(k)
	}
	type stats struct {
		hits   int
		misses int
	}
	var cs stats
	var gcs stats
	for i := 0; i < 100; i++ {
		for _, k := range testKeys {
			if c.Get(k) {
				cs.hits++
			} else {
				cs.misses++
				c.Put(k)
			}
			if gc.Get(k) {
				gcs.hits++
			} else {
				gcs.misses++
				gc.Put(k)
			}
		}
	}
	chr := float64(cs.hits) / float64(cs.hits+cs.misses)
	gchr := float64(gcs.hits) / float64(gcs.hits+gcs.misses)
	ratio := chr / gchr
	if ratio > 1/8 {
		t.Errorf("unexpected hit rate, gchr want 1 got %f, chr want max 1/8 got %f", gchr, chr)
	}
}

func TestFindCollisions(t *testing.T) {
	c := NewLocalHashedLRUCache(80, 8)
	t.Logf("localCap: %d", c.nodes[0].cap)
	collisions := findCollisions(c, 0, 9)
	testKeys := []int64{0}
	testKeys = append(testKeys, collisions...)
	gc := NewLRUCache(80)
	for _, k := range testKeys {
		c.Put(k)
		gc.Put(k)
	}
	type stats struct {
		hits   int
		misses int
	}
	var cs stats
	var gcs stats
	for i := 0; i < 100; i++ {
		for _, k := range testKeys {
			if c.Get(k) {
				cs.hits++
			} else {
				cs.misses++
				c.Put(k)
			}
			if gc.Get(k) {
				gcs.hits++
			} else {
				gcs.misses++
				gc.Put(k)
			}
		}
	}
	chr := float64(cs.hits) / float64(cs.hits+cs.misses)
	gchr := float64(gcs.hits) / float64(gcs.hits+gcs.misses)
	if chr != 1 {
		t.Errorf("chr: want hit rate of 1 got %f", chr)
	}
	if gchr != 1 {
		t.Errorf("gchr: want hit rate of 1 got %f", gchr)
	}
	lens := make([]int, 0, 8)
	for _, n := range c.nodes {
		lens = append(lens, n.len)
	}
	sort.Ints(lens)
	if !reflect.DeepEqual(lens, []int{0, 0, 0, 0, 0, 0, 0, 10}) {
		t.Errorf("expected just one node to contain entries: got entry lens: %v", lens)
	}
}
