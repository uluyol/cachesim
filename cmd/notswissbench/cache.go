package main

import (
	"container/list"
	"hash"
	"hash/fnv"
	"math/rand"
)

type Cache interface {
	Has(k int64) bool
	Get(k int64) bool
	Put(k int64)
	IsFull() bool
	CumReqs() []int64
	CumProbs(probOf func(k int64) float64) []float64
	SectionCumProbs(nsection int, probOf func(k int64) float64) [][]float64
}

type LocalShardedLRUCache struct {
	nrec  int64
	nodes []*LRUCache
}

func NewLocalShardedLRUCache(cap, numNodes int, numRecs int64) *LocalShardedLRUCache {
	localCap := cap / numNodes
	ns := make([]*LRUCache, numNodes)
	for i := range ns {
		ns[i] = NewLRUCache(localCap)
	}
	return &LocalShardedLRUCache{
		nrec:  numRecs,
		nodes: ns,
	}
}

func (c *LocalShardedLRUCache) ni(k int64) int {
	return int(k * int64(len(c.nodes)) / c.nrec)
}

func (c *LocalShardedLRUCache) Get(k int64) bool { return c.nodes[c.ni(k)].Get(k) }
func (c *LocalShardedLRUCache) Has(k int64) bool { return c.nodes[c.ni(k)].Get(k) }
func (c *LocalShardedLRUCache) Put(k int64)      { c.nodes[c.ni(k)].Put(k) }

func (c *LocalShardedLRUCache) IsFull() bool {
	for _, n := range c.nodes {
		if !n.IsFull() {
			return false
		}
	}
	return true
}

func (c *LocalShardedLRUCache) CumReqs() []int64 {
	reqs := make([]int64, len(c.nodes))
	for i, n := range c.nodes {
		reqs[i] = n.CumReqs()[0]
	}
	return reqs
}

func (c *LocalShardedLRUCache) CumProbs(probOf func(k int64) float64) []float64 {
	probs := make([]float64, len(c.nodes))
	for i, n := range c.nodes {
		probs[i] = n.CumProbs(probOf)[0]
	}
	return probs
}

func (c *LocalShardedLRUCache) SectionCumProbs(nsection int, p func(k int64) float64) [][]float64 {
	return allSectionCumProbs(c.nodes, nsection, p)
}

type LocalHashedLRUCache struct {
	hash  hash.Hash32
	nodes []*LRUCache
}

func NewLocalHashedLRUCache(cap, numNodes int) *LocalHashedLRUCache {
	localCap := cap / numNodes
	ns := make([]*LRUCache, numNodes)
	for i := range ns {
		ns[i] = NewLRUCache(localCap)
	}
	return &LocalHashedLRUCache{
		hash:  fnv.New32(),
		nodes: ns,
	}
}

func (c *LocalHashedLRUCache) ni(k int64) int {
	b := [8]byte{
		byte(k),
		byte(k >> 8),
		byte(k >> 16),
		byte(k >> 24),
		byte(k >> 32),
		byte(k >> 40),
		byte(k >> 48),
		byte(k >> 56),
	}
	c.hash.Write(b[:])
	index := int(c.hash.Sum32()) % len(c.nodes)
	c.hash.Reset()
	return int(index)
}

func (c *LocalHashedLRUCache) Get(k int64) bool { return c.nodes[c.ni(k)].Get(k) }
func (c *LocalHashedLRUCache) Has(k int64) bool { return c.nodes[c.ni(k)].Has(k) }
func (c *LocalHashedLRUCache) Put(k int64)      { c.nodes[c.ni(k)].Put(k) }

func (c *LocalHashedLRUCache) IsFull() bool {
	for _, n := range c.nodes {
		if !n.IsFull() {
			return false
		}
	}
	return true
}

func (c *LocalHashedLRUCache) CumReqs() []int64 {
	reqs := make([]int64, len(c.nodes))
	for i, n := range c.nodes {
		reqs[i] = n.CumReqs()[0]
	}
	return reqs
}

func (c *LocalHashedLRUCache) CumProbs(probOf func(k int64) float64) []float64 {
	probs := make([]float64, len(c.nodes))
	for i, n := range c.nodes {
		probs[i] = n.CumProbs(probOf)[0]
	}
	return probs
}

func (c *LocalHashedLRUCache) SectionCumProbs(nsection int, p func(k int64) float64) [][]float64 {
	return allSectionCumProbs(c.nodes, nsection, p)
}

type CassandraCache struct {
	rng   *rand.Rand
	hash  hash.Hash32
	nodes []*LRUCache
}

func NewCassandraCache(cap, numNodes int) *CassandraCache {
	localCap := cap / numNodes
	ns := make([]*LRUCache, numNodes)
	for i := range ns {
		ns[i] = NewLRUCache(localCap)
	}
	return &CassandraCache{
		rng:   rand.New(rand.NewSource(0)),
		hash:  fnv.New32(),
		nodes: ns,
	}
}

func (c *CassandraCache) nis(k int64) [3]int {
	b := [8]byte{
		byte(k),
		byte(k >> 8),
		byte(k >> 16),
		byte(k >> 24),
		byte(k >> 32),
		byte(k >> 40),
		byte(k >> 48),
		byte(k >> 56),
	}
	c.hash.Write(b[:])
	index := int(c.hash.Sum32()) % len(c.nodes)
	c.hash.Reset()
	return [3]int{
		index,
		(index + 1) % len(c.nodes),
		(index + 2) % len(c.nodes),
	}
}

func (c *CassandraCache) Get(k int64) bool {
	nis := c.nis(k)
	i := nis[c.rng.Intn(len(nis))]
	return c.nodes[i].Get(k)
}

func (c *CassandraCache) Has(k int64) bool {
	nis := c.nis(k)
	i := nis[c.rng.Intn(len(nis))]
	return c.nodes[i].Has(k)
}

func (c *CassandraCache) Put(k int64) {
	nis := c.nis(k)
	i := nis[c.rng.Intn(len(nis))]
	c.nodes[i].Put(k)
}

func (c *CassandraCache) IsFull() bool {
	for _, n := range c.nodes {
		if !n.IsFull() {
			return false
		}
	}
	return true
}

func (c *CassandraCache) CumReqs() []int64 {
	reqs := make([]int64, len(c.nodes))
	for i, n := range c.nodes {
		reqs[i] = n.CumReqs()[0]
	}
	return reqs
}

func (c *CassandraCache) CumProbs(probOf func(k int64) float64) []float64 {
	probs := make([]float64, len(c.nodes))
	for i, n := range c.nodes {
		probs[i] = n.CumProbs(probOf)[0]
	}
	return probs
}

func (c *CassandraCache) SectionCumProbs(nsection int, p func(k int64) float64) [][]float64 {
	return allSectionCumProbs(c.nodes, nsection, p)
}

type CacheVal struct {
	key int64
}

type LRUCache struct {
	kmap map[int64]*list.Element
	list list.List
	len  int
	cap  int

	reqs int64
}

func NewLRUCache(cap int) *LRUCache {
	return &LRUCache{
		kmap: make(map[int64]*list.Element),
		cap:  cap,
	}
}

func (c *LRUCache) Get(k int64) bool {
	c.reqs++
	if e, ok := c.kmap[k]; ok {
		c.list.MoveToFront(e)
		return true
	}
	return false
}

func (c *LRUCache) Has(k int64) bool {
	_, ok := c.kmap[k]
	return ok
}

func (c *LRUCache) Put(k int64) {
	if e, ok := c.kmap[k]; ok {
		c.list.MoveToFront(e)
		return
	}
	if c.len < c.cap {
		c.kmap[k] = c.list.PushFront(CacheVal{k})
		c.len++
		return
	}
	if c.cap == 0 {
		return
	}
	e := c.list.Back()
	delete(c.kmap, e.Value.(CacheVal).key)
	e.Value = CacheVal{k}
	c.kmap[k] = e
	c.list.MoveToFront(e)
}

func (c *LRUCache) IsFull() bool {
	return c.len == c.cap
}

func (c *LRUCache) CumReqs() []int64 {
	return []int64{c.reqs}
}

func (c *LRUCache) CumProbs(probOf func(k int64) float64) []float64 {
	var sum float64
	for k := range c.kmap {
		sum += probOf(k)
	}
	return []float64{sum}
}

func (c *LRUCache) SectionCumProbs(nsection int, probOf func(k int64) float64) [][]float64 {
	sums := make([][]float64, nsection)
	for i := range sums {
		sums[i] = []float64{0}
	}
	llen := c.list.Len()
	for i, e := 0, c.list.Front(); e != nil; i, e = i+1, e.Next() {
		sums[nsection*i/llen][0] += probOf(e.Value.(CacheVal).key)
	}
	return sums
}

func combineSections(all [][][]float64) [][]float64 {
	if len(all) == 0 {
		return nil
	}
	combined := make([][]float64, len(all[0]))
	for i := range combined {
		combined[i] = make([]float64, len(all))
	}
	for i, nodeSections := range all {
		for j := range nodeSections {
			if len(nodeSections[j]) > 1 {
				panic("input contains more than singleton node values")
			}
			combined[j][i] = nodeSections[j][0]
		}
	}
	return combined
}

func allSectionCumProbs(nodes []*LRUCache, nsection int, probOf func(k int64) float64) [][]float64 {
	all := make([][][]float64, len(nodes))
	for i := range nodes {
		all[i] = nodes[i].SectionCumProbs(nsection, probOf)
	}
	return combineSections(all)
}
