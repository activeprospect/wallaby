#!/bin/sh
"$@" &
pid=$!
while read line ; do
  :
done
kill -9 $pid 2> /dev/null
echo $(dirname $0)
