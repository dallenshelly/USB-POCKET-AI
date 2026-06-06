' show_help.vbs - Display help information for USB Pocket AI
' Usage: wscript.exe show_help.vbs

helpText = "==========================================" & vbCrLf & _
           "   USB Pocket AI - Help Guide" & vbCrLf & _
           "==========================================" & vbCrLf & vbCrLf & _
           "QUICK START:" & vbCrLf & _
           "  1. Double-click 'start-windows.bat' to launch" & vbCrLf & _
           "  2. Type 'ollama list' to see available models" & vbCrLf & _
           "  3. Type 'ollama run lily-uncensored' to start chatting" & vbCrLf & vbCrLf & _
           "COMMANDS:" & vbCrLf & _
           "  ollama list                    - Show installed models" & vbCrLf & _
           "  ollama run <model>             - Chat with a model" & vbCrLf & _
           "  ollama pull <model>            - Download a new model" & vbCrLf & _
           "  ollama rm <model>              - Remove a model" & vbCrLf & _
           "  ollama cp <source> <dest>      - Copy a model" & vbCrLf & _
           "  ollama show <model>            - Show model details" & vbCrLf & vbCrLf & _
           "EXAMPLES:" & vbCrLf & _
           "  ollama run llama3.2:1b         - Run a small, fast model" & vbCrLf & _
           "  ollama run qwen2.5-coder:7b    - Run a coding model" & vbCrLf & _
           "  ollama pull deepseek-coder:6.7b - Download a new model" & vbCrLf & vbCrLf & _
           "TIPS:" & vbCrLf & _
           "  - Type '/bye' to exit a chat session" & vbCrLf & _
           "  - Type '/?' for more chat commands" & vbCrLf & _
           "  - Models are stored in the 'models' folder" & vbCrLf & _
           "  - Close the terminal to stop Ollama" & vbCrLf & vbCrLf & _
           "=========================================="

MsgBox helpText, 64, "USB Pocket AI - Help"
