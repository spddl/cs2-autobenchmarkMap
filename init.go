package main

import (
	"log"
	"os"
	"path/filepath"
)

var AppFolder string

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	executable, err := os.Executable()
	if err != nil {
		panic(err)
	}
	AppFolder = filepath.Dir(executable)
}
