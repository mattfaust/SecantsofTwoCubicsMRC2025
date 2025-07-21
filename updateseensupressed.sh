#!/bin/bash

# Path to your Python script
PYTHON_SCRIPT="coupon2.py"

# Find and process each "results.txt" file
find . -type f -name "results.txt" | while read -r file; do
    echo "📄 Processing: $file"
    python3 "$PYTHON_SCRIPT" "$file" > /dev/null 2>&1
done
