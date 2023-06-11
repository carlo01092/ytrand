# ytrand

Stuck at your youtube's hunderds to thousands videos of **"Watch later"** playlist?

Don't know which video to start watching

Start decluttering your playlist by *randomizing* what to watch **one** video at a time

Opens video at chrome's incognito tab by default

## Prerequisites
* [yt-dlp](https://github.com/yt-dlp) - For downloading playlists
* [jq](https://github.com/jqlang/jq) - Formatting json database

## Setup
* fill your playlist ids in **playlist.txt**

## Usage

* #### Updates all playlist to the database (db.json)
```powershell
  ytrand -Update
```

* #### Update only watch later and liked videos playlist (naming refers from playlist.txt)
```powershell
  ytrand -Update "watch_later","liked"
```

* #### randomly select a video from all playlist
```powershell
  ytrand
```
  
  * #### randomly select a 5 minute (or less) video from all playlist
```powershell
  ytrand 5
```

* #### randomly select a video from watch later and liked videos playlist (naming refers from actual youtube's playlist name)
```powershell
  ytrand "Watch later","Liked videos"
  
  # or a 5 minute (or less) video
  ytrand "Watch later","Liked videos" 5
  
  #alternative syntax (with command parameter name)
  ytrand -playlist "Watch later","Liked videos" -minutes 5
```

* #### Show all playlist & their number of videos
```powershell
  ytrand -Update
```
