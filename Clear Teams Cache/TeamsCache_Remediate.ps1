<#
    Title:    ClearTeamsCache

    Description:    Closes New teams, clears the user cache and restarts the application.

    Context:    User

#>



$LoggedOnUser = whoami

if ([string]::IsNullOrWhiteSpace($LoggedOnUser)) {
    Write-Output "No currently signed-in user."
    exit 0
}

# Extract username from domain\username
$UserID = $LoggedOnUser -replace '.*\\', ''
$CachePath = "C:\Users\{0}\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe" -f $UserID
$LocalCachePath = Join-Path $CachePath "LocalCache"

# Verify the cache path by checking for the LocalCache folder
if (-not (Test-Path $LocalCachePath)) {
    Write-Output "LocalCache folder not found. Aborting cache clear to avoid unintended deletion."
    exit 1
}

Write-Output "Verified Teams cache location via LocalCache folder."

# Stop Teams process if running
$stopTeamsSucceeded = $true
try {
    Stop-Process -Name "ms-teams" -Force -ErrorAction Stop
    Write-Output "Stopped Teams process."
    Start-Sleep -Seconds 5  # Wait for file handles to release
} catch {
    Write-Output "Failed to stop Teams process: $_"
    $stopTeamsSucceeded = $false
}

# Proceed only if Teams was successfully stopped
if ($stopTeamsSucceeded -and (Test-Path $CachePath)) {
    try {
        Get-ChildItem -Path $CachePath -Force | ForEach-Object {
            if (-not ($_.Attributes -match "ReparsePoint")) { # Check for links to other folders
                try {
                    Remove-Item -Path $_.FullName -Recurse -Force  -ErrorAction Stop
                } catch {
                    Write-Output "Could not delete: $($_.FullName) — $($_.Exception.Message)"
                }
            }
        }
        Write-Output "Teams cache cleared from $CachePath."
    } catch {
        Write-Output "Error clearing Teams cache: $_"
    }
} else {
    Write-Output "Skipping cache clear due to Teams process not being stopped or cache path not found."
}

# Restart Teams
try {
    Start-Process "ms-teams"
    Write-Output "Teams restarted."
} catch {
    Write-Output "Failed to restart Teams: $_"
}

exit 0
