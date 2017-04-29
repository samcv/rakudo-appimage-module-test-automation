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

sub MAIN(Str :$repo) {
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

    die "Repository name is incorrect"; if !%nuhash{$repo}.defined;

    # Find appropriate url and truncate it
    my $repo-url-base = %nuhash{$repo}.split('/')[3..*].join('/');
    # We got to the issues url
    $repo-url = $api-url ~ $repo-url-base ~ '/issues';

    # json getting and checking
    my $json = from-json(qqx{curl '$repo-url'});
    if ($json>>.<title>.grep(/'[Eco] Tests are failing'/).elems != 0) {
        say 'It is clear';
        exit 0; # the issue is already opened
    } else {
        say 'We need to post something quickly!';
        exit 1; # we need to create an issue
        # Some credential related work here
        # Given the repo-url-base, we can construct an API calls
        # to create issues here
    };
}
