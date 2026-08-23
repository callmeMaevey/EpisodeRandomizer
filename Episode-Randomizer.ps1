################### simple script for shuffleplaying tv episodes ###################

## config and settings and firstrun stuff ##

if (!(Test-Path $PSScriptRoot\settings.json)) {
    $defaultSettings = @{
        MediaPath = "$PSScriptRoot\Episodes"
        PlayedEpisodesPath = "$PSScriptRoot\playedEpisodes.txt"
        PlaybackApplication = "vlc"
        SupportedExtensions = @( 
            ".mp4", ".mkv", ".mov", ".avi", ".webm", ".wmv", ".m4v", ".mpg", ".mpeg",
            ".ts", ".m2ts", ".mts", ".flv", ".3gp", ".vob", ".asf", ".ogv", ".rmvb",
            ".rm", ".mxf", ".h264", ".hevc", ".h265", ".m2v", ".f4v", ".divx", ".3g2",
            ".dv", ".m2t", ".m1v", ".ogm", ".tod", ".nut", ".pva"
        ) 
    }
    $defaultSettings | ConvertTo-Json -Depth 3 | Out-File $PSScriptRoot\settings.json
    Write-Host "Created default settings.json. Please edit it as needed."
    exit
}
$settings = Get-Content $PSScriptRoot\settings.json | ConvertFrom-Json

if (!(Test-Path $settings.PlayedEpisodesPath)) {
    Write-Host "Creating played episodes file at $($settings.PlayedEpisodesPath)"
    New-Item -ItemType File -Path $settings.PlayedEpisodesPath | Out-Null
}
if (!(Test-Path $settings.MediaPath)) {
    Write-Host "Creating media directory at $($settings.MediaPath)"
    New-Item -ItemType Directory -Path $settings.MediaPath | Out-Null
    write-Host "Please add your media files to the media directory and run the script again."
    exit;
}


## Load media information ##
$playedEpisodes = [System.Collections.Generic.HashSet[string]]::new()
Get-Content $settings.PlayedEpisodesPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" } |
    ForEach-Object { $playedEpisodes.Add($_) | Out-Null }


$episodes = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -Recurse $settings.MediaPath -File |
    where-Object { $settings.SupportedExtensions -contains $_.Extension } |
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
