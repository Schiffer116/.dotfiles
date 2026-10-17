package main

import (
	"bufio"
	"fmt"
	"net"
	"path/filepath"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"
)

// fakeSystem records calls. While gate is non-nil, each step blocks until a value arrives on it,
// standing in for a slow backend.
type fakeSystem struct {
	mu         sync.Mutex
	calls      []string
	volume     int
	muted      bool
	active     string
	brightness map[string]int
	enabled    []string
	failReads  int // the next brightness reads that fail, like DDC right after login
	reads      int
	gate       chan struct{}
}

func newFake() *fakeSystem {
	return &fakeSystem{volume: 40, active: "eDP-1", brightness: map[string]int{"eDP-1": 50, "HDMI-A-1": 30},
		enabled: []string{"eDP-1", "HDMI-A-1"}}
}

func (f *fakeSystem) record(call string) {
	f.mu.Lock()
	f.calls = append(f.calls, call)
	f.mu.Unlock()
}

func (f *fakeSystem) wait() {
	if f.gate != nil {
		<-f.gate
	}
}

func (f *fakeSystem) StepVolume(delta int) error {
	f.record(fmt.Sprintf("volume %+d", delta))
	f.wait()
	f.mu.Lock()
	f.volume = min(100, max(0, f.volume+delta))
	f.mu.Unlock()
	return nil
}

func (f *fakeSystem) SetMute(mode string) error {
	f.record("mute " + mode)
	f.mu.Lock()
	f.muted = mode == "1" || (mode == "toggle" && !f.muted)
	f.mu.Unlock()
	return nil
}

func (f *fakeSystem) Volume() (int, bool, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.volume, f.muted, nil
}

func (f *fakeSystem) ActiveMonitor() (string, error) { return f.active, nil }

func (f *fakeSystem) BrightnessMonitors() ([]string, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]string(nil), f.enabled...), nil
}

func (f *fakeSystem) StepBrightness(monitor string, delta int) error {
	f.record(fmt.Sprintf("brightness %s %+d", monitor, delta))
	f.wait()
	f.mu.Lock()
	f.brightness[monitor] += delta
	f.mu.Unlock()
	return nil
}

func (f *fakeSystem) Brightness(monitor string) (int, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.reads++
	if f.failReads > 0 {
		f.failReads--
		return 0, fmt.Errorf("ddcutil: display not found")
	}
	return f.brightness[monitor], nil
}

func (f *fakeSystem) recorded() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]string(nil), f.calls...)
}

func waitFor(t *testing.T, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for !cond() {
		if time.Now().After(deadline) {
			t.Fatal("timed out")
		}
		time.Sleep(5 * time.Millisecond)
	}
}

func TestFirstStepAloneThenBacklogAsOneJump(t *testing.T) {
	f := newFake()
	f.gate = make(chan struct{})
	d := newDaemon(f)
	d.start()

	d.volume <- request{delta: 5}
	waitFor(t, func() bool { return len(f.recorded()) == 1 })
	// The key is held while the first step is still being applied.
	for range 4 {
		d.volume <- request{delta: 5}
	}
	f.gate <- struct{}{}
	f.gate <- struct{}{}

	waitFor(t, func() bool { return len(f.recorded()) == 2 })
	if got, want := f.recorded(), []string{"volume +5", "volume +20"}; !reflect.DeepEqual(got, want) {
		t.Fatalf("calls = %v, want %v", got, want)
	}
}

func TestMuteKeepsItsPlaceBetweenSteps(t *testing.T) {
	f := newFake()
	d := newDaemon(f)
	d.applyVolume([]request{{delta: 2}, {delta: 1}, {mute: "toggle"}, {delta: -3}})
	if got, want := f.recorded(), []string{"volume +3", "mute toggle", "volume -3"}; !reflect.DeepEqual(got, want) {
		t.Fatalf("calls = %v, want %v", got, want)
	}
}

func TestBrightnessGoesToFocusedOutput(t *testing.T) {
	f := newFake()
	f.active = "HDMI-A-1"
	d := newDaemon(f)
	d.applyBrightness([]request{{delta: -1}, {delta: -1}})
	if got, want := f.recorded(), []string{"brightness HDMI-A-1 -2"}; !reflect.DeepEqual(got, want) {
		t.Fatalf("calls = %v, want %v", got, want)
	}
	if d.state.Brightness["HDMI-A-1"] != 28 || d.state.Brightness["eDP-1"] != 0 {
		t.Fatalf("state = %v", d.state.Brightness)
	}
}

// fastRetries makes a daemon retry reads after 1ms, 2ms, 4ms... for 50ms.
func fastRetries(d *daemon) *daemon {
	d.firstRetry, d.retryFor = time.Millisecond, 50*time.Millisecond
	return d
}

func (d *daemon) brightnessOf(monitor string) (int, bool) {
	d.mu.Lock()
	defer d.mu.Unlock()
	v, ok := d.state.Brightness[monitor]
	return v, ok
}

func (f *fakeSystem) readCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.reads
}

func (f *fakeSystem) setEnabled(monitors ...string) {
	f.mu.Lock()
	f.enabled = monitors
	f.mu.Unlock()
}

func TestBrightnessReadRetriedUntilItAnswers(t *testing.T) {
	f := newFake()
	f.enabled = []string{"HDMI-A-1"}
	f.failReads = 3
	d := fastRetries(newDaemon(f))
	d.start()
	waitFor(t, func() bool { v, _ := d.brightnessOf("HDMI-A-1"); return v == 30 })
	if got := f.readCount(); got != 4 {
		t.Fatalf("reads = %d, want 4", got)
	}
}

func TestBrightnessReadGivesUp(t *testing.T) {
	f := newFake()
	f.enabled = []string{"HDMI-A-1"}
	f.failReads = 1000
	d := fastRetries(newDaemon(f))
	d.syncOutputs()
	time.Sleep(200 * time.Millisecond)
	settled := f.readCount()
	time.Sleep(100 * time.Millisecond)
	// Backoff from 1ms within 50ms is at most 6 reads (0, 1, 3, 7, 15, 31ms), then nothing.
	if got := f.readCount(); got != settled || got < 2 || got > 6 {
		t.Fatalf("reads = %d then %d, want 2..6 and then no more", settled, got)
	}
	if _, ok := d.brightnessOf("HDMI-A-1"); ok {
		t.Fatal("unreadable output has a brightness")
	}
}

func TestUnpluggedOutputStopsRetryingAndIsReadAgainOnReplug(t *testing.T) {
	f := newFake()
	f.enabled = []string{"HDMI-A-1"}
	f.failReads = 1000
	d := newDaemon(f)
	d.firstRetry, d.retryFor = 20*time.Millisecond, time.Minute
	d.syncOutputs()
	waitFor(t, func() bool { return f.readCount() == 1 })
	f.setEnabled()
	d.syncOutputs()
	time.Sleep(100 * time.Millisecond)
	if got := f.readCount(); got > 2 {
		t.Fatalf("reads = %d after unplug, want the retries to stop", got)
	}

	f.mu.Lock()
	f.failReads, f.brightness["HDMI-A-1"] = 0, 70
	f.mu.Unlock()
	f.setEnabled("HDMI-A-1")
	d.syncOutputs()
	waitFor(t, func() bool { v, _ := d.brightnessOf("HDMI-A-1"); return v == 70 })

	f.setEnabled()
	d.syncOutputs()
	if _, ok := d.brightnessOf("HDMI-A-1"); ok {
		t.Fatal("unplugged output kept its brightness")
	}
}

func TestOutputEvents(t *testing.T) {
	for event, want := range map[string]bool{
		"monitoradded>>HDMI-A-1":                 true,
		"monitorremoved>>eDP-1":                  true,
		"monitoraddedv2>>1,HDMI-A-1,AOC Q27G2G4": false,
		"activewindow>>kitty,monitoradded>>x":    false,
	} {
		if got := isOutputChange(event); got != want {
			t.Errorf("isOutputChange(%q) = %v, want %v", event, got, want)
		}
	}
}

func TestParseRequest(t *testing.T) {
	for _, tc := range []struct {
		args  string
		want  request
		level string
		bad   bool
	}{
		{args: "volume +5", want: request{delta: 5}, level: "volume"},
		{args: "brightness -1", want: request{delta: -1}, level: "brightness"},
		{args: "volume toggle-mute", want: request{mute: "toggle"}, level: "volume"},
		{args: "volume mute", want: request{mute: "1"}, level: "volume"},
		{args: "brightness mute", bad: true},
		{args: "volume 5", bad: true},
		{args: "volume +0", bad: true},
		{args: "volume +x", bad: true},
		{args: "speaker +5", bad: true},
	} {
		r, level, err := parseRequest(strings.Fields(tc.args))
		if tc.bad {
			if err == nil {
				t.Errorf("%q: want error", tc.args)
			}
			continue
		}
		if err != nil || r != tc.want || level != tc.level {
			t.Errorf("%q = %+v %q %v, want %+v %q", tc.args, r, level, err, tc.want, tc.level)
		}
	}
}

// The protocol end to end: a watcher sees the initial state, then the change a client asked for.
func TestWatchSeesChangesOverSocket(t *testing.T) {
	path := filepath.Join(t.TempDir(), "levelctl.sock")
	t.Setenv("LEVELCTL_SOCKET", path)
	ln, err := net.Listen("unix", path)
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	d := newDaemon(newFake())
	d.start()
	waitFor(t, func() bool { _, ok := d.brightnessOf("HDMI-A-1"); _, ok2 := d.brightnessOf("eDP-1"); return ok && ok2 })
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			go d.serve(c)
		}
	}()

	w, err := net.Dial("unix", path)
	if err != nil {
		t.Fatal(err)
	}
	defer w.Close()
	fmt.Fprintln(w, "watch")
	lines := bufio.NewScanner(w)
	lines.Scan()
	if got, want := lines.Text(), `{"volume":40,"muted":false,"brightness":{"HDMI-A-1":30,"eDP-1":50}}`; got != want {
		t.Fatalf("initial state = %s, want %s", got, want)
	}

	if err := send("volume +5"); err != nil {
		t.Fatal(err)
	}
	lines.Scan()
	if got, want := lines.Text(), `{"volume":45,"muted":false,"brightness":{"HDMI-A-1":30,"eDP-1":50}}`; got != want {
		t.Fatalf("state after step = %s, want %s", got, want)
	}

	if err := send("volume +x"); err == nil || !strings.Contains(err.Error(), "+N or -N") {
		t.Fatalf("bad step error = %v", err)
	}
}
