#!/bin/bash


# Function to extract the app ID from the App Store URL
get_app_id() {
    local url=$1
    local app_id=$(echo $url | sed -n 's/.*id\([0-9]*\).*/\1/p')
    echo $app_id
}


# Function to get the bundle ID from the App Store via iTunes lookup
get_bundle_id() {
    local app_id=$1
    local lookup_url="https://itunes.apple.com/lookup?id=$app_id"
    curl -s $lookup_url -o 1.txt
    local bundle_id=$(sed -n 's/.*"bundleId":"\([^"]*\)".*/\1/p' 1.txt)
    echo $bundle_id
}


<<comment
Function for getting the Bundle ID from a local Application using mdfind (spotlight) and defaults

It checks to see if an app is in installed locally and extracts the bundle ID from it's Info.plist if it does.

The Bundle ID of an app can be found in its Info.plist file in a key named CFBundleIdentifier
    - On MacOS, this file will be found in the Contents directory inside the Bundle (.app) directory
    - On iOS, this file will be inside in the Bundle (.app) directory

Bundle Structures:
    https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html
comment

get_local_bundle_id() {
    local app_name="$1"
    local bundle_path=""
    if [[ -d "/Applications/$app_name.app" ]]; then
        bundle_path="/Applications/$app_name.app"
    elif [[ -d "/System/Applications/$app_name.app" ]]; then
        bundle_path="/System/Applications/$app_name.app"
    elif [[ -d "$HOME/Applications/$app_name.app" ]]; then
        bundle_path="$HOME/Applications/$app_name.app"
    else
        bundle_path=$(mdfind "kMDItemKind == 'Application'" | grep -i "$app_name.app")
    fi

    if [[ -n "$bundle_path" ]]; then
        local plist_path="$bundle_path/Contents/Info.plist"
        local bundle_id=$(defaults read "$plist_path" CFBundleIdentifier 2>/dev/null)
        if [[ -n "$bundle_id" ]]; then
            echo "$bundle_id"
        else
            echo "Failed to read bundle ID from Info.plist."
            return 1
        fi
    else
        echo "$app_name is not installed locally."
        return 1
    fi
}


# Check if an argument (URL or app name) was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <App Store URL or Application Name>"
    exit 1
fi

# First, try to use the app name as a local search
APP_NAME="$1"
bundle_id=$(get_local_bundle_id "$APP_NAME")

# If the local search fails, treat the argument as an App Store URL
if [[ $? -ne 0 ]]; then
    app_store_url=$1
    app_id=$(get_app_id $app_store_url)

    if [ -z "$app_id" ]; then
        echo "Failed to extract app ID from the URL."
        exit 1
    fi
    # Use the App Store lookup to get the bundle ID. If the lookup fails, exit
    bundle_id=$(get_bundle_id $app_id)
    if [ -z "$bundle_id" ]; then
        echo "Failed to extract bundle ID from the App Store lookup result."
        exit 1
    fi
fi

echo "Bundle ID: $bundle_id"