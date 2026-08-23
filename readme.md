# Episode Randomizer

A simple PowerShell script for playing TV episodes in random order without repeating episodes.

## Installation

1. Install [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell).
2. Install [VLC](https://www.videolan.org/vlc/), or edit `settings.json` to use another media player.

## Setup

Add your episode files to the `Episodes` folder. Subdirectories are supported, so you can organize multiple shows and seasons while shuffling them together.

To restart the shuffle, clear the `playedEpisodes.txt` file.

## Usage

Run `Episode-Randomizer.ps1` in PowerShell, or start it from a terminal:

```powershell
pwsh ./Episode-Randomizer.ps1
```

Follow the prompts to play an episode or exit. When an episode finishes, close the media player and return to the script. The script will then prompt you to play the next episode or exit.

### macOS

On macOS, quit the media player completely instead of simply closing its window. In VLC, use **VLC > Quit** or press **Cmd+Q** so the script can continue.