# Deploy scenario map

This map reflects the current code. Independent package choices are not expanded into every possible combination. Package definitions are in `config/features/`.

The extended Homebrew menu checks both installed formulae and casks on every
supported platform. This includes CLI packages such as codex, claude-code,
antigravity-cli, and openclaw installed as casks. Matching packages start checked
and are excluded from the installation selection. A failure to read either list
stops the questionnaire without using partial results.

## Errors before the questionnaire

- Bash versions below 5, a non-interactive terminal, an invalid catalog, or an unsupported system cause startup to fail.
- Multiple arguments or an unknown flag cause an error. `-h` and `--help` display help.
- macOS rejects `--wsl`, `--server`, and `--desktop`; Linux outside WSL rejects `--wsl` and `--mac`; WSL rejects `--server`, `--desktop`, and `--mac`.

## Linux presets

`--server`, `--desktop`, and `--wsl` automatically select the procedures listed
for that preset, subject to the enabled queue and platform availability.
These procedures are mandatory and cannot be disabled separately. During the
questionnaire, procedure yes/no questions are skipped; only package lists remain
interactive. Review and dependency confirmations still follow.
Restarting the questionnaire resets package choices and restores mandatory
procedure selections. Run without a preset flag to choose procedures individually.

## Fedora

The `native_desktop` menu is available without a flag, with `--desktop`, and
with `--add-optionals`. It offers Applications: `firefox alacritty`; System:
`gparted timeshift`; and Dependencies: `wl-clipboard wmctrl`. Only `--desktop`
adds `firefox alacritty` to the checked defaults. Installed packages detected
with `rpm -qa` are checked and excluded from installation. A failed probe stops
the questionnaire. The selected packages are installed by DNF through the
shared native executor; an empty selection skips the action.

```text
Start
├─ No flag → separate yes/no questions for native_packages, zsh_default, homebrew, dotfiles.
│  Package menus open in queue order. Declining Homebrew hides
│  dependent Homebrew menus but does not affect dotfiles or Flatpak.
├─ --server (outside WSL) → native_packages, zsh_default, homebrew, dotfiles; formulae.
├─ --desktop (outside WSL) → native_packages, zsh_default, homebrew, dotfiles;
│  select native desktop packages, fonts, formulae, and Flatpak apps.
├─ --wsl (WSL only) → native_packages, zsh_default, homebrew, dotfiles; formulae.
├─ -a / --add-optionals → native desktop, font, formula, and Flatpak app menus.
│  No new packages → exit. Otherwise, review → dependencies → if needed,
│  ask to install missing Homebrew: No → restart the questionnaire;
│  Yes → prepare Homebrew after confirmation. A Flatpak-only selection does not require Homebrew.
├─ Installed packages are checked in the menus but are not installed again.
│  Unchecking a package does not uninstall it. Selecting zsh_default also checks
│  starship, zsh-autosuggestions, zsh-syntax-highlighting, pfetch-rs, zoxide,
│  herdr, stow. Failure to detect installed packages or interrupted input → exit.
├─ Review → Start / Restart / Exit.
│  ├─ Restart → reset answers and restart the questionnaire; Exit → exit without changes.
│  └─ Start → ask about each required native dependency.
│     Yes → continue; No → Review with selections preserved / Restart / Exit.
├─ Running as root → error. Approved dependencies are installed first.
│  A sudo or action failure stops execution without rolling back previous steps.
│  Empty selection → message; success → message and elapsed execution time.
└─ Selected action order:
   ├─ native_packages → dnf: git git-lfs curl zsh file openssh-clients gawk openssl ca-certificates.
   │  DNF disables fedora-cisco-openh264 and refreshes the cache before installation.
   ├─ native_desktop → dnf: selected native desktop packages, excluding installed candidates.
   ├─ zsh_default → validate the user account, chsh, and executable /bin/zsh before changing the shell.
   │  A failed check or chsh command marks the procedure failed and stops the script.
   ├─ homebrew → if missing, download and run the installer; check
   │  the executable and its version. A fresh Homebrew installation on Linux also installs the ca-certificates formula.
   ├─ homebrew_fonts → install the selected fonts.
   ├─ homebrew_extended → sdkman-cli selected → tap and trust sdkman/tap;
   │  install the selected formulae without upgrading installed packages.
   ├─ flatpak_apps → install the CLI through dnf if missing; WSL uses
   │  a user remote; Linux outside WSL uses a system remote. An unexpected Flathub URL
   │  or a configured filter → error; enable a disabled remote or add a missing one.
   │  On Fedora outside WSL, remove the system fedora remote if present. Install the selected apps with terminal input.
   └─ dotfiles → check .stow-local-ignore and find stow in PATH or Homebrew;
      apply the repository root, zsh_common, wallpaper, and zsh_linux to HOME.
```

NATIVE_BUILD_TOOLS = development-tools; required by sdkman-cli.

Available packages by group, as defined in the source code:

```text
brew_cask / homebrew_fonts: font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
brew / shell_tools: starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
brew / util_tools: lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
brew / dev_tooling: fresh-editor neovim podman nvm rustup uv sdkman-cli go qt bun cmake ninja openspec mise hyperfine
brew / media_tools: yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
brew / cli_harness: codex claude-code opencode hermes-agent kimi-code antigravity-cli openclaw
flatpak / internet: org.telegram.desktop org.qbittorrent.qBittorrent com.mattermost.Desktop org.mozilla.firefox com.discordapp.Discord com.google.Chrome
flatpak / work_media: md.obsidian.Obsidian com.bitwarden.desktop org.videolan.VLC io.bassi.Amberol org.gnome.Snapshot com.github.johnfactotum.Foliate app.drey.EarTag org.inkscape.Inkscape org.gnome.Decibels org.gnome.Loupe org.libreoffice.LibreOffice com.obsproject.Studio com.spotify.Client
flatpak / development: ai.lmstudio.lm-studio com.jgraph.drawio.desktop me.iepure.devtoolbox
flatpak / system: com.belmoussaoui.Authenticator it.mijorus.gearlever com.mattjakeman.ExtensionManager com.github.tchx84.Flatseal
```

## Debian

The `native_desktop` menu is available without a flag, with `--desktop`, and
with `--add-optionals`. Its categories contain:

| Category | Packages |
| --- | --- |
| Applications | `firefox-esr alacritty` |
| Development | `build-essential qt6-base-dev qtcreator qt6-declarative-dev qml6-module-qtquick qml6-module-qtquick-controls` |
| System | `gparted timeshift` |
| Dependencies | `wl-clipboard wmctrl` |

Only `--desktop` additionally checks `firefox-esr alacritty`. Packages detected
as installed through `dpkg-query` are checked and excluded from installation;
failure to read the database stops the questionnaire. The selected packages are
installed by APT through the shared native executor; an empty selection skips
the action.

```text
Start
├─ No flag → separate yes/no questions for native_packages, zsh_default, homebrew, dotfiles.
│  Package menus open in queue order. Declining Homebrew hides
│  dependent Homebrew menus but does not affect dotfiles or Flatpak.
├─ --server (outside WSL) → native_packages, zsh_default, homebrew, dotfiles; formulae.
├─ --desktop (outside WSL) → native_packages, zsh_default, homebrew, dotfiles;
│  select native desktop packages, fonts, formulae, and Flatpak apps.
├─ --wsl (WSL only) → native_packages, zsh_default, homebrew, dotfiles; formulae.
├─ -a / --add-optionals → native desktop, font, formula, and Flatpak app menus.
│  No new packages → exit. Otherwise, review → dependencies → if needed,
│  ask to install missing Homebrew: No → restart the questionnaire;
│  Yes → prepare Homebrew after confirmation. A Flatpak-only selection does not require Homebrew.
├─ Installed packages are checked in the menus but are not installed again.
│  Unchecking a package does not uninstall it. Selecting zsh_default also checks
│  starship, zsh-autosuggestions, zsh-syntax-highlighting, pfetch-rs, zoxide,
│  herdr, stow. Failure to detect installed packages or interrupted input → exit.
├─ Review → Start / Restart / Exit.
│  ├─ Restart → reset answers and restart the questionnaire; Exit → exit without changes.
│  └─ Start → ask about each required native dependency.
│     Yes → continue; No → Review with selections preserved / Restart / Exit.
├─ Running as root → error. Approved dependencies are installed first.
│  A sudo or action failure stops execution without rolling back previous steps.
│  Empty selection → message; success → message and elapsed execution time.
└─ Selected action order:
   ├─ native_packages → apt: git git-lfs curl zsh file ssh nala gawk openssl ca-certificates.
   │  APT updates package lists before installation.
   ├─ native_desktop → apt: selected native desktop packages, excluding installed candidates.
   ├─ zsh_default → validate the user account, chsh, and executable /bin/zsh before changing the shell.
   │  A failed check or chsh command marks the procedure failed and stops the script.
   ├─ homebrew → if missing, download and run the installer; check
   │  the executable and its version. A fresh Homebrew installation on Linux also installs the ca-certificates formula.
   ├─ homebrew_fonts → install the selected fonts.
   ├─ homebrew_extended → sdkman-cli selected → tap and trust sdkman/tap;
   │  install the selected formulae without upgrading installed packages.
   ├─ flatpak_apps → install the CLI through apt if missing; WSL uses
   │  a user remote; Linux outside WSL uses a system remote. An unexpected Flathub URL
   │  or a configured filter → error; enable a disabled remote or add a missing one.
   │   Install the selected apps with terminal input.
   └─ dotfiles → check .stow-local-ignore and find stow in PATH or Homebrew;
      apply the repository root, zsh_common, wallpaper, and zsh_linux to HOME.
```

NATIVE_BUILD_TOOLS = build-essential; required by sdkman-cli.

Available packages by group, as defined in the source code:

```text
brew_cask / homebrew_fonts: font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
brew / shell_tools: starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
brew / util_tools: lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
brew / dev_tooling: fresh-editor neovim podman nvm rustup uv sdkman-cli go qt bun cmake ninja openspec mise hyperfine
brew / media_tools: yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
brew / cli_harness: codex claude-code opencode hermes-agent kimi-code antigravity-cli openclaw
flatpak / internet: org.telegram.desktop org.qbittorrent.qBittorrent com.mattermost.Desktop org.mozilla.firefox com.discordapp.Discord com.google.Chrome
flatpak / work_media: md.obsidian.Obsidian com.bitwarden.desktop org.videolan.VLC io.bassi.Amberol org.gnome.Snapshot com.github.johnfactotum.Foliate app.drey.EarTag org.inkscape.Inkscape org.gnome.Decibels org.gnome.Loupe org.libreoffice.LibreOffice com.obsproject.Studio com.spotify.Client
flatpak / development: ai.lmstudio.lm-studio com.jgraph.drawio.desktop me.iepure.devtoolbox
flatpak / system: com.belmoussaoui.Authenticator it.mijorus.gearlever com.mattjakeman.ExtensionManager com.github.tchx84.Flatseal
```

## Arch

The selectable `native_desktop` procedure follows `native_packages` and precedes
`yay`. It is available without a flag, with `--desktop`, and with
`-a` / `--add-optionals`; it is excluded from `--server` and `--wsl`.
In optional-only mode, a native-only selection requires neither Homebrew nor
the base native procedure. macOS has no native desktop set.

Installed candidates detected through `pacman -Qq` start checked in all three
modes and are excluded from installation. A probe failure stops the questionnaire
before displaying the menu. Only `--desktop` adds the defaults listed below.
Users may clear any checkbox; clearing an installed package does not uninstall
it. Restart resets choices and repeats detection and default selection.

| Category | Arch packages | Additional defaults with `--desktop` |
| --- | --- | --- |
| Applications | firefox alacritty ghostty veracrypt virtualbox gcolor3 | firefox alacritty |
| Development | zed qtcreator docker | zed |
| System | gparted timeshift virtualbox-host-dkms linux-headers dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g | dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g |
| Dependencies | xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor | none |

After review and confirmation, only selected packages not detected as installed
are passed to `pacman -Syu --needed --noconfirm`. An empty selection skips the
procedure. This also upgrades the system. There is no additional Docker service,
user-group, or VirtualBox configuration; the package manager resolves normal
dependencies. The three virtualization entries remain independent choices.

```text
Start
├─ No flag → separate yes/no questions for native_packages, yay, zsh_default, homebrew, dotfiles;
│  also select native desktop packages.
│  Package menus open in queue order. Declining Homebrew hides
│  dependent Homebrew menus but does not affect dotfiles or Flatpak.
├─ --server (outside WSL) → native_packages, zsh_default, homebrew, dotfiles; formulae.
├─ --desktop (outside WSL) → native_packages, yay, zsh_default, homebrew, dotfiles;
│  select native desktop packages, fonts, formulae, and Flatpak apps.
├─ --wsl (WSL only) → native_packages, yay, zsh_default, homebrew, dotfiles; formulae.
├─ -a / --add-optionals → native desktop, font, formula, and Flatpak app menus.
│  No new packages → exit. Otherwise, review → dependencies → if needed,
│  ask to install missing Homebrew: No → restart the questionnaire;
│  Yes → prepare Homebrew after confirmation. A Flatpak-only selection does not require Homebrew.
├─ Installed packages are checked in the menus but are not installed again.
│  Unchecking a package does not uninstall it. Selecting zsh_default also checks
│  starship, zsh-autosuggestions, zsh-syntax-highlighting, pfetch-rs, zoxide,
│  herdr, stow. Failure to detect installed packages or interrupted input → exit.
├─ Review → Start / Restart / Exit.
│  ├─ Restart → reset answers and restart the questionnaire; Exit → exit without changes.
│  └─ Start → ask about each required native dependency.
│     Yes → continue; No → Review with selections preserved / Restart / Exit.
├─ Running as root → error. Approved dependencies are installed first.
│  A sudo or action failure stops execution without rolling back previous steps.
│  Empty selection → message; success → message and elapsed execution time.
└─ Selected action order:
   ├─ native_packages → pacman: git git-lfs curl zsh file openssh cronie gawk openssl ca-certificates.
   ├─ native_desktop → pacman: selected native desktop packages, excluding installed candidates.
   ├─ yay → base-devel; if yay is missing, install go, update or clone the
   │  AUR checkout, build with makepkg, install the package with pacman, and verify yay.
   ├─ zsh_default → validate the user account, chsh, and executable /bin/zsh before changing the shell.
   │  A failed check or chsh command marks the procedure failed and stops the script.
   ├─ homebrew → if missing, download and run the installer; check
   │  the executable and its version. A fresh Homebrew installation on Linux also installs the ca-certificates formula.
   ├─ homebrew_fonts → install the selected fonts.
   ├─ homebrew_extended → sdkman-cli selected → tap and trust sdkman/tap;
   │  install the selected formulae without upgrading installed packages.
   ├─ flatpak_apps → install the CLI through pacman if missing; WSL uses
   │  a user remote; Linux outside WSL uses a system remote. An unexpected Flathub URL
   │  or a configured filter → error; enable a disabled remote or add a missing one.
   │   Install the selected apps with terminal input.
   └─ dotfiles → check .stow-local-ignore and find stow in PATH or Homebrew;
      apply the repository root, zsh_common, wallpaper, and zsh_linux to HOME.
```

NATIVE_BUILD_TOOLS = base-devel; required by sdkman-cli and yay.

When `yay` is selected and available in PATH, its native requirements are skipped:
there is no `base-devel` question or installation on behalf of `yay`.
If `yay` is missing, the script asks to install `base-devel` even if `base-devel`
is already installed. The shared build-tool requirement is requested only once
when both `yay` and `sdkman-cli` require it. An installed `yay` does not suppress
the requirement of a selected `sdkman-cli`.

Installing native packages and approved native dependencies, installing go for a missing yay, and installing a missing Flatpak CLI all use `pacman -Syu --needed --noconfirm`. These commands also perform a full system upgrade. `--needed` skips reinstalling target packages that are already up to date but does not prevent the system upgrade.

Available packages by group, as defined in the source code:

```text
brew_cask / homebrew_fonts: font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
brew / shell_tools: starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
brew / util_tools: lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
brew / dev_tooling: fresh-editor neovim podman nvm rustup uv sdkman-cli go qt bun cmake ninja openspec mise hyperfine
brew / media_tools: yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
brew / cli_harness: codex claude-code opencode hermes-agent kimi-code antigravity-cli openclaw
flatpak / internet: org.telegram.desktop org.qbittorrent.qBittorrent com.mattermost.Desktop org.mozilla.firefox com.discordapp.Discord com.google.Chrome
flatpak / work_media: md.obsidian.Obsidian com.bitwarden.desktop org.videolan.VLC io.bassi.Amberol org.gnome.Snapshot com.github.johnfactotum.Foliate app.drey.EarTag org.inkscape.Inkscape org.gnome.Decibels org.gnome.Loupe org.libreoffice.LibreOffice com.obsproject.Studio com.spotify.Client
flatpak / development: ai.lmstudio.lm-studio com.jgraph.drawio.desktop me.iepure.devtoolbox
flatpak / system: com.belmoussaoui.Authenticator it.mijorus.gearlever com.mattjakeman.ExtensionManager com.github.tchx84.Flatseal
```

## macOS

```text
Start
├─ No flag → separate yes/no questions for macos_command_line_tools, macos_finder, macos_spaces, homebrew, dotfiles.
│  Package menus open in queue order. Declining Homebrew hides
│  dependent Homebrew menus but does not affect dotfiles. Flatpak is unavailable on macOS.
├─ --mac → automatically select CLT, Finder, Spaces, Homebrew, and dotfiles; select fonts, formulae, and casks interactively.
├─ -a / --add-optionals → font, formula, and cask menus.
│  No new packages → exit. Otherwise, review → if needed,
│  ask to install missing Homebrew: No → restart the questionnaire;
│  Yes → prepare Homebrew after confirmation. Prepare CLT first if needed.
├─ Installed packages are checked in the menus but are not installed again.
│  Unchecking a package does not uninstall it. Only installed packages are preselected.
│  The zsh_default procedure is unavailable on macOS; additional Zsh formulae
│  are not checked automatically. Failure to detect installed packages or interrupted input → exit.
├─ Review → Start / Restart / Exit.
│  ├─ Restart → reset answers and restart the questionnaire; Exit → exit without changes.
│  └─ Start → continue without native-dependency prompts; the current catalog
│     declares no native requirements for macOS.
├─ Running as root → error.
│  A sudo or action failure stops execution without rolling back previous steps.
│  Empty selection → message; success → message and elapsed execution time.
└─ Selected action order:
   ├─ macos_command_line_tools → preserve a working Xcode/CLT selection; otherwise, open
   │  the Apple installer, wait for Enter, and check again; failure → stop.
   ├─ macos_finder → configure Finder and restart it if running.
   ├─ macos_spaces → disable automatic Spaces rearrangement and restart Dock if running.
   ├─ homebrew → if missing, download and run the installer; check
   │  the executable and its version. A new installation requires working CLT and administrator access.
   ├─ homebrew_fonts → install the selected fonts.
   ├─ homebrew_extended → sdkman-cli selected → tap and trust sdkman/tap;
   │  install the selected formulae without upgrading installed packages.
   ├─ homebrew_casks → verify brew and install the selected apps with direct terminal input.
   └─ dotfiles → check .stow-local-ignore and find stow in PATH or Homebrew;
      apply the repository root, zsh_common, wallpaper, and zsh_mac to HOME.
```

No native dependency is declared for sdkman-cli on macOS.

Available packages by group, as defined in the source code:

```text
brew_cask / homebrew_fonts: font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
brew / shell_tools: starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
brew / util_tools: lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
brew / dev_tooling: fresh-editor neovim podman nvm rustup uv sdkman-cli go qt bun cmake ninja openspec mise hyperfine
brew / media_tools: yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
brew / cli_harness: codex claude-code opencode hermes-agent kimi-code antigravity-cli openclaw
brew_cask / internet: firefox google-chrome librewolf zen ungoogled-chromium tor-browser telegram whatsapp discord slack zoom qbittorrent amneziavpn
brew_cask / work_media: obsidian libreoffice bitwarden veracrypt iina vlc spotify
brew_cask / create: figma inkscape drawio figma blender audacity obs
brew_cask / development: zed visual-studio-code vscodium android-studio intellij-idea qt-creator iterm2 ghostty cmux warp wezterm docker-desktop hermes-desktop lm-studio wireshark-app
brew_cask / system: raycast maccy rectangle alt-tab jordanbaird-ice betterdisplay mos linearmouse karabiner-elements hammerspoon stats coconutbattery appcleaner macfuse balenaetcher raspberry-pi-imager utm
brew_cask / games: steam playcover-community
```
