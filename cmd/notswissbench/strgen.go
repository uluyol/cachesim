package main

import (
	"math/rand"
	"strconv"
	"sync"

	"github.com/uluyol/cachesim/cmd/notswissbench/internal/fnv"
	"github.com/uluyol/cachesim/cmd/notswissbench/intgen"
)

type StringGen struct {
	G intgen.Gen

	// desired string length, will be ':' padded
	// should be long enough to fit 3 64-bit ints
	// encoded in base36 (i.e. >= 39)
	SLen int
}

func (g StringGen) next() string {
	return formatKeyName(g.G.Next(), g.SLen)
}

var fmtBufPool = sync.Pool{
	New: func() interface{} { return make([]byte, 1024) },
}

func formatKeyName(v int64, keySize int) string {
	s := strconv.FormatInt(fnv.Hash64(v), 36)
	s2 := strconv.FormatInt(fnv.Hash64(v+1), 36)
	s3 := strconv.FormatInt(fnv.Hash64(v+2), 36)

	buf := fmtBufPool.Get().([]byte)
	if cap(buf) < keySize {
		buf = make([]byte, keySize)
	}
	buf = buf[0:keySize]

	for i := range buf {
		buf[i] = ':'
	}
	off := len(buf) - len(s)
	for i := 0; i < len(s); i++ {
		buf[off+i] = s[i]
	}
	off = off - len(s2)
	for i := 0; i < len(s2); i++ {
		buf[off+i] = s2[i]
	}
	off = off - len(s3)
	for i := 0; i < len(s3); i++ {
		buf[off+i] = s3[i]
	}

	ret := string(buf)
	fmtBufPool.Put(buf)

	return ret
}

type ValueGen struct {
	mu   sync.Mutex
	buf  []byte
	rand *rand.Rand
}

func NewValueGen(src rand.Source, size int) *ValueGen {
	return &ValueGen{
		buf:  make([]byte, size),
		rand: rand.New(src),
	}
}

func (g *ValueGen) next() string {
	g.mu.Lock()
	defer g.mu.Unlock()
	for i := range g.buf {
		g.buf[i] = randStringVals[g.rand.Intn(len(randStringVals))]
	}
	return string(g.buf)
}

var randStringVals = []byte("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
