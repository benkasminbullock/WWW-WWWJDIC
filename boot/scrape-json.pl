#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use LWP::Simple;
use FindBin '$Bin';
use JSON::Create 'create_json';
use Getopt::Long;
my $verbose;
GetOptions (
verbose => \$verbose,
);
my $toppage = "https://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?1C";
my $stuff = get_mirrors_nice ($toppage);
open my $out, ">:encoding(utf8)", "$Bin/../lib/WWW/WWWJDIC.json" or die $!;
print $out create_json ($stuff), "\n";
close $out or die $!;
exit;

sub get_mirrors_nice
{
    my ($url) = @_;
    my $html = get ($url);
    $html =~ s{<!--.*?-->}{}gsm;
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
	    if (/<\s*option.*value\s*=\s*"([0-9A-Z])"\s*>\s*([^<]*)/i) {
		my $dic = $1;
		my $value = $2;
		$value =~ s/^\s+|\s+$//g;
		$options {$dic} = $value;
		if ($verbose) {
		    print "Value $dic dictionary '$value'\n";
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
		    # Don't include the melbourne server
 		    if ($place =~ /(melb)/i) {
			next;
		    }
		    $place = 'australia';
		}
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
