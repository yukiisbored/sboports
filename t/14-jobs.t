#!/usr/bin/env perl

use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Capture::Tiny qw/ capture_merged /;
use FindBin '$RealBin';
use lib $RealBin;
use Test::Sboports qw/ set_lo set_jobs sboinstall sboremove sboconfig restore_perf_dummy make_slackbuilds_txt sboupgrade /;

if ($ENV{TEST_INSTALL}) {
	plan tests => 9;
} else {
	plan skip_all => "Only run these tests if TEST_INSTALL=1";
}

sub cleanup {
	capture_merged {
		system(qw!/sbin/removepkg nonexistentslackbuild!);
		unlink "$RealBin/LO-jobs/nonexistentslackbuild/perf.dummy";
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild-1.0!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild!);
	};
}

cleanup();
make_slackbuilds_txt();
set_lo("$RealBin/LO-jobs");
set_jobs("FALSE");
restore_perf_dummy();

# 1: sboinstall with jobs set to FALSE
{
	my ($time) = sboinstall(qw/ -r nonexistentslackbuild /, { expected => qr/\nreal\s+\d+m([0-9.]+)s\n/, test => 0, });
	ok ($time > 5, "jobs set to FALSE took the expected amount of time");
}
sboremove('nonexistentslackbuild', { input => "y\ny", test => 0 });

# 2: sboinstall with jobs set to 2
sboconfig(qw/ -j 2 /, { test => 0 });
{
	my ($time) = sboinstall(qw/ -r nonexistentslackbuild /, { expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 });
	ok ($time < 5, "jobs set to 2 took less time than otherwise");
}
sboremove('nonexistentslackbuild', { input => "y\ny", test => 0 });

# 3: sboinstall -j FALSE with jobs set to 2
{
	my ($time) = sboinstall(qw/ -j FALSE -r nonexistentslackbuild /, { expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 });
	ok ($time > 5, "-j FALSE took the expected amount of time");
}
sboremove('nonexistentslackbuild', { input => "y\ny", test => 0 });

# 4: sboinstall -j 2 with jobs set to FALSE
sboconfig(qw/ -j FALSE /, { test => 0 });
{
	my ($time) = sboinstall(qw/ -j 2 -r nonexistentslackbuild /, { expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 });
	ok ($time < 5, "-j 2 took less time than otherwise");
}
sboremove('nonexistentslackbuild', { input => "y\ny", test => 0 });

# 5: sboinstall -j 0 with jobs set to 2
sboconfig(qw/ -j 2 /, { test => 0 });
{
	my ($time) = sboinstall(qw/ -j 0 -r nonexistentslackbuild /, { expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 });
	ok ($time > 5, "-j 0 took the expected amount of time");
}
sboremove('nonexistentslackbuild', { input => "y\ny", test => 0 });

#6: sboinstall -j invalid
sboinstall(qw/ -j invalid nonexistentslackbuild /, { exit => 1, expected => "You have provided an invalid value for -j|--jobs\n" });

#7: sboupgrade -j invalid
sboinstall qw/ -r nonexistentslackbuild /, { test => 0 };
set_lo "$RealBin/LO-jobs2";
sboupgrade qw/ -j invalid nonexistentslackbuild /, { exit => 1, expected => "You have provided an invalid value for -j|--jobs\n" };

#8: sboupgrade -j 2
{
	my ($time) = sboupgrade qw/ -j 2 nonexistentslackbuild /, { input => "y\ny", expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 };
	ok ($time < 5, "sboupgrade -j 2 took less time than otherwise");
}

#9: sboupgrade -j 0
{
	set_lo "$RealBin/LO-jobs";
	my ($time) = sboupgrade qw/ -j 0 nonexistentslackbuild /, { input => "y\ny", expected => qr/^real\s+\d+m([\d.]+)s$/m, test => 0 };
	ok ($time > 5, "sboupgrade -j 0 took the expected amount of time");
}


# Cleanup
END {
	cleanup();
}
