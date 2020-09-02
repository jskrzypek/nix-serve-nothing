use POSIX;
use Nix::Config;
use String::ShellQuote;
use Getopt::Long;
use Plack::App::Proxy;
use strict;

use constant DEBUG => $ENV{NIX_SERVE_NOTHING_DEBUG} || 0;
select(STDOUT);

my %proxyOpts = (
    target => $ENV{PROXY_TARGET} || "",
    command => $ENV{PROXY_COMMAND} || "",
    when => $ENV{PROXY_WHEN} || "",
    cachettl => $ENV{PROXY_CACHETTL} || 300,
);
$proxyOpts{'cachettl'} = int($proxyOpts{'cachettl'});
my $useProxy = "";
my $proxy = Plack::App::Proxy->new(
    remote => $proxyOpts{'target'},
    backend => 'LWP',
)->to_app;
my $checkedAt = 0;
GetOptions ('proxy-opts|p:s%{2,4}' => \%proxyOpts);

print scalar localtime;
print ": Booting server with proxy-options\n";
print "  * target   : $proxyOpts{'target'}\n";
print "  * command  : $proxyOpts{'command'}\n";
print "  * when     : $proxyOpts{'when'}\n";
print "  * cachettl : $proxyOpts{'cachettl'}\n";

# we don't just check at startup so we can be lazy and wait for the state when
# first queried
sub checkUseProxy {
    my $now = time;
    my $nextcheck = int($checkedAt) + int($proxyOpts{'cachettl'});

    DEBUG && print(scalar(localtime), ": Last checked command at ", scalar(localtime($checkedAt)), "\n");
    DEBUG && print(scalar(localtime), ": Check scheduled for ", scalar(localtime($nextcheck)), "\n");

    if ($now > $nextcheck) {
        $checkedAt = $now;
        DEBUG && print(scalar(localtime), ": Checking command now...");
        my $cmd_ret_val = readpipe(shell_quote split(" ", $proxyOpts{'command'}));
        my $cmd_exit_code = $?;

        DEBUG && print scalar(localtime), ": Command `";
        DEBUG && print shell_quote split(" ", $proxyOpts{'command'});
        DEBUG && print "` exited with $cmd_exit_code and returned '$cmd_ret_val'.\n";
    
        $useProxy = 0;

        if ($proxyOpts{'when'} && $cmd_ret_val == $proxyOpts{'when'}) {
            $useProxy = 1;
        }

        elsif ($cmd_exit_code == 0) {
            $useProxy = 1;
        }

        if ($useProxy == 1 && length $proxyOpts{'target'} > 0) {
            print scalar localtime;
            print ": Nix-serve-nothing is now proxying to ";
            print $proxyOpts{'target'};
            print ".\n";
        }
        else {
            print scalar localtime;
            print ": Nix-serve-nothing is now resoponding without proxy.\n";
        }
    }


    return $useProxy;
}

my $app = sub {
    my $env = shift;

    my $path = $env->{PATH_INFO};


    if (checkUseProxy() == 1) {
        print "$env->{REQUEST_METHOD} <$proxyOpts{'target'}> $path\n";
        return $proxy->($env);
    }

    print "$env->{REQUEST_METHOD} $path\n";

    if ($path eq "/nix-cache-info") {
        return [200, ['Content-Type' => 'text/plain'], ["StoreDir: $Nix::Config::storeDir\nWantMassQuery: 1\nPriority: 30\n"]];
    }

    return [404, ['Content-Type' => 'text/plain'], ["File not found.\n"]];
}