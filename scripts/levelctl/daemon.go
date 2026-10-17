package main

import (
	"bufio"
	"encoding/json"
	"log"
	"net"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// State is what `levelctl watch` prints, one JSON line per change.
type State struct {
	Volume     *int           `json:"volume"`
	Muted      bool           `json:"muted"`
	Brightness map[string]int `json:"brightness"`
}

// A request for one level: a step in percent, or (volume only) a mute change.
type request struct {
	delta int
	mute  string
}

type daemon struct {
	sys System

	mu       sync.Mutex
	state    State
	last     []byte // last state line sent to watchers
	watchers map[net.Conn]struct{}

	volume     chan request
	brightness chan request

	backlight  sync.Mutex     // one brightness backend call at a time: ddcutil shares the I2C bus
	outputs    map[string]int // enabled outputs with a backlight, each with the id of its latest read loop
	loops      int
	firstRetry time.Duration // a failed read is retried after this, doubling each time,
	retryFor   time.Duration // until this long has passed since the output appeared
}

func newDaemon(sys System) *daemon {
	return &daemon{
		sys:        sys,
		state:      State{Brightness: map[string]int{}},
		watchers:   map[net.Conn]struct{}{},
		outputs:    map[string]int{},
		firstRetry: 500 * time.Millisecond,
		retryFor:   30 * time.Second,
		volume:     make(chan request, 256),
		brightness: make(chan request, 256),
	}
}

// start reads the initial state and runs one worker per level. The caller keeps the outputs
// current by calling syncOutputs on every output change.
func (d *daemon) start() {
	d.refreshVolume()
	d.syncOutputs()
	go d.work(d.volume, d.applyVolume)
	go d.work(d.brightness, d.applyBrightness)
}

// syncOutputs starts reading each newly enabled output and forgets outputs that are gone, so a
// replugged monitor is read fresh. Idempotent: extra calls cost one hyprctl run.
func (d *daemon) syncOutputs() {
	monitors, err := d.sys.BrightnessMonitors()
	if err != nil {
		log.Print(err)
		return
	}
	present := map[string]bool{}
	d.mu.Lock()
	for _, m := range monitors {
		present[m] = true
		if _, ok := d.outputs[m]; !ok {
			d.loops++
			d.outputs[m] = d.loops
			go d.readUntilAnswered(m, d.loops)
		}
	}
	for m := range d.outputs {
		if !present[m] {
			delete(d.outputs, m)
			delete(d.state.Brightness, m)
		}
	}
	d.mu.Unlock()
	d.publish()
}

// readUntilAnswered reads an output's brightness, retrying with backoff: a monitor's DDC channel
// often does not answer for a few seconds after login or hotplug. Stops early if the output goes
// away (or was replugged, starting a newer loop).
func (d *daemon) readUntilAnswered(monitor string, loop int) {
	deadline := time.Now().Add(d.retryFor)
	for delay := d.firstRetry; ; delay *= 2 {
		d.mu.Lock()
		current := d.outputs[monitor] == loop
		d.mu.Unlock()
		if !current {
			return
		}
		d.backlight.Lock()
		value, err := d.sys.Brightness(monitor)
		d.backlight.Unlock()
		if err == nil {
			d.mu.Lock()
			if d.outputs[monitor] == loop {
				d.state.Brightness[monitor] = value
			}
			d.mu.Unlock()
			d.publish()
			return
		}
		if time.Now().Add(delay).After(deadline) {
			log.Printf("giving up on %s brightness: %v", monitor, err)
			return
		}
		time.Sleep(delay)
	}
}

// work applies the first request of a burst on its own, so steps at a human pace are visible
// one by one. Whatever queued up meanwhile (a held key outrunning a slow backend like ddcutil)
// is applied as one jump instead of trickling through a stale backlog.
func (d *daemon) work(reqs <-chan request, apply func([]request)) {
	for r := range reqs {
		apply([]request{r})
		var backlog []request
	drain:
		for {
			select {
			case r, ok := <-reqs:
				if !ok {
					break drain
				}
				backlog = append(backlog, r)
			default:
				break drain
			}
		}
		if len(backlog) > 0 {
			apply(backlog)
		}
	}
}

// applyVolume sums consecutive steps; a mute change flushes the steps before it, keeping order.
func (d *daemon) applyVolume(batch []request) {
	delta := 0
	flush := func() {
		if delta != 0 {
			if err := d.sys.StepVolume(delta); err != nil {
				log.Print(err)
			}
			delta = 0
		}
	}
	for _, r := range batch {
		if r.mute != "" {
			flush()
			if err := d.sys.SetMute(r.mute); err != nil {
				log.Print(err)
			}
			continue
		}
		delta += r.delta
	}
	flush()
	d.refreshVolume()
}

func (d *daemon) applyBrightness(batch []request) {
	d.backlight.Lock()
	defer d.backlight.Unlock()
	delta := 0
	for _, r := range batch {
		delta += r.delta
	}
	monitor, err := d.sys.ActiveMonitor()
	if err != nil {
		log.Print(err)
		return
	}
	if delta != 0 {
		if err := d.sys.StepBrightness(monitor, delta); err != nil {
			log.Print(err)
			return
		}
	}
	d.refreshBrightness(monitor)
}

func (d *daemon) refreshVolume() {
	volume, muted, err := d.sys.Volume()
	if err != nil {
		log.Print(err)
		return
	}
	d.mu.Lock()
	d.state.Volume, d.state.Muted = &volume, muted
	d.mu.Unlock()
	d.publish()
}

func (d *daemon) refreshBrightness(monitor string) {
	value, err := d.sys.Brightness(monitor)
	if err != nil {
		log.Print(err)
		return
	}
	d.mu.Lock()
	d.state.Brightness[monitor] = value
	d.mu.Unlock()
	d.publish()
}

func (d *daemon) stateLine() []byte {
	line, _ := json.Marshal(d.state)
	return append(line, '\n')
}

// publish sends the state to every watcher, only when it changed.
func (d *daemon) publish() {
	d.mu.Lock()
	defer d.mu.Unlock()
	line := d.stateLine()
	if string(line) == string(d.last) {
		return
	}
	d.last = line
	for c := range d.watchers {
		c.SetWriteDeadline(time.Now().Add(time.Second))
		if _, err := c.Write(line); err != nil {
			c.Close()
			delete(d.watchers, c)
		}
	}
}

// followSink re-reads the volume whenever the sink or the default sink changes outside
// levelctl (pavucontrol, headphones plugged in), so the bar never goes stale.
func (d *daemon) followSink() {
	changed := make(chan struct{}, 1)
	go func() {
		for range changed {
			time.Sleep(50 * time.Millisecond) // one refresh per burst of events
			d.refreshVolume()
		}
	}()
	for {
		cmd := exec.Command("pactl", "subscribe")
		out, err := cmd.StdoutPipe()
		if err == nil {
			err = cmd.Start()
		}
		if err != nil {
			log.Print("pactl subscribe: ", err)
			time.Sleep(5 * time.Second)
			continue
		}
		scanner := bufio.NewScanner(out)
		for scanner.Scan() {
			// "Event 'change' on sink #57", "Event 'change' on server #-1" (default sink)
			line := scanner.Text()
			if strings.Contains(line, " on sink #") || strings.Contains(line, " on server") {
				select {
				case changed <- struct{}{}:
				default:
				}
			}
		}
		cmd.Wait()
		time.Sleep(time.Second)
	}
}

// serve handles one client connection: a single command line.
//
//	volume +N | volume -N | volume toggle-mute | volume mute | volume unmute
//	brightness +N | brightness -N
//	get       reply with the state line
//	watch     reply with the state line now and on every change
func (d *daemon) serve(c net.Conn) {
	line, err := bufio.NewReader(c).ReadString('\n')
	if err != nil {
		c.Close()
		return
	}
	args := strings.Fields(line)
	if len(args) == 1 && args[0] == "watch" {
		d.mu.Lock()
		c.Write(d.stateLine())
		d.watchers[c] = struct{}{}
		d.mu.Unlock()
		return
	}
	defer c.Close()
	if len(args) == 1 && args[0] == "get" {
		d.mu.Lock()
		c.Write(d.stateLine())
		d.mu.Unlock()
		return
	}
	r, level, err := parseRequest(args)
	if err != nil {
		c.Write([]byte("error: " + err.Error() + "\n"))
		return
	}
	if level == "volume" {
		d.volume <- r
	} else {
		d.brightness <- r
	}
	c.Write([]byte("ok\n"))
}
