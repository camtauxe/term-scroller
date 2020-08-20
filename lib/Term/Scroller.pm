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

use IO::Pty;
use Term::ReadKey qw(GetTerminalSize);

sub scroller {
    my %params = @_;

    my $buf_height = $params{height} // 10;
    my $buf_width  = $params{width}  // (GetTerminalSize)[0]    // 80;
    my $outfh      = $params{out}    // qualify_to_ref(select);

    my $pty     = IO::Pty->new;

    defined(my $pid = fork)     or croak "unable to fork: $!";

    return $pty if $pid;

    # Child
    my $slave = $pty->slave;

    my @buf;

    print "\n";
    while(my $line = <$slave>) {
        chomp $line;
        
        # Remove cursor-changing escape sequences
        $line =~ s/\033\[\d+(?>(;\d)+)*[A-HJKSTf]//g;

        # We need to crop the line to the width of the buffer, but keep
        # any SGR (color/text-style) escape sequences intact. To do this,
        # we split the input line into chunks consisting of a run of
        # non-escape sequence characters optionally followed by one escape
        # sequence. We use these to rebuild the line that we're gonna print,
        # keeping all escape sequences, but stopping the regular text
        # at the width of the buffer.

        my $to_print    = "";   # line that will eventually get printed
        my $text_length = 0;    # length of text sequences so far
        my $sgr_split = qr{     # regex to split into text+sgr sequences
            (?<TEXT> .*? ) 
            (?<SGR>  \033\[\d+(?>(;\d)+)*m )?
        }x;

        # Iterate through matches
        while ($line =~ m/$sgr_split/cg) {
            my $text = $+{TEXT} // "";
            my $sgr  = $+{SGR}  // "";

            # Add text if we haven't yet passed the buffer width
            if ($text_length < $buf_width) {
                $text_length += length($text);
                # Crop to buffer width if we went over
                if ($text_length > $buf_width) {
                    $text = substr $text, 0, -( $text_length - $buf_width );
                    $text_length = $buf_width;
                }
            # If we've already passed the buffer width, no more text
            } else {
                $text = "";
            }

            $to_print .= $text.$sgr;
        }

        #print "$to_print\n";

        # Print next frame

        # Reset cursor back to top
        printf $outfh "\033[%d;F", scalar(@buf);

        # Add line to buffer and rotate out old line
        push @buf, $to_print;
        shift @buf if @buf > $buf_height;

        # Print frame
        print $outfh  "$_\033[K\n"  for (@buf);

        # Reset
        print "\033[0m";
    }

    close $slave;

    exit
}


1;

=head1 AUTHOR

Cameron Tauxe C<camerontauxe@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
