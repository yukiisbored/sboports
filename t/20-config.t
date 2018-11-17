#!/usr/bin/env perl

use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin '$RealBin';
use lib $RealBin;
use Test::Sboports qw/ sboconfig /;

plan tests => 20;

# 1-7: test invalid arguments
sboconfig '-c', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -c\n" };
sboconfig '-d', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -d\n" };
sboconfig '-j', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -j\n" };
sboconfig '-p', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -p\n" };
sboconfig '-s', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -s\n" };
sboconfig '-o', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -o\n" };
sboconfig '-V', 'invalid', { exit => 1, expected => "You have provided an invalid parameter for -V\n" };

# 8-9: move original dir away and run tests on the config file
SKIP: {
	skip "Only run this test under Travis CI", 13 unless $ENV{TRAVIS};

	my $dir = '/etc/sboports';
	rename $dir, "$dir.moved";
	system 'touch', $dir;

	sboconfig '-V', '14.1', { exit => 1, expected => qr"\QUnable to create $dir. Exiting." };

	unlink $dir;

	sboconfig '-V', '14.1', { test => 0 };
	ok(-d $dir, "$dir created correctly.");

	unlink "$dir/sboports.conf";

	# set up sboports.conf
	open my $fh, '>', "$dir/sboports.conf" or do {
		my $err = $!;
		fail "Writing sboports.conf";
		diag "Could not open $dir/sboports.conf for writing: $err";
		skip 10, "Could not write sboports.conf";
		goto CLEANUP;
	};

	say $fh "#comment=foo";
	say $fh "#comment=bar";
	say $fh "";
	say $fh "";
	say $fh "FOO=FOO";
	say $fh "FOO=BAR";
	say $fh "";
	say $fh "SLACKWARE_VERSION=14.0";
	say $fh "SLACKWARE_VERSION=14.2";

	close $fh;

	sboconfig '-V', '14.1', { test => 0 };

	open my $cfh, '<', "$dir/sboports.conf" or do {
		my $err = $!;
		fail "Reading sboports.conf";
		diag "Could not open $dir/sboports.conf for reading: $err";
		skip 10, "Could not read sboports.conf";
		goto CLEANUP;
	};

	chomp(my @lines = readline $cfh);

	close $cfh;

	is($lines[0], "#comment=foo", "First comment preserved.");
	is($lines[1], "#comment=bar", "Second comment preserved.");
	is($lines[2], "", "First empty line preserved.");
	is($lines[3], "", "Second empty line preserved.");
	is($lines[4], "FOO=FOO", "First setting preserved.");
	is($lines[5], "", "Second setting correctly collapsed. Third empty line preserved.");
	is($lines[6], "SLACKWARE_VERSION=14.1", "SLACKWARE_VERSION correctly set.");
	is($lines[7], undef, "SLACKWARE_VERSION correctly collapsed.");

	sboconfig qw[ -V 14.0 -j 2 ], { test => 0 };

	open $cfh, '<', "$dir/sboports.conf" or do {
		my $err = $!;
		fail "Reading sboports.conf";
		diag "Could not open $dir/sboports.conf for reading: $err";
		skip 3, "Could not read sboports.conf";
		goto CLEANUP;
	};

	chomp(@lines = readline $cfh);

	close $cfh;

	is($lines[6], "SLACKWARE_VERSION=14.0", "SLACKWARE_VERSION correctly set again.");
	is($lines[7], "JOBS=2", "JOBS correctly set.");
	is($lines[8], undef, "Nothing new collapsed.");

	CLEANUP:
	unlink "$dir/sboports.conf";
	rmdir $dir;
	rename "$dir.moved", $dir;
}
