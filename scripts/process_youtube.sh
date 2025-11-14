#!/bin/bash

# process_youtube.sh - Download and process videos from web URLs or local files
# Usage: ./process_youtube.sh [OPTIONS] URL_OR_FILE
#   OPTIONS:
#     -d    Delete unnecessary files, keeping only cleaned.txt and cleaned.pdf
#     -n    Skip saving results to Obsidian
#     -s    Skip AI summarization (transcript only)
#     -o    Open the cleaned PDF file in Firefox

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/config.sh"

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Function to open PDF in Firefox if requested
open_pdf_in_firefox() {
    local base_filename="$1"
    if [ "$OPEN_PDF" = true ]; then
        local pdf_file="${base_filename}_cleaned.pdf"
        if [ -f "$pdf_file" ]; then
            echo "====================================="
            echo "Opening PDF in Firefox..."
            echo "====================================="
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open -a Firefox "$pdf_file"
            else
                firefox "$pdf_file" &
            fi
        else
            echo "Warning: Could not find PDF file to open: $pdf_file"
        fi
    fi
}

# Parse command line options
DELETE_FILES=false
SKIP_OBSIDIAN=false
SKIP_SUMMARY=false
OPEN_PDF=true
while getopts ":dnso" opt; do
  case ${opt} in
    d )
      DELETE_FILES=true
      ;;
    n )
      SKIP_OBSIDIAN=true
      ;;
    s )
      SKIP_SUMMARY=true
      ;;
    o )
      OPEN_PDF=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      echo "Usage: $0 [-d] [-n] [-s] [-o] VIDEO_URL_OR_FILE"
      echo "  -d    Delete unnecessary files, keeping only cleaned.txt and cleaned.pdf"
      echo "  -n    Skip saving results to Obsidian"
      echo "  -s    Skip AI summarization (transcript only)"
      echo "  -o    Open the cleaned PDF file in Firefox"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Check if input is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-d] [-n] [-s] [-o] VIDEO_URL_OR_FILE"
    echo ""
    echo "Examples:"
    echo "  $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    echo "  $0 /path/to/video.mp4"
    echo "  $0 ~/Downloads/lecture.mkv"
    echo ""
    echo "Options:"
    echo "  -d    Delete unnecessary files, keeping only cleaned.txt and cleaned.pdf"
    echo "  -n    Skip saving results to Obsidian"
    echo "  -s    Skip AI summarization (transcript only)"
    echo "  -o    Open the cleaned PDF file in Firefox"
    exit 1
fi

INPUT="$1"
CURRENT_DIR=$(pwd)
IS_LOCAL_FILE=false
VIDEO_SOURCE=""

# Function to process the video (common part for both URL and local file)
process_video() {
    local video_file="$1"
    local source_info="$2"

    echo "====================================="
    echo "Processing video with whisper..."
    echo "====================================="

    # Process the video using the whisperit script
    "$SCRIPT_DIR/whisperit.sh" "$video_file"

    # Run the summarize script to generate a summary of the transcript
    if [ "$SKIP_SUMMARY" = false ] && [ -f "$SCRIPT_DIR/summarize.sh" ]; then
        # Export FILENAME for the summarize.sh script
        export FILENAME="$video_file"

        # Call the summarize script
        "$SCRIPT_DIR/summarize.sh"

        # Get the base filename without extension
        local base_name="${video_file%.*}"
        CLEANED_FILE="${base_name}_cleaned.txt"
        SUMMARY_FILE="${base_name}_summary.txt"

        # Check if both files exist
        if [ -f "$SUMMARY_FILE" ] && [ -f "$CLEANED_FILE" ]; then
            echo "====================================="
            echo "Putting summary at the top of transcript file..."
            echo "====================================="

            # Create a temporary file with source info, summary and transcript
            {
                echo "# VIDEO SOURCE"
                echo "$source_info"
                echo ""
                echo "# SUMMARY"
                echo ""
                cat "$SUMMARY_FILE"
                echo ""
                echo "# TRANSCRIPT"
                echo ""
                cat "$CLEANED_FILE"
            } > "${CLEANED_FILE}.tmp"

            # Replace the original cleaned file
            mv "${CLEANED_FILE}.tmp" "$CLEANED_FILE"

            # Generate PDF from the combined file
            echo "====================================="
            echo "Creating PDF version..."
            echo "====================================="
            "$SCRIPT_DIR/fix_pdf.sh" "$CLEANED_FILE"

            # Open PDF in Firefox if requested
            open_pdf_in_firefox "$base_name"

            # Create Obsidian markdown file (if not skipped)
            if [ "$SKIP_OBSIDIAN" = false ]; then
                echo "====================================="
                echo "Creating Obsidian markdown file..."
                echo "====================================="

                # Ensure Obsidian directory exists
                mkdir -p "$OBSIDIAN_DIR"

                # Create markdown file with the same content
                OBSIDIAN_FILE="$OBSIDIAN_DIR/${base_name}.md"
                cp "$CLEANED_FILE" "$OBSIDIAN_FILE"

                echo "Obsidian file created at: $OBSIDIAN_FILE"
            else
                echo "====================================="
                echo "Skipping Obsidian file creation (as requested)"
                echo "====================================="
            fi
        else
            echo "====================================="
            echo "Warning: Could not find summary or transcript files"
            if [ ! -f "$CLEANED_FILE" ]; then
                echo "Missing: $CLEANED_FILE"
            fi
            if [ ! -f "$SUMMARY_FILE" ]; then
                echo "Missing: $SUMMARY_FILE"
            fi
            echo "====================================="
        fi
    elif [ "$SKIP_SUMMARY" = true ]; then
        echo "====================================="
        echo "Skipping AI summarization (as requested)"
        echo "====================================="

        # Still process the transcript file if it exists
        local base_name="${video_file%.*}"
        CLEANED_FILE="${base_name}_cleaned.txt"

        if [ -f "$CLEANED_FILE" ]; then
            # Create a file with source info and transcript only
            {
                echo "# VIDEO SOURCE"
                echo "$source_info"
                echo ""
                echo "# TRANSCRIPT"
                echo ""
                cat "$CLEANED_FILE"
            } > "${CLEANED_FILE}.tmp"

            # Replace the original cleaned file
            mv "${CLEANED_FILE}.tmp" "$CLEANED_FILE"

            # Generate PDF from the combined file
            echo "====================================="
            echo "Creating PDF version..."
            echo "====================================="
            "$SCRIPT_DIR/fix_pdf.sh" "$CLEANED_FILE"

            # Open PDF in Firefox if requested
            open_pdf_in_firefox "$base_name"

            # Create Obsidian markdown file (if not skipped)
            if [ "$SKIP_OBSIDIAN" = false ]; then
                echo "====================================="
                echo "Creating Obsidian markdown file..."
                echo "====================================="

                # Ensure Obsidian directory exists
                mkdir -p "$OBSIDIAN_DIR"

                # Create markdown file with the same content
                OBSIDIAN_FILE="$OBSIDIAN_DIR/${base_name}.md"
                cp "$CLEANED_FILE" "$OBSIDIAN_FILE"

                echo "Obsidian file created at: $OBSIDIAN_FILE"
            else
                echo "====================================="
                echo "Skipping Obsidian file creation (as requested)"
                echo "====================================="
            fi
        else
            echo "====================================="
            echo "Warning: Could not find transcript file: $CLEANED_FILE"
            echo "====================================="
        fi
    else
        echo "====================================="
        echo "Warning: summarize.sh not found, skipping summary generation"
        echo "====================================="
    fi
}

# Check if input is a local file or URL
if [ -f "$INPUT" ]; then
    # It's a local file
    IS_LOCAL_FILE=true
    VIDEO_SOURCE="Local file: $(realpath "$INPUT")"

    echo "====================================="
    echo "Processing local video file: $INPUT"
    echo "====================================="

    # Get the filename and base name
    FILENAME=$(basename "$INPUT")
    BASE_FILENAME="${FILENAME%.*}"

    # Create a subfolder for this video within the destination directory
    VIDEO_FOLDER="$DEST_DIR/$BASE_FILENAME"
    mkdir -p "$VIDEO_FOLDER"

    # Copy the file to the video folder
    echo "Copying video to processing folder..."
    cp "$INPUT" "$VIDEO_FOLDER/"

    # Change to the video folder for processing
    cd "$VIDEO_FOLDER" || exit 1

    echo "====================================="
    echo "Processing video in folder: $VIDEO_FOLDER"
    echo "====================================="

    # Process the video
    process_video "$FILENAME" "$VIDEO_SOURCE"

elif [[ "$INPUT" =~ ^https?:// ]]; then
    # It's a URL
    VIDEO_SOURCE="$INPUT"
    TEMP_DIR=$(mktemp -d)

    echo "====================================="
    echo "Downloading video from: $INPUT"
    echo "====================================="

    # Navigate to temp directory to download
    cd "$TEMP_DIR" || exit 1

    # Download video using yt-dlp
    # -i flag to ignore errors
    # --restrict-filenames to avoid special characters
    # -f worst to get smallest file size for faster processing
    "$YT_DLP" -i --restrict-filename -f worst "$INPUT"

    # Check if download succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download video from $INPUT"
        cd "$CURRENT_DIR"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Get the downloaded filename
    # This handles the case where yt-dlp might modify the filename
    FILENAME=$(find . -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.avi" -o -name "*.mov" \) | head -n 1)

    if [ -z "$FILENAME" ]; then
        echo "Error: Could not find downloaded video file"
        cd "$CURRENT_DIR"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    FILENAME=$(basename "$FILENAME")
    echo "Video downloaded as: $FILENAME"

    # Get the base filename without extension for folder name
    BASE_FILENAME="${FILENAME%.*}"

    # Create a subfolder for this video within the destination directory
    VIDEO_FOLDER="$DEST_DIR/$BASE_FILENAME"
    mkdir -p "$VIDEO_FOLDER"

    # Copy the file to the video folder
    cp "$FILENAME" "$VIDEO_FOLDER/"

    # Go back to original directory
    cd "$CURRENT_DIR" || exit 1

    # Change to the video folder for processing
    cd "$VIDEO_FOLDER" || exit 1

    echo "====================================="
    echo "Processing video in folder: $VIDEO_FOLDER"
    echo "====================================="

    # Process the video
    process_video "$FILENAME" "$VIDEO_SOURCE"

    # Clean up the temp directory
    rm -rf "$TEMP_DIR"
else
    echo "Error: '$INPUT' is neither a valid URL nor an existing file"
    echo ""
    echo "Please provide either:"
    echo "  - A YouTube/video URL (starting with http:// or https://)"
    echo "  - A path to a local video file"
    exit 1
fi

# Go back to the original directory
cd "$CURRENT_DIR" || exit 1

# Clean up unnecessary files if -d flag was provided
if [ "$DELETE_FILES" = true ]; then
    echo "====================================="
    echo "Cleaning up unnecessary files..."
    echo "====================================="

    cd "$VIDEO_FOLDER" || exit 1

    # Get the base filename without extension again to be sure
    BASE_FILENAME="${FILENAME%.*}"
    CLEANED_TXT="${BASE_FILENAME}_cleaned.txt"
    CLEANED_PDF="${BASE_FILENAME}_cleaned.pdf"

    # Check if the essential files exist before removing others
    if [ -f "$CLEANED_TXT" ] && [ -f "$CLEANED_PDF" ]; then
        # Loop through all files in the directory
        for file in *; do
            # Skip the cleaned.txt and cleaned.pdf files
            if [ "$file" != "$CLEANED_TXT" ] && [ "$file" != "$CLEANED_PDF" ]; then
                echo "Removing: $file"
                rm "$file"
            fi
        done
        echo "Cleanup complete. Kept only $CLEANED_TXT and $CLEANED_PDF."
    else
        echo "Warning: Essential files not found. Skipping cleanup."
        if [ ! -f "$CLEANED_TXT" ]; then
            echo "Missing: $CLEANED_TXT"
        fi
        if [ ! -f "$CLEANED_PDF" ]; then
            echo "Missing: $CLEANED_PDF"
        fi
    fi

    # Return to original directory
    cd "$CURRENT_DIR" || exit 1
fi

echo "====================================="
echo "Process complete! All files are in: $VIDEO_FOLDER"
if [ "$OPEN_PDF" = true ]; then
    echo "PDF should have opened in Firefox"
fi
echo "====================================="