## 1. Install PowerShell and Starship

Run in a terminal:

```powershell
winget install --id Microsoft.PowerShell
winget install --id Starship.Starship
```

Close the terminal and open PowerShell 7. In Windows Terminal settings, select **PowerShell** as the default profile. The built-in **Windows PowerShell 5.1** uses a different profile file. Run the commands below in PowerShell 7.

Verify the installation:

```powershell
$PSVersionTable.PSVersion
Get-Command starship
```

## 2. Install pfetch

Use [Gobidev/pfetch-rs](https://github.com/Gobidev/pfetch-rs).

1. Download `pfetch-windows-x86_64.exe`.
2. Create the `%LOCALAPPDATA%\pfetch` folder.
3. Rename the downloaded file to `pfetch.exe` and place it in this folder.
4. In Windows, open **Edit environment variables for your account**, edit the user `Path` variable, and add `%LOCALAPPDATA%\pfetch` as a separate entry. Keep the existing entries.
5. Close all Windows Terminal windows and reopen it to load the updated `Path`.

## 3. Copy the PowerShell profile

Copy [profile](C:\Users\User\Developer\personal\Dotfiles\guide\windows\powershell\Microsoft.PowerShell_profile.ps1) from this folder to your PowerShell 7 profile location. The default path is:

```text
C:\Users\<username>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

Or run `$PROFILE` in PowerShell 7 to see the actual file on device and paste content of [profile](C:\Users\User\Developer\personal\Dotfiles\guide\windows\powershell\Microsoft.PowerShell_profile.ps1)
