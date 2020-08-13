#!/usr/bin/perl
use strict;
use warnings;

use Term::Scroller;
use Time::HiRes qw(usleep);

my @pattern = (
    '#-----#',
    ' #---#',
    '  #-#',
    '   #'
);

push @pattern, reverse @pattern;

my $scroll = scroller;

while (1) {
    for (@pattern) {
        print $scroll "$_\n";
        usleep 50_000;
    }
}
