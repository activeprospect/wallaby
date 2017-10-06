#!/bin/bash
set -e

shutdown(){
  my_pid=$$

  children=$(ps xao pid,pgid | grep $my_pid | awk '{print $1}' | grep -v $my_pid)
  kill $phantom_pid 2>/dev/null

  for child_pid in $children; do
    while kill -0 $child_pid 2>/dev/null; do
      sleep 0.1
    done
  done

  exit 0
}

cleanup_tmppipe(){
  rm -f $tmppipe
}

trap "shutdown" SIGINT SIGHUP SIGTERM
trap "cleanup_tmppipe" EXIT

# Start the script in a subshell so we can wait until it ends and then kill this
# wrapper script. In order to communicate the pid up to the parent process we
# need to use a fifo pipe.
script_pid=$$
tmppipe=$(mktemp -u)
mkfifo -m 600 "$tmppipe"
(
  "$@" &
  echo $! >> $tmppipe
  wait
  kill $script_pid
) &
read phantom_pid < "$tmppipe"
cleanup_tmppipe

# Wait for stdin to be closed before we shutdown
while read line ; do
  :
done
shutdown
