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

# Check if there is piped input
if [ -t 0 ]; then
    echo "No piped input found. Please pipe input to the script."
    exit 1
fi

while IFS= read -r line; do
    seq_start_ending=$(awk -F', ' '{gsub("seq ","",$2);print $2}' <<< "$line")

    if [[ "${seq_start_ending%:*}" -lt "$prev_seq_ending" ]]; then
	echo "|${seq_start_ending%:*}|$prev_seq_ending|" 
	echo $line >> "$output_file"
    	/usr/sbin/ss -netim $ss_filter >> "$output_file"
    else
	echo good
    fi

    prev_seq_ending="${seq_start_ending#*:}"
done

