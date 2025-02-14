#requires -Version 5.1

###############################################################################
# 0) USER CONFIGURATION
###############################################################################
$config = @{
    # The shortcut or exe that first launches the BsgLauncher.
    # Example: "C:\Users\$env:USERNAME\Desktop\hwho.lnk"
    HwhoPath      = "C:\Users\$env:USERNAME\Desktop\hwho.lnk"
    HwhoName      = "hwho"               # Process name (without .exe)
    
    # Tarkov launcher and game
    LauncherName  = "BsgLauncher"        # Process name for BsgLauncher
    GameName      = "EscapeFromTarkov"   # Process name for Tarkov (no .exe)
    GameOrLnkPath = "C:\Users\$env:USERNAME\Desktop\hwho.lnk"

    # Where to click on the launcher window
    RelX          = 1222
    RelY          = 665

    # Time intervals
    InitialWait   = 60    # Seconds to wait initially before click
    PostClickWait = 180   # Seconds to wait after the mouse click
    WaitBeforeF1  = 4    # Seconds before pressing F1 once game is in foreground
    F1Interval    = 5    # Minutes between each F1 press
}

###############################################################################
# 1) IMPORT WINDOWS API FUNCTIONS
###############################################################################
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class User32
{
    [Flags]
    public enum MouseEventFlags : uint
    {
        LEFTDOWN = 0x0002,
        LEFTUP   = 0x0004
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
"@

Add-Type -AssemblyName System.Windows.Forms  # For SendKeys

###############################################################################
# 2) HELPER FUNCTIONS
###############################################################################
function Wait-UntilProcessExists {
    param(
        [Parameter(Mandatory)][string]$Name,
        [int]$TimeoutSeconds = 60
    )
    $start = Get-Date
    while ((Get-Date) -lt $start.AddSeconds($TimeoutSeconds)) {
        $proc = Get-Process -Name $Name -ErrorAction SilentlyContinue
        if ($proc) { return $true }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Bring-WindowToFront {
    param([string]$procName)

    $proc = Get-Process -Name $procName -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne 0 }
    if ($proc) {
        [User32]::ShowWindow($proc.MainWindowHandle, 1) | Out-Null
        [User32]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
    }
}

function Click-Launcher {
    param([int]$RelX, [int]$RelY)
    $p = Get-Process -Name $config.LauncherName -ErrorAction SilentlyContinue |
         Where-Object { $_.MainWindowHandle -ne 0 }
    if (-not $p) {
        Write-Host "Launcher not running or no window handle."
        return
    }
    Bring-WindowToFront -procName $config.LauncherName

    $rect = New-Object User32+RECT
    if (-not [User32]::GetWindowRect($p.MainWindowHandle, [ref]$rect)) {
        Write-Host "Unable to get launcher window rect."
        return
    }

    $absX = $rect.Left + $RelX
    $absY = $rect.Top  + $RelY

    [User32]::SetCursorPos($absX, $absY) | Out-Null
    Start-Sleep -Milliseconds 100

    [User32]::mouse_event([User32+MouseEventFlags]::LEFTDOWN, 0, 0, 0, 0)
    Start-Sleep -Milliseconds 50
    [User32]::mouse_event([User32+MouseEventFlags]::LEFTUP,   0, 0, 0, 0)

    Write-Host "Clicked offset ($RelX,$RelY) => absolute ($absX,$absY)"
}

function Ensure-Hwho {
    param()
    $proc = Get-Process -Name $config.HwhoName -ErrorAction SilentlyContinue
    if (-not $proc) {
        Write-Host "Starting hwho from $($config.HwhoPath)..."
        Start-Process -FilePath $config.HwhoPath
        Write-Host "Waiting for hwho process..."
        Wait-UntilProcessExists -Name $config.HwhoName -TimeoutSeconds 30 | Out-Null
    }
}

function Ensure-Launcher {
    param()
    $proc = Get-Process -Name $config.LauncherName -ErrorAction SilentlyContinue
    if (-not $proc) {
        # If the launcher isn't open, run hwho again to spawn the launcher
        Ensure-Hwho
        Write-Host "Waiting up to 60s for launcher..."
        Wait-UntilProcessExists -Name $config.LauncherName -TimeoutSeconds 30 | Out-Null
    }
}

function Ensure-Game {
    param()
    $proc = Get-Process -Name $config.GameName -ErrorAction SilentlyContinue
    if (-not $proc) {
        Write-Host "Game not running, ensuring launcher is up..."
        Ensure-Launcher
        Write-Host "Clicking to start game..."
        Click-Launcher -RelX $config.RelX -RelY $config.RelY
        Start-Sleep -Seconds $config.PostClickWait
        Write-Host "Waiting up to 60s for $($config.GameName) to appear..."
        Wait-UntilProcessExists -Name $config.GameName -TimeoutSeconds 60 | Out-Null
    }
}

###############################################################################
# 3) MAIN LOOP
###############################################################################
Write-Host "Press Ctrl+C to stop at any time."

while ($true) {
    Write-Host "1) Ensure hwho is running..."
    Ensure-Hwho

    Write-Host "2) Ensure BsgLauncher is running..."
    Ensure-Launcher

    Write-Host "3) Bring BsgLauncher to front, wait $($config.InitialWait) seconds, click it..."
    Bring-WindowToFront -procName $config.LauncherName
    Start-Sleep -Seconds $config.InitialWait
    Click-Launcher -RelX $config.RelX -RelY $config.RelY
    Write-Host "   Post-click wait $($config.PostClickWait) seconds..."
    Start-Sleep -Seconds $config.PostClickWait

    Write-Host "4) Ensure Tarkov is running..."
    Ensure-Game
    Bring-WindowToFront -procName $config.GameName
    Write-Host "   Waiting $($config.WaitBeforeF1) seconds before F1..."
    Start-Sleep -Seconds $config.WaitBeforeF1
    [System.Windows.Forms.SendKeys]::SendWait("{F1}")

    Write-Host "5) Entering F1 loop. Will press F1 every $($config.F1Interval) minute(s)."
    Write-Host "   Press Ctrl+C to break this cycle."

    while ($true) {
        # Check if game is still running
        $gameProc = Get-Process -Name $config.GameName -ErrorAction SilentlyContinue
        if (-not $gameProc) {
            Write-Host "Game closed. Breaking loop to re-init..."
            break
        }
        # Bring game to foreground, press F1
        Bring-WindowToFront -procName $config.GameName
        [System.Windows.Forms.SendKeys]::SendWait("{F1}")
        Start-Sleep -Seconds ($config.F1Interval * 60)
    }
}
