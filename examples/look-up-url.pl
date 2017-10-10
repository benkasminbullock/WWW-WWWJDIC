#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use WWW::WWWJDIC;
my $wwwjdic = WWW::WWWJDIC->new();
print $wwwjdic->lookup_url ("日本"), "\n";

