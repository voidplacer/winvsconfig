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

    if (!(Test-Path $exePath) -or !(Test-Path $ahkPath)) {
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
    }
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
        "ms-vscode.cpptools",
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

    $settingsUrl = "https://raw.githubusercontent.com/voidplacer/myeditorconfig/main/vscode-default/settings.json"
    $settingsPath = "$vscodeUserDir\settings.json"
    Invoke-WebRequest -Uri $settingsUrl -OutFile $settingsPath -UseBasicParsing | Out-Null
    $step++

    # ==========================================
    # Step 4: VS Code Keybindings Injection
    # ==========================================
    Write-Progress -Activity "Applying Configuration" -Status "Writing VS Code Keybindings..." -PercentComplete (($step / $totalSteps) * 100)

    $keybindingsUrl = "https://raw.githubusercontent.com/voidplacer/myeditorconfig/main/vscode-default/keybindings.json"
    $keybindingsPath = "$vscodeUserDir\keybindings.json"
    Invoke-WebRequest -Uri $keybindingsUrl -OutFile $keybindingsPath -UseBasicParsing | Out-Null

    Write-Progress -Activity "Applying Configuration" -Completed
    
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