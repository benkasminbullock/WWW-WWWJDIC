#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Deploy 'do_system';
do_system ("rm -rf $Bin/WWW-WWWJDIC-[0-9]*");
