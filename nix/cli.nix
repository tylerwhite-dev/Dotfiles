{ pkgs, ... }:
{
  home.packages = with pkgs; [
    starship
    zsh-autosuggestions
    zsh-syntax-highlighting
    pfetch-rs
    fastfetch
    yazi
    superfile
    eza
    btop
    nvtopPackages.v3d
    tmux
    neovim
    lazygit
    ffmpeg
    zoxide
    imagemagick
    tree
    yt-dlp
    mailsy
  ];
}
