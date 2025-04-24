#!/bin/bash

# Read the file of hosts and ports
while IFS=':' read -r host port; do
  # Build the nmap command for each host-port pair
  nmap_command="nmap -p $port $host -A -sC -sV"

  # Execute the nmap command and output to separate files
  echo "Scanning $host:$port..."
  eval "$nmap_command" >> "scan_$host.txt" 2>&1
done < "$1"

echo "Completed the scanning"

