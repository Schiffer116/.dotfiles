package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"golang.org/x/sys/unix"
)

func main() {
	pipeFile, ok := os.LookupEnv("VOLUME_PIPE")
	if !ok {
		log.Println("VOLUME_PIPE is not set")
		pipeFile = "/tmp/volume.pipe"
	}
	os.Remove(pipeFile)

	err := unix.Mkfifo(pipeFile, 0666)
	if err != nil {
		log.Fatal("Error making named pipe: ", err)
	}
	log.Println("Created pipe: ", pipeFile)

	file, err := os.OpenFile(pipeFile, os.O_RDWR, os.ModeNamedPipe)
	if err != nil {
		log.Fatal("Error opening named pipe: ", err)
	}

	reader := bufio.NewReader(file)

	log.Println("Listening on: ", pipeFile)
	for {
		line, err := reader.ReadBytes('\n')
		if err == nil {
			cmd := strings.Split(strings.TrimSpace(string(line)), " ")
			log.Println("Command: ", cmd)
			handleCommand(cmd)
		}
	}
}

func handleCommand(cmd []string) {
	switch cmd[0] {
	case "set":
		if len(cmd) != 2 {
			fmt.Println("Usage: set <volume>")
		}
		runCmd("wpctl", "set-volume", "@DEFAULT_SINK@", cmd[1], "--limit=1.5")
		setEwwVolume()
	default:
		fmt.Println("Unknown command:", cmd)
	}
}

func runCmd(name string, args ...string) {
	if out, err := exec.Command(name, args...).CombinedOutput(); err != nil {
	 	log.Printf("Error: %v (out: %s)", err, out)
	} else if len(out) > 0 {
		fmt.Println(string(out))
	}
}

func setEwwVolume() {
	volume, err := getVolume()
	if err != nil {
		log.Println("Error getting volume: ", err)
		return
	}
	runCmd("eww", "update", fmt.Sprintf("volume=%d", volume))
}

func getVolume() (int, error) {
	out, err := exec.Command("wpctl", "get-volume", "@DEFAULT_SINK@").
		CombinedOutput();
	if  err != nil {
		return 0, err
	}

	rawString := strings.TrimSpace(string(out))
	rawVolume := strings.Replace(strings.Split(rawString, " ")[1], ".", "", 1)
	volume, err := strconv.Atoi(rawVolume)
	if err != nil {
		log.Printf("Error converting volume to int: %v (out: %s)", err, out)
		return 0, err
	}

	return volume, nil
}
