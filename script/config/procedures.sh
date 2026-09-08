#!/usr/bin/env bash

# A procedure block owns its text, handler, platforms, dependencies, and inputs.

procedure_define native_packages
procedure_handler native_packages action_install_native_packages
procedure_platforms native_packages arch debian fedora
procedure_requires_root native_packages
procedure_packages native_packages native @distribution
message_define procedure.native_packages.question "Install base system packages?"
message_define procedure.native_packages.label "Install base system packages"
message_define procedure.native_packages.description \
  "The following packages will be installed from the native repository:"

procedure_define zsh_default
procedure_handler zsh_default action_set_zsh_default
procedure_platforms zsh_default arch debian fedora
procedure_requires_root zsh_default
message_define procedure.zsh_default.question "Set zsh as the default shell?"
message_define procedure.zsh_default.label "Set zsh as the default shell"
message_define procedure.zsh_default.description \
  "The current user's login shell will be changed to /bin/zsh."

procedure_define homebrew
procedure_handler homebrew action_install_homebrew
procedure_platforms homebrew arch debian fedora
procedure_requires_root homebrew
procedure_packages homebrew \
  brew extensions \
  brew cli_tools \
  brew_cask fonts
message_define procedure.homebrew.question \
  "Install Homebrew, core CLI tools, and fonts?"
message_define procedure.homebrew.label \
  "Install Homebrew, core CLI tools, and fonts"
message_define procedure.homebrew.description \
  "Homebrew will be installed, followed by these packages:"

procedure_define homebrew_extended
procedure_handler homebrew_extended action_install_homebrew_extended
procedure_platforms homebrew_extended arch debian fedora
procedure_requires homebrew_extended homebrew
procedure_packages homebrew_extended \
  brew_tap optional \
  brew optional
message_define procedure.homebrew_extended.question \
  "Install the extended Homebrew package set?"
message_define procedure.homebrew_extended.label \
  "Install the extended Homebrew package set"
message_define procedure.homebrew_extended.description \
  "An additional tap will be added, followed by these packages:"

procedure_define dotfiles
procedure_handler dotfiles action_apply_dotfiles
procedure_platforms dotfiles arch debian fedora
message_define procedure.dotfiles.question \
  "Apply dotfiles, Zsh configuration, and wallpapers with GNU Stow?"
message_define procedure.dotfiles.label \
  "Apply dotfiles, Zsh config and wallpapers"
message_define procedure.dotfiles.description \
  "Stow will apply .configs, zsh_common, wallpaper, and zsh_linux from the Dotfiles directory."

procedure_define yay
procedure_handler yay action_install_yay
procedure_platforms yay arch
procedure_requires_root yay
procedure_packages yay native yay_prerequisites
message_define procedure.yay.question "Install yay?"
message_define procedure.yay.label "Install yay"
message_define procedure.yay.description \
  "The build dependencies will be installed first. Then yay will be built from the AUR and installed:"
