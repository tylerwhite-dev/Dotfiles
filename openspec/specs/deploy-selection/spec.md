# Deploy procedure and package selection

## Purpose

Define which procedures the setup questionnaire offers, how named presets select procedures, and which package choices reach installation.

## Requirements

### Requirement: Standard procedure selection

The standard questionnaire SHALL offer enabled procedures supported by the detected platform in configured queue order. It SHALL ask yes or no for ordinary procedures and use package checklists for selectable procedures. A procedure with a disabled prerequisite SHALL be unavailable. A procedure whose prerequisite was declined SHALL be skipped.

#### Scenario: Decline Homebrew during standard setup

- **GIVEN** a Linux host with the default procedure queue
- **WHEN** the user declines Homebrew
- **THEN** the questionnaire skips Homebrew fonts and extended packages while independently offering Flatpak applications and dotfiles

### Requirement: Named preset selection

Named presets SHALL filter the enabled, platform-supported queue to the procedures for the requested mode. The script SHALL automatically select ordinary procedures in the preset and present package checklists for its selectable procedures.

#### Scenario: Use the default named presets

- **GIVEN** the default procedure queue and a host compatible with the requested preset
- **WHEN** the user opens the questionnaire for that preset
- **THEN** it automatically selects the ordinary procedures and opens the package checklists listed for that preset below

| Preset | Automatically selected | Package checklists in default queue order |
| --- | --- | --- |
| `--server` | Native packages, default Zsh shell, Homebrew, dotfiles | Extended Homebrew packages |
| `--desktop` | Native packages, yay on Arch, default Zsh shell, Homebrew, dotfiles | Native desktop packages, Homebrew fonts, extended Homebrew packages, Flatpak apps |
| `--wsl` | Native packages, yay on Arch, default Zsh shell, Homebrew, dotfiles | Extended Homebrew packages |
| `--mac` | Command Line Tools, Finder, Spaces, Homebrew, dotfiles | Homebrew fonts, extended Homebrew packages, Homebrew casks |

#### Scenario: Run the WSL preset on Arch

- **GIVEN** Arch on WSL with the default procedure queue
- **WHEN** the user opens the `--wsl` questionnaire
- **THEN** it automatically selects yay and the other ordinary WSL procedures and opens only the extended Homebrew checklist

### Requirement: Optional-package procedure selection

Optional-package mode SHALL offer only selectable procedures supported by the platform. It SHALL allow the user to select Homebrew packages without selecting a separate Homebrew procedure.

#### Scenario: Compare optional menus on Linux and macOS

- **GIVEN** the default procedure queue
- **WHEN** the user runs `--add-optionals`
- **THEN** Linux offers native desktop packages, Homebrew fonts, extended Homebrew packages and Flatpak apps
- **AND** macOS offers Homebrew fonts, extended Homebrew packages and Homebrew casks

### Requirement: Initial package checks

The script SHALL initially check installed candidates and any applicable defaults. The native desktop checklist SHALL add preset defaults only under `--desktop`. The extended Homebrew checklist SHALL detect both installed formulae and casks and add the Zsh package defaults when the default Zsh shell procedure is selected.

#### Scenario: Show desktop defaults on a fresh host

- **GIVEN** the native desktop packages are absent and the user runs `--desktop`
- **WHEN** the native desktop checklist opens
- **THEN** Arch initially checks `firefox`, `alacritty`, `zed`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `xfsprogs`, `exfatprogs` and `ntfs-3g`
- **AND** Debian initially checks `firefox-esr` and `alacritty`, and Fedora initially checks `firefox` and `alacritty`

#### Scenario: Show Zsh defaults in the extended Homebrew checklist

- **GIVEN** the default Zsh shell procedure is selected and no extended Homebrew candidates are installed
- **WHEN** the extended Homebrew checklist opens
- **THEN** it initially checks `starship`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `pfetch-rs`, `zoxide`, `herdr` and `stow`

#### Scenario: Fail to read installed Homebrew casks

- **GIVEN** Homebrew is installed and the formula listing succeeds
- **WHEN** the cask listing fails during collection of extended Homebrew choices
- **THEN** the script reports the failed package probe and stops collection before opening that checklist

### Requirement: Installation candidates

The script SHALL pass only checked packages that were not detected as installed to a selectable procedure. It SHALL skip that procedure when the resulting list is empty. Unchecking an installed package SHALL leave it installed.

#### Scenario: Keep an installed package checked

- **GIVEN** the extended Homebrew menu shows an installed cask and an uninstalled formula
- **WHEN** the user confirms both checked
- **THEN** the review counts one package to install and the installer receives only the formula
