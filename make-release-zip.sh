#!/bin/bash

set -euo pipefail

# Files to include (add more files here as needed)
FILES_TO_INCLUDE=(
    "README.md"
    "LICENSE.md"
    "info.json"
    "changelog.txt"
    "thumbnail.png"
    "locale/"
    "resources/"
    "scripts/"
    *.lua
)

# Get mod info from info.json
if ! command -v jq &> /dev/null; then
    echo "Error: jq command is required but not installed."
    echo "Please install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

INFO_FILE="info.json"
if [[ ! -f "$INFO_FILE" ]]; then
    echo "Error: $INFO_FILE not found in current directory"
    exit 1
fi

MOD_NAME=$(jq -r '.name' "$INFO_FILE")
VERSION=$(jq -r '.version' "$INFO_FILE")

if [[ "$MOD_NAME" == "null" || "$VERSION" == "null" ]]; then
    echo "Error: Could not extract name or version from $INFO_FILE"
    exit 1
fi

echo "Creating release zip for $MOD_NAME v$VERSION"

# Create release directory
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"

ZIP_NAME="${MOD_NAME}-${VERSION}.zip"
ZIP_PATH="$RELEASE_DIR/$ZIP_NAME"

# Remove existing zip if it exists
if [[ -f "$ZIP_PATH" ]]; then
    echo "Removing existing $ZIP_NAME"
    rm "$ZIP_PATH"
fi

# Check if all required files exist
echo "Checking required files..."
MISSING_FILES=()
for file in "${FILES_TO_INCLUDE[@]}"; do
    if [[ ! -e "$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo "Error: The following required files are missing:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo "Please ensure all required files are present before creating release."
    exit 1
fi

# Create zip directly
echo "Creating $ZIP_NAME..."
cd "$(dirname "$0")"

# Add files to zip
echo "Adding files to zip..."
for file in "${FILES_TO_INCLUDE[@]}"; do
    echo "  Including: $file"
    # Add file/directory, excluding .DS_Store files
    if [[ -d "$file" ]]; then
        # For directories, use find to exclude .DS_Store
        find "$file" -name ".DS_Store" -prune -o -print | zip -q "$ZIP_PATH" -@
    else
        # For single files, check if it's not .DS_Store
        if [[ "$(basename "$file")" != ".DS_Store" ]]; then
            zip -q "$ZIP_PATH" "$file"
        fi
    fi
done

echo "✅ Release zip created: $ZIP_PATH"
echo "📦 Size: $(du -h "$ZIP_PATH" | cut -f1)"
echo "🚀 Ready for upload to Factorio mod portal!"
