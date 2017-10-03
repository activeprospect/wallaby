#!/bin/bash
set -e

shutdown(){
  # echo "running shutdown $$" >> /Users/aaron/result
  my_pid=$$

  # echo "ps xao \n$(ps xao pid,pgid,command | grep $my_pid)" >> /Users/aaron/result
  children=$(ps xao pid,pgid | grep $my_pid | awk '{print $1}' | grep -v $my_pid)
  # echo "sending kill signal to $phantom_pid" >> /Users/aaron/result
  kill $phantom_pid 2>/dev/null

  # echo "after kill $(ps xao pid,pgid | grep $pid | awk '{print $1}' | grep -v $my_pid || true) ---" >> /Users/aaron/result
  # echo $(ps xao pid,pgid | grep $pid | awk '{print $1}' | grep -v $my_pid) >>

  for child_pid in $children; do
    # echo "ensuring $child_pid is shut down" >> /Users/aaron/result
    while kill -0 $child_pid 2>/dev/null; do
      sleep 0.1
      # echo "waiting for $child_pid" >> /Users/aaron/result
    done
  done

  # pgid=$(ps xao pid,pgid | grep $pid | awk '{print $2}')
  #
  # echo "kill signal sent to $pgid" >> /Users/aaron/result
  #
  # # Wait for process to die
  # while kill -0 $pgid 2>/dev/null; do
  #   sleep 1
  #   echo "waiting" >> /Users/aaron/result
  # done
  exit 0
}
#
# on_exit(){
#   echo "exiting" >> /Users/aaron/result
# }
#
# echo "starting - script pid $$" >> /Users/aaron/result
# trap "exit" EXIT
trap "shutdown" SIGINT SIGHUP SIGTERM
"$@" &
phantom_pid=$!
# echo "phantom_pid $phantom_pid" >> /Users/aaron/result
while read line ; do
  :
done
shutdown
