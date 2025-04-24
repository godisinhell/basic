#!/bin/bash

##This script doesn't work from Digital Ocean. Security Trails have banned Digital Ocean ip maybe.

# Check if the domain argument is provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <domain> <path_key>"
    exit 1
fi

domain="$1"
path_key="$2"

URL='https://securitytrails.com/api/auth/login'
DATA='{"email":"jeetbhdr@bugcrowdninja.com","password":"Trailspassword01@@"}'

# Execute the curl command and capture the response
RESPONSE=$(curl --path-as-is -i -s -k -X POST \
    -H 'Host: securitytrails.com' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:129.0) Gecko/20100101 Firefox/129.0' \
    -H 'Content-Type: application/json' \
    -H 'Te: trailers' \
    -H 'Content-Length: '${#DATA} \
    --data-binary "$DATA" \
    "$URL")

# Extract just the SecurityTrails cookie value
COOKIE_VALUE=$(echo "$RESPONSE" | grep -i 'Set-Cookie: SecurityTrails=' | awk -F '=' '{print $2}' | awk -F ';' '{print $1}')

# Check if COOKIE_VALUE is correctly extracted
if [ -z "$COOKIE_VALUE" ]; then
    echo "Failed to extract SecurityTrails cookie."
    exit 1
fi

##A Name Record

# Initialize page number
page=1

# Loop until no "ip" is found in the response
while true; do
    # Define the URL with the current page number
    url="https://securitytrails.com/_next/data/$path_key/domain/$domain/history/a.json?page=$page&domain=$domain&type=a"

    # Perform the curl request and save the response to a file
    curl --path-as-is -i -s -k -X GET \
        -H 'Host: securitytrails.com' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:129.0) Gecko/20100101 Firefox/129.0' \
        -H 'Accept: */*' \
        -b "SecurityTrails=${COOKIE_VALUE}" \
        "$url" > "page_${page}.txt"

    # Greps out ip from the collected page
    awk -F'"ip":"' '{ for(i=2;i<=NF;i++) { split($i, a, "\""); print a[1] } }' "page_${page}.txt" >> "${domain}_ip.txt"

    # Check if the response contains "ip"
    if grep -q '"ip"' "page_${page}.txt"; then
        echo "Page $page contains 'ip'."
        # Increment the page number and continue the loop
        rm "page_${page}.txt"
        page=$((page + 1))
    else
        echo "Page $page does not contain 'ip'."
        rm "page_${page}.txt"
        # Stop the loop
        break
    fi
done


#SUBDOMAIN Records

# Initialize page number
page=1

# Define the initial URL for the first page
url="https://securitytrails.com/_next/data/$path_key/list/apex_domain/$domain.json?page=$page&domain=$domain"

# Perform the initial curl request to get the subdomainsCount
curl --path-as-is -i -s -k -X GET \
    -H 'Host: securitytrails.com' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:129.0) Gecko/20100101 Firefox/129.0' \
    -H 'Accept: */*' \
    -b "SecurityTrails=${COOKIE_VALUE}" \
    "$url" > "page_${page}.txt"

# Extract subdomainsCount from the response
subdomains_count=$(grep -o '"subdomainsCount":[0-9]*' "page_${page}.txt" | grep -o '[0-9]*')

# Calculate the maximum number of pages
max_page=$((subdomains_count / 100 + 1))


# Loop through pages until reaching the max_page
while [ $page -le $max_page ]; do
    # Define the URL with the current page number
    url="https://securitytrails.com/_next/data/$path_key/list/apex_domain/$domain.json?&domain=$domain&page=$page"

    # Perform the curl request and save the response to a file
    curl --path-as-is -i -s -k -X GET \
        -H 'Host: securitytrails.com' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:129.0) Gecko/20100101 Firefox/129.0' \
        -H 'Accept: */*' \
        -b "SecurityTrails=${COOKIE_VALUE}" \
        "$url" > "page_${page}.txt"

    # Grep out IPs from the collected page
    awk -F'"hostname":"' '{ for(i=2;i<=NF;i++) { split($i, a, "\""); print a[1] } }' "page_${page}.txt" >> "${domain}_subdomain.txt"
    
    rm "page_${page}.txt"
    # Increment the page number
    page=$((page + 1))
done

echo "Finished processing up to page $max_page."





