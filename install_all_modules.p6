#!/usr/bin/env perl6
use v6;
#`(
The number of builds is the number of sections the module builds are broken
up in.
For example if there's 10 build nums (10 builds), then the build numbers will
range from 0-9
#`)
sub message ($module, :$timeout, :$exitcode, :$installing) {
  if $installing {
    say "\n»» $module »» Trying to install";
  }
  if $timeout {
    say "\n»» $module »» ⚠️ TIMED OUT »» (FAIL, TIMED OUT after $timeout seconds)";
  }
  elsif $exitcode == 0 {
    say "\n»» $module »» 🆗 $exitcode »» (PASS, exit code is $exitcode)";
  }
  else {
    say "\n»» $module »» ⚠️ $exitcode »» (FAIL, exit code is $exitcode)";
  }
}
say %*ENV<NUM_BUILDS BUILD_NUM>;
%*ENV<NUM_BUILDS BUILD_NUM> = 10, 10.rand.Int if %*ENV<NUM_BUILDS>:!exists or %*ENV<BUILD_NUM>:!exists;
my $prefix = %*ENV<Prefix> // '/rsu';
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
  my @module-array = $modules.lines.sort.unique;
  my $module-elems = @module-array.elems;
  my @a := @module-array;
  my @new =  (@a.rotor: @a/(%*ENV<NUM_BUILDS>-1), :partial)[%*ENV<BUILD_NUM>];
  say "Installing: ", @new.join(', ');
  my $timeout = 10 * 60;
  for $modules.lines -> $module {
    my @cmd = $zef, 'install', $module;
    my $proc = Proc::Async.new(|@cmd);
    my $promise = $proc.start;
    message $module, :installing;
    my $waitfor = $promise;
    $waitfor = Promise.anyof(Promise.in($timeout), $promise)
      if $timeout;
    await $waitfor;
    if $promise.status ~~ Kept {
      message $module, :exitcode($promise.result.exitcode);
    }
    else {
      message $module, :timeout($timeout);
      $proc.kill;
      sleep 1 if $promise.status ~~ Planned;
      $proc.kill: 9;
    }
  }
}
