# Deploy execution and failure handling

## Purpose

Define the order and effects of confirmed deployment work, including privilege checks, completion messages and failure handling.

## Requirements

### Requirement: Root and privilege checks

Setup SHALL reject execution as root. Optional-package mode SHALL reject root before collecting answers. Standard and preset modes SHALL reject root before installation. For a selected procedure that needs elevated privileges, setup SHALL prepare sudo before running the procedure.

#### Scenario: Start a preset as root

- **GIVEN** a compatible preset is run under root and the user completes its confirmations
- **WHEN** setup reaches installation
- **THEN** it reports the root execution error before installing dependencies or running selected procedures

#### Scenario: Sudo authorization fails

- **GIVEN** a confirmed procedure requires elevated privileges and sudo authorization fails
- **WHEN** setup reaches that procedure
- **THEN** it marks the procedure as failed without running its action

### Requirement: Dependency and procedure order

Setup SHALL install approved native dependencies before running selected procedures in configured queue order. The native build-tools targets SHALL be `base-devel` on Arch, `build-essential` on Debian and the `development-tools` group on Fedora. A selected yay already available in PATH SHALL contribute no native dependency of its own.

#### Scenario: Install selected procedures in queue order

- **GIVEN** the user confirms native packages, extended Homebrew packages and dotfiles in the default queue with Homebrew selected
- **WHEN** execution starts
- **THEN** setup installs approved dependencies first, then runs native packages, Homebrew, extended Homebrew packages and dotfiles in that order

#### Scenario: Keep an installed yay

- **GIVEN** yay is already in PATH and no other selection requires native build tools
- **WHEN** the user confirms an Arch preset that selects yay
- **THEN** setup neither requests the build-tools dependency on behalf of yay nor rebuilds yay

### Requirement: Installation of missing yay

On Arch, when yay is selected and missing from PATH, setup SHALL install `go` through pacman with a full system upgrade, obtain the yay source from the AUR, build the package, install the built artifacts with pacman and verify that yay is available in PATH.

#### Scenario: Install yay on Arch in WSL

- **GIVEN** yay is missing, the user starts the Arch `--wsl` preset and approves `base-devel`
- **WHEN** setup reaches the yay procedure after installing approved native dependencies
- **THEN** it installs `go` with `pacman -Syu --needed --noconfirm` and clones the AUR checkout or updates an existing checkout with a fast-forward pull
- **AND** it builds the package, installs the resulting files with `pacman -U` and checks that yay is in PATH

#### Scenario: A built package file is missing

- **GIVEN** the yay build command succeeded but an expected package file is missing
- **WHEN** setup prepares to install the built package
- **THEN** it reports the missing package file and stops without running the package installation or later procedures

### Requirement: Native package-manager effects

Setup SHALL use pacman on Arch, APT on Debian-family systems and DNF on Fedora. The Arch native install operation SHALL include a package database refresh and full system upgrade. The Debian native install operation SHALL refresh package metadata before installing. The Fedora native install operation SHALL disable `fedora-cisco-openh264` and refresh the cache before the package or group install.

#### Scenario: Install an approved native dependency on Arch

- **GIVEN** setup has approval to install a native dependency on Arch
- **WHEN** it runs the native install
- **THEN** the pacman invocation includes `-Syu --needed --noconfirm`, so the operation also upgrades the system

### Requirement: Homebrew preparation

Setup SHALL use the configured Homebrew executable when available. For a new Linux installation it SHALL install the Homebrew `ca-certificates` formula. For a new macOS installation it SHALL require working developer tools and administrator access. When optional-package mode has approval to install missing Homebrew on macOS, setup SHALL run the Command Line Tools preparation first if that procedure is enabled.

#### Scenario: Prepare Homebrew for optional casks on macOS

- **GIVEN** Homebrew is missing, the Command Line Tools procedure is enabled, and the user approved a selected optional cask and Homebrew installation
- **WHEN** setup starts execution
- **THEN** setup checks and prepares Command Line Tools before installing Homebrew, then runs the selected cask installer

### Requirement: Extended Homebrew package installation

The extended package installer SHALL suppress upgrades of installed packages. It SHALL tap and trust `sdkman/tap` before installing a selection that contains `sdkman-cli`.

#### Scenario: Install sdkman-cli through Homebrew

- **GIVEN** the user confirms a selection containing `sdkman-cli` and any applicable native dependency
- **WHEN** the extended Homebrew package procedure runs
- **THEN** it taps and trusts `sdkman/tap` before installing the selected packages with upgrades suppressed

### Requirement: Flatpak installation scope

For selected Flatpak apps, setup SHALL install the Flatpak CLI through the native package manager if missing. It SHALL manage Flathub and install apps in user scope on WSL and in system scope on other supported Linux hosts. It SHALL add a missing Flathub remote or enable a valid disabled one. It SHALL stop when the existing Flathub remote has an unexpected URL or a configured filter. In Fedora system scope it SHALL remove the `fedora` remote when present after preparing Flathub.

#### Scenario: Install Flatpak apps on WSL

- **GIVEN** the user confirms Flatpak apps in standard or optional-package mode on WSL
- **WHEN** setup prepares Flathub and installs those apps
- **THEN** both operations use the user Flatpak installation

#### Scenario: Reject a filtered Flathub remote

- **GIVEN** the selected Flatpak scope has an existing Flathub remote with a filter
- **WHEN** setup prepares Flatpak
- **THEN** it reports a remote configuration error and skips app installation

### Requirement: Dotfiles deployment

The dotfiles procedure SHALL require `.stow-local-ignore` and an available GNU Stow executable. It SHALL apply the repository root first, then `zsh_common`, `wallpaper` and the platform-specific Zsh package to the current user's home directory.

#### Scenario: Apply dotfiles on macOS

- **GIVEN** a valid repository and an available GNU Stow executable
- **WHEN** setup runs the confirmed dotfiles procedure on macOS
- **THEN** it applies the root package, `zsh_common`, `wallpaper` and `zsh_mac` to the user's home directory in that order

### Requirement: Linux login shell configuration

The default Zsh shell procedure SHALL change the resolved user's login shell to `/bin/zsh` only after validating the account, checking for `chsh` and verifying that `/bin/zsh` is executable.

#### Scenario: Handle missing Zsh

- **GIVEN** the user selects the default Zsh shell procedure and `/bin/zsh` is missing
- **WHEN** setup runs that procedure
- **THEN** it reports the missing executable and stops before changing the login shell

### Requirement: macOS preferences

The Finder procedure SHALL show filename extensions and the path bar, put folders first, search the current folder and open new windows in Home. The Spaces procedure SHALL disable rearrangement by most recent use.

#### Scenario: Apply the macOS preference procedures

- **GIVEN** Finder and Dock are running and the user confirms both preference procedures
- **WHEN** the procedures complete successfully
- **THEN** the requested Finder settings are applied and Finder restarts
- **AND** automatic rearrangement of Spaces is disabled and Dock restarts

### Requirement: Procedure completion and failures

Setup SHALL run a procedure's terminal-facing final step only after its main action succeeds. If privilege preparation, a dependency installation, the main action or its final step fails, setup SHALL stop without running later procedures or rolling back completed work.

#### Scenario: A Flatpak installation fails after preparation

- **GIVEN** Flatpak preparation succeeds and dotfiles are queued after Flatpak
- **WHEN** the terminal-facing Flatpak install fails
- **THEN** setup marks the Flatpak procedure failed and terminates without applying dotfiles or undoing earlier changes

### Requirement: Successful execution output

Successful execution SHALL display elapsed time measured from the end of confirmations. It SHALL report completion after successfully running a nonempty queue. When execution starts with an empty queue, it SHALL report that no procedures were selected.

#### Scenario: Complete a nonempty queue

- **GIVEN** at least one procedure is selected
- **WHEN** the approved native dependencies and every selected procedure succeed
- **THEN** setup prints "Setup completed successfully." and elapsed execution time, excluding time spent answering questions

#### Scenario: Start execution with no selected procedures

- **GIVEN** a non-root user reaches standard-mode review with no selected procedures
- **WHEN** the user selects Start execution
- **THEN** setup prints "No procedures were selected. Nothing to do." and elapsed execution time, then exits with status 0
