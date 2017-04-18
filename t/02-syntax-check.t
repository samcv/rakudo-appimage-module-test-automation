use Test;
my $owd = %*ENV<OWD> // '';
chdir $owd if $owd;
my @scripts = <install_all_modules.p6>;
my @procs;
for @scripts {
  push @procs, run 'perl6', '-c', $_;
}
is-deeply @procs».exitcode.all == 0, True, "@scripts.join(' ') syntax is ok";
done-testing;
