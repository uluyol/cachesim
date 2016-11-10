package main

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"sort"
	"sync"
	"time"

	"github.com/gocql/gocql"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/uluyol/cachesim/cmd/notswissbench/intgen"
)

func mkTable(cluster *gocql.ClusterConfig) error {
	session, err := cluster.CreateSession()
	if err != nil {
		return err
	}
	q := session.Query("CREATE KEYSPACE notswissbench WITH REPLICATION =" +
		"{'class': 'SimpleStrategy', 'replication_factor': 3}")
	if err := q.Exec(); err != nil {
		return errors.Wrap(err, "unable to create keyspace notswissbench")
	}
	q = session.Query("CREATE table notswissbench.udata (vkey varchar primary key, vval varchar)")
	if err := q.Exec(); err != nil {
		return errors.Wrap(err, "unable to create table notswissbench.udata")
	}
	return nil
}

var rootCmd = &cobra.Command{
	Use:   "notswissbench",
	Short: "Not a swiss army knife benchmark",
	Long:  "Used for certain things.",
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		cluster = gocql.NewCluster(hosts...)
		cluster.ProtoVersion = 4
		cluster.RetryPolicy = &gocql.SimpleRetryPolicy{NumRetries: numRetries}
		cluster.Timeout = timeout
		cluster.NumConns = numConns

		var err error
		readConsistency, err = parseConsistency(readConsistencyStr)
		if err != nil {
			return err
		}
		writeConsistency, err = parseConsistency(writeConsistencyStr)
		if err != nil {
			return err
		}

		switch cmd.Use {
		case "load", "run":
			cluster.Keyspace = "notswissbench"
		}
		return nil
	},
}

func parseConsistency(s string) (c gocql.Consistency, err error) {
	defer func() {
		if e := recover(); e != nil {
			if er, ok := e.(error); ok {
				err = er
				return
			}
			panic(e)
		}
	}()
	return gocql.ParseConsistency(s), nil
}

var mkTableCmd = &cobra.Command{
	Use:   "mktable",
	Short: "Create keyspace and table",
	RunE: func(cmd *cobra.Command, args []string) error {
		session, err := cluster.CreateSession()
		if err != nil {
			return err
		}
		defer session.Close()
		qstring := fmt.Sprintf(
			"CREATE KEYSPACE notswissbench "+
				"WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': %d}",
			replicationFactor)
		q := session.Query(qstring)
		if err := q.Exec(); err != nil {
			return errors.Wrap(err, "unable to create keyspace notswissbench")
		}
		qstring = fmt.Sprintf(
			"CREATE table notswissbench.udata"+
				"(vkey varchar primary key, vval varchar) "+
				"WITH compaction = {'class': '%s'} AND caching = {'keys': '%s'}",
			compactionStrategy, keyCaching)
		q = session.Query(qstring)
		if err := q.Exec(); err != nil {
			return errors.Wrap(err, "unable to create table notswissbench.udata")
		}
		return nil
	},
}

type counter struct {
	mu sync.Mutex
	c  int64
}

func (c *counter) getAndInc() int64 {
	c.mu.Lock()
	v := c.c
	c.c++
	c.mu.Unlock()
	return v
}

var loadCmd = &cobra.Command{
	Use:   "load",
	Short: "Load data into cassandra",
	RunE: func(cmd *cobra.Command, args []string) error {
		keyGen := StringGen{
			G:    intgen.NewSync(&intgen.Counter{Count: loadStart}),
			SLen: keySize,
		}
		valueGen := NewValueGen(rand.NewSource(genSeed), valSize)

		session, err := cluster.CreateSession()
		if err != nil {
			return err
		}
		defer session.Close()
		session.SetConsistency(writeConsistency)
		var wg sync.WaitGroup
		ec := make(chan error, workerCount)
		opCount := &counter{}
		for w := 0; w < workerCount; w++ {
			wg.Add(1)
			go func() {
				q := session.Query("INSERT INTO udata (vkey, vval) VALUES (?, ?)")
				if loadCount == -1 {
					loadCount = recordCount
				}
			Outer:
				for i := opCount.getAndInc(); i < loadCount; i = opCount.getAndInc() {
					key := keyGen.next()
					val := valueGen.next()
				Inner:
					for retry := 0; retry < 10; retry++ {
						err := q.Bind(key, val).Exec()
						switch err {
						case nil:
							break Inner
						case gocql.ErrNoConnections:
							// retry
						default:
							ec <- errors.Wrapf(err, "failed to execute insert %d", i)
							break Outer
						}
					}
				}
				wg.Done()
			}()
		}
		wg.Wait()
		select {
		case err := <-ec:
			return errors.Wrapf(err, "encountered error")
		default:
		}
		return nil
	},
}

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run workload",
	RunE: func(cmd *cobra.Command, args []string) error {
		keyGen := StringGen{
			G:    intgen.NewSync(intgen.NewMapScrambledZipfian(rand.NewSource(genSeed), recordCount, zfTheta)),
			SLen: keySize,
		}

		session, err := cluster.CreateSession()
		if err != nil {
			return err
		}
		defer session.Close()
		session.SetConsistency(readConsistency)
		var wg sync.WaitGroup
		ec := make(chan error, workerCount)
		opCount := &counter{}
		for w := 0; w < workerCount; w++ {
			wg.Add(1)
			go func() {
				q := session.Query("SELECT vval FROM udata WHERE vkey = ?")
				var data []byte
			Outer:
				for i := opCount.getAndInc(); i < operationCount; i = opCount.getAndInc() {
					key := keyGen.next()
				Inner:
					for retry := 0; retry < 10; retry++ {
						err := q.Bind(key).Scan(&data)
						switch err {
						case nil:
							break Inner
						case gocql.ErrNoConnections:
							// retry
						default:
							ec <- errors.Wrapf(err, "failed to execute read %d", i)
							break Outer
						}
					}
				}
				wg.Done()
			}()
		}
		wg.Wait()
		select {
		case err := <-ec:
			return errors.Wrapf(err, "encountered error")
		default:
		}
		return nil
	},
}

var replayCmd = &cobra.Command{
	Use:   "replay",
	Short: "Replay execution",
	RunE: func(cmd *cobra.Command, args []string) error {
		const fudgeFactor = 4

		g := intgen.NewMapScrambledZipfian(rand.NewSource(genSeed), recordCount, zfTheta)

		if replayNLast < 0 {
			for i := int64(0); i < operationCount; i++ {
				fmt.Println(formatKeyName(g.Next(), keySize))
			}
			return nil
		}

		lastKeys := make([]int64, 0, fudgeFactor*replayNLast)
		for i := int64(0); i < operationCount; i++ {
			n := g.Next()
			if i >= operationCount-fudgeFactor*replayNLast {
				lastKeys = append(lastKeys, n)
			}
		}

		seen := make(map[int64]bool)
		printed := int64(0)
		for i := len(lastKeys) - 1; i >= 0 && printed < replayNLast; i-- {
			n := lastKeys[i]
			if !seen[n] {
				fmt.Println(formatKeyName(n, keySize))
				seen[n] = true
				printed++
			}
		}

		if printed < replayNLast {
			return errors.Errorf("unable to produce enough keys, have %d/%d (increase fudge factor)", printed, replayNLast)
		}
		return nil
	},
}

func getGen() (intgen.DistGen, error) {
	rsrc := rand.NewSource(genSeed)
	switch genType {
	case "uniform":
		return intgen.NewUniform(rsrc, recordCount), nil
	case "linear":
		return intgen.NewLinear(rsrc, recordCount), nil
	case "linstep":
		return intgen.NewLinearStep(rsrc, recordCount, linSteps), nil
	case "zipfian":
		return &intgen.ObservingDistGen{
			G: intgen.NewMapScrambledZipfian(rsrc, recordCount, zfTheta),
			N: recordCount,
		}, nil
	case "skzipfian":
		return &intgen.ObservingDistGen{
			G: intgen.NewSimpleZipfian(rsrc, recordCount, zfTheta),
			N: recordCount,
		}, nil
	case "zfswitch":
		zfg := intgen.NewMapScrambledZipfian(rsrc, recordCount, zfTheta)
		return &intgen.ObservingDistGen{
			G: intgen.NewSwitching(zfg, rsrc, 0, recordCount, changingProb),
			N: recordCount,
		}, nil
	case "changing":
		return &intgen.ObservingDistGen{
			G: intgen.NewChangingZipfian(rsrc, recordCount, zfTheta, changingN, changingProb),
			N: recordCount,
		}, nil
	default:
		return nil, fmt.Errorf("invalid generator %q: must be uniform, linear, linstep, skzipfian, zipfian, zfswitch, or changing", genType)
	}
}

var lruHitrateCmd = &cobra.Command{
	Use:   "lru-hitrate",
	Short: "Calculate hit rate of an lru of the provided size",
	RunE: func(cmd *cobra.Command, args []string) error {
		g, err := getGen()
		if err != nil {
			return err
		}

		var cache Cache
		switch cacheType {
		case "global":
			cache = NewLRUCache(lruCacheSize)
		case "localHashed":
			cache = NewLocalHashedLRUCache(lruCacheSize, numNodes)
		case "cassandra":
			cache = NewCassandraCache(lruCacheSize, numNodes)
		case "sharded":
			cache = NewLocalShardedLRUCache(lruCacheSize, numNodes, recordCount)
		default:
			return fmt.Errorf("invalid cache type %q: must be global, localHashed, sharded, or cassandra", cacheType)
		}

		var i int64
		for !cache.IsFull() {
			cache.Put(g.Next())
			i++
		}

		if 0 < warmupCount && warmupCount < i {
			fmt.Fprintf(os.Stderr, "warn: warmup of %d ops insufficient, need %d ops\n", warmupCount, i)
		}

		for ; i < warmupCount; i++ {
			cache.Put(g.Next())
		}

		var hits int64
		for i := int64(0); i < operationCount; i++ {
			k := g.Next()
			if cache.Get(k) {
				hits++
			} else {
				cache.Put(k)
			}
		}

		fmt.Printf("HitRate: %d/%d %f\n", hits, operationCount, float64(hits)/float64(operationCount))
		fmt.Printf("CumReqs: %s\n", Int64Join(cache.CumReqs(), ","))
		fmt.Printf("CumProbs: %s\n", Float64Join(cache.CumProbs(g.ProbOf), ","))
		sectionCumProbs := cache.SectionCumProbs(3, g.ProbOf)
		for i := range sectionCumProbs {
			fmt.Printf("SectionCumProbs: %d_%d %s\n", i, len(sectionCumProbs), Float64Join(sectionCumProbs[i], ","))
		}
		return nil
	},
}

var warmupLenCmd = &cobra.Command{
	Use:   "warmup-len",
	Short: "Calculate the number of requests needed to warmup an lru of the provided size",
	Run: func(cmd *cobra.Command, args []string) {
		g := intgen.NewMapScrambledZipfian(rand.NewSource(genSeed), recordCount, zfTheta)

		cache := NewLRUCache(lruCacheSize)

		var nops int64
		for !cache.IsFull() {
			cache.Put(g.Next())
			nops++
		}
		fmt.Println(nops)
	},
}

type hitPair struct {
	key  int64
	hits int32
}

type byHits []hitPair

func (s byHits) Len() int      { return len(s) }
func (s byHits) Swap(i, j int) { s[i], s[j] = s[j], s[i] }

func (s byHits) Less(i, j int) bool {
	if s[i].hits == s[j].hits {
		return s[i].key < s[j].key
	}
	return s[i].hits < s[j].hits
}

var histCmd = &cobra.Command{
	Use:   "hist",
	Short: "Output histogram of keys",
	RunE: func(cmd *cobra.Command, args []string) error {

		g, err := getGen()
		if err != nil {
			return err
		}

		hitMap := make([]int32, recordCount)

		for i := int64(0); i < operationCount; i++ {
			k := g.Next()
			hitMap[int(k)] += 1
		}

		var hist []hitPair
		for key, hits := range hitMap {
			hist = append(hist, hitPair{int64(key), hits})
		}
		sort.Sort(byHits(hist))
		for _, p := range hist {
			fmt.Printf("%d,%d\n", p.key, p.hits)
		}
		return nil
	},
}

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Cleanup all data put into cassandra",
	RunE: func(cmd *cobra.Command, arg []string) error {
		session, err := cluster.CreateSession()
		if err != nil {
			return err
		}
		defer session.Close()
		return session.Query("DROP KEYSPACE notswissbench").Exec()
	},
}

var (
	cluster *gocql.ClusterConfig

	// global flags
	hosts               []string
	numConns            int
	timeout             time.Duration
	numRetries          int
	recordCount         int64
	keySize, valSize    int
	operationCount      int64
	genSeed             int64
	readConsistencyStr  string
	writeConsistencyStr string
	readConsistency     gocql.Consistency
	writeConsistency    gocql.Consistency
	workerCount         int
	zfTheta             float64
	lruCacheSize        int
	genType             string
	changingN           int
	changingProb        float32
	linSteps            int64

	// mktable flags
	replicationFactor  int
	keyCaching         string
	compactionStrategy string

	// load flags
	loadStart int64
	loadCount int64

	// replay flag
	replayNLast int64

	// lru-hitrate flags
	warmupCount int64
	cacheType   string
	numNodes    int
)

func main() {
	log.SetPrefix("notswissbench: ")
	log.SetFlags(0)

	pflags := rootCmd.PersistentFlags()
	pflags.StringSliceVar(&hosts, "hosts", []string{"127.0.0.1"}, "addresses of cassandra nodes")
	pflags.DurationVar(&timeout, "timeout", 5*time.Second, "request timeout")
	pflags.IntVar(&numRetries, "retries", 10, "number of retries for a request")
	pflags.Int64Var(&recordCount, "records", 100, "number of records in the db")
	pflags.IntVar(&keySize, "keysize", 50, "size of generated keys in bytes")
	pflags.IntVar(&valSize, "valsize", 1000, "size of values in bytes")
	pflags.Int64Var(&operationCount, "ops", 10, "number of operations to do")
	pflags.Int64Var(&genSeed, "seed", 123234975361, "seed for zipfian generator")
	pflags.StringVar(&readConsistencyStr, "readc", "QUORUM", "read consistency level")
	pflags.StringVar(&writeConsistencyStr, "writec", "QUORUM", "write consistency level")
	pflags.IntVar(&workerCount, "workers", 1, "number of worker goroutines")
	pflags.IntVar(&numConns, "conns", 20, "number of connections per host")
	pflags.Float64Var(&zfTheta, "zftheta", 0.99, "zipfian theta parameter")
	pflags.IntVar(&lruCacheSize, "cache-size", 0, "size of lru cache (for lru-hitrate and warmup-len)")
	pflags.StringVar(&genType, "generator", "zipfian", "kind of generator (uniform, zipfian, changing, linear, linstep, skzipfian, zfswitch)")
	pflags.IntVar(&changingN, "changing-n", 1000, "changing generator: switch up map every n requests")
	pflags.Float32Var(&changingProb, "changing-prob", 0.2, "changing, zfswitch generators: probability that an entry will be selected to change")
	pflags.Int64Var(&linSteps, "steps", 3, "linstep generator: number of steps to have")

	mkTableCmd.Flags().IntVar(&replicationFactor, "replication", 3, "cassandra replication factor")
	mkTableCmd.Flags().StringVar(&keyCaching, "key-caching", "ALL", "key caching policy")
	mkTableCmd.Flags().StringVar(&compactionStrategy, "compaction", "LeveledCompactionStrategy", "compaction strategy")

	loadCmd.Flags().Int64Var(&loadStart, "loadstart", 0, "what index to start loading from (use to load from multiple clients)")
	loadCmd.Flags().Int64Var(&loadCount, "loadcount", -1, "how many keys to insert (use to load from multiple clients), -1 is all")

	replayCmd.Flags().Int64Var(&replayNLast, "nlast", -1, "get last n keys read (-1 for all)")

	lruHitrateCmd.Flags().Int64Var(&warmupCount, "warmup-ops", 0, "number of warmup ops")
	lruHitrateCmd.Flags().StringVar(&cacheType, "cache-type", "global", "cache type to simulate (global, localHashed, sharded, or cassandra)")
	lruHitrateCmd.Flags().IntVar(&numNodes, "node-count", 1, "number of nodes to simulate (does not apply for global)")

	rootCmd.AddCommand(mkTableCmd)
	rootCmd.AddCommand(loadCmd)
	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(replayCmd)
	rootCmd.AddCommand(cleanupCmd)
	rootCmd.AddCommand(lruHitrateCmd)
	rootCmd.AddCommand(histCmd)
	rootCmd.AddCommand(warmupLenCmd)

	if err := rootCmd.Execute(); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}
