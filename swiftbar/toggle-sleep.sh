#!/bin/bash

# <swiftbar.title>🌙 Sleep</swiftbar.title>
# <swiftbar.refreshOnClick>true</swiftbar.refreshOnClick>

CURRENT=$(pmset -g | grep displaysleep | awk '{print $2}')

# این خط اول خروجی منوباره
if [ "$CURRENT" = "10" ]; then
  echo "⏳run"
else
  echo "⏳stop"
fi


echo "---"

if [ "$CURRENT" = "10" ]; then
  echo "⏳stop | bash='/usr/bin/sudo' param1='/usr/bin/pmset' param2='displaysleep' param3='0' refresh=true terminal=false"
else
  echo "⏳Set to 10m | bash='/usr/bin/sudo' param1='/usr/bin/pmset' param2='displaysleep' param3='10' refresh=true terminal=false"
fi
