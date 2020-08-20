#!/usr/bin/perl
use strict;
use warnings;

use Term::Scroller;
use Time::HiRes qw(usleep);

my @pattern = (
    "\033[31m#-----#\033[0m",
    "\033[32m #---# \033[0m",
    "\033[33m  #-#  \033[0m",
    "\033[34m   #   \033[0m"
);
push @pattern, reverse @pattern;
$_ = "$_    "x10 for (@pattern);

my $scroller = scroller(height => 20, width => 47, out => *STDERR);
while (1) {
    for (@pattern) {
        print $scroller "$_\n";
        usleep 60_000;
    }
}
