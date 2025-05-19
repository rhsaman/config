#!/bin/bash
# <swiftbar.title>ram usage</swiftbar.title>
# <swiftbar.version>1.0</swiftbar.version>
# <swiftbar.desc>Show RAM usage</swiftbar.desc>

pagesize=4096

# گرفتن تعداد صفحات حافظه از vm_stat
active=$(vm_stat | awk '/Pages active:/ {print $3}' | sed 's/\.//')
wired=$(vm_stat | awk '/Pages wired down:/ {print $4}' | sed 's/\.//')
speculative=$(vm_stat | awk '/Pages speculative:/ {print $3}' | sed 's/\.//')
free=$(vm_stat | awk '/Pages free:/ {print $3}' | sed 's/\.//')

# محاسبه مقدار حافظه استفاده شده و کل حافظه
used=$(( (active + wired + speculative) * pagesize ))
free_mem=$(( free * pagesize ))
total=$(( used + free_mem ))

# تبدیل به مگابایت
used_mb=$(( used / 1024 / 1024 ))
total_mb=$(( total / 1024 / 1024 ))

# درصد استفاده
percent=$(echo "scale=1; $used_mb * 100 / $total_mb" | bc)

echo "RAM: ${percent}%  | refresh=true"

