{ pkgs, debug ? false, ... }:

with pkgs;
with lib;
with stdenv.lib;

stdenv.mkDerivation {
  pname = "nix-serve-nothing";
  version = "0.5";

  src = ./.;

  buildInputs = [ bzip2 perl nix nix.perl-bindings ]
    ++ (with perlPackages;
        [ GetoptLong LWPProtocolHttps Plack PlackAppProxy StringShellQuote Starman ]);

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/libexec/nix-serve-nothing
    cp nix-serve-nothing.psgi $out/libexec/nix-serve-nothing/nix-serve-nothing.psgi

    mkdir -p $out/bin
    cat > $out/bin/nix-serve-nothing <<EOF
    #! ${stdenv.shell}
    NIX_SERVE_NOTHING_DEBUG=${toString debug} PATH=${makeBinPath [ bzip2 nix ]}:\$PATH PERL5LIB=$PERL5LIB exec ${perlPackages.Starman}/bin/starman $out/libexec/nix-serve-nothing/nix-serve-nothing.psgi "\$@"
    EOF
    chmod +x $out/bin/nix-serve-nothing
  '';

  meta = {
    homepage = "https://github.com/jskrzypek/nix-serve-nothing";
    description = "A utility for sharing absolutely nothing as a binary cache";
    maintainers = [{
        email = "jskrzypek@gmail.com";
        github = "jskrzypek";
        githubId = 1513265;
        name = "Joshua Skrzypek";
    }];
    license = licenses.lgpl21;
    platforms = nix.meta.platforms;
  };
}
