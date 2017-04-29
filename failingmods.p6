use JSON::Fast;
# http://hack.p6c.org/~samcv/ecosystem-tests/2017-04-28_21.52.json
my $site = 'http://hack.p6c.org/~samcv/ecosystem-tests';
my $time = '2017-04-28_21.52';
my $json-file = "$site/$time.json";
my %json = from-json(qqx{curl -s '$json-file'});
my @failing = %json»<flag>.keys.grep({%json{$_}<flag> eq 'nok';});
my @result;
for @failing -> $module {
    my $url = "$site/$time/$module.log".subst(' ', '%20', :g);
    my $str = "- [ ] [$module]" ~ '(' ~ "$url" ~ ")";
    @result.push: $str;
}
@result.unshift: qq:to/END/;
Generated from JSON [here]($json-file).

This build began at $time UTC.

Using nom branch of Rakudo-MoarVM

Links go to the logs of the module's installation.

Progress of this run: **%json.elems()** of ~821

Number of failing modules found so far during this run: **@failing.elems()**

END
say @result.join("\n");
