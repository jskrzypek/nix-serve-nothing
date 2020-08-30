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

Use the included default.nix derivation to build the server, and service.nix to
set up the service.

## Options

The service specifies configuring options. Otherwise the following parameters
can be passed on the command line to the PSGI server:

 * **listen** - The address on which to listen
 * **proxy** - (*optional*) A hash that configures the proxy
   * **target** - The remote binary cache to proxy requests to
   * **command** - The shell command to determine if requests should be proxied
   * **when** - (*optional*) A value to match the output of command against
