// levelctl owns the volume of the default sink and the brightness of each output.
//
//	levelctl daemon                    run the daemon (Hyprland starts it at login)
//	levelctl volume +5 | -5            step the volume, in percent
//	levelctl volume toggle-mute | mute | unmute
//	levelctl brightness +5 | -5        step the brightness of the focused output
//	levelctl get                       print the state once
//	levelctl watch                     print the state now and on every change (eww deflisten);
//	                                   waits for the daemon and reconnects if it restarts
//
// State lines look like {"volume":42,"muted":false,"brightness":{"eDP-1":56,"HDMI-A-1":56}}.
// Which outputs have brightness, and through which backend, comes from the monitor table.
package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func socketPath() string {
	if p := os.Getenv("LEVELCTL_SOCKET"); p != "" {
		return p
	}
	return filepath.Join(os.Getenv("XDG_RUNTIME_DIR"), "levelctl.sock")
}

// parseRequest turns client arguments into a request for one level.
func parseRequest(args []string) (request, string, error) {
	if len(args) != 2 || (args[0] != "volume" && args[0] != "brightness") {
		return request{}, "", errors.New("usage: levelctl volume|brightness +N|-N")
	}
	level, arg := args[0], args[1]
	if level == "volume" {
		switch arg {
		case "toggle-mute":
			return request{mute: "toggle"}, level, nil
		case "mute":
			return request{mute: "1"}, level, nil
		case "unmute":
			return request{mute: "0"}, level, nil
		}
	}
	if len(arg) < 2 || (arg[0] != '+' && arg[0] != '-') {
		return request{}, "", fmt.Errorf("step must be +N or -N percent, got %q", arg)
	}
	n, err := strconv.Atoi(arg[1:])
	if err != nil || n <= 0 {
		return request{}, "", fmt.Errorf("step must be +N or -N percent, got %q", arg)
	}
	if arg[0] == '-' {
		n = -n
	}
	return request{delta: n}, level, nil
}

func runDaemon() error {
	path := socketPath()
	if c, err := net.Dial("unix", path); err == nil {
		c.Close()
		return errors.New("already running at " + path)
	}
	os.Remove(path)
	ln, err := net.Listen("unix", path)
	if err != nil {
		return err
	}
	desktop := newDesktop()
	d := newDaemon(desktop)
	d.start()
	go d.followSink()
	go desktop.FollowOutputs(d.syncOutputs)
	for {
		c, err := ln.Accept()
		if err != nil {
			return err
		}
		go d.serve(c)
	}
}

// send sends one command and copies the reply to stdout.
func send(command string) error {
	c, err := net.Dial("unix", socketPath())
	if err != nil {
		return fmt.Errorf("daemon not running: %w", err)
	}
	defer c.Close()
	if _, err := fmt.Fprintln(c, command); err != nil {
		return err
	}
	reply, err := io.ReadAll(c)
	if err != nil {
		return err
	}
	if len(reply) > 6 && string(reply[:6]) == "error:" {
		return errors.New(string(reply[7 : len(reply)-1]))
	}
	if string(reply) != "ok\n" {
		os.Stdout.Write(reply)
	}
	return nil
}

// watch never exits: eww starts it before the daemon at login, and the daemon may restart.
func watch() {
	for {
		c, err := net.Dial("unix", socketPath())
		if err == nil {
			fmt.Fprintln(c, "watch")
			scanner := bufio.NewScanner(c)
			for scanner.Scan() {
				fmt.Println(scanner.Text())
			}
			c.Close()
		}
		time.Sleep(500 * time.Millisecond)
	}
}

func main() {
	log.SetFlags(0)
	log.SetPrefix("levelctl: ")
	args := os.Args[1:]
	if len(args) == 0 {
		log.Fatal("usage: levelctl daemon | watch | get | volume|brightness <step|mute>")
	}
	switch args[0] {
	case "daemon":
		log.Fatal(runDaemon())
	case "watch":
		watch()
	case "get":
		if err := send("get"); err != nil {
			log.Fatal(err)
		}
	default:
		if _, _, err := parseRequest(args); err != nil {
			log.Fatal(err)
		}
		if err := send(args[0] + " " + args[1]); err != nil {
			log.Fatal(err)
		}
	}
}
