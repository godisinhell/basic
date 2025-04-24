#!/bin/bash


##This code takes a file as input and gives 3 differnet files depending on the response code status

# Check if the input file is provided as a command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Getting all 200 hosts
grep '200[^[:alnum:]]' "$input_file" | awk '{print $1}' > 200.txt

# Getting redirected urls 300

grep '30[0-9][^[:alnum:]]' "$input_file" | awk -F'[][]' '{print $1}' > 300.txt

# Getting all 403

grep '403[^[:alnum:]]' manual_read_httpx_output.txt | awk '{print $1}' > 403.txt




