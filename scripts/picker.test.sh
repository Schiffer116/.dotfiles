#!/usr/bin/env bash
# Tests for picker.jq, the picker's paging and selection: bash scripts/picker.test.sh
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
failures=0

# check NAME FILTER EXPECTED: run FILTER on a 23-entry state (pages of 10: 10, 10, 3).
check() {
    local got
    got=$(jq -n -c -L "$here" 'include "picker";
        {size: 10, page: 0, index: 0, all: [range(23) | {label: "e\(.)", value: .}]} | '"$2")
    if [ "$got" = "$3" ]; then
        echo "ok   $1"
    else
        echo "FAIL $1: got $got, want $3"
        failures=$((failures + 1))
    fi
}

check "three pages" 'pages' '3'
check "empty list still has one page" '.all = [] | pages' '1'
check "next moves within the page" 'next | [.page, .index]' '[0,1]'
check "next past the page end turns the page" '.index = 9 | next | [.page, .index]' '[1,0]'
check "next past the last entry wraps to the first" '.page = 2 | .index = 2 | next | [.page, .index]' '[0,0]'
check "previous from the first entry goes to the last entry" 'previous | [.page, .index]' '[2,2]'
check "previous onto a full page selects its end" '.page = 1 | previous | [.page, .index]' '[0,9]'
check "previous page wraps" 'turn(-1) | [.page, .index]' '[2,0]'
check "next on an empty list does nothing" '.all = [] | next | [.page, .index]' '[0,0]'
check "selected" '.page = 1 | .index = 3 | selected.label' '"e13"'
check "view numbers entries within the page" '.page = 2 | view | [.items[] | .i], .pages' '[0,1,2]
3'
check "text label keeps one line" '"first\nsecond" | clip_label' '"first⏎second"'
check "long text label is cut" '"0123456789012345678901234567890123456789XYZ" | clip_label' '"012345678901234567890123456789012345678…"'
check "image label" '"[[ binary data 304 B png 28x34 ]]" | clip_label' '"󰋩 png 28×34"'

[ "$failures" -eq 0 ] || exit 1
