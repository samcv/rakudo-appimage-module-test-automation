#!/rsu/bin/perl6
constant $zef-repo = 'https://github.com/ugexe/zef.git';
use v6;
chdir "/rsu";
my $p6 = '/rsu/bin/perl6';
run 'git', 'clone', $zef-repo;
chdir "zef";
qqx{$p6 -Ilib bin/zef install .};
run '/rsu/bin/zef', 'update';
my $modules = qx{/rsu/bin/zef list};
$modules ~~ s:g/ ':' [ auth | ver ] '(' .*? '\)' //;
say $modules;
for $modules.lines -> $module {
    run '/rsu/bin/zef', 'install', $module;
}
