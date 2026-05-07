Paste URL / path to playlist file at the end of command in quotes

You need ffmpeg in order to convert audio formats

## Video or YT playlist
```bash
yt-dlp -x --audio-format mp3 --embed-thumbnail --embed-metadata -o "%(title)s.%(ext)s" ""
```

## Additional flags
```bash
-a ""
```