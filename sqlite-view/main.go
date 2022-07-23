package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"sort"
	"time"
)

func main() {
	args := os.Args
	if len(args) == 1 {
		fmt.Fprintln(os.Stderr, "You should set args")
		os.Exit(1)
	}

	if err := run(args[1]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v", err)
		os.Exit(1)
	}
}

type data struct {
	Time      time.Time `json:"time"`
	Statement string    `json:"statement"`
	// Args         []string  `json:"args"`
	QueryTime    float64 `json:"query_time"`
	AffectedRows int     `json:"affected_rows"`
}

func run(file string) error {
	f, err := os.Open(file)
	if err != nil {
		return err
	}
	defer f.Close()

	sc := bufio.NewScanner(f)
	sc.Split(bufio.ScanLines)

	dataList := make(map[string][]data)
	for sc.Scan() {
		var d data
		err := json.Unmarshal(sc.Bytes(), &d)
		if err != nil {
			return err
		}
		dataList[d.Statement] = append(dataList[d.Statement], d)
	}

	fmt.Println("statement, count, average")
	type result struct {
		query   string
		count   int
		average float64
	}
	results := make([]result, 0, len(dataList))
	for query, dataList := range dataList {
		results = append(results, result{
			query:   query,
			count:   count(dataList),
			average: average(dataList),
		})
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].average > results[j].average
	})

	for _, res := range results {
		fmt.Printf("%s, %i, %f\n", res.query, res.count, res.average)
	}

	return nil
}

var re = regexp.MustCompile("(\\?, )+")

func parseQuery(query string) string {
	return string(re.ReplaceAll([]byte(query), []byte("(?)")))
}

func average(dataList []data) float64 {
	return sum(dataList) / float64(count(dataList))
}

func sum(dataList []data) float64 {
	s := 0.
	for _, d := range dataList {
		s += d.QueryTime
	}
	return s
}

func count(dataList []data) int {
	return len(dataList)
}
