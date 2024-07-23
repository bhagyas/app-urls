#!/bin/bash

# Function to find the app ID from the App Store URL
get_app_id() {
    local url=$1
    local app_id=$(echo $url | sed -n 's/.*id\([0-9]*\).*/\1/p')
    echo $app_id
}

# Function to download the lookup file and extract the bundle ID
get_bundle_id() {
    local app_id=$1
    local lookup_url="https://itunes.apple.com/lookup?id=$app_id"
    curl -s $lookup_url -o 1.txt
    local bundle_id=$(sed -n 's/.*"bundleId":"\([^"]*\)".*/\1/p' 1.txt)
    echo $bundle_id
}

# Main script
if [ -z "$1" ]; then
    echo "Usage: $0 <App Store URL>"
    exit 1
fi

app_store_url=$1
app_id=$(get_app_id $app_store_url)
if [ -z "$app_id" ]; then
    echo "Failed to extract app ID from the URL."
    exit 1
fi

bundle_id=$(get_bundle_id $app_id)
if [ -z "$bundle_id" ]; then
    echo "Failed to extract bundle ID from the lookup result."
    exit 1
else
    echo "Bundle ID: $bundle_id"
fi
