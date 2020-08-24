package Term::Scroller;

use 5.020;
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
use Symbol qw(qualify_to_ref);
use Scalar::Util qw(openhandle);

use IO::Pty;
use Term::ReadKey qw(GetTerminalSize);

sub scroller {

    my %params = @_;
    my $buf_height  = $params{height}       // 10;
    my $buf_width   = $params{width}        // (GetTerminalSize)[0]    // 80;
    my $style       = $params{style};
    my $outfh       = $params{out}          // qualify_to_ref(select);
    my $hide        = $params{hide}         // 0;
    my $pidref      = $params{getpid};
    my $passthru    = $params{passthrough};

    my $pty     = IO::Pty->new;

    defined(my $pid = fork)     or croak "unable to fork: $!";

    if ($pid) {
        $pty->close_slave();
        if (exists $params{getpid}) {
            ${ $params{getpid} } = \$pid;
        }
        return $pty;
    }

    # Child
    close $pty;
    my @buf;
    my $slave = $pty->slave;
    select $outfh;

    print "\n";
    while(my $line = <$slave>) {

        print $passthru $line if openhandle($passthru);

        chomp $line;

        my $to_print = "";

        if (defined $style) {
            # Remove all escape sequences
            $line =~ s/\033\[\d+(?>(;\d)+)*[A-HJKSTfm]//g;
            # Crop to buffer, add style
            $to_print = $style . (substr $line, 0, $buf_width) . "\033[0m";
        }
        else {
            # Remove cursor-changing escape sequences
            $line =~ s/\033\[\d+(?>(;\d)+)*[A-HJKSTf]//g;
            # Crop to buffer, keeping remaining escapes intact
            $to_print = _crop_to_width($line, $buf_width);
        }

        #print "$to_print\n";

        # Print next frame:
        # Reset cursor back to top
        printf "\033[%d;F", scalar(@buf);
        # Add line to buffer and rotate out old line
        push @buf, $to_print;
        shift @buf if @buf > $buf_height;
        # Print frame
        print "$_\033[K\n"  for (@buf);
        # Reset
        print "\033[0m";
    }

    close $passthru if openhandle($passthru);

    if ($hide) {
        print "\033[1;F\033[K" for (1..@buf)
    }

    exit
}

=for comment
crop_to_width STRING, LENGTH

Cut the given string down to LENGTH characters while keeping any 
SGR ANSI esccape sequences intact. Return the new string.
=cut
sub _crop_to_width {
    my $in  = shift;
    my $len = shift;

    # We need to crop the line to the width of the buffer, but keep
    # any SGR (color/text-style) escape sequences intact. To do this,
    # we split the input line into chunks consisting of a run of
    # non-escape sequence characters optionally followed by one escape
    # sequence. We use these to rebuild the line that we're gonna print,
    # keeping all escape sequences, but stopping the regular text
    # at the width of the buffer.

    my $out    = "";   # line that will eventually get printed
    my $text_length = 0;    # length of text sequences so far
    my $sgr_split = qr{     # regex to split into text+sgr sequences
        (?<TEXT> .*? ) 
        (?<SGR>  \033\[\d+(?>(;\d)+)*m )?
    }x;

    # Iterate through matches
    while ($in =~ m/$sgr_split/cg) {
        my $text = $+{TEXT} // "";
        my $sgr  = $+{SGR}  // "";

        # Add text if we haven't yet passed the buffer width
        if ($text_length < $len) {
            $text_length += length($text);
            # Crop to buffer width if we went over
            if ($text_length > $len) {
                $text = substr $text, 0, -( $text_length - $len );
                $text_length = $len;
            }
        # If we've already passed the buffer width, no more text
        } else {
            $text = "";
        }

        $out .= $text.$sgr;
    }
    return $out;
}

1;

=head1 AUTHOR

Cameron Tauxe C<camerontauxe@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
