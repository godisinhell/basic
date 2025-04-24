#!/bin/bash

# Check if a domain is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain="$1"
echo "Working with domain: $domain"

# Create a folder for the domain
folder_name="${domain}"
mkdir -p "$folder_name"

# Run amass and save output to a file
echo "Running amass..."
amass enum -d "$domain" -o "$folder_name/amass.txt"
echo "amass completed. Output saved to $folder_name/amass.txt"


# Run subfinder and save output to a file
echo "Running subfinder..."
subfinder -d "$domain" -all -o "$folder_name/subfinder_output.txt"
echo "subfinder completed. Output saved to $folder_name/subfinder_output.txt"

# Run shrewdeye.sh and save output to a file
echo "Running shrewdeye.sh..."
shrewdeye.sh -d "$domain" > "$folder_name/shrewdeye_output.txt"
echo "shrewdeye.sh completed. Output saved to $folder_name/shrewdeye_output.txt"


# Merge and sort by unique
echo "Merging and sorting..."
cat "$folder_name/amass.txt" "$folder_name/subfinder_output.txt" "$folder_name/shrewdeye_output.txt" | sort -u > "$folder_name/uniq_domains.txt"
echo "Merged and sorted output saved to $folder_name/uniq_domains.txt"

# Run httpx-toolkit 
echo "Running httpx-toolkit on uniq_domains.txt..."
cat "$folder_name/uniq_domains.txt" | httpx -t 5 -sc -location -server -td -cname -asn -o "$folder_name/httpx_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/httpx_output.txt"


## Get domains from httpx
cut -d ' ' -f 1 "$folder_name/httpx_output.txt" > "final_merged_output.txt"
mv "final_merged_output.txt" "$folder_name/subdomains.txt" 

##Input file from httpx command above
input_file="$folder_name/subdomains.txt"

# Define output and alive file names based on input file
output_file="${input_file}_output.txt"
alive_file="$subdomain_alive.txt"

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

# Wait for all background jobs to finish and rename
wait
mv "${input_file}_alive.txt" "$folder_name/hostfor-naabu.txt"



# Run naabu on naabu_alive.txt
echo "Running naabu on hostfor-naabu.txt"
cat "$folder_name/hostfor-naabu.txt" | parallel -j3 'naabu -host {} -nmap-cli "nmap -sV -oX nmap-output" >> naabu_output.txt'


##Grep hosts from naabu_output.txt
##If hostname from naabu is required use uncomment this.
#cgrep -oP '[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+:\d+' manual_check_naabu_output.txt > "$folder_name/hostname_from_naabu.txt"
#sed -n 's/.*for \([^ ]*\) .*/\1/p' naabu_output.txt > "hostname_from_naabu.txt"


##Run nuclei

input_file_nuclei="$folder_name/hostfor-naabu.txt"

# Loop through each hostname in the input file
while IFS= read -r hostname; do
    # Perform Nuclei scan and save the result to a temporary file
    nuclei -u "$hostname" -rl 50 -o nuclei_scan_full.txt

    # Extract lines containing 'high' or 'critical' from the scan result
    grep -E 'medium|high|critical|unknown' nuclei_scan_full.txt >> any_bugs.txt

done < "$input_file_nuclei"

# Remove the output files.
echo "Cleaning up all the junks"
rm "$output_file"
rm "$folder_name/amass.txt"
rm "$folder_name/subfinder_output.txt"
rm "$folder_name/shrewdeye_output.txt"
rm "$folder_name/merged_output.txt"
rm "$folder_name/naabu_alive.txt"

echo "Intermediate files saved in $folder_name folder."
