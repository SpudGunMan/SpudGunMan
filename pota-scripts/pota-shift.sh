
#!/bin/bash
# Calculate POTA shift (Early/Day/Late)
# This script will calculate the current POTA shift based on the current time in UTC
# MIT License Copyright 2023 Kelly Keeton K7MHI

# set variables for shift times by looking at the POTA Shifts Map and converting to local time
# Shifts map https://docs.pota.app/assets/images/shift_map.png
# "PST" time zone shown below in 24 hour format, shift time do not follow time zone see map
early_start_local=0300
early_end_local=0900
late_start_local=1700

# example of "EST" time zone shown below in 24 hour format
#early_start_local=0600
#early_end_local=1200
#late_start_local=2200

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

# If the current time is not in the early or late shift then
echo "POTA Day Shift"
exit 0
