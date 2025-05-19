#!/bin/bash

# <swiftbar.title>🖥️ Sleep</swiftbar.title>
# <swiftbar.refreshOnClick>true</swiftbar.refreshOnClick>

CURRENT=$(pmset -g | grep displaysleep | awk '{print $2}')

# این خط اول خروجی منوباره
if [ "$CURRENT" = "10" ]; then
  echo "🖥️ 10m"
elif [ "$CURRENT" = "15" ]; then 
  echo "🖥️ 15m"
else
  echo "📴"
fi


echo "---"

echo "🖥️ Set display sleep to 10 minutes | bash='/usr/bin/sudo' param1='/usr/bin/pmset' param2='displaysleep' param3='10' refresh=true terminal=false"
echo "🖥️ Set display sleep to 15 minutes | bash='/usr/bin/sudo' param1='/usr/bin/pmset' param2='displaysleep' param3='15' refresh=true terminal=false"
echo "📴 Turn display sleep off | bash='/usr/bin/sudo' param1='/usr/bin/pmset' param2='displaysleep' param3='0' refresh=true terminal=false"
