Paste URL / path to playlist file at the end of command in quotes

You need ffmpeg in order to convert video formats

Configure resolution by changing `height` parameter: 1080 / 1440 / 2160

## Video or YT playlist
```bash
yt-dlp -f "bestvideo[height<=1080]+bestaudio" --merge-output-format mp4 -o "%(title)s.%(ext)s" ""
```

## Additional flags

### Links from file
```bash
-a ""
```

### Subs

```bash
--write-auto-subs
```

### Cookies
```bash
--cookies-from-browser chrome
```