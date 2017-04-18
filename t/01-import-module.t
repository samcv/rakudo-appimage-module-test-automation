use v6;
use Test;
my $appimage = %*ENV<APPIMAGE>;
note "Don't see APPIMAGE ENV var set, should be set to the location of the AppImage" if !$appimage ;
if !%*ENV<OWD> && !$appimage {
    $appimage = 'perl6';
    note "Don't see OWD or APPIMAGE env var so assuming you're not running an AppImage, and using normal perl6 binary";
}
elsif %*ENV<OWD> {
    chdir %*ENV<OWD>;
}
is qqx{$appimage -I t/lib -e "use test-module; say my-test-sub('abc 123')"}, "abc 123abc 123\n", 'Can -I t/lib and use a module';
done-testing;
