# EC2 specifics. The official NixOS AMI's own configuration imports this module;
# ours replaces it, so it must be imported here or the next rebuild stops booting
# (EBS root resize, instance metadata, amazon-ssm-agent).
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
}
