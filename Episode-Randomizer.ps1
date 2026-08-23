################### simple script for shuffleplaying tv episodes ###################

## config and settings and loading episodes and stuff ##
if(!(test-path $PSScriptRoot\settings.json)) {
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
$settings = get-content $PSScriptRoot\settings.json | convertfrom-json

if (!(test-path $settings.PlayedEpisodesPath)) {
    New-Item -ItemType File -Path $settings.PlayedEpisodesPath | Out-Null
}

$playedEpisodes = get-content $settings.PlayedEpisodesPath |
    ForEach-Object { return $_.Trim() } |
    Where-Object { $_ -ne "" }

if (!(test-path $settings.MediaPath)) {
    New-Item -ItemType Directory -Path $settings.MediaPath | Out-Null
}

$episodes = [System.Collections.Generic.List[string]]::new()
Get-Childitem -Recurse $settings.MediaPath -file |
    where-object { $_fullname -notmatch $settings.ExcludePaths } |
    where-object { $_.FullName -notin $playedEpisodes } |
    ForEach-Object { $episodes.Add($_.FullName) }

################### Functions ###################
function Get-Episode {
    $index = get-random -Minimum 0 -Maximum $episodes.Count
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

$PlayNext=$true
while ($PlayNext -and $episodes) {
    $episodePath = Get-Episode
    write-host "Now playing: $episodePath \nClose the player when finished to continue..."
    Play-Episode $episodePath
    if (read-host "Play next? (Y/N)" -eq "N") { $PlayNext = $false }
}
