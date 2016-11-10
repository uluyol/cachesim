package main

import "testing"

func TestLRUCache(t *testing.T) {
	tests := []struct {
		cap    int
		items  []int64
		has    []int64
		notHas []int64
	}{
		{0, []int64{1, 1, 2}, nil, []int64{1, 2}},
		{1, []int64{1, 1, 2}, []int64{2}, []int64{1}},
		{1, []int64{1, 2, 1}, []int64{1}, []int64{2}},
		{4, []int64{1, 2, 3, 1, 1, 4, 5}, []int64{5, 4, 1, 3}, []int64{2}},
		{10, []int64{1, 1, 1, 2, 3, 4, 5, 2, 6, 7, 8, 2, 9, 10, 2, 11, 12, 13, 2}, []int64{2, 13, 12, 11, 10, 9, 8, 7, 6, 5}, []int64{4, 3, 1}},
	}

	for i, test := range tests {
		c := NewLRUCache(test.cap)
		for _, it := range test.items {
			c.Put(it)
		}
		for _, it := range test.has {
			if !c.Has(it) {
				t.Errorf("cas %d: want %d", i, it)
			}
		}
		for _, it := range test.notHas {
			if c.Has(it) {
				t.Errorf("case %d: don't want %d", i, it)
			}
		}
	}
}
