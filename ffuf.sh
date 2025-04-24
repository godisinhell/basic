#!/bin/bash

# Check for required tool
if ! command -v ffuf &> /dev/null; then
    echo "Error: ffuf is not installed. Please install it before proceeding."
    exit 1
fi

# Define custom User-Agent header
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:124.0) Gecko/20100101 Firefox/124.0"

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <hosts_file>"
    exit 1
fi

# Create or clear the combined output file
> ffuf_all.txt

# Read hosts from the file
while IFS= read -r host; do
    echo "Running ffuf on $host..."
    
    # Check host reachability
    if curl -s "$host" >/dev/null 2>&1; then
        # Run ffuf and append results to the combined file
        ffuf -u "${host}/FUZZ" \
             -w /usr/share/dirb/wordlists/common.txt \
             -H "User-Agent: ${USER_AGENT}" \
             -mc 200,301,302,307,401,403 \
             -rate 20 \
             -recursion \
             -recursion-depth 2 \
             -o "ffuf_${host##*/}.json" \
             -of json

        # If ffuf output exists, process and append to combined file
        if [[ -f "ffuf_${host##*/}.json" ]]; then
            echo "Results for $host:" >> ffuf_all.txt
            jq -r '.results[] | "\(.url) [\(.status)]"' "ffuf_${host##*/}.json" >> ffuf_all.txt
            echo -e "\n" >> ffuf_all.txt
            echo "Ffuf results for $host saved to ffuf_all.txt"
        else
            echo "Warning: No output file found for $host. Skipping append."
        fi
    else
        echo "Host $host is not reachable or dead. Skipping..."
    fi
done < "$1"

echo "All scanning completed. Combined results are in ffuf_all.txt"