package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/micmonay/keybd_event"
	"golang.org/x/sys/windows"
)

func (c *Container) startBenchmarkMap(projectName string, secure bool) {
	csParameter := []string{"+map de_dust2_benchmark customgamemode=3240880604 nomapvalidation=true"}
	// csParameter := []string{"+map de_dust2"}
	if !secure {
		csParameter = append(csParameter, "-insecure")
	}
	if flagParameter != "" {
		csParameter = append(csParameter, strings.Split(flagParameter, " ")...)
	}
	c.startCS(csParameter)

	select {
	case <-c.loadChan:
		if err := PressAnyKey(keybd_event.VK_E); err != nil {
			log.Println(err)
		}

	case <-time.After(5 * time.Minute):
		panic("TimeOut, CS Map not loaded")
	}

	// log.Println("time.Sleep(time.Hour)")
	// time.Sleep(time.Hour)

	// output folder
	if _, err := os.Stat(filepath.Join(AppFolder, "output")); os.IsNotExist(err) {
		os.Mkdir(filepath.Join(AppFolder, "output"), os.ModePerm)
	}

	// PresentMon
	StartPresentMon(filepath.Join("output", fmt.Sprintf("%s.csv", projectName)), 105)

	select {
	case slice := <-c.vprofSummary:
		// Map finished

		c.WriteFile(filepath.Join(AppFolder, "output", fmt.Sprintf("%s_vprov.log", projectName)), slice)

	case <-time.After(3 * time.Minute):
		panic("TimeOut")
	}

	// CS2
	if pid, err := ProcessNameExist("cs2.exe"); err != nil {
		log.Println(err)
	} else {
		terminateProcess(int(pid), 0)
	}
}

func StartPresentMon(filename string, duration float64) int {
	// https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md
	cmd := exec.Command(filepath.Join(AppFolder, "PresentMon.exe"),
		"--no_console_stats",
		"--stop_existing_session",
		"--delay", "5",
		"--timed", fmt.Sprintf("%g", duration),
		"--terminate_after_timed",
		"--process_name", "cs2.exe",
		"--output_file", filepath.Join(AppFolder, filename),
	)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}

	/// Debuging
	// log.Println(Green, "Start PresentMon", Reset)
	// go func(duration float64) {
	// 	time.Sleep(5 * time.Second)
	// 	log.Println(Red, "Start Recording", Reset)
	// 	time.Sleep(time.Duration(duration) * time.Second)
	// 	log.Println(Red, "Stop Recording", Reset)
	// }(duration)

	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}

	// log.Println(Green, "Stop PresentMon", Reset)
	return cmd.Process.Pid
}

func terminateProcess(pid, exitcode int) error {
	h, e := syscall.OpenProcess(syscall.PROCESS_TERMINATE, false, uint32(pid))
	if e != nil {
		return fmt.Errorf("openProcess %s", e)
	}
	defer syscall.CloseHandle(h)
	e = syscall.TerminateProcess(h, uint32(exitcode))
	return fmt.Errorf("terminateProcess %s", e)
}

const processEntrySize = 568 // unsafe.Sizeof(windows.ProcessEntry32{})

func ProcessNameExist(name string) (uint32, error) {
	h, e := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if e != nil {
		return 0, e
	}
	p := windows.ProcessEntry32{Size: processEntrySize}
	for {
		e := windows.Process32Next(h, &p)
		if e != nil {
			return 0, e
		}
		if windows.UTF16ToString(p.ExeFile[:]) == name {
			return p.ProcessID, nil
		}
	}
}
