#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use LWP::Simple;
use FindBin;
use JSON 'encode_json';
my $verbose;
my $toppage = "http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?1C";
my $stuff = get_mirrors_nice ($toppage);
open my $out, ">:encoding(utf8)", "$FindBin::Bin/../lib/WWW/WWWJDIC.json" or die $!;
print $out encode_json ($stuff);
close $out or die $!;
exit;

sub get_mirrors_nice
{
    my ($url) = @_;
    my $html = get ($url);
    my @lines = split /\n/, $html;
    my $options;
    my %options;
    my $mirrors;
    my %mirrors;
    for (@lines) {
#	print;
	if (/Dictionary:/ && /<select/i) {
#	    print "Found options\n";
	    $options = 1;
	}
	if ($options) {
	    if (/<\s*option.*value\s*=\s*"([0-9A-Z])"\s*>\s*(.*)/i) {
		$options {$1} = $2;
		if ($verbose) {
		print "Value $1 dictionary '$2'\n";
	    }
	    }
	    $options = undef if (/<\/select>/);
	}
	$mirrors = 1 if /Mirror Sites:/i;
	if ($mirrors) {
	    $mirrors = undef if (/<\/td>/);
	    if (/<a\s+href="(.*)">(.*)<\/a>/i) {
		my $mirror = $1;
		my $place = lc $2;
		$mirror =~ s/\?1C//;
		if ($verbose) {
		print "'$place' => '$mirror',\n";
	    }
		$mirrors{$place} = $mirror;
	    }
	}
    }
    return {options => \%options, mirrors => \%mirrors};
}
