#!/bin/bash

# Portable AI - USB Pocket AI (macOS)

cd "$(dirname "$0")"

# Set environment variables for portable operation
export OLLAMA_MODELS="$(pwd)/models"
export OLLAMA_HOST="127.0.0.1:11434"

# Check if Ollama is already running
if pgrep -f "ollama serve" > /dev/null; then
    echo "Ollama is already running."
else
    echo "Starting Portable AI from USB..."
    "$(pwd)/ollama_bin/ollama" serve > logs/ollama.log 2>&1 &
    OLLAMA_PID=$!
    echo "Ollama server running with PID: $OLLAMA_PID"
    sleep 2
fi

# Add Ollama to PATH for this session
export PATH="$(pwd)/ollama_bin:$PATH"

echo ""
echo "================================================"
echo "   USB Pocket AI - Ready to Use"
echo "================================================"
echo ""
echo "Available models:"
ollama list
echo ""
echo "Commands:"
echo "  ollama list              - Show installed models"
echo "  ollama run <model>       - Start chatting with a model"
echo "  ollama pull <model>      - Download a new model"
echo "  ollama help              - Show all commands"
echo ""
echo "Example:"
echo "  ollama run lily-uncensored"
echo ""
echo "To stop Ollama later, run: kill $OLLAMA_PID"
echo "================================================"
echo ""

/bin/bash
