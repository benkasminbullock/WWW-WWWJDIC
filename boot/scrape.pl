#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use LWP::Simple;
use File::Versions 'make_backup';
my $verbose;
my $toppage = "http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?1C";
#http://gengo.com/wwwjdic/cgi-data/wwwjdic?1C";
get_mirrors_nice ($toppage);
exit;

sub replace_scrapes
{
    my ($source, $destination, $scraped_info) = @_;
    open my $input, "<", $source or die $!;
    if (-f $destination) {
	die "$destination exists";
    }
    open my $output, ">", $destination or die $!;
    my $outputting;
    while (<$input>) {
 	if (/#\s*SCRAPE\s*([A-Z]+)/) {
	    print $output $_;
 	    $outputting = 1;
 	    my $name = lc $1;
 	    if ($scraped_info->{$name}) {
		print $output "my \%$name = (\n";
 		my $h = $scraped_info->{$name};
 		for my $key (sort keys %$h) {
		    my $out = $h->{$key};
		    $out =~ s/'/\\'/g;
		    print $output "'$key' => '$out',\n";
		}
		print $output ");\n";
	    }
	    else {
		die "No scraped information for '$name'";
	    }
	}
	if ($outputting) {
	    if (/\#\s*END\s+SCRAPE/) {
		$outputting = 0;
	    }
	    else {
		next;
	    }
	}
	print $output $_;
    }
    close $input or die $!;
    close $output or die $!;
}

sub get_mirrors
{
    my ($scraped_info, $url) = @_;
    my $html = get ($url);
    my @lines = split /\n/, $html;
    my $options;
    my %options;
    my $mirrors;
    my %mirrors;
    for (@lines) {
	if (/Dictionary:/ && /<select/i) {
	    $options = 1;
	}
	if ($options) {
	    if (/<\s*option.*value\s*=\s*"([0-9A-Z])"\s*>\s*(.*)/i) {
		$options {$1} = $2;
		print "Value $1 dictionary '$2'\n";
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
		    print "$place => $mirror\n";
		}
		$mirrors{$place} = $mirror;
	    }
	}
    }
    $scraped_info->{mirrors} = \%mirrors;
    $scraped_info->{options} = \%options;
}

sub get_mirrors_nice
{
    my ($url) = @_;
    if ($verbose) {
	print "Getting $url\n";
    }
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
		print "Value $1 dictionary '$2'\n";
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
		#		    print "'$place' => '$mirror',\n";
		$mirrors{$place} = $mirror;
	    }
	}
    }
}

sub get_codes
{
    my ($scraped_info, $url) = @_;
    if ($verbose) {
	print "Getting $url\n";
    }
    my $html = get ($url);
    my @lines = split /\n/, $html;
    my $dictionaries = 0;
    my %dictionaries;
    my $codes = 0;
    my %codes;
    my $splitcodes = 0;
    my $firstline;
    for (@lines) {
	if (/Dictionary File Codes/) {
	    $dictionaries = 1;
	}
	if ($dictionaries) {
	    if (m!<TD>\s*<B>\s*([A-Z0-9]+)\s*</B>\s*</TD>\s*<TD>(.*)</TD>!i) {
		$dictionaries {$1} = $2;
	    }
	    $dictionaries = 0 if (/<\/table>/i);
	}
	if (/Part-of-Speech \(POS\) Codes|Miscellaneous Codes/) {
	    $codes = 1;
	}
	if ($codes) {
	    if (m!<TD><B>\s*(.*?)\s*</B></TD>\s*<TD>\s*(.*?)\s*</TD>!i) {
		add_code (\%codes, $1, $2);
	    }
	    $codes = 0 if (/<\/table>/i);
	}
	if (/Domain or Field Codes|Names Dictionary Codes/) {
	    $splitcodes = 1;
	}
	if ($splitcodes) {
	    $splitcodes = 0 if (/<\/table>/i);
	    if ($firstline) {
		if (m!<TD>\s*(.*?)\s*</TD>!) {
		    add_code (\%codes, $firstline, $1);
		}
		$firstline = 0;
	    }
	    elsif (m!<TD><B>\s*(.*?)\s*</B></TD>!) {
		$firstline = $1;
	    }
	}
	die "Parse error" if $dictionaries + $codes + $splitcodes > 1;
    }
    $scraped_info->{dictionaries} = \%dictionaries;
    $scraped_info->{codes} = \%codes;
}

sub add_code
{
    my ($codes, $code, $meaning) = @_;
    return if ($code eq uc $code && $meaning eq uc $meaning);
    return if ($code eq "-");
    if ($codes->{$code}) {
	print STDERR "Duplicate code for '$code'\n";
    }
    else {
	$codes->{$code} = $meaning;
    }
}
