# Idle auto-stop: power off (EC2 then stops the instance) once the firstmate fleet,
# SSH sessions and CPU have all been idle for idleMinutes. Logic in idle-stop.sh;
# see each run's verdict with `journalctl -u idle-stop`.
# Keep the box up regardless: touch ~/.config/idle-stop/inhibit
{ pkgs, ... }:
let
  idleStop = pkgs.writeShellApplication {
    name = "idle-stop";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
      procps
      systemd
    ];
    text = builtins.readFile ./idle-stop.sh;
  };
in
{
  systemd.services.idle-stop = {
    description = "Power off the dev box when the fleet and the captain are idle";
    environment = {
      IDLE_MINUTES = "30";
      CPU_PERCENT = "20"; # of one vCPU, averaged over one timer interval
      FLEET_HOME = "/home/schiffer/firstmate";
      INHIBIT_FILE = "/home/schiffer/.config/idle-stop/inhibit";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${idleStop}/bin/idle-stop";
    };
  };

  systemd.timers.idle-stop = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "5min";
    };
  };
}
