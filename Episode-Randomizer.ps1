################### simple script for shuffleplaying tv episodes ###################

## config and settings and loading episodes and stuff ##
if (!(Test-Path $PSScriptRoot\settings.json)) {
    $defaultSettings = @{
        MediaPath = "$PSScriptRoot\Episodes"
        PlayedEpisodesPath = "$PSScriptRoot\playedEpisodes.txt"
        PlaybackApplication = "vlc"
        ExcludePaths = @("*put_media_here")
    }
    $defaultSettings | ConvertTo-Json -Depth 3 | Out-File $PSScriptRoot\settings.json
    Write-Host "Created default settings.json. Please edit it as needed."
    exit
}
$settings = Get-Content $PSScriptRoot\settings.json | ConvertFrom-Json

if (!(Test-Path $settings.PlayedEpisodesPath)) {
    New-Item -ItemType File -Path $settings.PlayedEpisodesPath | Out-Null
}

$playedEpisodes = Get-Content $settings.PlayedEpisodesPath |
    ForEach-Object { return $_.Trim() } |
    Where-Object { $_ -ne "" }

if (!(Test-Path $settings.MediaPath)) {
    New-Item -ItemType Directory -Path $settings.MediaPath | Out-Null
}

$episodes = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -Recurse $settings.MediaPath -File |
    Where-Object { $_.FullName -notmatch $settings.ExcludePaths } |
    Where-Object { $_.FullName -notin $playedEpisodes } |
    ForEach-Object { $episodes.Add($_.FullName) }

################### Functions ###################
function Get-Episode {
    $index = Get-Random -Minimum 0 -Maximum $episodes.Count
    $episodePath = $episodes[$index]
    $episodes.RemoveAt($index)
    $episodePath | Out-File -Append $settings.PlayedEpisodesPath
    return $episodePath 
}

function Play-Episode ($episodePath) {
    if ($IsMacOS) {
        & open -W -a $settings.PlaybackApplication --args $episodePath
    }
    else {
        & $settings.PlaybackApplication $episodePath
    }
}

$playNext = $true
while ($playNext -and $episodes) {
    $episodePath = Get-Episode
    Write-Host "Now playing: $episodePath \nClose the player when finished to continue..."
    Play-Episode $episodePath
    if (Read-Host "Play next? (Y/N)" -eq "N") { $playNext = $false }
}
