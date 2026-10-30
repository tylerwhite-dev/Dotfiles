Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord

Invoke-Expression (&starship init powershell)

Clear-Host

pfetch
