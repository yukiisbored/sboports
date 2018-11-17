#!/usr/bin/env perl

use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Capture::Tiny qw/ capture_merged /;
use FindBin '$RealBin';
use lib $RealBin;
use Test::Sboports qw/ make_slackbuilds_txt set_lo sboconfig sboinstall sboupgrade restore_perf_dummy set_repo sbosnap /;
use File::Temp 'tempdir';

if ($ENV{TEST_INSTALL}) {
	plan tests => 21;
} else {
	plan skip_all => 'Only run these tests if TEST_INSTALL=1';
}
$ENV{TEST_ONLINE} //= 0;

sub cleanup {
	capture_merged {
		system(qw!/sbin/removepkg nonexistentslackbuild!);
		system(qw!/sbin/removepkg nonexistentslackbuild2!);
		system(qw!/sbin/removepkg nonexistentslackbuild4!);
		system(qw!/sbin/removepkg nonexistentslackbuild5!);
		system(qw!/sbin/removepkg nonexistentslackbuild6!);
		system(qw!/sbin/removepkg weird-versionsbo!);
		system(qw!/sbin/removepkg locale-versionsbo!);
		unlink "$RealBin/LO/nonexistentslackbuild/perf.dummy";
		unlink "$RealBin/LO/nonexistentslackbuild2/perf.dummy";
		unlink "$RealBin/LO/nonexistentslackbuild4/perf.dummy";
		unlink "$RealBin/LO/nonexistentslackbuild5/perf.dummy";
		unlink "$RealBin/LO/nonexistentslackbuild6/perf.dummy";
		unlink "$RealBin/LO/weird-versionsbo/perf.dummy";
		unlink "$RealBin/LO/locale-versionsbo/perf.dummy";
		unlink "$RealBin/LO2/nonexistentslackbuild/perf.dummy";
		unlink "$RealBin/LO2/nonexistentslackbuild2/perf.dummy";
		unlink "$RealBin/LO2/nonexistentslackbuild4/perf.dummy";
		unlink "$RealBin/LO2/nonexistentslackbuild5/perf.dummy";
		unlink "$RealBin/LO2/nonexistentslackbuild6/perf.dummy";
		unlink "$RealBin/LO3/nonexistentslackbuild/perf.dummy";
		unlink "$RealBin/LO3/nonexistentslackbuild4/perf.dummy";
		unlink "$RealBin/LO3/nonexistentslackbuild5/perf.dummy";
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild-0.9!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild2-0.9!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild4-0.9!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild5-0.9!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild6-0.9!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild-1.0!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild2-1.0!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild4-1.0!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild5-1.0!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild6-1.0!);
		system(qw!rm -rf /tmp/SBo/weird-versionsbo-1.0!);
		system(qw!rm -rf /tmp/SBo/locale-versionsbo-1.0!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild-1.1!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild2-1.1!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild4-1.1!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild5-1.1!);
		system(qw!rm -rf /tmp/SBo/nonexistentslackbuild6-1.1!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild2!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild4!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild5!);
		system(qw!rm -rf /tmp/package-nonexistentslackbuild6!);
		system(qw!rm -rf /tmp/package-weird-versionsbo!);
		system(qw!rm -rf /tmp/package-locale-versionsbo!);
	};
}

cleanup();
make_slackbuilds_txt();
set_lo("$RealBin/LO");
restore_perf_dummy();

sub install {
	cleanup();
	my $lo = shift;
	my @pkgs = @_;

	sboconfig '-o', "$RealBin/LO", { test => 0 };
	for my $pkg (@pkgs) {
		sboinstall '-r', $pkg, { test => 0 };
	}
	sboconfig '-o', "$RealBin/$lo", { test => 0 };
}

# 1-2: sboupgrade nonexistentslackbuild when it doesn't need to be upgraded
install( 'LO', 'nonexistentslackbuild' );
sboupgrade 'nonexistentslackbuild', { expected => '' };
sboupgrade qw/ -f nonexistentslackbuild /, { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild\b.*Upgrade queue: nonexistentslackbuild\n/s };

# 3-7: sboupgrade nonexistentslackbuild4 and 5 when they don't need to be upgraded
install( 'LO', 'nonexistentslackbuild5', 'nonexistentslackbuild4' );
sboupgrade 'nonexistentslackbuild4', { expected => '' };
sboupgrade qw/ nonexistentslackbuild5 /, { expected => '' };
sboupgrade qw/ -f nonexistentslackbuild4 /, { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild4\b.*Upgrade queue: nonexistentslackbuild4\n/s };
sboupgrade qw/ -f nonexistentslackbuild5 /, { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild5\b.*Upgrade queue: nonexistentslackbuild5\n/s };
sboupgrade qw/ -f -z nonexistentslackbuild4 /, { input => "y\ny\ny", expected => qr/Proceed with nonexistentslackbuild5\b.*Proceed with nonexistentslackbuild4\b.*Upgrade queue: nonexistentslackbuild5 nonexistentslackbuild4\n/s };

# 8: sboupgrade works with nonexistentslackbuild6
install( 'LO2', 'nonexistentslackbuild6' );
sboupgrade 'nonexistentslackbuild6', { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild6\b.*Upgrade queue: nonexistentslackbuild6\n/s };

# 9: sboupgrade nonexistentslackbuild when it needs to be upgraded
install( 'LO2', 'nonexistentslackbuild' );
sboupgrade 'nonexistentslackbuild', { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild\b.*Upgrade queue: nonexistentslackbuild\n/s };

# 10: sboupgrade nonexistentslackbuild4 and 5 when they need to be upgraded
install( 'LO2', 'nonexistentslackbuild5', 'nonexistentslackbuild4' );
sboupgrade 'nonexistentslackbuild4', { input => "y\ny\ny", expected => qr/Proceed with nonexistentslackbuild5\b.*Proceed with nonexistentslackbuild4\b.*Upgrade queue: nonexistentslackbuild5 nonexistentslackbuild4\n/s };

# 11-12: sboupgrade nonexistentslackbuild4 and 5 when only 5 needs an update
install( 'LO3', 'nonexistentslackbuild5', 'nonexistentslackbuild4' );
sboupgrade 'nonexistentslackbuild4', { input => "y\ny", expected => qr/Proceed with nonexistentslackbuild5\b.*Upgrade queue: nonexistentslackbuild5\n/s };
install( 'LO3', 'nonexistentslackbuild5', 'nonexistentslackbuild4' );
sboupgrade qw/ -f nonexistentslackbuild4 /, { input => "y\ny\ny", expected => qr/Proceed with nonexistentslackbuild5\b.*Proceed with nonexistentslackbuild4\b.*Upgrade queue: nonexistentslackbuild5 nonexistentslackbuild4\n/s };

# 13-16: sbosnap + sboupgrade --all
my $temp = tempdir(CLEANUP => 1);
set_repo("file://$temp");
capture_merged { system <<"END"; };
cd $temp; git init;
END
sbosnap 'fetch', { expected => qr/Pulling SlackBuilds tree[.][.][.]/ };
install( 'LO2', 'nonexistentslackbuild' );
my @sbos = glob("/var/log/packages/*_SBo");
sboupgrade '--all', { input => ("n\n" x (@sbos+1)), expected => qr/Proceed with nonexistentslackbuild\b/ };
install( 'LO2', 'nonexistentslackbuild', 'nonexistentslackbuild5', 'nonexistentslackbuild4' );
sboupgrade '--all', { input => ("n\n" x (@sbos+3)), expected => qr/Proceed with nonexistentslackbuild\b.*Proceed with nonexistentslackbuild5\b.*Proceed with nonexistentslackbuild4\b/s };
set_lo("$RealBin/LO");
sboupgrade '--all', { expected => "Checking for updated SlackBuilds...\nNothing to update.\n" };

cleanup();

# 17: sboupgrade --all shouldn't pick up weird-versionsbo or locale-versionsbo
install('LO', 'weird-versionsbo', 'locale-versionsbo');
sboupgrade '--all', { input => ("n\n" x (@sbos+1)), expected => sub { not /weird-versionsbo/ and not /locale-versionsbo/ } };

# 18-19: sboupgrade -r -f both something installed and something not installed
install('LO', 'nonexistentslackbuild');
sboupgrade qw/ -r -f nonexistentslackbuild /, { expected => qr/^Upgrade queue: nonexistentslackbuild$/m };
sboupgrade qw/ -r -f nonexistentslackbuild2 /, { expected => "" };

# 20: sboupgrade -r on something already up to date
sboupgrade qw/ -r nonexistentslackbuild /, { expected => "" };

# 21: sboupgrade and answer weirdly and use a default and then answer no twice
install('LO2', 'nonexistentslackbuild', 'nonexistentslackbuild5');
sboupgrade qw/nonexistentslackbuild nonexistentslackbuild5/, { input => "foo\n\nn\nn\n", expected => qr/Proceed with nonexistentslackbuild\?.*Proceed with nonexistentslackbuild\?.*Proceed with nonexistentslackbuild5\?.*Upgrade queue: nonexistentslackbuild$/sm };

# Cleanup
END {
	cleanup();
}
