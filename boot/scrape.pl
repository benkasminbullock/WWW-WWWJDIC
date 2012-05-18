#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use LWP::Simple;
my $source = "WWWJDIC.pm";
die "no $source" unless -f $source;
my %scraped_info;
my $toppage = "http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?1C";
my $docpage = "http://www.csse.monash.edu.au/~jwb/wwwjdicinf.html";
get_mirrors(\%scraped_info, $toppage);
get_codes(\%scraped_info, $docpage);
my $destination = "$source.backup";
replace_scrapes ($source, $destination, \%scraped_info);
my $backup = "backup/$source";
backupfile ($backup);
rename $source, "backup/$source" or die $!;
rename $destination, $source or die $!;
exit (0);

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
	    } else {
		die "No scraped information for '$name'";
	    }
	}
	if ($outputting) {
	    if (/\#\s*END\s+SCRAPE/) {
		$outputting = 0;
	    } else {
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
#	print;
	if (/Dictionary:/ && /<select/i) {
#	    print "Found options\n";
	    $options = 1;
	}
	if ($options) {
	    if (/<\s*option.*value\s*=\s*"([0-9A-Z])"\s*>\s*(.*)/i) {
		$options {$1} = $2;
#		print "Value $1 dictionary '$2'\n";
	    }
	    $options = undef if (/<\/select>/);
	}
	$mirrors = 1 if /Mirror Sites:/i;
	if ($mirrors) {
	    $mirrors = undef if (/<\/td>/);
	    if (/<a\s+href="(.*)">(.*)<\/a>/i) {
#		print "Mirror in '$2' at '$1'\n";
		my $mirror = $1;
		my $place = lc $2;
		$mirror =~ s/\?1C//;
		$mirrors{$place} = $mirror;
	    }
	}
    }
    $scraped_info->{mirrors} = \%mirrors;
    $scraped_info->{options} = \%options;
}

sub get_codes
{
    my ($scraped_info, $url) = @_;
    my $html = get ($url);
    my @lines = split /\n/, $html;
    my $dictionaries = 0;
    my %dictionaries;
    my $codes = 0;
    my %codes;
    my $splitcodes = 0;
    my $firstline;
    for (@lines) {
#	print;
	if (/Dictionary File Codes/) {
#	    print "Found dictionaries\n";
	    $dictionaries = 1;
	}
	if ($dictionaries) {
	    if (m!<TD>\s*<B>\s*([A-Z0-9]+)\s*</B>\s*</TD>\s*<TD>(.*)</TD>!i) {
		$dictionaries {$1} = $2;
#		print "Dictionary code $1 dictionary '$2'\n";
	    }
	    $dictionaries = 0 if (/<\/table>/i);
	}
	if (/Part-of-Speech \(POS\) Codes|Miscellaneous Codes/) {
	    $codes = 1;
	}
	if ($codes) {
	    if (m!<TD><B>\s*(.*?)\s*</B></TD>\s*<TD>\s*(.*?)\s*</TD>!i) {
		add_code (\%codes, $1, $2);
#		print "Abbreviation: '$1' = '$2'\n";
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
#		    print "Abbreviation: '$firstline' = '$1'\n";
		}
		$firstline = 0;
	    } elsif (m!<TD><B>\s*(.*?)\s*</B></TD>!) {
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
    } else {
	$codes->{$code} = $meaning;
    }
}
sub backupfile
{
    my ($hfile) = @_;
    if (-f $hfile) {
        my @hfiles = <$hfile.~*~>;
        my $newest = 0;
        for my $backup (@hfiles) {
            if ($backup =~ /^$hfile.~(\d+)~$/) {
                my $number = $1;
                if ($number > $newest) {
                    $newest = $number;
                }
            }
        }
        $newest++;
        my $backupfilename = "$hfile.~$newest~";
        if ( -f  $backupfilename) {
            print STDERR "Bug in backup maker";
            exit (1);
        } else {
            rename $hfile, $backupfilename or die $!;
        }
    }
}
