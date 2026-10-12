# What the firstmate fleet needs on the box, beyond the home-manager dev environment
# (git, gh, node, herdr, tmux and jq come from nix/home).
# Self-updating tools are installed per user, not here: Claude Code (native installer),
# the npm *-axi tools, treehouse and no-mistakes. See infra/aws-dev/README.md.
{ pkgs, ... }:
{
  # ~/.local/bin holds the native Claude Code binary and the npm-global (prefix ~/.local) tools.
  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    tmux
    git
    jq
    python3
    perl
    curl
    openssl
    lsof
    chromium # headless browser for chrome-devtools-axi
  ];

  # Fleet sessions run under the user manager; keep it alive with nobody logged in.
  users.users.schiffer.linger = true;
}
