#!/bin/bash
tos_values=(0 32 64 128)  # Example TOS values; adjust as needed
server_a_ip="germ176"  # Replace with the hostname or IP address of Server A
port=5001  # Initial port number
timeout=600  # Timeout value in seconds (default: 10 seconds)
bridge_network="my-bridge-network"  # Bridge network name

# Create the bridge network if it doesn't exist
podman network inspect $bridge_network >/dev/null 2>&1 || \
  podman network create $bridge_network

# Pull the iperf3 image from the networkstatic repository
podman image pull docker.io/networkstatic/iperf3

# Run iperf3 in a separate container for each combination of TOS and port
for tos in "${tos_values[@]}"; do
  podman run -d --rm --name iperf_$port \
    --network $bridge_network docker.io/networkstatic/iperf3 \
    iperf3 -c $server_a_ip -p $port --cport $port -t $timeout -S $tos
  echo "Container iperf_$port is running."
  ((port++))
done

