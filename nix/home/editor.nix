# Neovim with the repo's lazy.nvim config, plus the LSP servers and formatters it uses,
# so they come from Nix instead of Mason (Mason binaries need an FHS loader on NixOS).
{ config, pkgs, ... }:
{
  xdg.configFile."nvim".source = config.lib.dotfiles.link ".config/nvim";

  home.packages = with pkgs; [
    neovim
    tree-sitter # nvim-treesitter builds parsers with it and the OS C compiler
    nodejs # copilot.vim, cfn-lsp

    # LSP servers, enabled in lsp.lua when found on PATH.
    # gh-actions-language-server and sqlls are not in nixpkgs and stay on Mason.
    lua-language-server
    gopls
    basedpyright
    bash-language-server
    vscode-langservers-extracted
    typescript-language-server
    yaml-language-server
    terraform-ls
    tflint
    texlab
    dockerfile-language-server
    docker-compose-language-service
    tailwindcss-language-server
    emmet-language-server
    nil

    # Linters and formatters used by none-ls
    actionlint
    shellcheck
    prettier
    stylua
    black
    eslint_d
    python3Packages.cfn-lint
    nixfmt
  ];
}
