#!/rsu/bin/perl6
constant $zef-repo = 'https://github.com/ugexe/zef.git';
use v6;
chdir "/rsu";
my $p6 = '/rsu/bin/perl6';
run 'git', 'clone', $zef-repo;
chdir "zef";
run $p6, '-Ilib', 'bin/zef', 'install', '.';
my $zef = '/rsu/share/perl6/site/bin/zef';
run $zef, 'update';
my $modules = qqx{$zef list};
$modules ~~ s:g/ ':' [ auth | ver ] '(' .*? '\)' //;
say $modules;
for $modules.lines -> $module {
    run $zef, 'install', $module;
}
