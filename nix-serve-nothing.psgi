use MIME::Base64;
use Nix::Config;
use Nix::Manifest;
use Nix::Store;
use Nix::Utils;
use strict;

sub stripPath {
    my ($x) = @_;
    $x =~ s/.*\///; $x
}

my $app = sub {
    my $env = shift;
    my $path = $env->{PATH_INFO};

    # log to journald
    print "$env->{REQUEST_METHOD} $path\n";

    if ($path eq "/nix-cache-info") {
        return [200, ['Content-Type' => 'text/plain'], ["StoreDir: $Nix::Config::storeDir\nWantMassQuery: 1\nPriority: 30\n"]];
    }

    else {
        return [404, ['Content-Type' => 'text/plain'], ["File not found.\n"]];
    }
}
