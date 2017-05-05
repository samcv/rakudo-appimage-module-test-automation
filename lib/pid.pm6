sub get-other-moar-pid's is export {
    my $term = "'^$*PID\$'";
    qqx{ pgrep -u %*ENV<USER> moar | grep -vE $term }.lines».Int;
}
multi kill (Cool(Int:D) $pid, Int :$signal) is export {
    my $cmd = $signal ?? "kill -s $signal $pid" !!
    "kill $pid";
    say $cmd;
    my $proc = shell $cmd;
    $proc.exitcode;
}
multi kill (Str:D $name, Int :$signal) is export {
    my $cmd = "killall -u %*ENV<USER> $name";
    say $cmd;
    my $proc = shell $cmd;
    $proc.exitcode;
}
