#!/rsu/bin/perl6
constant $zef-repo = 'https://github.com/ugexe/zef.git';
use v6;
my $prefix = '/rsu';
chdir $prefix;
my $p6 = "$prefix/bin/perl6";
run 'git', 'clone', $zef-repo;
chdir "zef";
run $p6, '-Ilib', 'bin/zef', 'install', '.';
my $zef = "$prefix/share/perl6/site/bin/zef";
if $zef.IO.f.not {
    note "Cannot find $zef file";
    qqx{find $prefix -type f -name 'zef' }.say;
    exit 1;
}
run $zef, 'update';
my $modules = qqx{$zef list};
$modules ~~ s:g/ ':' [ auth | ver ] '(' .*? '\)' //;
say "module: [$modules]";
for $modules.lines -> $module {
    run $zef, 'install', $module;
}
