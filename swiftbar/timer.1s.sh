#!/bin/bash

# <swiftbar.title=Timer>
# <swiftbar.version=1.0>
# <swiftbar.language=bash>
# <swiftbar.author=YourName>
# <swiftbar.desc=A countdown timer with alert>
# <swiftbar.dependencies=>
# <swiftbar.refresh=1>

TIMER_FILE="/tmp/swiftbar_timer_end"
ALERT_FILE="/tmp/swiftbar_timer_alert"
now=$(date +%s)

if [[ "$1" == "start" && -n "$2" ]]; then
  end=$((now + $2))
  echo $end > "$TIMER_FILE"
  rm -f "$ALERT_FILE"    # reset alert flag on new start
  exit
fi

if [[ "$1" == "stop" ]]; then
  rm -f "$TIMER_FILE" "$ALERT_FILE"
  exit
fi

if [[ -f "$TIMER_FILE" ]]; then
  end=$(cat "$TIMER_FILE")
  remaining=$((end - now))
  if (( remaining <= 0 )); then
    if [[ ! -f "$ALERT_FILE" ]]; then
      afplay /System/Library/Sounds/Ping.aiff
      osascript -e 'display notification "Time is up!" with title "⏰ SwiftBar Timer"'
      touch "$ALERT_FILE"
    fi
    echo "⏰"
  else
    mins=$((remaining / 60))
    secs=$((remaining % 60))
    printf "⏰ %02d:%02d\n" $mins $secs
  fi
else
  echo "⏰"
fi

echo "---"
echo "Start 30 min | bash='$0' param1=start param2=1800 terminal=false refresh=true"
echo "Start 60 min | bash='$0' param1=start param2=3600 terminal=false refresh=true"
echo "Start 4 min | bash='$0' param1=start param2=300 terminal=false refresh=true"
echo "Stop Timer | bash='$0' param1=stop terminal=false refresh=true"
