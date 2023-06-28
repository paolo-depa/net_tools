#!/bin/bash
#
# Script: iperf3_client_start.sh
# Description: Script to start iperf3 client containers running with different TOS values
#
# Author: paolodepa
# Date: 2023-06-27
#
# Usage: ./iperf3_client_start.sh
#

iperf_img="docker.io/networkstatic/iperf3"
tos_values=(0 8 16)  # Example TOS values; adjust as needed
server_a_ip="germ176"  # Replace with the hostname or IP address of Server A
port=5001  # Initial port number
timeout=600  # Timeout value in seconds (default: 10 seconds)
bridge_network="my-bridge-network"  # Bridge network name
macvlan_network="macvlan-net"
macvlan_nic="eth0"

# Create the bridge network if it doesn't exist
# podman network inspect $bridge_network >/dev/null 2>&1 ||
#   podman network create $bridge_network

# Uncomment the above lines to create a bridged network using Podman

# Create the macvlan network if it doesn't exist
podman network inspect $macvlan_network >/dev/null 2>&1 ||
  podman network create -d macvlan -o parent=$macvlan_nic $macvlan_network

# Pull the iperf3 image from the networkstatic repository if not already present
podman image exists $iperf_img >/dev/null 2>&1 ||
  podman image pull $iperf_img

# Run iperf3 in a separate container for each combination of TOS and port
for tos in "${tos_values[@]}"; do

  echo "======= TOS: $TOS / PORT: $port ======="

  tcpdump -ni any host $server_a_ip and port $port -v > /tmp/$port.txt &
  echo "TOS: $tos traffic being captured in /tmp/$port.pcap"

  podman run -d --rm --name iperf_$port --cap-add CAP_NET_RAW --cap-add CAP_NET_ADMIN \
    --network $macvlan_network $iperf_img \
    iperf3 -c $server_a_ip -p $port --cport $port -t $timeout -S "$tos"
  echo "Container iperf_$port is running."
  
  ((port++))
done

echo ""
echo "======================================================================"
echo "Don't forget to monitor the pods and, on completion, to stop tcpdumps:"
echo ""
echo "watch -n 1 'podman ps'"
echo "killall tcpdump"
