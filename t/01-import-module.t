use Test;
my $appimage = %*ENV<APPIMAGE>;
die "Don't see APPIMAGE ENV var set, should be set to the location of the AppImage" unless $appimage ;
chdir %*ENV<OWD>;
is qqx{$appimage -I t/lib -e "use test-module; say my-test-sub('abc 123')"}, "abc 123abc 123\n", 'Can -I t/lib and use a module';
