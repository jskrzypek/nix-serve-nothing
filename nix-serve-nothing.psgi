use MIME::Base64;
use Nix::Config;
use Nix::Manifest;
use Nix::Store;
use Nix::Utils;
use String::ShellQuote;
use GetOpt::Long;
use strict;

my %proxyOpts;
GetOptions ('proxy-opts|proxy|p:s%{2,3}' => \%proxyOpts)
my $target = $proxyOpts{'target'};
my $check_cmd = shell_quote $proxyOpts{'command'};
my $when = $proxyOpts{'when'};

our $useProxy;
our $proxy;

sub checkUseProxy {
    if ($useProxy != "") {
        return $useProxy;
    }

    $useProxy = 0;

    if ($target) {
        $proxy = Plack::App::Proxy->new(remote => $target)->to_app;

        my $cmd_ret_val = readpipe($check_cmd);
        my $cmd_exit_code = $?;

        if ($when && $cmd_ret_val == $when) {
            $useProxy = 1;
        }

        elsif ($cmd_exit_code == 0) {
            $useProxy = 1;
        }
    }

    return $useProxy;
}

my $app = sub {
    my $env = shift;

    my $path = $env->{PATH_INFO};

    if (checkUseProxy() == 1) {
        return $proxy->($env)
    }

    elsif ($path eq "/nix-cache-info") {
        return [200, ['Content-Type' => 'text/plain'], ["StoreDir: $Nix::Config::storeDir\nWantMassQuery: 1\nPriority: 30\n"]];
    }

    else {
        return [404, ['Content-Type' => 'text/plain'], ["File not found.\n"]];
    }
}
