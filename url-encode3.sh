#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 3 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <input_file> <output_file> <error_file>"
    exit 1
fi

# Input, output, and error file paths
input_file="$1"
output_file="$2"
error_file="$3"

# Clear the output and error files
> "$output_file"
> "$error_file"

# Process URLs with single quotes and handle in parallel
grep "'" "$input_file" >> "$error_file"

# Encode URLs in parallel
cat "$input_file" | grep -v "'" | parallel -j 80 'python3 -c "import urllib.parse; import sys; print(urllib.parse.quote(sys.argv[1], safe=\":/?&=\"))" {}' >> "$output_file"


echo "Encoded URLs saved to $output_file"
echo "URLs with single quotes saved to $error_file"

