#!/bin/bash

# Validate script usage
if [[ $# -ne 3 ]]; then
   echo "Usage: $0 <base_folder> <application> <data_type>"
   echo "<application> can be a specific folder name, 'tools', 'platform', or '*' for all folders."
   echo "<data_type> can be 'images' or 'charts' to specify the type of data to process."
   exit 1
fi

BASE_FOLDER="$1"
APPLICATION="$2"
DATA_TYPE="$3"  # This parameter determines what data to process: 'images' or 'charts'

# Initialize a variable to hold the combined JSON content
COMBINED_JSON="[]"

# Function to process YAML files
process_files() {
   # Echo the directory being processed for troubleshooting
   echo "Processing directory: $1"

   # Correct the wildcard pattern to search for inventory.yaml files
   for file in "$1"/*/inventory.yaml; do
       # Echo the file path being processed for troubleshooting
       echo "Processing file: $file"

       if [[ -e "$file" ]]; then
           # Extract the relevant directory name from the path (e.g., the first directory after the base)
           local dir_name=$(echo "$file" | sed -E 's#.*/([^/]+)/[^/]+/inventory\.yaml#\1#')
           echo "Extracted directory name: $dir_name"

           # Depending on DATA_TYPE, extract either images or charts entries as JSON
           local key=".[]"
           key+=".$DATA_TYPE"  # Construct the query based on the data type
           
           # Extract JSON content and handle potential null output
           local file_content=$(yq e "$key" "$file" -o=json)
           if [[ "$file_content" == "null" ]]; then
               echo "Warning: No $DATA_TYPE found in $file"
               continue
           fi

           # Add the directory name to each item in the JSON
           file_content=$(echo "$file_content" | jq --arg dir "$dir_name" '.[] | .directory = $dir' | jq -s .)

           # Use jq to merge the current file content into the combined JSON array
           COMBINED_JSON=$(jq -c --argjson newContent "$file_content" '. + $newContent' <<< "$COMBINED_JSON")
       else
           echo "File does not exist: $file"
       fi
   done
}

# Function to process specified application directories, including 'tools' and 'platform' using regex
process_applications() {
   local dir="$1"
   echo "Processing application directory: $dir"

   # Directly process inventory.yaml within the application directory
   process_files "$dir"
}

# Process a specific application folder, 'tools', 'platform', or all folders
if [[ "$APPLICATION" == "*" ]]; then
   # Look for all directories under the base folder
   for dir in $BASE_FOLDER/*; do
       if [[ -d "$dir" ]]; then
           process_files "$dir"
       else
           echo "Directory does not exist or is not accessible: $dir"
       fi
   done
else
   # For specific application folders like 'platform/argocd', construct the correct path
   APP_DIR="$BASE_FOLDER/$APPLICATION"
   if [[ -d "$APP_DIR" ]]; then
       process_applications "$APP_DIR"
   else
       echo "Application directory $APP_DIR does not exist."
       exit 1
   fi
fi

# Depending on the data type, transform COMBINED_JSON into an object with either image names or chart names as keys
if [[ "$DATA_TYPE" == "images" ]]; then
   COMBINED_JSON=$(echo "$COMBINED_JSON" | jq -c 'reduce .[] as $item ({}; .[$item.imageName] = {directory: $item.directory, imageName: $item.imageName, imageRegistry: $item.imageRegistry, imageTag: $item.imageTag})')
elif [[ "$DATA_TYPE" == "charts" ]]; then
   COMBINED_JSON=$(echo "$COMBINED_JSON" | jq -c 'reduce .[] as $item ({}; .[$item.chartName] = {directory: $item.directory, chartName: $item.chartName, chartRepository: $item.chartRepository, chartVersion: $item.chartVersion})')
fi

# Output the transformed JSON
echo "$COMBINED_JSON"