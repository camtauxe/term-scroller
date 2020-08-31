#!/usr/bin/perl
use strict;
use warnings;

use Term::Scroller;
use Time::HiRes qw(usleep);
use Term::ANSIColor;

my @pattern = (
    "\033[31m#-----#\033[0m",
    "\033[32m #---# \033[0m",
    "\033[33m  #-#  \033[0m",
    "\033[34m   #   \033[0m"
);
push @pattern, reverse @pattern;
$_ = "$_    "x10 for (@pattern);

for (1..5) {
    for (@pattern) {
        print "$_\n";
        usleep 60_000;
    }
}
