# This script checks certain github repo for a custom issue presence.

use v6;
use JSON::Fast;

my $modules-url = 'https://modules.perl6.org/.json';
# Name for a cache file
my $pairs-filename = 'name-url-list.txt';
my $api-url = 'https://api.github.com/repos/';
my $pairs;
my $repo-url;
my %nuhash; # name-url hash

sub MAIN(Str :$repo, Bool:D :$debug = False) {
    die "Repository name must be passed" if !$repo.defined;

    # Populate our URL cache
    if ($pairs-filename.IO.e) {
        $pairs = from-json(slurp $pairs-filename).flat;
        if DateTime.now.day != $pairs-filename.IO.modified.DateTime.day {
            unlink $pairs-filename;
        }
    } else {
        $pairs = from-json(qqx{curl -s '$modules-url'})<dists>>>.<name url>;
        spurt($pairs-filename, to-json($pairs));
    }
    for @$pairs -> $entry {
        %nuhash.push: $entry[0] => $entry[1];
    }

    die "Repository name is incorrect" ~ %nuhash.perl if !%nuhash{$repo}.defined;

    # Find appropriate url and truncate it
    my $repo-url-base = %nuhash{$repo}.split('/')[3..*].join('/');
    # We got to the issues url
    $repo-url = $api-url ~ $repo-url-base ~ '/issues';

    # json getting and checking
    my $json = from-json(qqx{curl '$repo-url'});
    my token eco-fail { '[Eco] Tests are failing'};
    if ($json>>.<title>.grep(/<eco-fail>/).elems != 0) {
        say 'It is clear';
        exit 0; # the issue is already opened
    } else {
        say 'We need to post something quickly!';
        ( .note for $json>>.<title>.list ) if $debug;

        exit 1; # we need to create an issue
        # Some credential related work here
        # Given the repo-url-base, we can construct an API calls
        # to create issues here
    };
}
sub github-api-fetch (Str:D $url) {
    state $token = do {
        from-json('config.json')<token> if 'config.json'.IO.f;
    }
    my @args = 'curl', '-s';
    @args.append: '-H', "Authorization: token $token" if $token;
    my $cmd = run |@args, $url, :out;
    $cmd.out.slurp;
}
