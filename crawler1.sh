#!/bin/bash

# Function to check if a command is installed
check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: $1 is not installed. Please install it before running the script."
        exit 1
    fi
}

# Check for required tools
for cmd in gau hakrawler waybackurls; do
    check_command "$cmd"
done

# Check if URL argument is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a URL as an argument."
    exit 1
fi

url="$1"
domain="$2"

# Validate URL format
if ! [[ "$url" =~ ^https?:// ]]; then
    echo "Error: Invalid URL format. Please provide a valid URL (e.g., https://example.com)."
    exit 1
fi


# Define output files
gau_output="gau_output.txt"
hakrawler_output="hakrawler_output.txt"
wayback_output="wayback_output.txt"
katana_output="katana_output.txt"
merged_output="merged_output.txt"
unique_urls="${domain}-urls.txt"
static_files="${domain}-static_files.txt"

# Run tools and save outputs to respective files
echo "$url" | gau > "$gau_output"
echo "$url" | hakrawler -subs > "$hakrawler_output"
echo "$url" | waybackurls > "$wayback_output"
katana -u "$url" -jc -d 10 > "$katana_output"

# Merge the outputs into one file
cat "$gau_output" "$hakrawler_output" "$wayback_output" "$katana_output"> "$merged_output"

# Filter and sort URLs
sort -uf "$merged_output" | grep -v -E '\.(js|css|jpeg|png|jpg|woff2|woff|gif)' > "$unique_urls"
sort -uf "$merged_output" | grep -E '\.(js|css|jpeg|png|jpg|woff2|woff|gif)' > "$static_files"

# Clean up temporary files
rm "$gau_output" "$hakrawler_output" "$wayback_output" "$merged_output" "$katana_output"

# Final message
echo "Script completed. Unique URLs without static files saved to $unique_urls."
