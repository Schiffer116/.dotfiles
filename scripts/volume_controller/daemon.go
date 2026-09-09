package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

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
	writeBuffer := make([]byte, writeBufferSize)
	for {
		writeBuffer = writeBuffer[:0]

	read:
		for len(writeBuffer) < writeBufferSize {
			select {
			case event := <-events:
				writeBuffer = append(writeBuffer, event)
			default:
				if len(writeBuffer) != 0 {
					break read
				} else {
					writeBuffer = append(writeBuffer, <-events)
				}
			}
		}

		log.Println("Running batch: ", string(writeBuffer))
		runBatch(writeBuffer, logFile)
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

	var sign rune
	if delta >= 0 {
		sign = '+'
	} else {
		sign = '-'
		delta = -delta
	}

	input := fmt.Sprintf("%d%%%c", delta, sign)
	log.Printf("Delta, sign, input: %d, %c, %s", delta, sign, input)

	execCommand("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_SINK@", fmt.Sprintf("%d%%%c", delta, sign))
	volume, err := getVolume()
	if err != nil {
		log.Println("Error getting volume: ", err)
		return
	}
	log.Println("Volume: ", volume)

	if _, err := fmt.Fprintln(logFile, volume); err != nil {
		log.Fatal(err)
	}
}

func getVolume() (int, error) {
	out, err := execCommand("wpctl", "get-volume", "@DEFAULT_SINK@")
	if err != nil {
		log.Printf("Error getting volume: %v (out: %s)", err, out)
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
