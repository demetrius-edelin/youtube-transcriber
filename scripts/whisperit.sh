#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/config.sh"

# Function to process a single file
process_file() {
    local input_file="$1"
    local filename=$(basename -- "$input_file")
    local filename_noext="${filename%.*}"
    local extension="${filename##*.}"
    local dir=$(dirname "$input_file")

    # Check if file has already been processed
    if [ -f "${dir}/${filename_noext}.txt" ]; then
        echo "Skipping ${input_file} - already processed (.txt file exists)"
        return 0
    fi

    echo "====================================="
    echo "Processing: $input_file"
    echo "====================================="

    # Create temporary WAV file
    local temp_wav_file="${dir}/${filename_noext}.wav"

    echo "Converting $input_file to WAV format and removing silences..."
    # ffmpeg can handle both audio and video files
    # Remove silences and convert to WAV format
    "$FFMPEG" -i "$input_file" \
           -vn \
           -af "silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB:stop_periods=-1:stop_duration=0.02:stop_threshold=-50dB,apad=pad_dur=0.02" \
           -c:a pcm_s16le -ar 16000 -ac 2 "$temp_wav_file" -y

    if [ $? -ne 0 ]; then
        echo "Error: FFmpeg conversion failed for $input_file"
        return 1
    fi

    echo "Transcribing audio with Whisper..."
    # Redirect output directly to file without displaying in terminal
    "$WHISPER_CLI" -m "$WHISPER_MODEL" -f "$temp_wav_file" > "${dir}/${filename_noext}.txt"

    if [ $? -ne 0 ]; then
        echo "Error: Whisper transcription failed for $input_file"
        # Remove the temporary WAV file
        rm "$temp_wav_file"
        return 1
    fi

    echo "Transcription complete: ${dir}/${filename_noext}.txt"

    # Remove the temporary WAV file
    rm "$temp_wav_file"
    echo "Temporary WAV file removed"

    # Initial cleanup with vim
    vim -c ':%s/ -->[^]]\+//g' -c 'wq' "${dir}/${filename_noext}.txt"

    # Run the JavaScript cleanup script to format the transcript
    echo "Running transcript cleanup script..."
    "$NODE" "$SCRIPT_DIR/cleanup.js" "${dir}/${filename_noext}.txt"

    echo "Transcript processing complete. Clean version available at: ${dir}/${filename_noext}_cleaned.txt"

    # Create PDF from the cleaned transcript
    echo "Generating PDF from cleaned transcript..."

    # Check if pandoc is installed
    if ! command -v "$PANDOC" &> /dev/null; then
        echo "Error: pandoc is not installed. Please install it with: brew install pandoc"
        echo "PDF generation skipped."
    else
        # Create a temporary log file for capturing errors
        pdf_log="/tmp/pdf_generation_$$.log"

        # Use pandoc to create a nicely formatted PDF
        "$SCRIPT_DIR/fix_pdf.sh" "${dir}/${filename_noext}_cleaned.txt"

        # Remove the temporary log file
        rm -f "$pdf_log"
    fi

    echo "====================================="
    echo "Completed processing: $input_file"
    echo "====================================="
    echo ""
}

# Check if input file/pattern is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 input_file.[mp3|mp4|mkv|wav|etc] or pattern (e.g., *.mp4)"
    exit 1
fi

input_pattern="$1"

# Check if it's a pattern or specific file
if [[ "$input_pattern" == *\** ]]; then
    # It's a pattern, find matching files
    echo "Processing multiple files matching pattern: $input_pattern"
    echo "====================================="

    # Get the directory from the pattern or use current directory
    pattern_dir=$(dirname "$input_pattern")
    if [ "$pattern_dir" = "." ] || [ "$pattern_dir" = "$input_pattern" ]; then
        # Pattern doesn't include directory, use current directory
        search_path="$input_pattern"
    else
        # Pattern includes directory path
        search_path="$input_pattern"
    fi

    # Count matching files
    matching_files=($(find "$(dirname "$search_path")" -name "$(basename "$search_path")" -type f))
    file_count=${#matching_files[@]}

    if [ $file_count -eq 0 ]; then
        echo "No files found matching pattern: $input_pattern"
        exit 1
    fi

    echo "Found $file_count matching files"

    # Keep track of success and failure
    success_count=0
    fail_count=0
    skip_count=0

    for file in "${matching_files[@]}"; do
        # Skip non-media files (basic filter)
        ext="${file##*.}"
        if [[ ! "$ext" =~ ^(mp3|mp4|wav|mkv|m4a|flac|ogg|avi|mov|wmv|webm)$ ]]; then
            echo "Skipping non-media file: $file"
            continue
        fi

        # Check if file has already been processed
        filename_noext="${file%.*}"
        if [ -f "${filename_noext}.txt" ]; then
            echo "Skipping $file - already processed (.txt file exists)"
            ((skip_count++))
            continue
        fi

        if process_file "$file"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    echo "====================================="
    echo "Batch Processing Complete"
    echo "====================================="
    echo "Total files: $file_count"
    echo "Successfully processed: $success_count"
    echo "Failed: $fail_count"
    echo "Skipped (already processed): $skip_count"

else
    # It's a specific file, process directly
    if [ ! -f "$input_pattern" ]; then
        echo "Error: File not found: $input_pattern"
        exit 1
    fi

    process_file "$input_pattern"
fi