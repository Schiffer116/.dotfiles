package main

import (
	"log"
	"net"
	"os"
)

const readBufferSize = 1024
const writeBufferSize = 20

func main() {
	// Initialize Unix socket
	socketPath := os.Getenv("VOLUME_SERVER_SOCKET")
	if socketPath == "" {
		log.Fatal("Error getting socket server path: VOLUME_SERVER_SOCKET is empty")
	}
	os.Remove(socketPath)

	addr, err := net.ResolveUnixAddr("unixgram", socketPath)
	if err != nil {
		log.Fatal("Error resolving Unix socket")
	}
	defer os.Remove(socketPath)

	conn, err := net.ListenUnixgram("unixgram", addr)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	// Initialize log file
	logPath := os.Getenv("VOLUME_LOG")
	if logPath == "" {
		log.Fatal("Error getting log path: VOLUME_SERVER_SOCKET is empty")
	}
	logFile, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer logFile.Close()

	log.Println("Listening on:", socketPath)

	events := make(chan byte, readBufferSize)
	go socketListen(conn, events)
	processEvents(events, logFile)
}
