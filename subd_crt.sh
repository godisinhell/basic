#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <organization_name>"
    exit 1
fi

org_name="$1"
crt_sh_url="https://crt.sh/?o=${org_name// /%2C+}&output=json"
output_file="${org_name}_crt_data.json"
subdomains_file="subdomains.txt"
hosts_file="hosts.txt"

echo "Fetching raw data for $org_name from crt.sh..."

curl -s "$crt_sh_url" > "$output_file"

# Extracting common_name value using jq and saving to a file
jq -r '.[].common_name' "$output_file" | sed 's/\*\.//' > "$subdomains_file"

# Extracting host names from the subdomains
awk -F. '{print $(NF-1)"."$NF}' "$subdomains_file" | sort | uniq > "$hosts_file"

# Cleanup
rm "$output_file"

echo "Subdomains for $org_name saved to $subdomains_file"
echo "Hosts for $org_name saved to $hosts_file"
