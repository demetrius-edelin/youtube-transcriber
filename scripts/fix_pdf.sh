#!/bin/bash

# This script fixes PDF generation issues by handling special characters in transcript files
# Usage: ./fix_pdf.sh input_file.txt

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/config.sh"

if [ $# -eq 0 ]; then
    echo "Usage: $0 input_file.txt"
    exit 1
fi

input_file="$1"
filename=$(basename -- "$input_file")
filename_noext="${filename%.*}"
output_pdf="${filename_noext}.pdf"

echo "Fixing PDF generation for file: $input_file"

# Method 1: Try pandoc directly with the text file
echo "Attempting PDF generation..."
echo "Using pandoc directly with input file..."

# Clean the title to avoid LaTeX errors
clean_title=$(echo "$filename_noext" | sed 's/_/ /g' | sed 's/[&$#^%{}~]/\\&/g')

"$PANDOC" "$input_file" -f markdown -o "$output_pdf" \
  --pdf-engine=pdflatex \
  -V geometry:margin=1in \
  -V title="$clean_title" \
  -V date="$(date +"%B %d, %Y")" 2> /tmp/pandoc_error.log

if [ $? -eq 0 ]; then
    echo "PDF successfully created: $output_pdf"
    exit 0
else
    echo "Direct pandoc conversion failed with error:"
    cat /tmp/pandoc_error.log
fi

# If pandoc failed, try the HTML approach
echo "Direct pandoc conversion failed, trying HTML approach..."

# Create a temporary HTML file - HTML is more forgiving than LaTeX
temp_html="${filename_noext}_temp.html"

# Create a simple HTML document
echo "<!DOCTYPE html>" > "$temp_html"
echo "<html>" >> "$temp_html"
echo "<head>" >> "$temp_html"
echo "  <meta charset=\"UTF-8\">" >> "$temp_html"
echo "  <title>Transcript for $filename_noext</title>" >> "$temp_html"
echo "  <style>" >> "$temp_html"
echo "    body { font-family: 'Times New Roman', Georgia, serif; margin: 40px; line-height: 1.6; }" >> "$temp_html"
echo "    h1 { text-align: center; font-family: 'Times New Roman', Georgia, serif; }" >> "$temp_html"
echo "    .date { text-align: center; margin-bottom: 30px; font-style: italic; }" >> "$temp_html"
echo "    p { margin-bottom: 10px; text-align: justify; }" >> "$temp_html"
echo "  </style>" >> "$temp_html"
echo "</head>" >> "$temp_html"
echo "<body>" >> "$temp_html"
echo "  <h1>Transcript for $filename_noext</h1>" >> "$temp_html"
echo "  <div class=\"date\">Generated on $(date +"%B %d, %Y")</div>" >> "$temp_html"

# Convert text file content to paragraphs in HTML
cat "$input_file" | sed 's/$/<\/p><p>/g' | sed '1s/^/<p>/' >> "$temp_html"

# Close HTML tags
echo "</p></body></html>" >> "$temp_html"

# Try pandoc with HTML first
echo "Using pandoc with HTML..."
"$PANDOC" "$temp_html" -f html -o "$output_pdf" \
  --pdf-engine=xelatex \
  -V geometry:margin=1in \
  -V fontsize=11pt \
  -V mainfont="Times New Roman" 2> /tmp/pandoc_html_error.log

if [ $? -eq 0 ]; then
    echo "PDF successfully created: $output_pdf"
    rm "$temp_html"
    exit 0
else
    echo "Pandoc HTML conversion failed with error:"
    cat /tmp/pandoc_html_error.log
fi

# If pandoc with HTML failed, try wkhtmltopdf
if command -v wkhtmltopdf > /dev/null; then
    echo "Using wkhtmltopdf..."
    wkhtmltopdf --margin-top 25 --margin-right 25 --margin-bottom 25 --margin-left 25 "$temp_html" "$output_pdf" 2> /tmp/wkhtmltopdf_error.log

    if [ $? -eq 0 ]; then
        echo "PDF successfully created: $output_pdf"
        rm "$temp_html"
        exit 0
    else
        echo "wkhtmltopdf failed with error:"
        cat /tmp/wkhtmltopdf_error.log
    fi
fi

echo "All PDF generation methods failed."
echo "Saving the intermediate HTML file for inspection: $temp_html"