' check_gpu.vbs - Detect GPU and recommend which AI models will run well
' Usage: cscript.exe check_gpu.vbs

Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_VideoController")

gpuFound = False
recommendation = ""

For Each objItem in colItems
    name = objItem.Name
    adapterRAM = objItem.AdapterRAM
    
    ' Convert bytes to GB
    If IsNull(adapterRAM) Then
        vramGB = 0
    Else
        vramGB = adapterRAM / 1073741824
    End If
    
    ' Check for dedicated GPU (NVIDIA, AMD, Intel Arc)
    If InStr(name, "NVIDIA") > 0 Or InStr(name, "AMD") > 0 Or InStr(name, "Radeon") > 0 Or InStr(name, "Intel Arc") > 0 Then
        gpuFound = True
        
        WScript.Echo "========================================"
        WScript.Echo "GPU Detected: " & name
        WScript.Echo "VRAM: " & Round(vramGB, 1) & " GB"
        WScript.Echo "========================================"
        
        If vramGB >= 16 Then
            recommendation = "Excellent! You can run 33B+ models (e.g., DeepSeek-Coder-33B)"
        ElseIf vramGB >= 12 Then
            recommendation = "Great! You can run 13B-20B models (e.g., Qwen2.5-Coder-14B)"
        ElseIf vramGB >= 8 Then
            recommendation = "Good! You can run 7B-8B models (e.g., Lily-Cybersecurity-7B)"
        ElseIf vramGB >= 4 Then
            recommendation = "OK. You can run 3B-4B models (e.g., Phi-3-mini)"
        Else
            recommendation = "Limited VRAM. CPU mode recommended (will be slower but works)"
        End If
        
        WScript.Echo recommendation
        WScript.Echo ""
        WScript.Echo "Recommended command:"
        If vramGB >= 4 Then
            WScript.Echo "  ollama run lily-uncensored"
        Else
            WScript.Echo "  ollama run tinyllama (very small, fast on CPU)"
        End If
    End If
Next

If Not gpuFound Then
    WScript.Echo "========================================"
    WScript.Echo "No dedicated GPU detected."
    WScript.Echo "Running AI will use CPU only."
    WScript.Echo "========================================"
    WScript.Echo ""
    WScript.Echo "Recommendation: Use smaller models (3B-7B) for better speed."
    WScript.Echo "Example: ollama run tinyllama"
    WScript.Echo "Or:      ollama run phi3:mini"
End If

WScript.Echo ""
WScript.Echo "Press any key to close..."
