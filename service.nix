{
  config
, pkgs
, lib
, nix-serve-nothing ? import ./. {}
, ...
}:

with lib;

let
  cfg = config.services.nix-serve-nothing;
in
{
  options = {
    services.nix-serve-nothing = {
      enable = mkEnableOption "nix-serve-nothing, the standalone Nix nothing server. This server will always return 404s.";

      port = mkOption {
        type = types.int;
        default = 5000;
        description = ''
          Port number where nix-serve-nothing will listen on.
        '';
      };

      bindAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          IP address where nix-serve-nothing will bind its listening socket.
        '';
      };

      extraParams = mkOption {
        type = types.separatedString " ";
        default = "";
        description = ''
          Extra command line parameters for nix-serve-nothing.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.nix-serve-nothing = {
      description = "nix-serve-nothing binary cache server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [ config.nix.package.out pkgs.bzip2.bin ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
        ExecStart = "${nix-serve-nothing}/bin/nix-serve-nothing " +
          "--listen ${cfg.bindAddress}:${toString cfg.port} ${cfg.extraParams}";
        User = "nix-serve-nothing";
        Group = "nogroup";
      };
    };

    users.users.nix-serve-nothing = {
      description = "Nix-serve-nothing user";
      uid = config.ids.uids.nix-serve-nothing;
    };
  };
}
