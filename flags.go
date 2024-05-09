package main

import (
	"flag"
	"time"
)

var (
	flagProjectName string
	flagParameter   string
	flagSecure      bool
)

func init() {
	flag.StringVar(&flagProjectName, "name", "", "ProjectName")
	flag.StringVar(&flagParameter, "parameter", "", "CS2 Parameter (comma separated)")
	flag.BoolVar(&flagSecure, "secure", false, "remove -insecure parameter to cs2")

	if flagProjectName == "" {
		flagProjectName = time.Now().Format("020106150405")
	}

	flag.Parse()
}
