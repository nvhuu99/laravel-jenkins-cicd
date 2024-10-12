#!/bin/bash

# Check if prefix is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <prefix>"
    exit 1
fi

PREFIX="$1"

# Fetch all branches
git fetch --all

# Get all local branches that start with the specified prefix
branches=$(git branch --list "$PREFIX*")

# Exit if no branches are found with the prefix
if [ -z "$branches" ]; then
    echo "No branches found with prefix '$PREFIX'."
    exit 0
fi

# Loop through the branches and delete them
for branch in $branches; do
    # Avoid deleting master or main branch by accident
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        echo "Skipping protected branch: $branch"
        continue
    fi

    # Confirm deletion
    echo "Deleting branch: $branch"
    git branch -D "$branch"
done
