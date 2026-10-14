# Everyday CLI tools.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    fd
    ripgrep
    eza
    jq
    socat
    tldr
    less
    lsof
    entr
    curl
    wget
    aria2
    zip
    unzip
    unrar
    btop
    yazi
    graphviz
    dnsutils
    netcat-gnu
    crudini
  ];
}
