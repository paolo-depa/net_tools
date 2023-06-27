#!/bin/bash
port=5001  # Initial port number

# Start iperf servers on the same ports where the clients bind to
for ((port=5001; port<=5004; port++)); do
  iperf3 -s --port $port &
  echo "iperf server started on port $port."
done

