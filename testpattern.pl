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

my $scroller = scroller(
    height  => 20,
    width   => 47,
#    style   => "\033[2m",
    hide    => 1,
    out     => *STDERR,
    getpid  => \my $pid
);

for (1..5) {
    for (@pattern) {
        print "$_\n";
        usleep 60_000;
    }
}
close $scroller;

waitpid($$pid, 0);

print "Done!\n";
