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
	gate       chan struct{}
}

func newFake() *fakeSystem {
	return &fakeSystem{volume: 40, active: "eDP-1", brightness: map[string]int{"eDP-1": 50, "HDMI-A-1": 30}}
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

func (f *fakeSystem) BrightnessMonitors() []string { return []string{"eDP-1", "HDMI-A-1"} }

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
