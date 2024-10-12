#!/bin/bash

# Check if directory is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Verify the directory exists
if [ ! -d "$1" ]; then
  echo "Error: Directory '$1' does not exist."
  exit 1
fi

# Iterate over all files in the directory
for file in "$1"/*; do
  if [ -f "$file" ]; then
    # Remove \r characters and save in-place
    sed -i 's/\r//g' "$file"
  fi
done

echo "Clean scripts: all files processed successfully."
