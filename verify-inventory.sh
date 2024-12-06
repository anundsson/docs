#!/bin/bash

# Validate-Yaml.sh
BASE_FOLDER="$1"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Install it before running the script."
    exit 1
fi

# Function to validate charts
validate_charts() {
    local charts="$1"
    local section="$2"
    for ((i = 0; i < $(echo "$charts" | yq length); i++)); do
        chart=$(echo "$charts" | yq e ".[$i]" -)
        if [[ -z $(echo "$chart" | yq e '.chartName' -) || -z $(echo "$chart" | yq e '.chartRepository' -) || -z $(echo "$chart" | yq e '.chartVersion' -) ]]; then
            echo "Error: Missing fields in 'charts' under '$section'."
            return 1
        fi
    done
}

# Function to validate images
validate_images() {
    local images="$1"
    local section="$2"
    for ((i = 0; i < $(echo "$images" | yq length); i++)); do
        image=$(echo "$images" | yq e ".[$i]" -)
        if [[ -z $(echo "$image" | yq e '.imageName' -) || -z $(echo "$image" | yq e '.imageRegistry' -) || -z $(echo "$image" | yq e '.imageTag' -) ]]; then
            echo "Error: Missing fields in 'images' under '$section'."
            return 1
        fi
    done
}

# Function to validate a single YAML file
validate_yaml_file() {
    local file="$1"
    echo "Validating: $file"

    # Validate YAML structure
    yq eval '.' "$file" > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "Error: Invalid YAML format in $file."
        return 1
    fi

    # Read top-level keys
    local keys=$(yq e 'keys' "$file" | yq e '.[]' -)
    local is_valid=true

    for key in $keys; do
        local section=$(yq e ".$key" "$file")
        local charts=$(echo "$section" | yq e '.charts // []' -)
        local images=$(echo "$section" | yq e '.images // []' -)

        if [[ -z "$charts" && -z "$images" ]]; then
            echo "Error: '$key' must have at least one 'charts' or 'images' entry in $file."
            is_valid=false
        fi

        if [[ -n "$charts" ]]; then
            validate_charts "$charts" "$key" || is_valid=false
        fi

        if [[ -n "$images" ]]; then
            validate_images "$images" "$key" || is_valid=false
        fi
    done

    if $is_valid; then
        echo "Validation passed for $file."
    else
        echo "Validation failed for $file."
        return 1
    fi
}

# Ensure base folder exists
if [[ ! -d "$BASE_FOLDER" ]]; then
    echo "Error: Provided folder does not exist: $BASE_FOLDER"
    exit 1
fi

# Find all YAML files and validate them
find "$BASE_FOLDER" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read -r file; do
    validate_yaml_file "$file"
    if [[ $? -ne 0 ]]; then
        echo "Validation failed for some files. Exiting."
        exit 1
    fi
done

echo "All YAML files validated successfully."