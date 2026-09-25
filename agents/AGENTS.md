# Dotfiles Repository Agent Instructions

## Setup Commands

- Full Linux setup: `bash dotfiles-deploy.sh`
- Automated (no prompts): `bash dotfiles-deploy.sh --yolo`
- Apply configs only, from the repository root:
  `stow --no-folding --override='.*' --dir="$(dirname "$PWD")" --target="$HOME" "$(basename "$PWD")"`
- Apply common Zsh config: `stow --no-folding --override='.*' --target="$HOME" zsh_common`
- Apply platform Zsh config: `stow --no-folding --override='.*' --target="$HOME" zsh_linux` or
  `stow --no-folding --override='.*' --target="$HOME" zsh_mac`

## Key Architecture Facts

- The setup implementation lives under `script/` and is organized into
  configuration, UI, business logic, actions, and execution adapters.
- Package and procedure declarations are separate from the code that applies
  them.
- GNU Stow creates symlinks for dotfiles and platform-specific Zsh settings.
- The setup script supports Arch, Debian/Ubuntu, and Fedora Linux.
- Homebrew provides most CLI tools and extensions on Linux.
- Detailed script interfaces and entities are documented in `script/AGENTS.md`.

## Important Commands

- Check SSH key: `ssh -T git@github.com`
- Git LFS setup: `git lfs install && git lfs fetch && git lfs checkout`
- Submodule setup: `git submodule init && git submodule update`

## Repo Conventions

- Dotfiles organized by system type (Linux/macOS)
- Setup code and tests live in `script/`
- Configuration guides in `guide/` directory
- Platform-specific ZSH configs in `zsh_linux/` and `zsh_mac/`

## File Naming

- A directory's landing document is `README.md`, always capitalized, and there is
  at most one per directory. Agent instruction files are `AGENTS.md`; other
  documents are lowercase, one word where possible, no spaces.
- Vendored upstream content keeps its own filenames and is never renamed.
  That currently covers the READMEs under `.config/yazi/`.
- Change a filename's case only with `git mv`. The repository is on a
  case-insensitive filesystem (`core.ignorecase=true`), where a plain `mv` or a
  Finder rename leaves `git status` and `git diff` empty and the old casing
  recorded in the index. Case-insensitive consumers will not resolve the name.
