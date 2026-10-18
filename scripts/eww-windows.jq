# Which eww windows eww-windows.sh opens and closes, as pure jq over the monitor table.
# Tests: bash scripts/eww-windows.test.sh
#
# Two kinds of window:
#   table windows  each output's bar and `windows` in monitors.json, open while the output is on.
#   popups         opened on demand (picker, powermenu, calendar) with id <window>@<output>;
#                  closed when their output goes away, never reopened.

def popup_id($window; $output): "\($window)@\($output)";

def popup_output: if contains("@") then split("@") | last else null end;

# Input: the table. $active: enabled output names. $open: open window ids.
# Output: {close: [id], open: [{id, config, output, workspace_base}]}, workspace_base only for bars.
def plan($active; $open):
  [.[] | select(.name as $n | $active | index($n)) |
    ({id: .bar, config: "bar", output: .name, workspace_base: .workspace_base}),
    (.windows[] as $w | {id: $w, config: $w, output: .name})] as $wanted
  | ([.[] | .bar, .windows[]]) as $managed
  | {
      close: [$open[] | select(
        (. as $id | ($managed | index($id)) and ([$wanted[].id] | index($id) | not))
        or (popup_output as $o | $o != null and ($active | index($o) | not)))],
      open: [$wanted[] | select(.id as $id | $open | index($id) | not)]
    };
