#!/bin/bash

# Portable AI USB Installer - Linux
# Run with: sudo bash install.sh

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
if [[ "$SCRIPT_DIR" != /tmp/* ]] && [[ "$SCRIPT_DIR" != /var/tmp/* ]]; then
    echo -e "${YELLOW}Script is running from USB. Copying to temp folder...${NC}"
    
    # Create unique temp folder
    TEMP_SCRIPT_DIR=$(mktemp -d -t PortableAI_Installer_XXXXXX)
    
    # Copy this script to temp
    cp "$0" "$TEMP_SCRIPT_DIR/install.sh"
    chmod +x "$TEMP_SCRIPT_DIR/install.sh"
    
    # Copy any helper scripts if they exist (like the scripts folder)
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -rf "$SCRIPT_DIR/scripts" "$TEMP_SCRIPT_DIR/"
    fi
    
    echo -e "${GREEN}Relaunching from temp folder: $TEMP_SCRIPT_DIR${NC}"
    sudo "$TEMP_SCRIPT_DIR/install.sh"
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
echo -e "${GREEN}   Portable AI USB Installer - Linux${NC}"
echo -e "${BLUE}================================================${NC}"
echo

# Detect USB drives
echo -e "${YELLOW}Scanning for removable USB drives...${NC}"
echo

usb_drives=()
drive_index=1
while IFS= read -r line; do
    drive=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $4}')
    model=$(echo "$line" | awk '{print $6,$7,$8,$9,$10}')
    if [[ $drive =~ ^sd[a-z]$ ]]; then
        usb_drives+=("/dev/$drive")
        echo -e "[$drive_index] /dev/$drive - ${size} - ${model}"
        ((drive_index++))
    fi
done < <(lsblk -d -o NAME,SIZE,MODEL -l 2>/dev/null | grep -E "^sd" | head -10)

if [[ ${#usb_drives[@]} -eq 0 ]]; then
    echo -e "${RED}No USB drives found. Please insert a USB drive and try again.${NC}"
    exit 1
fi

echo
read -p "Select USB drive number: " selection

selected_drive=""
count=1
for drive in "${usb_drives[@]}"; do
    if [[ $count -eq $selection ]]; then
        selected_drive=$drive
        break
    fi
    ((count++))
done

if [[ -z "$selected_drive" ]]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Selected: $selected_drive${NC}"
echo -e "${RED}WARNING: This will FORMAT $selected_drive to exFAT and erase ALL data!${NC}"
read -p "Type YES to continue: " confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Cancelled."
    exit 0
fi

# Unmount any mounted partitions
echo -e "\n${YELLOW}Unmounting partitions...${NC}"
for part in $(ls ${selected_drive}* 2>/dev/null | grep -E "${selected_drive}[0-9]"); do
    umount "$part" 2>/dev/null || true
done

# Format to exFAT
echo -e "\n${YELLOW}Formatting to exFAT...${NC}"

# Check if exfat utilities are installed
if ! command -v mkfs.exfat &> /dev/null; then
    echo -e "${YELLOW}exFAT utilities not found. Attempting to install...${NC}"
    if command -v apt &> /dev/null; then
        apt update && apt install -y exfatprogs
    elif command -v yum &> /dev/null; then
        yum install -y exfatprogs
    elif command -v dnf &> /dev/null; then
        dnf install -y exfatprogs
    elif command -v pacman &> /dev/null; then
        pacman -S exfatprogs --noconfirm
    else
        echo -e "${RED}Cannot install exfatprogs. Please install manually: exfatprogs or exfat-utils${NC}"
        exit 1
    fi
fi

# Create partition table and format
(
echo o
echo n
echo p
echo 1
echo
echo
echo t
echo 7
echo w
) | fdisk "$selected_drive" >/dev/null 2>&1

sleep 2
mkfs.exfat "${selected_drive}1" 2>/dev/null || mkfs.exfat "$selected_drive" 2>/dev/null

# Mount the drive
mount_point="/mnt/portable_ai_$$"
mkdir -p "$mount_point"
mount "${selected_drive}1" "$mount_point" 2>/dev/null || mount "$selected_drive" "$mount_point" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to mount drive.${NC}"
    exit 1
fi

echo -e "${GREEN}Format complete.${NC}"

# Create directory structure
USB_ROOT="$mount_point"
echo -e "\n${YELLOW}Creating folder structure...${NC}"
mkdir -p "$USB_ROOT/PortableAI"
cd "$USB_ROOT/PortableAI"

# ============================================
# CHECK FOR GIT AND PROMPT TO INSTALL
# ============================================
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed.${NC}"
    echo -e "${YELLOW}Would you like to install git? (y/n)${NC}"
    read -p "Choice: " install_git
    
    if [[ "$install_git" == "y" ]] || [[ "$install_git" == "Y" ]]; then
        echo -e "${YELLOW}Installing git...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y git
        elif command -v yum &> /dev/null; then
            yum install -y git
        elif command -v dnf &> /dev/null; then
            dnf install -y git
        elif command -v pacman &> /dev/null; then
            pacman -S git --noconfirm
        else
            echo -e "${RED}Cannot install git automatically. Please install git and run again.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Git installed successfully.${NC}"
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
echo -e "\n${YELLOW}Downloading Ollama for Linux...${NC}"
mkdir -p ollama_bin

curl -L https://github.com/ollama/ollama/releases/download/v0.5.7/ollama-linux-amd64.tgz -o ollama.tgz
tar -xzf ollama.tgz -C ollama_bin/
rm ollama.tgz

# ============================================
# CREATE LINUX LAUNCHER (if not in repo)
# ============================================
if [[ ! -f "start-linux.sh" ]]; then
    echo -e "\n${YELLOW}Creating start-linux.sh...${NC}"
    cat > start-linux.sh << 'EOF'
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
    chmod +x start-linux.sh
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

# Cleanup - unmount USB
cd /
umount "$mount_point" 2>/dev/null
rmdir "$mount_point" 2>/dev/null

# Clean up temp script folder
rm -rf "$SCRIPT_DIR" 2>/dev/null

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo
echo -e "Portable AI installed to: ${selected_drive} (PortableAI folder)"
echo -e "Repository cloned from: ${REPO_URL}"
echo
echo -e "To use:"
echo -e "  1. Plug USB into any Linux computer"
echo -e "  2. Mount the drive (usually auto-mounts to /media/username/PortableAI)"
echo -e "  3. cd /path/to/PortableAI"
echo -e "  4. sudo ./start-linux.sh"
echo
