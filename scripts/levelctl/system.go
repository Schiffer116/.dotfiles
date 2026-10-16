package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// System is everything levelctl reads or changes outside itself. The daemon only talks to the
// desktop through it, so tests swap in a fake.
type System interface {
	// StepVolume changes the default sink's volume by delta percent, capped at 100%.
	StepVolume(delta int) error
	// SetMute sets the default sink's mute: "toggle", "1" (mute) or "0" (unmute).
	SetMute(mode string) error
	Volume() (volume int, muted bool, err error)

	// ActiveMonitor is the output that has focus; brightness steps go to it.
	ActiveMonitor() (string, error)
	// BrightnessMonitors lists the outputs whose brightness can be read and set.
	BrightnessMonitors() []string
	StepBrightness(monitor string, delta int) error
	Brightness(monitor string) (int, error)
}

// desktop is the real System: wpctl for the sink, hyprctl for focus, and per output the
// backlight backend named in the monitor table ($XDG_RUNTIME_DIR/monitors.json, written by
// hyprland.lua from .config/hypr/monitors.lua).
type desktop struct {
	monitorTable string
}

func newDesktop() *desktop {
	path := os.Getenv("MONITORS_JSON")
	if path == "" {
		path = filepath.Join(os.Getenv("XDG_RUNTIME_DIR"), "monitors.json")
	}
	return &desktop{monitorTable: path}
}

func run(name string, args ...string) ([]byte, error) {
	out, err := exec.Command(name, args...).CombinedOutput()
	if err != nil {
		return out, fmt.Errorf("%s %s: %w: %s", name, strings.Join(args, " "), err, strings.TrimSpace(string(out)))
	}
	return out, nil
}

func signed(delta int) (abs int, sign string) {
	if delta < 0 {
		return -delta, "-"
	}
	return delta, "+"
}

func (d *desktop) StepVolume(delta int) error {
	abs, sign := signed(delta)
	_, err := run("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_SINK@", fmt.Sprintf("%d%%%s", abs, sign))
	return err
}

func (d *desktop) SetMute(mode string) error {
	_, err := run("wpctl", "set-mute", "@DEFAULT_SINK@", mode)
	return err
}

// wpctl prints "Volume: 0.42" or "Volume: 0.42 [MUTED]".
func (d *desktop) Volume() (int, bool, error) {
	out, err := run("wpctl", "get-volume", "@DEFAULT_SINK@")
	if err != nil {
		return 0, false, err
	}
	fields := strings.Fields(string(out))
	if len(fields) < 2 {
		return 0, false, fmt.Errorf("unexpected wpctl output: %q", out)
	}
	f, err := strconv.ParseFloat(fields[1], 64)
	if err != nil {
		return 0, false, fmt.Errorf("unexpected wpctl output: %q", out)
	}
	return int(f*100 + 0.5), strings.Contains(string(out), "[MUTED]"), nil
}

func (d *desktop) ActiveMonitor() (string, error) {
	out, err := run("hyprctl", "activeworkspace", "-j")
	if err != nil {
		return "", err
	}
	var ws struct {
		Monitor string `json:"monitor"`
	}
	if err := json.Unmarshal(out, &ws); err != nil {
		return "", fmt.Errorf("unexpected hyprctl output: %w", err)
	}
	return ws.Monitor, nil
}

// backlights maps each output to its backend from the monitor table. Read on every call:
// hyprland.lua rewrites the table when an unknown output is adopted.
func (d *desktop) backlights() map[string]string {
	data, err := os.ReadFile(d.monitorTable)
	if err != nil {
		return nil
	}
	var table []struct {
		Name      string  `json:"name"`
		Backlight *string `json:"backlight"`
	}
	if json.Unmarshal(data, &table) != nil {
		return nil
	}
	backlights := map[string]string{}
	for _, m := range table {
		if m.Backlight != nil {
			backlights[m.Name] = *m.Backlight
		}
	}
	return backlights
}

func (d *desktop) BrightnessMonitors() []string {
	var names []string
	for name := range d.backlights() {
		names = append(names, name)
	}
	return names
}

func (d *desktop) StepBrightness(monitor string, delta int) error {
	abs, sign := signed(delta)
	switch backend := d.backlights()[monitor]; backend {
	case "brightnessctl":
		if sign == "+" {
			_, err := run("brightnessctl", "set", fmt.Sprintf("+%d%%", abs))
			return err
		}
		_, err := run("brightnessctl", "set", "--min-value=1", fmt.Sprintf("%d%%-", abs))
		return err
	case "ddcutil":
		_, err := run("ddcutil", "setvcp", "10", sign, strconv.Itoa(abs))
		return err
	default:
		return fmt.Errorf("no brightness control for %s", monitor)
	}
}

var ddcutilValue = regexp.MustCompile(`current value =\s*(\d+)`)

func (d *desktop) Brightness(monitor string) (int, error) {
	switch backend := d.backlights()[monitor]; backend {
	case "brightnessctl":
		// device,class,current,percent,max
		out, err := run("brightnessctl", "i", "--machine-readable")
		if err != nil {
			return 0, err
		}
		fields := strings.Split(strings.TrimSpace(string(out)), ",")
		if len(fields) < 4 {
			return 0, fmt.Errorf("unexpected brightnessctl output: %q", out)
		}
		return strconv.Atoi(strings.TrimSuffix(fields[3], "%"))
	case "ddcutil":
		out, err := run("ddcutil", "getvcp", "10")
		if err != nil {
			return 0, err
		}
		m := ddcutilValue.FindSubmatch(out)
		if m == nil {
			return 0, fmt.Errorf("unexpected ddcutil output: %q", out)
		}
		return strconv.Atoi(string(m[1]))
	default:
		return 0, fmt.Errorf("no brightness control for %s", monitor)
	}
}
