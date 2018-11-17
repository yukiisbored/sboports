#!/usr/bin/env perl

use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Capture::Tiny qw/ capture_merged /;
use FindBin '$RealBin';
use lib $RealBin;
use Test::Sboports qw/ make_slackbuilds_txt set_lo sboinstall sboremove restore_perf_dummy /;
use File::Temp qw/ tempdir /;

if ($ENV{TEST_INSTALL}) {
	plan tests => 29;
} else {
	plan skip_all => 'Only run these tests if TEST_INSTALL=1';
}

sub cleanup {
	capture_merged {
		system(qw!/sbin/removepkg envsettingtest!);
		system(qw!/sbin/removepkg envsettingtest2!);
		system(qw!/sbin/removepkg commandinreadme!);
		system(qw!/sbin/removepkg commandinreadmespanslines!);
		unlink "$RealBin/LO-readme/envsettingtest/perf.dummy";
		unlink "$RealBin/LO-readme/envsettingtest2/perf.dummy";
		unlink "$RealBin/LO-readme/commandinreadme/perf.dummy";
		unlink "$RealBin/LO-readme/commandinreadmespanslines/perf.dummy";
		system(qw!rm -rf /tmp/SBo/envsettingtest-1.0!);
		system(qw!rm -rf /tmp/SBo/envsettingtest2-1.0!);
		system(qw!rm -rf /tmp/SBo/commandinreadme-1.0!);
		system(qw!rm -rf /tmp/SBo/commandinreadmespanslines-1.0!);
		system(qw!rm -rf /tmp/package-envsettingtest!);
		system(qw!rm -rf /tmp/package-envsettingtest2!);
		system(qw!rm -rf /tmp/package-commandinreadme!);
		system(qw!rm -rf /tmp/package-commandinreadmespanslines!);
	};
}

cleanup();
make_slackbuilds_txt();
set_lo("$RealBin/LO-readme");
restore_perf_dummy();

my $tempdir = tempdir(CLEANUP => 1);

# 1-3: sboinstall envsettingtest - fail
sboinstall '-i', '--create-template', "$tempdir/1.temp", 'envsettingtest', { input => "n\ny\ny", expected => qr!Template \Q$tempdir/1.temp saved.\E\n!, exit => 3 };
is (scalar capture_merged { system cat => "$tempdir/1.temp" }, <<"TEMP1", "1.temp is correct");
{
   "build_queue" : [
      "envsettingtest"
   ],
   "commands" : {
      "envsettingtest" : null
   },
   "options" : {
      "envsettingtest" : null
   }
}
TEMP1
sboinstall '--use-template', "$tempdir/1.temp", { exit => 3, expected => qr{FOO isn't bar!.*envsettingtest: envsettingtest.SlackBuild return non-zero}s };

# 4-6: sboinstall envsettingtest - fail 2
sboinstall '-i', '--create-template', "$tempdir/2.temp", 'envsettingtest', { input => "y\nFOO=foo\ny\ny", expected => qr!Template \Q$tempdir/2.temp saved.\E\n!, exit => 3 };
is (scalar capture_merged { system cat => "$tempdir/2.temp" }, <<"TEMP2", "2.temp is correct");
{
   "build_queue" : [
      "envsettingtest"
   ],
   "commands" : {
      "envsettingtest" : null
   },
   "options" : {
      "envsettingtest" : "FOO=foo"
   }
}
TEMP2
sboinstall '--use-template', "$tempdir/2.temp", { exit => 3, expected => qr{FOO isn't bar!.*envsettingtest: envsettingtest.SlackBuild return non-zero}s };

# 7-9: sboinstall envsettingtest - success
sboinstall '-i', '--create-template', "$tempdir/3.temp", 'envsettingtest', { input => "y\nFOO=bar\ny\ny", expected => qr!Template \Q$tempdir/3.temp saved.\E\n! };
is (scalar capture_merged { system cat => "$tempdir/3.temp" }, <<"TEMP3", "3.temp is correct");
{
   "build_queue" : [
      "envsettingtest"
   ],
   "commands" : {
      "envsettingtest" : null
   },
   "options" : {
      "envsettingtest" : "FOO=bar"
   }
}
TEMP3
sboinstall '--use-template', "$tempdir/3.temp", { expected => qr{Install queue: envsettingtest.*Cleaning for envsettingtest-1[.]0}s };
sboremove 'envsettingtest', { input => "y\ny", test => 0 };

# 10-12: sboinstall envsettingtest2 - fail prereq
sboinstall '-i', '--create-template', "$tempdir/4.temp", 'envsettingtest2', { input => "n\ny\ny\nFOO=quux\ny\ny\nn", expected => qr!Template \Q$tempdir/4.temp saved.\E\n!, exit => 3 };
is (scalar capture_merged { system cat => "$tempdir/4.temp" }, <<"TEMP4", "4.temp is correct");
{
   "build_queue" : [
      "envsettingtest",
      "envsettingtest2"
   ],
   "commands" : {
      "envsettingtest" : null,
      "envsettingtest2" : null
   },
   "options" : {
      "envsettingtest" : null,
      "envsettingtest2" : "FOO=quux"
   }
}
TEMP4
sboinstall '--use-template', "$tempdir/4.temp", { exit => 3, expected => qr{Install queue: envsettingtest envsettingtest2.*FOO isn't bar!.*envsettingtest: envsettingtest.SlackBuild return non-zero}s };

# 13-15: sboinstall envsettingtest2 - success
sboinstall '-i', '--create-template', "$tempdir/5.temp", 'envsettingtest2', { input => "y\nFOO=bar\ny\ny\nFOO=quux\ny\ny", expected => qr!Template \Q$tempdir/5.temp saved.\E\n! };
is (scalar capture_merged { system cat => "$tempdir/5.temp" }, <<"TEMP5", "5.temp is correct");
{
   "build_queue" : [
      "envsettingtest",
      "envsettingtest2"
   ],
   "commands" : {
      "envsettingtest" : null,
      "envsettingtest2" : null
   },
   "options" : {
      "envsettingtest" : "FOO=bar",
      "envsettingtest2" : "FOO=quux"
   }
}
TEMP5
sboinstall '--use-template', "$tempdir/5.temp", { expected => qr{Install queue: envsettingtest envsettingtest2.*Cleaning for envsettingtest2-1[.]0}s };
sboremove 'envsettingtest2', { input => "n\ny\ny\ny", test => 0 };

# 16-18: sboinstall commandinreadme
SKIP: {
	skip "Only run useradd/groupadd commands under Travis CI", 3 unless (defined $ENV{TRAVIS} and $ENV{TRAVIS} eq 'true');
	skip "Only run useradd/groupadd commands if there is no test user/group", 3, if (defined getgrnam('test') or defined getpwnam('test'));

  sboinstall '-i', '--create-template', "$tempdir/6.temp", 'commandinreadme', { input => "y\ny\ny", expected => qr!Template \Q$tempdir/6.temp saved.\E\n! };
	capture_merged { system(qw/ userdel test /); system(qw/ groupdel test /); };
  is (scalar capture_merged { system cat => "$tempdir/6.temp" }, <<"TEMP6", "6.temp is correct");
{
   "build_queue" : [
      "commandinreadme"
   ],
   "commands" : {
      "commandinreadme" : [
         "groupadd -g 199 test",
         "useradd -u 199 -g 199 -d /tmp test"
      ]
   },
   "options" : {
      "commandinreadme" : 0
   }
}
TEMP6
	sboinstall '--use-template', "$tempdir/6.temp", { expected => sub { ! m/exited non-zero/ } };
	sboremove 'commandinreadme', { input => "y\ny", test => 0 };

	capture_merged { system(qw/ userdel test /); system(qw/ groupdel test /); };
}

# 19-22: sboinstall envsettingtest - unreadable template
mkdir "$tempdir/7.temp";
sboinstall '--create-template', "$tempdir/7.temp", 'envsettingtest', { input => "n\ny\ny", expected => qr!Unable to open \Q$tempdir/7.temp.\E\n!, exit => 6 };
sboinstall '--use-template', "$tempdir/7.temp", { expected => qr!Could not read template from \Q$tempdir/7.temp.\E\n!, exit => 6 };
system touch => "$tempdir/8.temp";
sboinstall '--use-template', "$tempdir/8.temp", { expected => qr!Could not read template from \Q$tempdir/8.temp.\E\n!, exit => 6 };
system "echo foo > $tempdir/9.temp";
sboinstall '--use-template', "$tempdir/9.temp", { expected => qr!Could not read template from \Q$tempdir/9.temp.\E\n!, exit => 6 };

# 23-26: sboinstall with erroneous arguments for --use-template and --create-template
sboinstall '--use-template', { expected => qr/Usage/, exit => 1 };
sboinstall '--use-template', '', { expected => qr/Usage/, exit => 1 };
sboinstall '--use-template', '', '', { expected => qr/Usage/, exit => 1 };
sboinstall '--create-template', '', '', { expected => qr/Usage/, exit => 1 };

# 27-29: sboinstall commandinreadmespanslines
SKIP: {
  skip "Only run useradd/groupadd commands under Travis CI", 3 unless (defined $ENV{TRAVIS} and $ENV{TRAVIS} eq 'true');
  skip "Only run useradd/groupadd commands if there is no test user/group", 3 if (defined getgrnam('test') or defined getpwnam('test'));

  sboinstall '-i', '--create-template', "$tempdir/10.temp", 'commandinreadmespanslines', { input => "y\ny\ny", expected => qr!Template \Q$tempdir/10.temp saved.\E\n! };
  capture_merged { system(qw/ userdel test /); system(qw/ groupdel test /); };
  is (scalar capture_merged { system cat => "$tempdir/10.temp" }, <<'TEMP10', "10.temp is correct");
{
   "build_queue" : [
      "commandinreadmespanslines"
   ],
   "commands" : {
      "commandinreadmespanslines" : [
         "groupadd -g 199 test",
         "useradd -u 199 -g 199 -d /tmp \\\n    -s /bin/sh test"
      ]
   },
   "options" : {
      "commandinreadmespanslines" : 0
   }
}
TEMP10
  sboinstall '--use-template', "$tempdir/10.temp", { expected => sub { ! m/exited non-zero/ } };
	sboremove 'commandinreadmespanslines', { input => "y\ny", test => 0 };

	capture_merged { system(qw/ userdel test /); system(qw/ groupdel test /); };
}

# Cleanup
END {
	cleanup();
}
