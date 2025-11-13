#!/bin/bash

# YouTube Transcriber Installation Script
# This script installs all necessary dependencies and sets up the YouTube Transcriber

set -e

echo "=========================================="
echo "YouTube Transcriber Installation Script"
echo "=========================================="
echo ""

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"
echo ""

# Check for required tools
echo "Checking for required tools..."
echo "------------------------------"

MISSING_TOOLS=""

# Check for git
if ! command_exists git; then
    MISSING_TOOLS="$MISSING_TOOLS git"
    echo "❌ git is not installed"
else
    echo "✅ git is installed"
fi

# Check for Python 3
if ! command_exists python3; then
    MISSING_TOOLS="$MISSING_TOOLS python3"
    echo "❌ python3 is not installed"
else
    echo "✅ python3 is installed ($(python3 --version))"
fi

# Check for Node.js
if ! command_exists node; then
    MISSING_TOOLS="$MISSING_TOOLS node"
    echo "❌ Node.js is not installed"
else
    echo "✅ Node.js is installed ($(node --version))"
fi

# Check for npm
if ! command_exists npm; then
    MISSING_TOOLS="$MISSING_TOOLS npm"
    echo "❌ npm is not installed"
else
    echo "✅ npm is installed ($(npm --version))"
fi

# Check for ffmpeg
if ! command_exists ffmpeg; then
    MISSING_TOOLS="$MISSING_TOOLS ffmpeg"
    echo "❌ ffmpeg is not installed"
else
    echo "✅ ffmpeg is installed"
fi

# Check for pandoc
if ! command_exists pandoc; then
    echo "⚠️  pandoc is not installed (optional, needed for PDF generation)"
else
    echo "✅ pandoc is installed"
fi

# Check for vim
if ! command_exists vim; then
    MISSING_TOOLS="$MISSING_TOOLS vim"
    echo "❌ vim is not installed"
else
    echo "✅ vim is installed"
fi

# Check for jq
if ! command_exists jq; then
    echo "⚠️  jq is not installed (optional, for JSON parsing)"
else
    echo "✅ jq is installed"
fi

echo ""

# If there are missing required tools, provide installation instructions
if [ -n "$MISSING_TOOLS" ]; then
    echo "❌ Missing required tools:$MISSING_TOOLS"
    echo ""
    echo "Please install the missing tools:"

    if [ "$OS" = "macos" ]; then
        echo ""
        echo "On macOS, you can use Homebrew:"
        echo "  brew install$MISSING_TOOLS"
        if ! command_exists pandoc; then
            echo "  brew install pandoc # (optional, for PDF generation)"
        fi
        if ! command_exists jq; then
            echo "  brew install jq # (optional, for better JSON parsing)"
        fi
    elif [ "$OS" = "linux" ]; then
        echo ""
        echo "On Ubuntu/Debian:"
        echo "  sudo apt update"
        echo "  sudo apt install$MISSING_TOOLS"
        if ! command_exists pandoc; then
            echo "  sudo apt install pandoc # (optional, for PDF generation)"
        fi
        if ! command_exists jq; then
            echo "  sudo apt install jq # (optional, for better JSON parsing)"
        fi
        echo ""
        echo "On Fedora/RHEL:"
        echo "  sudo dnf install$MISSING_TOOLS"
        if ! command_exists pandoc; then
            echo "  sudo dnf install pandoc # (optional, for PDF generation)"
        fi
        if ! command_exists jq; then
            echo "  sudo dnf install jq # (optional, for better JSON parsing)"
        fi
    fi
    echo ""
    echo "After installing the missing tools, run this script again."
    exit 1
fi

# Install yt-dlp
echo "Installing/updating yt-dlp..."
echo "------------------------------"

if command_exists yt-dlp; then
    echo "yt-dlp is already installed, updating..."
    if [ "$OS" = "macos" ] && command_exists brew; then
        brew upgrade yt-dlp 2>/dev/null || brew install yt-dlp
    else
        pip3 install --upgrade yt-dlp
    fi
else
    echo "Installing yt-dlp..."
    if [ "$OS" = "macos" ] && command_exists brew; then
        brew install yt-dlp
    else
        pip3 install yt-dlp
    fi
fi

echo "✅ yt-dlp is ready"
echo ""

# Clone and build whisper.cpp
echo "Setting up whisper.cpp..."
echo "------------------------------"

WHISPER_DIR="$INSTALL_DIR/whisper.cpp"

if [ -d "$WHISPER_DIR" ]; then
    echo "whisper.cpp directory already exists, updating..."
    cd "$WHISPER_DIR"
    git pull
else
    echo "Cloning whisper.cpp repository..."
    git clone https://github.com/ggml-org/whisper.cpp.git "$WHISPER_DIR"
    cd "$WHISPER_DIR"
fi

echo "Building whisper.cpp..."
mkdir -p build
cd build

if [ "$OS" = "macos" ]; then
    # macOS build with Metal support
    cmake .. -DGGML_METAL=ON
else
    # Linux build
    cmake ..
fi

make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

if [ -f "bin/whisper-cli" ]; then
    echo "✅ whisper.cpp built successfully"
else
    echo "❌ Failed to build whisper.cpp"
    exit 1
fi

cd "$INSTALL_DIR"
echo ""

# Download Whisper model
echo "Downloading Whisper model..."
echo "------------------------------"

MODEL_DIR="$INSTALL_DIR/models"
mkdir -p "$MODEL_DIR"

MODEL_FILE="$MODEL_DIR/ggml-large-v3-turbo.bin"

if [ -f "$MODEL_FILE" ]; then
    echo "Model already exists: $MODEL_FILE"
else
    echo "Downloading ggml-large-v3-turbo model..."
    echo "This may take a while (model size is ~800MB)..."

    # Download the model
    cd "$WHISPER_DIR"
    bash models/download-ggml-model.sh large-v3-turbo

    # Copy the model to our models directory
    if [ -f "models/ggml-large-v3-turbo.bin" ]; then
        cp "models/ggml-large-v3-turbo.bin" "$MODEL_FILE"
        echo "✅ Model downloaded successfully"
    else
        echo "❌ Failed to download model"
        echo "You can manually download it from: https://huggingface.co/ggml-org/whisper"
    fi
fi

cd "$INSTALL_DIR"
echo ""

# Make scripts executable
echo "Setting up scripts..."
echo "------------------------------"

chmod +x scripts/*.sh
echo "✅ Scripts are now executable"
echo ""

# Create symlink for main script
echo "Creating command shortcuts..."
echo "------------------------------"

SYMLINK_DIR="$HOME/.local/bin"
mkdir -p "$SYMLINK_DIR"

# Remove old symlink if it exists
rm -f "$SYMLINK_DIR/yt-transcribe"

# Create new symlink to the wrapper script
ln -s "$INSTALL_DIR/yt-transcribe" "$SYMLINK_DIR/yt-transcribe"
echo "✅ Created 'yt-transcribe' command"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$SYMLINK_DIR:"* ]]; then
    echo ""
    echo "⚠️  Note: $SYMLINK_DIR is not in your PATH"
    echo "Add the following line to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""

# Setup configuration
echo "Setting up configuration..."
echo "------------------------------"

# Check for OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo ""
    echo "⚠️  OPENAI_API_KEY is not set"
    echo "To enable AI summarization, add your OpenAI API key to:"
    echo "  $INSTALL_DIR/config/config.sh"
    echo "Or set it as an environment variable:"
    echo "  export OPENAI_API_KEY='your-api-key-here'"
else
    echo "✅ OpenAI API key is configured"
fi

echo ""

# Create default directories
echo "Creating default directories..."
echo "------------------------------"

DEFAULT_OUTPUT_DIR="$HOME/Documents/youtuburi"
mkdir -p "$DEFAULT_OUTPUT_DIR"
echo "✅ Created output directory: $DEFAULT_OUTPUT_DIR"

echo ""

# Installation complete
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "You can now use the YouTube Transcriber!"
echo ""
echo "Usage:"
echo "  yt-transcribe [OPTIONS] VIDEO_URL"
echo ""
echo "Options:"
echo "  -d    Delete unnecessary files after processing"
echo "  -n    Skip saving to Obsidian"
echo "  -s    Skip AI summarization"
echo "  -o    Open PDF in Firefox when done"
echo ""
echo "Example:"
echo "  yt-transcribe https://www.youtube.com/watch?v=dQw4w9WgXcQ"
echo ""
echo "Configuration file:"
echo "  $INSTALL_DIR/config/config.sh"
echo ""
echo "Output directory:"
echo "  $DEFAULT_OUTPUT_DIR"
echo ""

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Note: To enable AI summarization, set your OpenAI API key in the config file."
    echo ""
fi

echo "Enjoy! 🎥📝"