# Linux installation checklist

Use a disposable Debian WSL2 instance and a regular user with sudo access.
Follow the WSL fast setup section in `guide/linux/debian.md`. Clone the
repository into the Linux home directory and fetch Git LFS objects. Record the
distribution version and tested commit SHA. Keep passwords out of logs.

## Environment and automated checks

- [ ] Debian is detected correctly; Bash is version 5 or newer.
- [ ] DNS, HTTPS, Git, Git LFS and sudo work as the regular user.
- [ ] All 11 automated tests listed in this directory's README pass.
- [ ] `bash -n` passes for the entry point and every shell file under `script`.
- [ ] `git diff --check` passes.

## Interactive workflow in a real terminal

- [ ] Arrow keys, Space and Enter work in single and grouped selection menus.
- [ ] Group selection, partial selection and empty selection behave correctly.
- [ ] Narrow terminals and resizing preserve usable controls and readable output.
- [ ] Ctrl+C restores the cursor and terminal settings.
- [ ] Review shows the selected procedures and packages in configured order.
- [ ] Restart returns to the questionnaire; exit runs no installation commands.
- [ ] Installation starts only after confirmation. Run without `--yolo`.
- [ ] Manual process and UI contract fixtures pass in a real TTY.

## Real installation and repeat execution

Select every Debian base procedure, only `tio` from the extended Homebrew
selection, and only `org.gnome.Decibels` from Flatpak applications.

- [ ] Privilege prompts and command output remain usable during execution.
- [ ] Native packages, Homebrew base formulae and fonts install successfully.
- [ ] `tio --version` succeeds; Flathub and Decibels are installed.
- [ ] The user's default shell is zsh.
- [ ] Existing files and Stow conflicts are inspected before applying dotfiles.
- [ ] Stow links point into this checkout; wallpaper files contain actual LFS data.
- [ ] Repeating the same selection succeeds without broken links or remotes.
- [ ] `--add-optionals` accepts an empty selection without installing packages.

## Procedure queue in an isolated configuration copy

- [ ] Reordering queue entries changes questionnaire and execution order.
- [ ] Removing an entry excludes it from normal, YOLO and optional execution.
- [ ] Removing a prerequisite also excludes its dependent procedures.
- [ ] An empty queue is valid and executes no procedures.
- [ ] Unknown IDs, duplicate IDs and dependencies ordered after their consumers
  produce configuration errors before installation.

Record failures with the command, exit status and relevant output. Distinguish
installer failures from network or WSL limitations. Automated checks alone do
not establish that real package installation passed.
