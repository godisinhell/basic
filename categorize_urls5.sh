#!/bin/bash

# Check if a file argument is provided
if [ -z "$1" ]; then
  echo "Please provide a file as an argument."
  echo "Usage: $0 <input_file>"
  exit 1
fi

# Create output files if they do not exist
touch 300-redir.txt 200.txt 404.txt unautorised.txt urls-with-parameters.txt

# Process the file and categorize URLs
while read -r line; do
  # Extract status code and URL
  status_code=$(echo "$line" | awk '{print $1}')
  url=$(echo "$line" | awk '{print $2}')

  # Save URLs with parameters separately
  if [[ "$url" == *\?* ]]; then
    echo "$url" >> urls-with-parameters.txt
  fi

  # Categorize based on the status code
  case "$status_code" in
    200)
      echo "$url" >> 200.txt
      ;;
    301|302|303|304|305|306|307|308)
      echo "$url" >> 300-redir.txt
      ;;
    404)
      echo "$url" >> 404.txt
      ;;
    401|403)
      echo "$url" >> unautorised.txt
      ;;
    *)
      # Ignore other status codes
      ;;
  esac
done < "$1"
