#!/usr/bin/env perl
# 
# Copyright (C) 2006 Felix Fietkau <nbd@nbd.name>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

use warnings;
use strict;

my @arg;
my $PREFIX = "CONFIG_";

sub usage;

# Given config $1, set the key $2 to newval $3 if:
#   1. the key is not already defined in config, or
#   2. mod_plus $4 is true, or
#   3. the key exists in config, but the value is '#undef', or
#   4. the newval is 'y'
#

sub set_config($$$$) {
	my $config = shift;
	my $idx = shift;
	my $newval = shift;
	my $mod_plus = shift;

	if (!defined($config->{$idx}) or !$mod_plus or
	    $config->{$idx} eq '#undef' or $newval eq 'y') {
		$config->{$idx} = $newval;
	}
}

# When not mod_plus $2:
# Just loads the goddam file.
#
# When mod_plus is true, then subsequent redefinition of a key will only occur
# if
# 1. it was last set to 'n'
# 2. the new value is 'y'
sub load_config($$) {
	my $file = shift;
	my $mod_plus = shift;
	my %config;

	open FILE, "$file" or die "can't open file '$file'";
	while (<FILE>) {
		chomp;
		/^$PREFIX(.+?)=(.+)/ and do {
			set_config(\%config, $1, $2, $mod_plus);
			next;
		};
		/^# $PREFIX(.+?) is not set/ and do {
			set_config(\%config, $1, "#undef", $mod_plus);
			next;
		};
		/^#/ and next;
		/^(.+)$/ and warn "WARNING: can't parse line: $1\n";
	}
	return \%config;
}


sub config_and($$) {
	my $cfg1 = shift;
	my $cfg2 = shift;
	my %config;

	foreach my $config (keys %$cfg1) {
		my $val1 = $cfg1->{$config};
		my $val2 = $cfg2->{$config};
		$val2 and ($val1 eq $val2) and do {
			$config{$config} = $val1;
		};
	}
	return \%config;
}


sub config_add($$$) {
	my $cfg1 = shift;
	my $cfg2 = shift;
	my $mod_plus = shift;
	my %config;
	
	for ($cfg1, $cfg2) {
		my %cfg = %$_;

		foreach my $config (keys %cfg) {
			if ($mod_plus and $config{$config}) {
				next if $config{$config} eq "y";
				next if $cfg{$config} eq '#undef';
			}
			$config{$config} = $cfg{$config};
		}
	}
	return \%config;
}

sub config_diff($$$) {
	my $cfg1 = shift;
	my $cfg2 = shift;
	my $new_only = shift;
	my %config;
	
	foreach my $config (keys %$cfg2) {
		if (!defined($cfg1->{$config}) or $cfg1->{$config} ne $cfg2->{$config}) {
			next if $new_only and !defined($cfg1->{$config}) and $cfg2->{$config} eq '#undef';
			$config{$config} = $cfg2->{$config};
		}
	}
	return \%config
}

sub config_sub($$) {
	my $cfg1 = shift;
	my $cfg2 = shift;
	my %config = %{$cfg1};
	my @keys = map {
		my $expr = $_;
		$expr =~ /[?.*]/ ?
			map {
				/^$expr$/ ? $_ : ()
			} keys %config : $expr;
	} keys %$cfg2;

	foreach my $config (@keys) {
		delete $config{$config};
	}
	return \%config;
}

sub print_cfgline($$) {
	my $name = shift;
	my $val = shift;
	if ($val eq '#undef' or $val eq 'n') {
		print "# $PREFIX$name is not set\n";
	} else {
		print "$PREFIX$name=$val\n";
	}
}


sub dump_config($) {
	my $cfg = shift;
	die "argument error in dump_config" unless ($cfg);
	my %config = %$cfg;
	foreach my $config (sort keys %config) {
		print_cfgline($config, $config{$config});
	}
}

sub parse_expr {
	my $pos = shift;
	my $mod_plus = shift;
	my $arg = $arg[$$pos++];

	usage "Parse error" if (!$arg);

	if ($arg eq '&') {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos);
		return config_and($arg1, $arg2);
	} elsif ($arg =~ /^\+/) {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos);
		return config_add($arg1, $arg2, 0);
	} elsif ($arg =~ /^m\+/) {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos, 1);
		return config_add($arg1, $arg2, 1);
	} elsif ($arg eq '>') {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos);
		return config_diff($arg1, $arg2, 0);
	} elsif ($arg eq '>+') {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos);
		return config_diff($arg1, $arg2, 1);
	} elsif ($arg eq '-') {
		my $arg1 = parse_expr($pos);
		my $arg2 = parse_expr($pos);
		return config_sub($arg1, $arg2);
	} else {
		return load_config($arg, $mod_plus);
	}
}

sub usage {
	my $msg = shift;

	print STDERR $msg, "\n" if $msg;
	#print STDERR "frank" =~ s/a/g/g;
	$msg = qq{
	USAGE
		$0 [-n|-p prefix] expr [expr [...]]

	Perform one or more binary operations on .config files.

		-n        clear prefix [default is "CONFIG_"]
		-p prefix set prefix [default is "CONFIG_"]

	Each expression consists of an operator and two operands passed in
	Polish notation.  Any number of operations can be performed as long as
	there is one more total operands (files) than operators.

	BINARY OPERATORS
		&   Return only values that are set and match in both operands.
		>   Return only the difference bewteen a and b.
		>+  Return only the positive difference bewteen a and b --
		    those where values from a are changed to 'y' or 'm' in b.
		+   Merge a and b overwriting values from a with values from b
		    if they are set in both.
		+m  Like +, but only overwrites values from a if they are set
		    to 'm' in b.
		-   Return values from a that are not set in b.

	EXAMPLES
		$0 + .config1 .config2
	Merge .config1 and .config2

		$0 + .config1 '&' .config2 .config3
	Merge .config1 with values that match in both .config2 and .config3.

	};
	$msg =~ s/^\t//mg;
	print STDERR $msg;
	die
}

while (@ARGV > 0 and $ARGV[0] =~ /^--?\w+$/) {
	my $cmd = shift @ARGV;
	if ($cmd =~ /^-n$/) {
		$PREFIX = "";
	} elsif ($cmd =~ /^-p$/) {
		$PREFIX = shift @ARGV;
	} elsif ($cmd =~ /^-(-help|h)$/) {
		usage
	} else {
		usage "Invalid option: $cmd\n";
	}
}
@arg = @ARGV;

my $pos = 0;
dump_config(parse_expr(\$pos));
die "Parse error" if ($arg[$pos]);
