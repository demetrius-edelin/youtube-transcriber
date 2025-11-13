# YouTube Transcriber

A powerful command-line tool that downloads YouTube videos, transcribes them using Whisper.cpp, generates AI summaries, and creates formatted PDFs and markdown files.

## Features

- **Video Download**: Downloads videos from YouTube and other platforms using yt-dlp
- **Transcription**: Converts audio to text using OpenAI's Whisper model (via whisper.cpp)
- **AI Summarization**: Generates concise summaries using OpenAI's API (optional)
- **Multiple Output Formats**: Creates clean text files, PDFs, and Obsidian-compatible markdown
- **Batch Processing**: Process multiple videos or patterns at once
- **Smart Silence Removal**: Automatically removes silence from audio for better transcription
- **Configurable**: Easily customize paths and settings via configuration file

## Prerequisites

The tool requires the following software to be installed on your system:

### Required
- Git
- Python 3
- Node.js and npm
- FFmpeg
- Vim
- CMake (for building whisper.cpp)
- C++ compiler (for building whisper.cpp)

### Optional
- Pandoc (for PDF generation)
- jq (for better JSON parsing)
- Obsidian (if you want to save notes there)

## Installation

### Quick Install

1. Clone this repository:
```bash
git clone https://github.com/demetrius-edelin/youtube-transcriber.git
cd youtube-transcriber
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

The installation script will:
- Check for required dependencies
- Install/update yt-dlp
- Clone and build whisper.cpp from https://github.com/ggml-org/whisper.cpp
- Download the Whisper large-v3-turbo model
- Set up the command shortcuts
- Create necessary directories

### Manual Installation

If you prefer to install manually or the automatic installation fails:

1. Install dependencies:

**macOS (using Homebrew):**
```bash
brew install git python3 node ffmpeg vim cmake pandoc jq
brew install yt-dlp
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install git python3 python3-pip nodejs npm ffmpeg vim cmake build-essential pandoc jq
pip3 install yt-dlp
```

**Fedora/RHEL:**
```bash
sudo dnf install git python3 python3-pip nodejs npm ffmpeg vim cmake gcc-c++ pandoc jq
pip3 install yt-dlp
```

2. Clone and build whisper.cpp:
```bash
git clone https://github.com/ggml-org/whisper.cpp.git
cd whisper.cpp
mkdir build && cd build
cmake .. -DGGML_METAL=ON  # For macOS with Metal support
# OR
cmake ..  # For Linux
make -j$(nproc)
```

3. Download the Whisper model:
```bash
cd whisper.cpp
bash models/download-ggml-model.sh large-v3-turbo
```

4. Set up the transcriber:
```bash
cd youtube-transcriber
chmod +x scripts/*.sh
ln -s $(pwd)/scripts/process_youtube.sh ~/.local/bin/yt-transcribe
```

## Configuration

Edit `config/config.sh` to customize:

- **Output directory**: Where transcribed videos are saved
- **Obsidian directory**: Where to save markdown notes
- **Model selection**: Choose different Whisper models
- **OpenAI API key**: For AI summarization (optional)

### Setting up OpenAI API Key (for summarization)

1. Get an API key from https://platform.openai.com/api-keys
2. Add it to `config/config.sh`:
```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or set it as an environment variable:
```bash
export OPENAI_API_KEY="your-api-key-here"
```

## Usage

### Basic Usage

Transcribe a YouTube video:
```bash
yt-transcribe https://www.youtube.com/watch?v=VIDEO_ID
```

### Command Options

```bash
yt-transcribe [OPTIONS] VIDEO_URL

Options:
  -d    Delete unnecessary files (keep only cleaned.txt and .pdf)
  -n    Skip saving to Obsidian
  -s    Skip AI summarization (transcript only)
  -o    Open PDF in Firefox when done
```

### Examples

Transcribe with all features:
```bash
yt-transcribe https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Transcribe without AI summary:
```bash
yt-transcribe -s https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Transcribe and clean up intermediate files:
```bash
yt-transcribe -d https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Skip Obsidian integration:
```bash
yt-transcribe -n https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### Batch Processing

Process multiple video files:
```bash
cd /path/to/videos
whisperit.sh "*.mp4"
```

## Output Files

For each video, the tool creates:

1. **Original transcript** (`video_name.txt`) - Raw Whisper output
2. **Cleaned transcript** (`video_name_cleaned.txt`) - Formatted and cleaned text
3. **Summary** (`video_name_summary.txt`) - AI-generated summary (if enabled)
4. **PDF** (`video_name_cleaned.pdf`) - Formatted PDF with summary and transcript
5. **Obsidian note** - Markdown file in your Obsidian vault (if enabled)

## Project Structure

```
youtube-transcriber/
├── install.sh              # Installation script
├── config/
│   └── config.sh          # Configuration file
├── scripts/
│   ├── process_youtube.sh  # Main script
│   ├── whisperit.sh        # Whisper processing
│   ├── summarize.sh        # AI summarization
│   ├── fix_pdf.sh          # PDF generation
│   └── cleanup.js          # Text cleanup utility
├── models/                # Whisper models directory
├── whisper.cpp/          # Whisper.cpp repository (created during install)
└── docs/                 # Documentation

```

## Troubleshooting

### Common Issues

**1. Whisper build fails**
- Ensure you have CMake and a C++ compiler installed
- On macOS, install Xcode Command Line Tools: `xcode-select --install`
- Try building without Metal support: `cmake ..` instead of `cmake .. -DGGML_METAL=ON`

**2. PDF generation fails**
- Install pandoc: `brew install pandoc` (macOS) or `apt install pandoc` (Linux)
- Check that LaTeX is installed for complex PDFs

**3. Summarization not working**
- Verify your OpenAI API key is set correctly
- Check you have API credits available
- Ensure Python and curl are working properly

**4. yt-dlp errors**
- Update yt-dlp: `pip3 install --upgrade yt-dlp`
- Some videos may have download restrictions

**5. Command not found**
- Add `~/.local/bin` to your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Debug Mode

To see detailed output, run scripts directly:
```bash
bash -x scripts/process_youtube_updated.sh URL
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Dependencies

This project uses:
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) - High-performance Whisper implementation
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - YouTube video downloader
- [OpenAI API](https://openai.com/api/) - For AI summarization (optional)

## License

MIT License - See LICENSE file for details

## Acknowledgments

- OpenAI for the Whisper model
- ggml-org for whisper.cpp implementation
- yt-dlp team for the video downloader

## Support

If you encounter any issues or have questions, please open an issue on GitHub.