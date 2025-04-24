#!/bin/bash

# Check if a domain file is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <File>"
    exit 1
fi

echo "Running httpx-toolkit on $1..."
httpx -t 5 -sc -location -server -td -cname -asn -o "httpx_output.txt" < "$1"
echo "httpx-toolkit completed. Output saved to httpx_output.txt"

file_for_nuclei="httpx_output.txt"

# Getting all 200 hosts
grep '20[0-9][^[:alnum:]]' "$file_for_nuclei" | awk '{print $1}' > 200.txt

# Getting redirected URLs (300)
grep '30[0-9][^[:alnum:]]' "$file_for_nuclei" | awk -F'[][]' '{print $1}' > 300.txt

# Getting all 403
grep '40[0-9][^[:alnum:]]' "$file_for_nuclei" | awk '{print $1}' > 403.txt

# Combine all results into a single file
cat "200.txt" "300.txt" "403.txt" > all.txt
nuclei_file="all.txt"

# Create or clear any_bugs.txt
> any_bugs.txt

# Loop through each hostname in the nuclei file
while IFS= read -r hostname; do
    # Perform Nuclei scan and append the result
    nuclei -u "$hostname" -rl 25 -o nuclei_scan_full.txt
    
    # Check if the Nuclei scan was successful
    if [ $? -eq 0 ]; then
        # Extract lines containing 'medium', 'high', 'critical', or 'unknown' from the scan result
        grep -E 'medium|high|critical|unknown' nuclei_scan_full.txt >> any_bugs.txt
    else
        echo "Nuclei scan failed for: $hostname"
    fi
done < "$nuclei_file"

echo "Nuclei scans completed. Results saved in any_bugs.txt."
