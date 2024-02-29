#!/usr/bin/env sh

magick /tmp/cover-art -colors 1 -define histogram:unique-colors=true \
-format "%c" histogram:info: | grep -o '#[A-Z0-9]\{6\}'
