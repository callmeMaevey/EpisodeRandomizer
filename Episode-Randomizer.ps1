
if(!(test-path $PSScriptRoot\settings.json)) {
    $defaultSettings = @{
        MediaPath = "$PSScriptRoot\Episodes"
        PlayedEpisodesPath = "$PSScriptRoot\playedEpisodes.txt"
        PlaybackApplication = "vlc"
        VideoExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".webm")
    }
    $defaultSettings | ConvertTo-Json -Depth 3 | Out-File $PSScriptRoot\settings.json
    Write-Host "Created default settings.json. Please edit it as needed."
    exit
}

$settings = get-content $PSScriptRoot\settings.json | convertfrom-json
$excludedEpisodes = get-content $settings.PlayedEpisodesPath |
    ForEach-Object { return $_.Trim() } |
    Where-Object { $_ -ne "" }

$episodes = [System.Collections.Generic.List[string]]::new()
Get-Childitem -Recurse $settings.MediaPath -file |
    Where-object { $_.Extension -in $settings.VideoExtensions } |
    where-object { $_.FullName -notin $excludedEpisodes } |
    ForEach-Object { $episodes.Add($_.FullName) }

function Get-Episode {
    $index = get-random -Minimum 0 -Maximum $episodes.Count
    $episodePath = $episodes[$index]
    $episodes.RemoveAt($index)
    $episodePath | Out-File -Append $settings.PlayedEpisodesPath
    return $episodePath 
}

function Play-Episode ($episodePath) {

    & $settings.PlaybackApplication $episodePath
}

$PlayNext=$true
while ($PlayNext -and $episodes) {
    $episodePath = Get-Episode
    Play-Episode $episodePath
    read-host "Press Enter after watching the episode to continue..."
    if (read-host "Play next? (Y/N)" -eq "N") { $PlayNext = $false }
}
