#!/rsu/bin/perl6
use v6;
#`(
The number of builds is the number of sections the module builds are broken
up in.
For example if there's 10 build nums (10 builds), then the build numbers will
range from 0-9
#`)
say %*ENV<NUM_BUILDS BUILD_NUM>;
%*ENV<NUM_BUILDS BUILD_NUM> = 10, 10.rand.Int if %*ENV<NUM_BUILDS>:!exists or %*ENV<BUILD_NUM>:!exists;
my $prefix = '/rsu';
my $build-no = %*ENV<BUILD_NUM>;
my $no-of-builds = %*ENV<NUM_BUILDS>;
note "MODULE BUILD NO ", %*ENV<BUILD_NUM>, ' of 0-', %*ENV<NUM_BUILDS>−1, " ($no-of-builds total)";
sub MAIN (Str:D $zef-repo = 'https://github.com/ugexe/zef.git',
  Str:D :$zef = "$prefix/share/perl6/site/bin/zef",
  Bool:D :$no-install = False) {
  if !$no-install {
    chdir $prefix;
    my $p6 = "$prefix/bin/perl6";
    run 'git', 'clone', $zef-repo;
    chdir "zef";
    run $p6, '-Ilib', 'bin/zef', 'install', '.';
    if $zef.IO.f.not {
        note "Cannot find $zef file";
        qqx{find $prefix -type f -name 'zef' }.say;
        exit 1;
    }
    run $zef, 'update';
  }
  my $modules = qqx{$zef list};
  #$modules ~~ s:g/ ':' [ auth | ver ] '(' .*? '\)' //;
  my @module-array = $modules.lines.sort.unique;
  my $module-elems = @module-array.elems;
  my @a := @module-array;
  my @new =  (@a.rotor: @a/(%*ENV<NUM_BUILDS>-1), :partial)[%*ENV<BUILD_NUM>];
  say "Installing: ", @new.join(', ');
  for $modules.lines -> $module {
      my $cmd = run $zef, 'install', $module;
      if $cmd.exitcode == 0 {
          say "»» $module »» 🆗 {$cmd.exitcode} »» (PASS, exit code is 0)";
      }
      else {
          say "»» $module »» ⚠️ {$cmd.exitcode} »» (FAIL, exit code is {$cmd.exitcode})"
      }
  }
}
