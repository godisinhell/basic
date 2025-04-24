#!/bin/bash
set -euo pipefail

# Function to check URL and get status code
check_url() {
    local url="$1"
    # Remove any leading/trailing whitespace
    url=$(echo "$url" | xargs)
    
    if [[ -z "$url" ]]; then
        echo "ERROR Empty URL"
        return 1
    fi

    # Attempt curl with timeout and retry
    response=$(curl --http2 --keepalive-time 60 \
            --connect-timeout 3 --max-time 5 \
            -L --max-redirs 3 \
            --retry 3 --retry-delay 2 \
            -s -o /dev/null -w '%{http_code}' \
            "$url") || {
        echo "ERROR Failed to fetch $url"
        return 1
    }
    
    echo "$response $url"
}

usage() {
    echo "Usage: $0 <url_file> [output_file]"
    echo "  url_file:    File containing list of URLs to check"
    echo "  output_file: Optional output file (default: response_codes.txt)"
    exit 1
}

# Check if we have at least one argument
if [[ $# -lt 1 ]]; then
    echo "Error: Missing required argument"
    usage
fi

# Check if required commands are installed
for cmd in parallel curl sed; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' command is not installed"
        echo "Please install $cmd first"
        exit 1
    fi
done

# Get the file name from the command-line argument
url_file="$1"
output_file="$2"  # Second argument for output file

# Check if the URL file exists and is readable
if [[ ! -f "$url_file" ]]; then
    echo "Error: File not found: $url_file"
    exit 1
fi

if [[ ! -r "$url_file" ]]; then
    echo "Error: Cannot read file: $url_file"
    exit 1
fi

# Check if output file is provided, if not set default
if [[ -z "$output_file" ]]; then
    output_file="response_codes.txt"  # Default output file
fi

# Create or clear the output file
> "$output_file"

# Process URLs in parallel with proper URL handling
export -f check_url
if ! parallel --line-buffer \
            --no-notice \
            -j 10000 \
            --colsep '\n' \
            --retries 3 \
            'check_url {1}' \
            :::: "$url_file" &> "$output_file"; then
    echo "Error: Failed to process URLs"
    exit 1
fi

# Remove any error messages from the output file
sed -i '' '/^ERROR/d;/^$/d' "$output_file"
echo "Successfully saved output to: $output_file"
