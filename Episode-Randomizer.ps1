################### simple script for shuffleplaying tv episodes ###################

## config and settings and firstrun stuff ##

if (!(Test-Path $PSScriptRoot\settings.json)) {
    $defaultSettings = @{
        MediaPath = (Join-Path $PSScriptRoot "Episodes")
        PlayedEpisodesPath = (Join-Path $PSScriptRoot "playedEpisodes.txt")
        PlaybackApplication = "vlc"
        SupportedExtensions = @( 
            ".mp4", ".mkv", ".mov", ".avi", ".webm", ".wmv", ".m4v", ".mpg", ".mpeg",
            ".ts", ".m2ts", ".mts", ".flv", ".3gp", ".vob", ".asf", ".ogv", ".rmvb",
            ".rm", ".mxf", ".h264", ".hevc", ".h265", ".m2v", ".f4v", ".divx", ".3g2",
            ".dv", ".m2t", ".m1v", ".ogm", ".tod", ".nut", ".pva"
        ) 
    }
    $defaultSettings | ConvertTo-Json -Depth 3 | Out-File $PSScriptRoot\settings.json
    Write-Host "Created default settings.json. Please edit it as needed." -ForegroundColor Blue
    if( (Read-Host "exit to edit the settings file? (y/N)") -eq "y") { exit }
}
$settings = Get-Content $PSScriptRoot\settings.json | ConvertFrom-Json

if (!(Test-Path $settings.PlayedEpisodesPath)) {
    Write-Host "Creating played episodes file at $($settings.PlayedEpisodesPath)" -ForegroundColor Blue
    New-Item -ItemType File -Path $settings.PlayedEpisodesPath | Out-Null
}
if (!(Test-Path $settings.MediaPath)) {
    Write-Host "Creating media directory at $($settings.MediaPath)..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path $settings.MediaPath | Out-Null
    Write-Host "`n`nAdd your media files to the media directory!! `nThen run the script again to start playing!" -ForegroundColor Green
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


if ($episodes.Count -eq 0) {
    Write-Host "No unplayed episodes found. Exiting..." -ForegroundColor Yellow
    exit
}

################### Functions ###################
function Get-Episode {
    $index = Get-Random -Minimum 0 -Maximum $episodes.Count
    $episodePath = $episodes[$index]
    $episodes.RemoveAt($index)
    return $episodePath 
}

function Start-Episode ($episodePath) {
    if ($IsMacOS) {
        & open -W -a $settings.PlaybackApplication --args $episodePath
    }
    else {
        & $settings.PlaybackApplication $episodePath
    }
    if (!($?)) { Write-Error "Error playing episode. Please check your playback application." -ea Stop }
}
function Write-PlayedEpisode ($episodePath) {
    try {
        $episodePath | Out-File -Append -FilePath $settings.PlayedEpisodesPath 
    }
    catch {
        Write-Error "Error marking episode as played: $($_.Exception.Message)" -ErrorAction Inquire
    }
}


## Main ##

$playNext = $true
while ($playNext -and $episodes) {
    $episodePath = Get-Episode
    Write-Host "Now playing: `n`t$episodePath"
    Write-Host "Close the player when finished to continue..."
    Start-Episode $episodePath
    Write-PlayedEpisode $episodePath
    if ($episodes.Count -eq 0) {
        Write-Host "No more unplayed episodes found. Exiting..." -ForegroundColor Yellow
        break
    }
    if ((Read-Host "Play next? (Y/n)") -eq "N") { $playNext = $false }
}
