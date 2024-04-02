#!/bin/bash

# Validate script usage
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <base_folder> <application> <data_type>"
    echo "<application> can be a specific folder name or '*' for all folders."
    echo "<data_type> can be 'images' or 'charts' to specify the type of data to process."
    exit 1
fi

BASE_FOLDER="$1"
APPLICATION="$2"
DATA_TYPE="$3"  # This new parameter determines what data to process: 'images' or 'charts'

# Initialize a variable to hold the combined JSON content
COMBINED_JSON="[]"

# Function to process YAML files
process_files() {
    for file in "$1"/inventory.yaml; do
        if [[ -e "$file" ]]; then
            # Depending on DATA_TYPE, extract either images or charts entries as JSON
            local key=".[]"
            key+=".$DATA_TYPE"  # Construct the query based on the data type
            
            local file_content=$(yq e "$key" "$file" -o=json)
            # Use jq to merge the current file content into the combined JSON array
            COMBINED_JSON=$(jq -c --argjson newContent "$file_content" '. + $newContent' <<< "$COMBINED_JSON")
        fi
    done
}

# Process a specific application folder or all folders
if [[ "$APPLICATION" == "*" ]]; then
    for dir in "$BASE_FOLDER"/*; do
        if [[ -d "$dir" ]]; then
            process_files "$dir"
        fi
    done
else
    APP_DIR="$BASE_FOLDER/$APPLICATION"
    if [[ -d "$APP_DIR" ]]; then
        process_files "$APP_DIR"
    else
        echo "Application directory $APP_DIR does not exist."
        exit 1
    fi
fi

# Depending on the data type, transform COMBINED_JSON into an object with either image names or chart names as keys
if [[ "$DATA_TYPE" == "images" ]]; then
    COMBINED_JSON=$(echo "$COMBINED_JSON" | jq -c 'reduce .[] as $item ({}; .[$item.imageName] = {imageName: $item.imageName, imageRegistry: $item.imageRegistry, imageTag: $item.imageTag})')
elif [[ "$DATA_TYPE" == "charts" ]]; then
    # Adjust this line according to how you wish to structure the chart data
    COMBINED_JSON=$(echo "$COMBINED_JSON" | jq -c 'reduce .[] as $item ({}; .[$item.chartName] = {chartName: $item.chartName, chartRepository: $item.chartRepository, chartVersion: $item.chartVersion})')
fi

# Output the transformed JSON
echo "$COMBINED_JSON"
