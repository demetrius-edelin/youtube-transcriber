#!/bin/bash
# Configuration file for YouTube Transcriber
# This file contains all configurable paths and settings

# Base directory for the project (automatically detected)
export YT_TRANSCRIBER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Output directory for downloaded and processed videos
export DEST_DIR="${DEST_DIR:-$HOME/Documents/youtubes}"

# Obsidian notes directory (optional)
export OBSIDIAN_DIR="${OBSIDIAN_DIR:-$HOME/Documents/obsidian_notes/Youtube_transcripts}"

# Whisper.cpp paths
export WHISPER_CPP_DIR="${WHISPER_CPP_DIR:-$YT_TRANSCRIBER_DIR/whisper.cpp}"
export WHISPER_CLI="${WHISPER_CLI:-$WHISPER_CPP_DIR/build/bin/whisper-cli}"
export WHISPER_MODEL="${WHISPER_MODEL:-$YT_TRANSCRIBER_DIR/models/ggml-large-v3-turbo.bin}"

# yt-dlp executable path
export YT_DLP="${YT_DLP:-yt-dlp}"

# ffmpeg executable path
export FFMPEG="${FFMPEG:-ffmpeg}"

# OpenAI configuration for summarization (optional)
# export OPENAI_API_KEY="your-api-key-here"
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-5-mini-2025-08-07}"

# Python executable
export PYTHON="${PYTHON:-python3}"

# Node.js executable
export NODE="${NODE:-node}"

# Pandoc executable
export PANDOC="${PANDOC:-pandoc}"

# Environment variables for macOS Metal support
export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/System/Library/Frameworks/Metal.framework/Versions/Current/Libraries"
export PYTORCH_ENABLE_MPS_FALLBACK=1