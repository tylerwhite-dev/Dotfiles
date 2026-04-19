{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    rustup
    qwen-code
  ];
}
