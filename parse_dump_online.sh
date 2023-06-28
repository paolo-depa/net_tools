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
true > $output_file
prev_seq_end="0"
prev_seq_start="0"

# Check if there is piped input
if [ $# -ne 1 ] || [ ! -r $1 ]; then
    echo "Usage: $0 <FILE_TO_PARSE>"
    exit 1
fi


line_counter=0
while read line; do
    ((line_counter++))

    # filtering outgoing packets, associated with a delivered sequence range (trimming the last ',' char from it)
    seq_start_ending=$(awk ' $3 ~ Out && $11 ~ /[0-9]*:[0-9]*,/ { print substr($11, 1, length($11)-1)}' <<< "$line")
    if [[ "z"$seq_start_ending == "z" ]]; then
        continue
    fi

    seq_start=${seq_start_ending%:*}
    seq_end=${seq_start_ending#*:}

    if [[ "$seq_start" -gt "$prev_seq_end" ]]; then

        #Jump in the sequence detected: searching for retransmissions of the same seq number through outgoing packets
        occurrences=$(tail -n +$line_counter "$1" | grep "$prev_seq_end:" | grep -c "Out")

        if [[ $occurrences -gt 0 ]]; then
            echo "$line_counter: |${seq_start}|$prev_seq_end|$occurrences"
            #echo $line >> "$output_file"
            # /usr/sbin/ss -netim $ss_filter >> "$output_file"
        fi
    fi

    prev_seq_start="$seq_start"
    prev_seq_end="$seq_end"
    
done < "$1"

