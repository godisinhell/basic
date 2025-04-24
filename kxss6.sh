#!/bin/bash

# Check if exactly one argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"
output_file="kxss_output.txt"

# Clear the output file if it exists, or create a new one
> "$output_file"

# Process each line of the input file
while IFS= read -r line; do
    # Pass each URL to kxss and append the output to the file
    echo "$line" | kxss >> "$output_file"
done < "$input_file"

echo "Processing complete. Output saved to $output_file."
