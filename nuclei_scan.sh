#!/bin/bash

# Check if the input file is provided as a command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Input file containing hostnames
input_file="$1"

# Nuclei Update
echo "Updating Nuclei"
nuclei -up -ut

# Loop through each hostname in the input file
while IFS= read -r hostname; do
    # Perform Nuclei scan and save the result to a temporary file
    nuclei -u "$hostname" > temp_scan_result.txt

    # Extract lines containing 'high' or 'critical' from the scan result
    cat temp_scan_result.txt >> all_scans.txt

    # Delete the temporary scan result file
    rm temp_scan_result.txt

done < "$input_file"

