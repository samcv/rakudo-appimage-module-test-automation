#!/usr/bin/env perl6
use v6;
#`(
The number of builds is the number of sections the module builds are broken
up in.
For example if there's 10 build nums (10 builds), then the build numbers will
range from 0-9
#`)
my %results;
my $date = DateTime.now(formatter => &datetime-formatter, timezone => 0);
sub message ($module, :$timeout, :$exitcode, :$installing) {
  if $installing {
    say "\n»» $module »» Trying to install";
  }
  elsif $timeout {
    say "\n»» $module »» ⚠️ TIMED OUT »» (FAIL, TIMED OUT after $timeout seconds)";
  }
  elsif $exitcode == 0 {
    say "\n»» $module »» 🆗 $exitcode »» (PASS, exit code is $exitcode)";
  }
  else {
    say "\n»» $module »» ⚠️ $exitcode »» (FAIL, exit code is $exitcode)";
  }
}
sub datetime-formatter {
   sprintf "%04d-%02d-%02d_%02d.%02d", .year, .month, .day, .hour, .minute given $^a
}

say %*ENV<NUM_BUILDS BUILD_NUM>;
%*ENV<NUM_BUILDS BUILD_NUM> = 10, 10.rand.Int if %*ENV<NUM_BUILDS>:!exists or %*ENV<BUILD_NUM>:!exists;
my Str:D $prefix = %*ENV<Prefix> // '/rsu';
my Int:D $build-no = %*ENV<BUILD_NUM> // 0;
my Int:D $no-of-builds = %*ENV<NUM_BUILDS> // 1;
note "MODULE BUILD NO ", %*ENV<BUILD_NUM>, ' of 0-', %*ENV<NUM_BUILDS>−1, " ($no-of-builds total)";
sub MAIN (Str :$folder = ".",
          Str:D :$zef-repo = 'https://github.com/ugexe/zef.git',
          Str:D :$zef = "$prefix/share/perl6/site/bin/zef",
          Bool:D :$no-install = False) {

  my $out-folder = $folder.IO.absolute;
  my $date-folder = "$out-folder/$date";
  mkdir $date-folder unless $date-folder.IO.d;
  if !$no-install {
    chdir $prefix;
    my $p6 = "$prefix/bin/perl6";
    if "zef".IO.d {
      chdir 'zef';
      run 'git', 'pull';
    }
    else {
      run 'git', 'clone', $zef-repo;
      chdir "zef";
    }
    run $p6, '-Ilib', 'bin/zef', 'install', '.';
    if $zef.IO.f.not {
        note "Cannot find $zef file";
        qqx{find $prefix -type f -name 'zef' }.say;
        exit 1;
    }
    run $zef, 'update';
  }
  my $modules = qqx{$zef list};
  my @module-array = $modules.lines.sort.unique.pick(*);
  my @new-mod-array;
  my $fast;
  for @module-array -> $mod {
    next unless $mod and $mod !~~ /^\s*$/;
    if $mod ~~ /^'JSON::Fast' ['('.*]? $/ {
      $fast = $mod;
    }
    else {
      @new-mod-array.push: $mod;
    }
  }
  @new-mod-array.unshift($fast) if $fast;
  @module-array = @new-mod-array;
  #my @new =  (@a.rotor: @a/(%*ENV<NUM_BUILDS>-1), :partial)[%*ENV<BUILD_NUM>];
  say "Installing ", @module-array.elems, ': ', @module-array.join(', ');
  my $timeout = 10 * 60;
  for @module-array -> $module {
    my @cmd = $zef, 'install', $module;
    my $proc = Proc::Async.new(|@cmd, :out, :err);
    my @output;
    $proc.stdout.tap({ .print; @output.push($_) });
    $proc.stderr.tap({ $*ERR.print($_); @output.push($_) });
    my $promise = $proc.start;
    message $module, :installing;
    %results{$module}<status> = 'Installing';
    my $waitfor = $promise;
    $waitfor = Promise.anyof(Promise.in($timeout), $promise)
      if $timeout;
    await $waitfor;
    if $promise.status ~~ Kept {
      my $exitcode = $promise.result.exitcode;
      message $module, :exitcode($exitcode);
      %results{$module}<exitcode> = $exitcode;
      %results{$module}<flag> = $exitcode == 0 ?? 'ok' !! 'nok';
      %results{$module}<status> = 'done';
    }
    else {
      %results{$module}<flag> = '?';
      %results{$module}<status> = 'Timeout ' ~ $timeout ~ 's';
      message $module, :timeout($timeout);
      $proc.kill;
      sleep 1 if $promise.status ~~ Planned;
      $proc.kill: 9;
    }
    %results{$module}<date> = DateTime.now(formatter => &datetime-formatter, timezone => 0).Str;
    write-out($out-folder, %results, $module, @output.join, $date-folder);
  }
}
sub my-to-json (|d) {
    my $json = try require JSON::Fast <&to-json>;
    $json = sub (|c) { Rakudo::Internals::JSON.to-json(|c) };
    &to-json.defined ?? to-json(|d) !! $json(|d);
}
sub write-out ($out-folder, %results, $module, $output, $date-folder) {
  "$out-folder/$date.json".IO.spurt(my-to-json(%results));
  "$date-folder/$module.log".IO.spurt($output);
}
