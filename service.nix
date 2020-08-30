{ config, pkgs, lib, ... }:

with pkgs;
with lib;

let
  nix-serve-nothing = callPackage ./default.nix;
  cfg = config.services.nix-serve-nothing;
  mkProxy = {enabled, target, command, when, ...}:
    let
      when = if when == null then "" else "when=${when}";
    in
    if ! enabled then "" else
      "--proxy-opts target=${target} command=${command} ${when}";
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

      proxy = mkOption {
        description = ''
          Options to make the server proxy requests to another binary cache
          when a check condition is specified.
        '';
        default = {};
        type = types.submodule {
          options = {
            enabled = mkEnableOption "Enable the proxy.";

            target = mkOption {
              type = types.types.str;
              description = "The address of the proxied binary cache";
              default = "";
            };

            command = mkOption {
              type = types.str;
              description = "The address of the proxied binary cache";
              default = "";
            };

            when = mkOption {
              type = types.nullOr types.str;
              description = ''
                An optional value against which to compare the stdout of proxy.command
              '';
            };
          };
        };
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
        ExecStart = ''
          ${nix-serve-nothing}/bin/nix-serve-nothing \
            --listen ${cfg.bindAddress}:${toString cfg.port} \
            ${mkProxy cfg.proxy} \
            ${cfg.extraParams}
        '';
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
