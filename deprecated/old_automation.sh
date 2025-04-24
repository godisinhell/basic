#!/bin/bash

# Check if a domain is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain="$1"
echo "Working with domain: $domain"

# Create a folder for the domain
folder_name="${domain}_output"
mkdir -p "$folder_name"

# Run knockpy and save output to a file
echo "Running knockpy..."
knockpy "$domain" --no-local --silent csv > "$folder_name/knockpy_output.csv"
echo "knockpy completed. Output saved to $folder_name/knockpy_output.csv"

# Seperating ip and domains from knockpy_output
awk 'BEGIN{FS=OFS=";"} {print $1}' "$folder_name/knockpy_output.csv" > "$folder_name/knockpy_ip.txt"
awk 'BEGIN{FS=OFS=";"} {print $3}' "$folder_name/knockpy_output.csv" > "$folder_name/knockpy_output.txt"

# Run httpx-toolkit
echo "Running httpx-toolkit on knockpy_output.txt..."
cat "$folder_name/knockpy_output.txt" | httpx > "$folder_name/knockpy_httpx_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/knockpy_httpx_output.txt"

# Run subfinder and save output to a file
echo "Running subfinder..."
subfinder -d "$domain" > "$folder_name/subfinder_output.txt"
echo "subfinder completed. Output saved to $folder_name/subfinder_output.txt"

# Run shrewdeye.sh and save output to a file
echo "Running shrewdeye.sh..."
shrewdeye.sh -d "$domain" > "$folder_name/shrewdeye_output.txt"
echo "shrewdeye.sh completed. Output saved to $folder_name/shrewdeye_output.txt"

# Run httpx-toolkit
echo "Running httpx-toolkit on subfinder_output.txt..."
cat "$folder_name/subfinder_output.txt" | httpx > "$folder_name/subfinder_httpx_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/subfinder_httpx_output.txt"

echo "Running httpx-toolkit on shrewdeye_output.txt..."
cat "$folder_name/shrewdeye_output.txt" | httpx > "$folder_name/shrewdeye_httpx_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/shrewdeye_httpx_output.txt"

# Merge and sort by unique
echo "Merging and sorting..."
cat "$folder_name/knockpy_httpx_output.txt" "$folder_name/subfinder_httpx_output.txt" "$folder_name/shrewdeye_httpx_output.txt" | sort -u > "$folder_name/merged_output.txt"
echo "Merged and sorted output saved to $folder_name/merged_output.txt"

# Run httpx-toolkit final
echo "Running httpx-toolkit on merged_output.txt..."
cat "$folder_name/merged_output.txt" | httpx > "$folder_name/final_merged_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/final_merged_output.txt"


##Input file from httpx command above
input_file="$folder_name/final_merged_output.txt"

# Check if the provided input file exists and is a regular file
if [ ! -f "$input_file" ]; then
    echo "Error: The provided input file does not exist or is not a regular file."
    exit 1
fi

# Define output and alive file names based on input file
output_file="${input_file}_output.txt"
alive_file="${input_file}_alive.txt"

# Remove "http://" or "https://" from URLs in the input file
sed -e 's|^http://||' -e 's|^https://||' "$input_file" > "$output_file"

check_reachability() {
    local hostname=$1
    if ping -c 1 "$hostname" &> /dev/null; then
        echo "$hostname" >> "$alive_file"
    fi
}

# Read output file and run check_reachability in the background
while IFS= read -r hostname; do
    check_reachability "$hostname" &
done < "$output_file"

# Wait for all background jobs to finish
wait

# Remove the output file and rename the alive file.
rm "$output_file"
mv "${input_file}_alive.txt" "naabu_alive.txt"


# Run naabu on naabu_alive.txt
echo "Running naabu on naabu_alive.tx"
cat naabu_alive.txt | parallel -j10 'naabu -host {} -nmap-cli "nmap -sV -oX nmap-output" >> naabu_output.txt'


##Grep hosts from naabu_output.txt
grep -oP '[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+:\d+' naabu_output.txt > "$folder_name/hostname_from_naabu.txt"

##Run nuclei

input_file_nuclei="$folder_name/hostname_from_naabu.txt"

# Loop through each hostname in the input file
while IFS= read -r hostname; do
    # Perform Nuclei scan and save the result to a temporary file
    nuclei -u "$hostname" -rl 10 > temp_scan_result.txt

    # Extract lines containing 'high' or 'critical' from the scan result
    grep -E 'medium|high|critical|unknown' temp_scan_result.txt >> high_critical_results.txt

    # Delete the temporary scan result file
    rm temp_scan_result.txt

done < "$input_file_nuclei"


echo "Intermediate files saved in $folder_name folder."
