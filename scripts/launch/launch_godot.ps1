$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Find-Godot {
    if ($env:GODOT_EXE -and (Test-Path $env:GODOT_EXE)) {
        return (Resolve-Path $env:GODOT_EXE).Path
    }

    $commands = @("godot", "godot4", "Godot")
    foreach ($command in $commands) {
        $resolved = Get-Command $command -ErrorAction SilentlyContinue
        if ($resolved -and $resolved.Source) {
            return $resolved.Source
        }
    }

    $patterns = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\GodotEngine.GodotEngine*\Godot*.exe"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\Godot*.exe"),
        (Join-Path $env:ProgramFiles "Godot*\Godot*.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Godot*\Godot*.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Godot*\Godot*.exe"),
        (Join-Path $env:LOCALAPPDATA "Godot*\Godot*.exe"),
        "C:\Godot*\Godot*.exe",
        "C:\Program Files\Steam\steamapps\common\Godot*\Godot*.exe",
        "C:\Program Files (x86)\Steam\steamapps\common\Godot*\Godot*.exe",
        "C:\Program Files\Epic Games\Godot*\Godot*.exe"
    )

    foreach ($pattern in $patterns) {
        $match = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "_console" } |
            Sort-Object FullName |
            Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }

    $downloads = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path $downloads) {
        $match = Get-ChildItem -Path $downloads -Recurse -Depth 3 -File -Filter "Godot*.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }

    return $null
}

$godot = Find-Godot
if (-not $godot) {
    Write-Host ""
    Write-Host "Godot was not found automatically."
    Write-Host "Install Godot 4, add it to PATH, or set the GODOT_EXE environment variable."
    Write-Host "Project: $projectRoot"
    Write-Host ""
    pause
    exit 1
}

Write-Host "Launching Red Meridian with: $godot"
Start-Process -FilePath $godot -ArgumentList @("--path", $projectRoot) -WorkingDirectory $projectRoot
