#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use LWP::Simple;
use FindBin;
use JSON::Create 'create_json';
my $verbose;
my $toppage = "http://gengo.com/wwwjdic/cgi-data/wwwjdic?1C";
#http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?1C";
my $stuff = get_mirrors_nice ($toppage);
open my $out, ">:encoding(utf8)", "$FindBin::Bin/../lib/WWW/WWWJDIC.json" or die $!;
print $out create_json ($stuff);
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
	if (/Mirror Sites:/i) {
	    $mirrors = 1;
	}
	if ($mirrors) {
	    if (/<\/td>/) {
		$mirrors = undef;
	    }
	    if (/<a\s+href="(.*)">(.*)<\/a>/i) {
		my $mirror = $1;
		my $place = lc $2;
		# Put the name of the location within Australia since
		# there are two of them.
		if ($place =~ /australia/i) {
		    if ($place =~ /(melb|monash)/i) {
			my $aloc = lc ($1);
			$place = "australia_$aloc";
			print "$place\n";
		    }
		    else {
			die "Unparsed australian name $place";
		    }
		}
			print "$place\n";

		if ($place =~ /full.*list/) {
		    next;
		}
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
