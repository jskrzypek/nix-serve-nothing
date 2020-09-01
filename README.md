# nix-serve-nothing

This is a hacky little fork of Eelco Dolstra's [nix-serve](https://github.com/edolstra/nix-serve) that lets us serve
responses that nix can understand and avoid a roundtrip call to a binary cache.

If you have a binary cache sitting behind a VPN/Firewall running nix-build
requires you to be on the VPN, or else nix hangs for a while until the request
times out and then fails. By providing a server that always claims to not have
the requested binaries we can force nix to move on to asking the next cache, or
even just building the binaries itself.

The server also supports passing a command that it can use to check if requests
should be proxied to a gonfigurable target server. If the check exits with 0 or
returns a specified value to STDOUT then the server will proxy to the binary
cache server specified at startup. Otherwise it will respond with 404s. This
allows us to impersonate and return the null responses for our private VPNed
binary cache without needing to impersonate its certificates.

## Installation

### NixOS

``` nix
imports = [
  "${(fetchTarball "https://github.com/jskrzypek/nix-serve-nothing/archive/0cfe7f8a4b3aed152be590885deefadb1324c732.tar.gz")}/service.nix"
];

nix.binaryCaches = [ "http://localhost:13823" ];

services.nix-serve-nothing = {
  enable = true;
  bindAddress = "localhost";
  port = 13823;
  proxy = {
    enable = true;
    target = "https://your.nix.cache.here";
    # Command to run to determine whether or not to proxy
    command = "systemctl is-active openvpn-your-vpn.service";
    # If the command outputs this string, proxy
    when = "active";
  };
};
```

## Options

The service specifies configuring options. Otherwise the following parameters
can be passed on the command line to the PSGI server:

 * **listen** - The address on which to listen
 * **proxy** - (*optional*) A hash that configures the proxy
   * **target** - The remote binary cache to proxy requests to
   * **command** - The shell command to determine if requests should be proxied
   * **when** - (*optional*) A value to match the output of command against
   * **cachettl** - (*optional - default 300*) The number of seconds to wait before checking the command again.
