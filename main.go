package main

import (
	"bufio"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Container struct {
	SteamPath string
	Cs2Path   string

	vprof []string

	loadChan     chan bool
	vprofSummary chan string
}

func main() {
	c := new(Container)

	if err := c.GetSteamPath(); err != nil {
		panic(err)
	}

	if err := c.GetCs2Path(); err != nil {
		panic(err)
	}

	c.loadChan = make(chan bool, 1)
	c.vprofSummary = make(chan string)
	go c.tailConsoleLog()

	c.startBenchmarkMap(flagProjectName, flagSecure)
}

func (c *Container) tailConsoleLog() {
	consoleFile := filepath.Join(c.Cs2Path, "console.log")
	os.WriteFile(consoleFile, []byte{10}, 0644) // Clearing the console.log

	t, err := newTailReader(consoleFile)
	if err != nil {
		log.Fatal(err)
	}
	defer t.Close()

	scanner := bufio.NewScanner(t)
	for scanner.Scan() {
		line := scanner.Text()
		switch {
		case strings.Contains(line, "[VProf] VProfLite started."):
			c.vprof = []string{}
			c.loadChan <- true

		case strings.Contains(line, "[VProf]"):
			_, after, _ := strings.Cut(line, "[VProf]")
			c.vprof = append(c.vprof, after)

		case strings.Contains(line, "[VProf] VProfLite stopped.") || strings.Contains(line, "[Server] SV:  Server shutting down"):
			c.vprofSummary <- strings.Join(c.vprof, "\n")

		default:
			// log.Println("CONSOLE:", line)
		}
	}
	if err := scanner.Err(); err != nil {
		if err := os.Remove(consoleFile); err != nil {
			panic(err)
		}
		c.tailConsoleLog()
	}
}

type tailReader struct { // https://stackoverflow.com/a/31122253
	io.ReadCloser
}

func (t tailReader) Read(b []byte) (int, error) {
	for {
		n, err := t.ReadCloser.Read(b)
		if n > 0 {
			return n, nil
		} else if err != io.EOF {
			return n, err
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func newTailReader(fileName string) (tailReader, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return tailReader{}, err
	}

	if _, err := f.Seek(0, 2); err != nil {
		return tailReader{}, err
	}
	return tailReader{f}, nil
}
