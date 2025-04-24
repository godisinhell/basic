#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 3 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <input_file> <output_file> <domain_name>"
    exit 1
fi

# Input file (URLs), output file, and list of domains to match
input_file="$1"
output_file="$2"
shift 2 # Shift off the first two arguments (input_file and output_file), leaving only domains

# Clear the output file
> "$output_file"

# Loop through each URL in the input file
while IFS= read -r url; do
    # Extract the domain name from the URL using sed
    domain=$(echo "$url" | sed -E 's|https?://([^/]+)/?.*|\1|')

    # Check if the extracted domain matches any of the provided domain arguments
    for arg_domain in "$@"; do
        if [[ "$domain" == "$arg_domain" ]]; then
            echo "$url" >> "$output_file"
            break
        fi
    done
done < "$input_file"

echo "Matching URLs saved to $output_file"
