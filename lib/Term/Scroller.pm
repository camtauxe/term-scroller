package Term::Scroller;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.1';

=head1 NAME

Term::Scroller - [description]

=head1 SYNOPSIS

    use Term::Scroller;
    # [usage here]

=cut

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(scroller);

use Carp;
use IO::Pty;

sub scroller {
    my $pty     = IO::Pty->new;

    defined(my $pid = fork)     or croak "unable to fork: $!";

    if ($pid == 0) {
        # Child
        my $slave = $pty->slave;

        my @buffer;

        print "\n";
        while(<$slave>) {
            chomp;

            printf "\033[%d;F", scalar(@buffer);

            push @buffer, $_;
            shift @buffer if @buffer > 8;


            print "$_\033[K\n"  for (@buffer);
        }

        close $slave;

        exit
    }

    return $pty;
}


1;

=head1 AUTHOR

Cameron Tauxe C<camerontauxe@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
