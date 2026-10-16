# Pure functions of the picker state, used by picker.sh and tested by picker.test.sh.
# State: {name, icon, size, query, all: [{label, value, pinned?}], page, index}
#   all    every entry matching the query; one page shows `size` of them
#   index  the selected entry within the current page

def pages: [(((.all | length) + .size - 1) / .size | floor), 1] | max;

def slice: .all[(.page * .size):((.page + 1) * .size)];

# Move by $d pages, wrapping around both ends, and select the page's first entry.
def turn($d): pages as $n | .page = ((((.page + $d) % $n) + $n) % $n) | .index = 0;

# Tab: the next entry, continuing onto the next page.
def next:
  (slice | length) as $len
  | if $len == 0 then .
    elif .index + 1 < $len then .index += 1
    else turn(1) end;

# Shift+Tab: the previous entry, continuing onto the last entry of the previous page.
def previous:
  (slice | length) as $len
  | if $len == 0 then .
    elif .index > 0 then .index -= 1
    else turn(-1) | .index = ([(slice | length) - 1, 0] | max) end;

def selected: slice[.index];

# What eww renders: the current page only, each entry with its position on the page.
def view:
  {name, icon, items: [slice | to_entries[] | {i: .key, label: .value.label, pinned: (.value.pinned // false)}],
   index, page, pages: pages};

# A one-line chip label for a clipboard entry.
def clip_label:
  if test("^\\[\\[ binary data ") then
    (capture("(?<type>\\w+) (?<w>\\d+)x(?<h>\\d+) \\]\\]$") // null) as $m
    | if $m then "󰋩 \($m.type) \($m.w)×\($m.h)" else "󰋩 image" end
  else
    gsub("\n"; "⏎") | if length > 40 then .[0:39] + "…" else . end
  end;
