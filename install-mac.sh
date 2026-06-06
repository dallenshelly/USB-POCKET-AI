#!/bin/bash

# Portable AI USB Installer - macOS
# Run with: sudo bash install-mac.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# HARDCODED GITHUB REPOSITORY URL - EDIT THIS
# ============================================
REPO_URL="https://github.com/dallenshelly/USB-POCKET-AI.git"
# ============================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# CHECK IF RUNNING FROM TEMP FOLDER
# If not, copy self to temp and relaunch
# ============================================
if [[ "$SCRIPT_DIR" != /tmp/* ]] && [[ "$SCRIPT_DIR" != /private/tmp/* ]]; then
    echo -e "${YELLOW}Script is running from USB. Copying to temp folder...${NC}"
    
    # Create unique temp folder
    TEMP_SCRIPT_DIR=$(mktemp -d -t PortableAI_Installer_XXXXXX)
    
    # Copy this script to temp
    cp "$0" "$TEMP_SCRIPT_DIR/install-mac.sh"
    chmod +x "$TEMP_SCRIPT_DIR/install-mac.sh"
    
    # Copy any helper scripts if they exist
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -rf "$SCRIPT_DIR/scripts" "$TEMP_SCRIPT_DIR/"
    fi
    
    echo -e "${GREEN}Relaunching from temp folder: $TEMP_SCRIPT_DIR${NC}"
    sudo "$TEMP_SCRIPT_DIR/install-mac.sh"
    exit 0
fi

# We are now running from temp folder - continue with installation
echo -e "${GREEN}Running from temp folder: $SCRIPT_DIR${NC}"
echo

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root. Try: sudo $0${NC}"
   exit 1
fi

clear
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}   Portable AI USB Installer - macOS${NC}"
echo -e "${BLUE}================================================${NC}"
echo

# Detect USB drives
echo -e "${YELLOW}Scanning for removable USB drives...${NC}"
echo

diskutil list external
echo
read -p "Enter disk identifier (e.g., disk2): " disk_id

selected_drive="/dev/r$disk_id"

if [[ ! -e "$selected_drive" ]]; then
    echo -e "${RED}Invalid disk.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Selected: $selected_drive${NC}"
echo -e "${RED}WARNING: This will FORMAT $selected_drive to exFAT and erase ALL data!${NC}"
read -p "Type YES to continue: " confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Cancelled."
    exit 0
fi

# Unmount and format
echo -e "\n${YELLOW}Unmounting drive...${NC}"
diskutil unmountDisk "$selected_drive"

echo -e "\n${YELLOW}Formatting to exFAT...${NC}"
diskutil eraseDisk EXFAT "PortableAI" "$selected_drive"

sleep 3

# Find the mounted volume
mount_point=$(diskutil info "${selected_drive}s1" 2>/dev/null | grep "Mount Point" | awk '{$1=""; $2=""; print $0}' | xargs)
if [[ -z "$mount_point" ]]; then
    mount_point="/Volumes/PortableAI"
fi

USB_ROOT="$mount_point"

echo -e "\n${YELLOW}Creating folder structure...${NC}"
mkdir -p "$USB_ROOT/PortableAI"
cd "$USB_ROOT/PortableAI"

# ============================================
# CHECK FOR GIT AND PROMPT TO INSTALL
# ============================================
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed.${NC}"
    echo -e "${YELLOW}Would you like to install Xcode Command Line Tools (includes git)? (y/n)${NC}"
    read -p "Choice: " install_git
    
    if [[ "$install_git" == "y" ]] || [[ "$install_git" == "Y" ]]; then
        echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
        xcode-select --install
        
        echo -e "${YELLOW}Please wait for installation to complete, then press Enter...${NC}"
        read -p "Press Enter when done: "
        
        if ! command -v git &> /dev/null; then
            echo -e "${RED}Git still not found. Please install manually and run again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Git is required. Installation cancelled.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Git is installed. Continuing...${NC}"

# ============================================
# CLONE YOUR GITHUB REPOSITORY
# ============================================
echo -e "\n${YELLOW}Cloning repository from: $REPO_URL${NC}"
echo "This may take a moment..."

git clone "$REPO_URL" temp_repo
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to clone repository. Check URL.${NC}"
    exit 1
fi

echo -e "${GREEN}Copying files...${NC}"
cp -rf temp_repo/* . 2>/dev/null
cp -rf temp_repo/.[!.]* . 2>/dev/null
rm -rf temp_repo
echo -e "${GREEN}Repository cloned successfully.${NC}"

# Ensure required folders exist
mkdir -p gguf scripts models logs

# ============================================
# INSTALL OLLAMA PORTABLE
# ============================================
echo -e "\n${YELLOW}Downloading Ollama for macOS...${NC}"
mkdir -p ollama_bin

curl -L https://github.com/ollama/ollama/releases/download/v0.5.7/ollama-darwin-amd64.tgz -o ollama.tgz
tar -xzf ollama.tgz -C ollama_bin/
rm ollama.tgz

# ============================================
# CREATE MACOS LAUNCHER (if not in repo)
# ============================================
if [[ ! -f "start-mac.sh" ]]; then
    echo -e "\n${YELLOW}Creating start-mac.sh...${NC}"
    cat > start-mac.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
export OLLAMA_MODELS="$(pwd)/models"
export OLLAMA_HOST="127.0.0.1:11434"
echo "Starting Portable AI from USB..."
./ollama_bin/ollama serve > logs/ollama.log 2>&1 &
OLLAMA_PID=$!
echo "Ollama running with PID: $OLLAMA_PID"
export PATH="$(pwd)/ollama_bin:$PATH"
echo ""
echo "Available models:"
./ollama_bin/ollama list
echo ""
echo "Commands:"
echo "  ollama list"
echo "  ollama run <model>"
echo "  ollama pull <model>"
echo ""
echo "Type 'kill $OLLAMA_PID' to stop Ollama"
/bin/bash
EOF
    chmod +x start-mac.sh
fi

# ============================================
# IMPORT GGUF FILES FROM gguf FOLDER
# ============================================
echo -e "\n${YELLOW}Checking for GGUF files in gguf folder...${NC}"

if ls gguf/*.gguf 1>/dev/null 2>&1; then
    echo -e "${GREEN}Found GGUF files. Importing...${NC}"
    
    # Start Ollama
    ./ollama_bin/ollama serve &
    OLLAMA_PID=$!
    sleep 3
    
    for gguf_file in gguf/*.gguf; do
        filename=$(basename "$gguf_file" .gguf)
        modelname=$(echo "$filename" | sed 's/_//g')
        echo -e "${YELLOW}Importing $modelname...${NC}"
        
        echo "FROM ./$gguf_file" > Modelfile
        ./ollama_bin/ollama create "$modelname" -f Modelfile
        rm Modelfile
    done
    
    # Stop Ollama
    kill $OLLAMA_PID 2>/dev/null
    echo -e "${GREEN}Import complete.${NC}"
else
    echo -e "${YELLOW}No GGUF files found in 'gguf' folder.${NC}"
    echo "Place your .gguf files there and run 'ollama create' manually."
fi

# Create version file
echo "1.0" > version.txt

# Clean up temp script folder
rm -rf "$SCRIPT_DIR" 2>/dev/null

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo
echo -e "Portable AI installed to: $mount_point/PortableAI"
echo -e "Repository cloned from: ${REPO_URL}"
echo
echo -e "To use:"
echo -e "  1. Plug USB into any Mac"
echo -e "  2. cd /Volumes/PortableAI/PortableAI"
echo -e "  3. ./start-mac.sh"
echo
