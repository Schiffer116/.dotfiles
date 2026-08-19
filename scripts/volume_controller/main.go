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

const readBufferSize = 1024
const writeBufferSize = 20

func main() {
	// Remove an old socket left behind by a previous run.
	socketPath := os.Getenv("VOLUME_SERVER_SOCKET")
	os.Remove(socketPath)

	addr, err := net.ResolveUnixAddr("unixgram", socketPath)
	if err != nil {
		log.Fatal(err)
	}

	conn, err := net.ListenUnixgram("unixgram", addr)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	defer os.Remove(socketPath)

	log.Println("Listening on:", socketPath)

	events := make(chan byte, readBufferSize)
	go func() {
		buffer := make([]byte, readBufferSize)

		for {
			n, _, err := conn.ReadFromUnix(buffer)
			if err != nil {
				log.Println(err)
				continue
			}

			for _, event := range buffer[:n] {
				if event != '+' && event != '-' {
					log.Println("Unknown character: ", event)
					continue
				}
				log.Println("Event: ", event)
				events <- event
			}
		}
	}()

	writeBuffer := make([]byte, writeBufferSize)
	log.Println("Initialized write buffer")
	for i := 0; ; {
	read:
		for i < writeBufferSize {
			select {
			case event := <-events:
				writeBuffer[i] = event
				i++
			default:
				if i != 0 {
					break read
				} else {
					writeBuffer[0] = <-events
					i++
				}
			}
		}

		log.Println("Running batch: ", string(writeBuffer[:i]))
		runBatch(writeBuffer, &i)
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

func runBatch(buffer []byte, size *int) {
	delta := 0
	for i := range *size {
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
	log.Printf("Delta, sign, input: %v, %v, %v", delta, sign, input)

	execCommand("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_SINK@", fmt.Sprintf("%d%%%c", delta, sign))
	*size = 0
	volume, err := getVolume()
	if err != nil {
		log.Println("Error getting volume: ", err)
		return
	}
	log.Println("Volume: ", volume)
	updateEwwVariable("volume", volume)

}

func updateEwwVariable(variable string, value int) {
	execCommand("eww", "update", fmt.Sprintf("%s=%d", variable, value))
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

func getBrightness() (int, error) {
	return 0, nil
}
