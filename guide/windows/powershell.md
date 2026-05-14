open settings:
```bash
notepad $PROFILE
```

paste settings
```bash
Clear-Host

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord

# Invoke-Expression (&starship init powershell)

# pfetch
```

uncomment what you need