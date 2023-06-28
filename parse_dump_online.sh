#!/bin/bash
#
# Script: parse_dump_online.sh
# Description: Parses piped input line by line and writes to a file when the sequence starting
#              number on the current line does not match the sequence ending number on the
#              previous line.
# Usage: cat input.txt | ./parse_dump_online.sh
#

ss_filter='dport :5201'
output_file="/tmp/ss_output.txt"
>$output_file
prev_seq_ending=""
prev_seq_starting=""

# Check if there is piped input
if [ -t 0 ]; then
    echo "No piped input found. Please pipe input to the script."
    exit 1
fi

same_seq_counter=1
line_counter=0
while IFS= read -r line; do
    ((line_counter++))
    # filtering outgoing packets, associated with a delivered sequence range (trimming the last ',' char from it)
    seq_start_ending=$(awk ' $3 ~ Out && $11 ~ /[0-9]*:[0-9]*,/ { print substr($11, 1, length($11)-1)}' <<< "$line")
    if [[ "z"$seq_start_ending == "z" ]]; then
        continue
    fi

    seq_start=${seq_start_ending%:*}
    seq_end=${seq_start_ending#*:}

    #echo $line_counter: "$seq_start_ending"
    if [[ "$seq_start" -le "$prev_seq_start" ]]; then
        echo "$line_counter: $((same_seq_counter++)) |${seq_start}|$prev_seq_start|" 
        #echo $line >> "$output_file"
    	# /usr/sbin/ss -netim $ss_filter >> "$output_file"
    else
        same_seq_counter=1
    fi

    prev_seq_start="$seq_start"
    prev_seq_end="$seq_end"
    
done

