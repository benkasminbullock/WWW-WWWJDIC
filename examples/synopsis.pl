#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use WWW::WWWJDIC;
use HTTP::Tiny;
my $wj = WWW::WWWJDIC->new (mirror => 'usa');
my $url = $wj->lookup_url ('日本');
my $ht = HTTP::Tiny->new ();
my $html = $ht->get ($url);
my $results = $wj->parse_results ($html);
for (@$results) {
    print "$_->{meaning}.\n";
}
