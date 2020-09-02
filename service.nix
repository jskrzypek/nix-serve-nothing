{ config, pkgs, lib, ... }:

with pkgs;
with lib;

let
  nix-serve-nothing = callPackage ./default.nix { inherit pkgs; };
  cfg = config.services.nix-serve-nothing;
  mkProxyArgs = nameMapper: proxy:
    mapAttrs'
      (n: v: nameValuePair
        (nameMapper n)
        (if (isString v) then (''"${v}"'') else (toString v)))
      (filterAttrs
        (n: v:
          ((isString v) && v != "") || (isInt v) || (isType types.float v))
        proxy);
  mkProxyFlags = proxy:
    let
      proxyArgs = mapAttrsToList (n: v: "${n}=${v}") (mkProxyArgs toLower proxy);
    in
    if proxy.enable -> proxyArgs != []
      then concatStringsSep " " (["--proxy-opts"] ++ proxyArgs)
      else "";
  mkProxyEnv = mkProxyArgs (n: "PROXY_${toUpper n}");
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
            enable = mkEnableOption "Enable the proxy.";

            target = mkOption {
              type = types.str;
              description = "The address of the proxied binary cache";
              default = "";
            };

            command = mkOption {
              type = types.separatedString " ";
              description = "The address of the proxied binary cache";
              default = "";
            };

            when = mkOption {
              type = types.nullOr types.str;
              description = ''
                An optional value against which to compare the stdout of proxy.command
              '';
            };

            cachettl = mkOption {
              type = types.nullOr types.int;
              description = "The number of seconds to wait before checking the command again.";
              default = 300;
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

      environment = mkProxyEnv cfg.proxy;
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
        ExecStart = concatStringsSep " "
          [ "${nix-serve-nothing}/bin/nix-serve-nothing"
            "--listen ${cfg.bindAddress}:${toString cfg.port}"
            "${mkProxyFlags cfg.proxy}"
            "${cfg.extraParams}" ];
        DynamicUser = true;
      };
    };
  };
}
