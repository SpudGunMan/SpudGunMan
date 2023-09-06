
#!/bin/bash
# Calculate POTA shift (Early/Day/Late)
# This script will calculate the current POTA shift based on the current time in UTC
# MIT License Copyright 2023 Kelly Keeton K7MHI
# version 1.0.0

# set variables for shift times by looking at the POTA Shifts Map and converting to local time
# Shifts map https://docs.pota.app/assets/images/shift_map.png
# shown below in 24 hour format, shift time as viewed on the park time zone map
early_start_local=0300
early_end_local=0900
late_start_local=1700

# Get the current time in local time
local_time=$(date +%H%M)

# Check if the current time is between the early shift
if [ $local_time -ge $early_start_local ] && [ $local_time -lt $early_end_local ]; then
    echo "POTA Early Shift"
    exit 0
fi

# Check if the current time is between the late shift
if [ $local_time -ge $late_start_local ]; then
    echo "POTA Late Shift"
    exit 0
fi

if [ $local_time -gt $early_end_local ] && [ $local_time -lt $late_start_local ]; then
    echo "POTA Day Shift"
    exit 0
fi

echo "POTA Shift Unknown, like what happened..."
exit 1
