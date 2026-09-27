package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

var monitorNames = []string{"eDP-1", "HDMI-A-1"}
var brightnessState = map[string]int{}

func socketListen(conn *net.UnixConn, events chan<- byte) {
	buffer := make([]byte, readBufferSize)
	for {
		n, _, err := conn.ReadFromUnix(buffer)
		if err != nil {
			log.Println("Error reading from socket: ", err)
			close(events)
			break
		}

		for _, event := range buffer[:n] {
			if event != '+' && event != '-' {
				log.Println("Unknown character received: ", event)
				continue
			}
			log.Println("Event: ", event)
			events <- event
		}
	}
}

func processEvents(events <-chan byte, logFile *os.File) {
	for {
		event, ok := <-events
		if !ok {
			return
		}

		// Apply the first event of a batch on its own, so input that
		// arrives at a human pace produces a visible, gradual step.
		log.Println("Step: ", string(event))
		runBatch([]byte{event}, logFile)

		// Anything that queued up while that step was being applied means
		// the change is still happening faster than we can step through
		// it - drain it and jump straight to the target instead of
		// trickling through a stale backlog one slow step at a time.
		backlog := make([]byte, 0, writeBufferSize)
	drain:
		for len(backlog) < writeBufferSize {
			select {
			case e, ok := <-events:
				if !ok {
					break drain
				}
				backlog = append(backlog, e)
			default:
				break drain
			}
		}

		if len(backlog) > 0 {
			log.Println("Jump: ", string(backlog))
			runBatch(backlog, logFile)
		}
	}
}

func execCommand(name string, args ...string) ([]byte, error) {
	out, err := exec.Command(name, args...).CombinedOutput()
	if err != nil {
		log.Printf("Error: %v (out: %s)", err, out)
	} else if len(out) > 0 {
		log.Println(string(out))
	}
	return out, err
}

func runBatch(buffer []byte, logFile *os.File) {
	log.Printf("RunBatch: %v", buffer)

	delta := 0
	for i := range buffer {
		switch buffer[i] {
		case '+':
			delta++
		case '-':
			delta--
		default:
			log.Println("Unknown character: ", buffer[i])
		}
	}

	var sign byte
	if delta >= 0 {
		sign = '+'
	} else {
		sign = '-'
		delta = -delta
	}

	monitor, err := getActiveMonitor()
	if err != nil {
		log.Println("Error getting active monitor: ", err)
		return
	}
	log.Printf("Monitor, delta, sign: %s, %d, %c", monitor, delta, sign)

	switch monitor {
	case "eDP-1":
		if sign == '+' {
			execCommand("brightnessctl", "set", fmt.Sprintf("%c%d%%", sign, delta))
		} else {
			execCommand("brightnessctl", "set", "--min-value=1", fmt.Sprintf("%d%%%c", delta, sign))
		}
	case "HDMI-A-1":
		execCommand("ddcutil", "setvcp", "10", string(sign), strconv.Itoa(delta))
	default:
		log.Println("Unknown monitor: ", monitor)
		return
	}

	updateBrightness(monitor, logFile)
}

func updateBrightness(monitor string, logFile *os.File) {
	value, err := getMonitorBrightness(monitor)
	if err != nil {
		log.Printf("Error getting brightness for %s: %v", monitor, err)
		return
	}
	log.Printf("Brightness for %s: %d", monitor, value)

	brightnessState[monitor] = value
	writeBrightnessState(logFile)
}

func writeBrightnessState(logFile *os.File) {
	out, err := json.Marshal(brightnessState)
	if err != nil {
		log.Fatal(err)
	}
	if _, err := fmt.Fprintln(logFile, string(out)); err != nil {
		log.Fatal(err)
	}
}

// initBrightnessState queries every known monitor once at startup and
// writes an initial snapshot, so the eww widgets show real values right
// away instead of waiting for the first increase/decrease event.
func initBrightnessState(logFile *os.File) {
	for _, monitor := range monitorNames {
		value, err := getMonitorBrightness(monitor)
		if err != nil {
			log.Printf("Error getting initial brightness for %s: %v", monitor, err)
			continue
		}
		brightnessState[monitor] = value
	}
	writeBrightnessState(logFile)
}

func getMonitorBrightness(monitor string) (int, error) {
	switch monitor {
	case "eDP-1":
		return getLaptopBrightness()
	case "HDMI-A-1":
		return getExternalBrightness()
	default:
		return 0, fmt.Errorf("unknown monitor: %s", monitor)
	}
}

func getActiveMonitor() (string, error) {
	out, err := execCommand("hyprctl", "activeworkspace", "-j")
	if err != nil {
		return "", err
	}

	var workspace struct {
		Monitor string `json:"monitor"`
	}
	if err := json.Unmarshal(out, &workspace); err != nil {
		log.Printf("Error parsing hyprctl output: %v (out: %s)", err, out)
		return "", err
	}

	return workspace.Monitor, nil
}

func getLaptopBrightness() (int, error) {
	out, err := execCommand("brightnessctl", "i", "--machine-readable")
	if err != nil {
		log.Printf("Error getting brightness: %v (out: %s)", err, out)
		return 0, err
	}

	fields := strings.Split(strings.TrimSpace(string(out)), ",")
	if len(fields) < 4 {
		err := fmt.Errorf("unexpected brightnessctl output: %s", out)
		log.Println(err)
		return 0, err
	}

	rawBrightness := strings.TrimSuffix(fields[3], "%")
	brightness, err := strconv.Atoi(rawBrightness)
	if err != nil {
		log.Printf("Error converting brightness to int: %v (out: %s)", err, out)
		return 0, err
	}

	return brightness, nil
}

var ddcutilBrightnessRe = regexp.MustCompile(`current value =\s*(\d+)`)

func getExternalBrightness() (int, error) {
	out, err := execCommand("ddcutil", "getvcp", "10")
	if err != nil {
		log.Printf("Error getting brightness: %v (out: %s)", err, out)
		return 0, err
	}

	match := ddcutilBrightnessRe.FindSubmatch(out)
	if match == nil {
		err := fmt.Errorf("unexpected ddcutil output: %s", out)
		log.Println(err)
		return 0, err
	}

	brightness, err := strconv.Atoi(string(match[1]))
	if err != nil {
		log.Printf("Error converting brightness to int: %v (out: %s)", err, out)
		return 0, err
	}

	return brightness, nil
}
