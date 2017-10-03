#!/bin/sh
set -e
"$@"
pid=$!
while read line ; do
  :
done
kill -9 $pid 2> /dev/null
