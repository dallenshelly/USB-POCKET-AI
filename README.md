# USB-POCKET-AI 🧠

**Portable, uncensored AI that fits in your pocket.**

Run powerful AI models directly from any USB drive on Windows, Linux, or macOS. No installation, no cloud, no censorship. Just plug in and run.

---

## ✨ Features

- **Truly Portable** – Everything runs from the USB drive. Zero traces left on the host computer.
- **Uncensored** – Run models without arbitrary refusals or safety lectures. Perfect for pentesting, research, and creative work.
- **Cross-Platform** – Works on Windows, Linux, and macOS.
- **No GPU Required** – Runs on CPU, though GPU acceleration is supported if available.
- **Auto-Detects GGUF Files** – Place your `.gguf` models in the `gguf` folder and they're automatically imported.
- **Self-Surviving Installer** – The installer copies itself to a temp folder before formatting, so it never gets deleted.

---

## 🚀 Quick Start

### 1. Download or Clone This Repository

```bash
git clone https://github.com/dallenshelly/USB-POCKET-AI.git
```

### 2. Insert a USB Drive (16GB+ minimum, 32GB+ recommended)

### 3. Run the Installer for Your OS

| OS | Command |
|----|---------|
| **Windows** | Right-click `install.bat` → **Run as Administrator** |
| **Linux** | `sudo bash install.sh` |
| **macOS** | `sudo bash install-mac.sh` |

### 4. Follow the Prompts

- Select your USB drive
- Type `YES` to confirm formatting (to **exFAT**)
- The installer will:
  - Format the drive
  - Clone this repository
  - Install Ollama portably
  - Import any `.gguf` files from the `gguf` folder

### 5. Run Portable AI

After installation, navigate to the `PortableAI` folder on your USB and run the launcher:

| OS | Command |
|----|---------|
| **Windows** | Double-click `start-windows.bat` |
| **Linux** | `./start-linux.sh` |
| **macOS** | `./start-mac.sh` |

### 6. Start Chatting

Once the launcher opens, type:

```bash
ollama list                    # See available models
ollama run lily-uncensored     # Start chatting (use your model name)
```

---

## 📁 Repository Structure

```
USB-POCKET-AI/
│
├── install.bat              # Windows installer (runs as admin)
├── install.sh               # Linux installer
├── install-mac.sh           # macOS installer
│
├── start-windows.bat        # Windows launcher
├── start-linux.sh           # Linux launcher
├── start-mac.sh             # macOS launcher
│
├── gguf/                    # ← Place your .gguf model files here
│   └── (your_model.Q4_K_M.gguf)
│
├── scripts/                 # VBS helper scripts for Windows
│   ├── elevate.vbs          # Request admin privileges
│   ├── check_gpu.vbs        # Detect GPU and recommend models
│   ├── hide_console.vbs     # Run launcher with console hidden
│   ├── install_git.vbs      # Popup to install Git if missing
│   ├── show_help.vbs        # Display help information
│   └── uninstall.vbs        # Remove Portable AI from USB
│
├── models/                  # Runtime folder (Ollama stores models here)
├── logs/                    # Runtime folder (Ollama logs)
└── README.md                # This file
```

---

## 🛠️ How It Works

### Installer Flow

1. **Self-Copy to Temp** – The installer detects if it's running from USB. If yes, it copies itself to a temp folder and relaunches. This ensures it survives the USB format.
2. **Format USB** – Formats the selected drive to **exFAT** (compatible with all OSes).
3. **Clone Repo** – Clones your GitHub repository to the USB.
4. **Install Ollama** – Downloads and extracts Ollama portable to the USB.
5. **Import GGUF** – Scans the `gguf` folder and imports any `.gguf` files into Ollama.
6. **Create Launchers** – Creates OS-specific launcher scripts if not present.

### Launcher Flow

1. Sets `OLLAMA_MODELS` to the local `models` folder on the USB.
2. Checks if Ollama is already running.
3. Starts Ollama in the background if not running.
4. Adds Ollama to PATH for the current session.
5. Displays available models and opens a shell prompt.

---

## 📦 Adding Your Own Models

1. **Download a GGUF model** from Hugging Face (e.g., `Lily-Uncensored-Q4_K_M.gguf`)
2. **Place it in the `gguf` folder** of your repository
3. **Commit and push** to GitHub, or add it manually to the USB after installation

The installer will automatically import any `.gguf` files found in the `gguf` folder.

### Recommended Models for Your Hardware

| RAM | Recommended Models |
|-----|-------------------|
| 8GB | `tinyllama`, `phi3:mini` (3B) |
| 16GB | `lily-cybersecurity-7b`, `qwen2.5-coder:7b` (7B) |
| 32GB+ | `deepseek-coder:6.7b`, `llama3.2:3b` |

---

## 🖥️ System Requirements

- **USB Drive:** 16GB minimum (32GB+ recommended for multiple models)
- **RAM:** 8GB minimum (16GB recommended for 7B models)
- **OS:** Windows 10/11, Linux (any distro), macOS 11+
- **Internet:** Required only for initial installation and downloading models
- **Git:** Required for cloning (installer will prompt to install if missing)

---

## 🔧 Helper Scripts (Windows)

The `scripts` folder contains VBS helper scripts:

| Script | Purpose |
|--------|---------|
| `elevate.vbs` | Run any script as administrator |
| `check_gpu.vbs` | Detect GPU and recommend models |
| `hide_console.vbs` | Launch Portable AI with no console window |
| `install_git.vbs` | Popup to install Git if missing |
| `show_help.vbs` | Display help information |
| `uninstall.vbs` | Remove Portable AI from USB |

**Example usage:**

```cmd
cscript.exe scripts\check_gpu.vbs
wscript.exe scripts\hide_console.vbs
```

---

## 🧹 Uninstalling

To completely remove Portable AI from your USB drive:

- **Windows:** Double-click `scripts\uninstall.vbs`
- **Manual:** Delete the `PortableAI` folder from your USB drive

---

## ⚠️ Important Notes

- **Formatting erases all data** on the selected USB drive. Back up important files first.
- **The installer must run as Administrator** (Windows) or with `sudo` (Linux/macOS).
- **Uncensored models** can generate any content. Use responsibly and only for authorized purposes.
- **As a pentester**, you are responsible for complying with all laws and obtaining proper authorization before testing.

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `Git is not installed` | Install Git from [git-scm.com](https://git-scm.com) or allow the installer to open the download page |
| `Access denied` | Run the installer as Administrator (Windows) or with `sudo` (Linux/macOS) |
| `No USB drives found` | Ensure the USB drive is inserted and detected by your OS |
| `Ollama fails to start` | Check `logs/ollama.log` for errors. Ensure no other Ollama instance is running |
| `Model import fails` | Verify the `.gguf` file is not corrupted. Try re-downloading |
| `Slow performance` | Use smaller models (3B-7B) or enable GPU acceleration if available |

---

## 📝 License

This project is open-source. Models and Ollama have their own respective licenses.

---

## 🙏 Acknowledgments

- [Ollama](https://ollama.com) – The incredible portable LLM runner
- [Hugging Face](https://huggingface.co) – Model hosting and GGUF format
- The uncensored AI community – For making models that respect user freedom

---

## 📞 Support & Contact

- **GitHub Issues:** [github.com/dallenshelly/USB-POCKET-AI/issues](https://github.com/dallenshelly/USB-POCKET-AI/issues)
- **Author:** Dallen Shelly

---

**Made for pentesters, researchers, and AI enthusiasts who value privacy and freedom.**

---

## ✅ What This README Includes

| Section | Content |
|---------|---------|
| **Features** | Highlights portability, uncensored nature, cross-platform support |
| **Quick Start** | Step-by-step instructions from cloning to chatting |
| **Repository Structure** | Complete file tree with explanations |
| **How It Works** | Technical flow of installer and launcher |
| **Adding Models** | Instructions for including GGUF files |
| **System Requirements** | Minimum hardware specs |
| **Helper Scripts** | Documentation for VBS scripts |
| **Troubleshooting** | Common issues and solutions |
| **Uninstalling** | Clean removal instructions |

---
