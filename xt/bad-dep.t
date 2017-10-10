use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Perl::Build 'get_info';
use Perl::Build::Dist qw/bad_modules depend/;
use Perl::Build::Pod 'get_dep_section';
use JSON::Parse 'json_file_to_perl';

my $info = get_info (base => "$Bin/..");

my $pm = "$info->{base}/$info->{pm}";
my $pod = "$info->{base}/$info->{pod}";
my $metajson = "$info->{base}/MYMETA.json";
my $meta;
if (-f $metajson) {
    $meta = json_file_to_perl ($metajson);
}
else {
    die "No $metajson";
}
my @modules = depend ($pm);

my %req = %{$meta->{prereqs}{runtime}{requires}};

SKIP: {
    if (! @modules) {
	skip "No dependencies", 2;
    }
    my @bad = bad_modules (\@modules);
    ok (! @bad, "no bad modules used");
    if (@bad) {
	for (@bad) {
	    note ("Bad module $_");
	}
    }
    my $deps = get_dep_section ($pod);
    ok ($deps, "has dependencies section");
    if ($deps) {
	for my $m (@modules) {
	    like ($deps, qr!L<\Q$m\E(?:/.*)?>!, "Documented dependence on $m");
	    ok ($req{$m}, "$m is in PREREQ_PM");
	}
    }
    my %modules;
    @modules{@modules} = (1) x @modules;
    for my $k (keys %req) {
	if ($k =~ /^(perl)$/) {
	    next;
	}
	ok ($modules{$k}, "$k is in the modules list");
    }
};


done_testing ();
