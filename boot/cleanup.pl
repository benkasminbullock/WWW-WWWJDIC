#! perl
use strict;
use warnings;
use lib "boot";
use Boot;
for my $crap (@Boot::crap) {
    system ("rm -rf $crap");
}
