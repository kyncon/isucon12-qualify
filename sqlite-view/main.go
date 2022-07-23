package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
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
	for query, dataList := range dataList {
		fmt.Printf("%s, %d, %f\n", query, count(dataList), average(dataList))
	}

	return nil
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
