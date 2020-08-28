# nix-serve-nothing

This is a hacky little fork of Eelco Dolstra's [nix-serve](https://github.com/edolstra/nix-serve) that lets us serve
responses that nix can understand and avoid a roundtrip call to a binary cache.

If you have a binary cache sitting behind a VPN/Firewall running nix-build 
requires you to be on the VPN, or else nix hangs for a while until the request
times out and then fails. By providing a server that always claims to not have
the requested binaries we can force nix to move on to asking the next cache, or
even just building the binaries itself.

## Installation

Use the included default.nix derivation to build the server, and service.nix to
set up the service.
