#!/bin/bash

# Check for required tool
if ! command -v dirsearch &> /dev/null; then
  echo "Error: dirsearch is not installed. Please install it before proceeding."
  exit 1
fi

# Define custom User-Agent header
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:124.0) Gecko/20100101 Firefox/124.0"

# Function to run dirsearch on a host
run_dirsearch() {
  local host="$1"
  local output_file="$2"
  dirsearch -u "$host" -H "User-Agent: $USER_AGENT" -r --max-rate 30 --exclude-status 400,404,405 -w /usr/share/dirb/wordlists/common.txt -F -o "$output_file"
}

# Function to process hosts from a file
process_hosts() {
  local filename="$1"
  while IFS= read -r host; do
    echo "Running dirsearch on $host..."
    # Check host reachability (optional)
    if curl -s "$host" >/dev/null 2>&1; then
      output_file="/usr/lib/python3/dist-packages/dirsearch/dirsearch.txt"
      run_dirsearch "$host" "$output_file"
      
      # Check if the output file exists before appending
      if [[ -f "$output_file" ]]; then
        cat "$output_file" >> "dirsearch_all.txt"
        rm "$output_file"
        echo "Dirsearch results for $host saved to dirsearch_all.txt"
      else
        echo "Warning: $output_file not found. Skipping append."
      fi
      
    else
      echo "Host $host is not reachable or dead. Skipping..."
    fi
  done < "$filename"
}

# Check if two input files are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 200.txt 403.txt"
  exit 1
fi

# Process hosts from the first file (200.txt)
process_hosts "$1"

# Process hosts from the second file (403.txt)
process_hosts "$2"
