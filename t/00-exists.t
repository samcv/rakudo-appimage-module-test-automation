use Test;
my $launching-cwd = %*ENV<OWD>;
say "See ENV OWD=$launching-cwd";
if $launching-cwd {
    say "Trying to chdir into the original directory";
    chdir $launching-cwd;
}
else {
    say "Seems not to be set. If you are launching from the AppImage there's something wrong";
}
