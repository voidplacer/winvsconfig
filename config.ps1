# Suppress standard output and default progress bars for silent operation
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

try {
    $totalSteps = 4
    $step = 1

    # ==========================================
    # Step 1: Download AutoHotkey, Setup Startup & Run Now
    # ==========================================
    Write-Progress -Activity "Applying Configuration" -Status "Configuring AutoHotkey..." -PercentComplete (($step / $totalSteps) * 100)
    
    $ahkDir = "$env:LOCALAPPDATA\CustomAHKEnvironment"
    if (!(Test-Path $ahkDir)) { New-Item -ItemType Directory -Path $ahkDir | Out-Null }

    # Using raw.githubusercontent URLs to directly download the file contents
    $exeUrl = "https://raw.githubusercontent.com/voidplacer/winvsconfig/main/autohotkey/AutoHotkey64.exe"
    $ahkUrl = "https://raw.githubusercontent.com/voidplacer/winvsconfig/main/autohotkey/EscVimBinds.ahk"
    $exePath = "$ahkDir\AutoHotkey64.exe"
    $ahkPath = "$ahkDir\EscVimBinds.ahk"

    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri $ahkUrl -OutFile $ahkPath -UseBasicParsing | Out-Null

    # Create a shortcut in the Startup folder to ensure it runs automatically on future reboots
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$startupFolder\EscVimBinds.lnk")
    $Shortcut.TargetPath = $exePath
    $Shortcut.Arguments = "`"$ahkPath`""
    $Shortcut.WorkingDirectory = $ahkDir
    $Shortcut.WindowStyle = 1
    $Shortcut.Save()

    # Instantly launch AutoHotkey for the current session, completely hidden
    Start-Process -FilePath $exePath -ArgumentList "`"$ahkPath`"" -WindowStyle Hidden
    
    $step++

    # ==========================================
    # Step 2: VS Code Extensions Management
    # ==========================================
    Write-Progress -Activity "Applying Configuration" -Status "Managing VS Code Extensions..." -PercentComplete (($step / $totalSteps) * 100)

    # Ensure VS Code is installed and accessible via CLI
    if (!(Get-Command "code" -ErrorAction SilentlyContinue)) {
        throw "VS Code 'code' command not found. Ensure VS Code is installed and in your system PATH."
    }

    # Temporarily relax error checking so harmless Node.js warnings do not break the script
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    # Uninstall all currently installed extensions (redirecting stderr to null to hide warnings)
    $installedExtensions = code --list-extensions 2>$null
    if ($installedExtensions) {
        foreach ($ext in $installedExtensions) {
            code --uninstall-extension $ext > $null 2>&1
        }
    }

    # Install desired extensions
    $extensionsToInstall = @(
        "vscodevim.vim",
        "llvm-vs-code-extensions.vscode-clangd",
        "catppuccin.catppuccin-vsc",
        "catppuccin.catppuccin-vsc-icons",
        "formulahendry.code-runner"
    )
    foreach ($ext in $extensionsToInstall) {
        code --install-extension $ext --force > $null 2>&1
    }

    # Restore strict error checking for the rest of the script
    $ErrorActionPreference = $previousErrorAction

    $step++

    # ==========================================
    # Step 3: VS Code Settings Injection
    # ==========================================
    Write-Progress -Activity "Applying Configuration" -Status "Writing VS Code Settings..." -PercentComplete (($step / $totalSteps) * 100)
    
    $vscodeUserDir = "$env:APPDATA\Code\User"
    if (!(Test-Path $vscodeUserDir)) { New-Item -ItemType Directory -Path $vscodeUserDir | Out-Null }

    $settingsJson = @'
{
    // Standard UI/Visual Component
    "workbench.startupEditor": "none",
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.sideBar.location": "right",
    "workbench.activityBar.location": "top",
    "code-runner.runInTerminal": true,
    "code-runner.saveFileBeforeRun": true,
    "vim.smartRelativeLine": true,
    "editor.minimap.enabled": false,
    "breadcrumbs.enabled": false,
    "vim.useSystemClipboard": true,
    "redhat.telemetry.enabled": false,
    "window.commandCenter": false,
    "terminal.integrated.fontFamily": "CaskaydiaMono Nerd Font",
    "editor.stickyScroll.enabled": false,
    "telemetry.telemetryLevel": "off",
    "workbench.enableExperiments": false,

    // Lang Specific
    "C_Cpp.intelliSenseEngine": "Disabled",
    "java.jdt.ls.vmargs": "-Xms2G -Xmx5G -XX:+UseG1GC -XX:+UseStringDeduplication",
    // Java CP   /*Comment out/Enable if working in a project*/
    "java.import.gradle.enabled": false,
    "java.import.maven.enabled": false,
    
    // Fetch optimization
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/node_modules/**": true,
        "**/dist/**": true,
        "**/build/**": true,
        "**/.cache/**": true,
        "**/target/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/build": true
    },
    // Smooth Behavior
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "workbench.list.smoothScrolling": true,
    "editor.cursorBlinking": "smooth"
}
'@
    Set-Content -Path "$vscodeUserDir\settings.json" -Value $settingsJson -Encoding UTF8
    
    $step++

    # ==========================================
    # Step 4: VS Code Keybindings Injection
    # ==========================================
    Write-Progress -Activity "Applying Configuration" -Status "Writing VS Code Keybindings..." -PercentComplete (($step / $totalSteps) * 100)

    $keybindingsJson = @'
[
  // --- Move between splits ---
  { "key": "ctrl+h", "command": "workbench.action.navigateLeft" },
  { "key": "ctrl+l", "command": "workbench.action.navigateRight" },
  { "key": "ctrl+k", "command": "workbench.action.navigateUp" },
  { "key": "ctrl+j", "command": "workbench.action.navigateDown" },

  // --- Resize splits ---
  // When in the LEFT split (Group 1)
  { 
    "key": "alt+h", 
    "command": "workbench.action.decreaseViewWidth",
    "when": "activeEditorGroupIndex == 1"
  },
  { 
    "key": "alt+l", 
    "command": "workbench.action.increaseViewWidth",
    "when": "activeEditorGroupIndex == 1"
  },

  // When in the RIGHT split (Group 2 or higher)
  { 
    "key": "alt+h", 
    "command": "workbench.action.increaseViewWidth",
    "when": "activeEditorGroupIndex > 1"
  },
  { 
    "key": "alt+l", 
    "command": "workbench.action.decreaseViewWidth",
    "when": "activeEditorGroupIndex > 1"
  },
  { "key": "alt+k", "command": "workbench.action.decreaseViewHeight" },
  { "key": "alt+j", "command": "workbench.action.increaseViewHeight" },

  // --- Move between tabs (1 to 9) ---
  { "key": "alt+1", "command": "workbench.action.openEditorAtIndex1" },
  { "key": "alt+2", "command": "workbench.action.openEditorAtIndex2" },
  { "key": "alt+3", "command": "workbench.action.openEditorAtIndex3" },
  { "key": "alt+4", "command": "workbench.action.openEditorAtIndex4" },
  { "key": "alt+5", "command": "workbench.action.openEditorAtIndex5" },
  { "key": "alt+6", "command": "workbench.action.openEditorAtIndex6" },
  { "key": "alt+7", "command": "workbench.action.openEditorAtIndex7" },
  { "key": "alt+8", "command": "workbench.action.openEditorAtIndex8" },
  { "key": "alt+9", "command": "workbench.action.openEditorAtIndex9" },

  // --- Move 1 tab left or right ---
  { "key": "ctrl+shift+h", "command": "workbench.action.previousEditor" },
  { "key": "ctrl+shift+l", "command": "workbench.action.nextEditor" },

  // --- Create splits ---
  // Note: Alt+\ splits vertically (right), Alt+Enter splits horizontally (down)
  { "key": "alt+\\", "command": "workbench.action.newGroupRight" },
  { "key": "alt+enter", "command": "workbench.action.newGroupBelow" },

  // --- New tab / Close tab ---
  { "key": "ctrl+t", "command": "workbench.action.files.newUntitledFile" },
  { "key": "ctrl+w", "command": "workbench.action.closeActiveEditor" },

  // --- Terminal focus toggle ---
  // If not in terminal, jump to terminal. If in terminal, jump to code editor.
  { 
    "key": "ctrl+shift+i", 
    "command": "workbench.action.terminal.focus", 
    "when": "!terminalFocus" 
  },
  { 
    "key": "ctrl+shift+i", 
    "command": "workbench.action.focusActiveEditorGroup", 
    "when": "terminalFocus" 
  },

  // --- Search for files ---
  { "key": "ctrl+r", "command": "workbench.action.quickOpen" },

  // --- Toggle File/Folder View (Explorer Sidebar) ---
  { "key": "ctrl+e", "command": "workbench.action.toggleSidebarVisibility" },
  
  // Move Terminal
  { "key": "alt+]", "command": "workbench.action.positionPanelRight" },
  { "key": "alt+'", "command": "workbench.action.positionPanelBottom" }
]
'@
    Set-Content -Path "$vscodeUserDir\keybindings.json" -Value $keybindingsJson -Encoding UTF8

    Write-Progress -Activity "Applying Configuration" -Completed
    
    # Exit cleanly (the PowerShell window will automatically close)
    exit 0

} catch {
    # If anything fails, print the specific error and hold the window open so you can see it
    Write-Progress -Activity "Applying Configuration" -Completed
    Write-Host "`n[ERROR] The script encountered an issue:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
