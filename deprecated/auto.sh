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
cat "$folder_name/amass.txt" "$folder_name/subfinder_output.txt" "$folder_name/shrewdeye_output.txt" | sort -u > "$folder_name/merged_output.txt"
echo "Merged and sorted output saved to $folder_name/merged_output.txt"

# Run httpx-toolkit 
echo "Running httpx-toolkit on merged_output.txt..."
cat "$folder_name/merged_output.txt" | httpx -t 5 -sc -location -server -td -cname -asn -o "$folder_name/manual_read_httpx_output.txt"
echo "httpx-toolkit completed. Output saved to $folder_name/manual_read_httpx_output.txt"


## Get domains from httpx
cut -d ' ' -f 1 "$folder_name/manual_read_httpx_output.txt" > "final_merged_output.txt"
mv "final_merged_output.txt" "$folder_name/subdomains_all.txt" 

##Input file from httpx command above
input_file="$folder_name/subdomains_all.txt"

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

# Wait for all background jobs to finish and rename
wait
mv "${input_file}_alive.txt" "$folder_name/naabu_alive.txt"



# Run naabu on naabu_alive.txt
echo "Running naabu on naabu_alive.txt"
cat "$folder_name/naabu_alive.txt" | parallel -j3 'naabu -host {} -nmap-cli "nmap -sV -oX nmap-output" >> manual_check_naabu_output.txt'


##Grep hosts from naabu_output.txt
#cgrep -oP '[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+:\d+' manual_check_naabu_output.txt > "$folder_name/hostname_from_naabu.txt"
#sed -n 's/.*for \([^ ]*\) .*/\1/p' "$folder_name/manual_check_naabu_output.txt" > "$folder_name/hostname_from_naabu.txt"

mv "manual_check_naabu_output.txt" "$folder_name/manual_check_naabu_output.txt"


# Remove the output files.
echo "Cleaning up all the junks"
rm "$output_file"
rm "$folder_name/subfinder_output.txt"
rm "$folder_name/shrewdeye_output.txt"
rm "$folder_name/merged_output.txt"
rm "$folder_name/naabu_alive.txt"
rm "nmap-output"

echo "Intermediate files saved in $folder_name folder."
