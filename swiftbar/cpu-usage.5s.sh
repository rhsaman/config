#!/bin/bash
# <swiftbar.title>cpu usage</swiftbar.title>
# <swiftbar.version>1.0</swiftbar.version>
# <swiftbar.author>YourName</swiftbar.author>
# <swiftbar.desc>Show CPU usage</swiftbar.desc>

cpu=$(top -l 1 | awk '/CPU usage/ {print $3 + $5 "%"}')
echo "CPU: $cpu | refresh=true"
