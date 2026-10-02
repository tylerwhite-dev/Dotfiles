# flatpak

The repository setup offers these applications in a grouped checkbox list on
Arch, Debian and Fedora. Run `bash dotfiles-deploy.sh`, or use
`bash dotfiles-deploy.sh --add-optionals` to choose optional packages only.
Execution starts after reviewing the selection. If Flatpak applications are
selected, setup installs Flatpak if missing and prepares system Flathub.
On Fedora it force-removes the system `fedora` remote while retaining installed
applications and runtimes; those refs no longer receive updates from that
remote. Existing Flathub configurations with a different URL or a filter need
manual review. Applications install with `flatpak install -y <ID>` commands,
accepting confirmations automatically. Authentication may still be requested
in the terminal.

add repository

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

```bash
flatpak install -y \
org.telegram.desktop \
md.obsidian.Obsidian \
com.bitwarden.desktop \
org.qbittorrent.qBittorrent \
org.videolan.VLC \
io.bassi.Amberol \
org.gnome.Snapshot \
com.belmoussaoui.Authenticator \
com.github.johnfactotum.Foliate \
app.drey.EarTag \
it.mijorus.gearlever \
ai.lmstudio.lm-studio \
com.mattjakeman.ExtensionManager \
com.github.tchx84.Flatseal \
\
com.jgraph.drawio.desktop \
org.inkscape.Inkscape \
com.mattermost.Desktop \
me.iepure.devtoolbox \
\
org.gnome.Decibels \
org.gnome.Loupe \
```
