#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Perl::Build qw/get_info get_commit/;
use Perl::Build::Pod ':all';
use BKB::Stuff;
use JSON::Parse ':all';

make_examples ("$Bin/examples", undef, undef);

# Template toolkit variable holder

my %vars;
my $tt = Template->new (
    ABSOLUTE => 1,
    FILTERS => {
        xtidy => [
            \& xtidy,
            0,
        ],
    },
    INCLUDE_PATH => [
	$Bin,
	"$Bin/examples",
	pbtmpl (),
    ],
    STRICT => 1,
);
my $info = get_info ();
$vars{info} = $info;
$vars{commit} = get_commit ();
my $json = "$Bin/lib/WWW/WWWJDIC.json";
die "no $json" unless -f $json;
my $wwwjdicinfo = json_file_to_perl ($json);
$vars{wwwjdicinfo} = $wwwjdicinfo;
my $pod = $info->{pod};
chmod 0644, $pod;
$tt->process ("$pod.tmpl", \%vars, $pod) or die '' . $tt->error ();
chmod 0444, $pod;
exit;
