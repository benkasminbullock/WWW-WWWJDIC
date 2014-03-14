use warnings;
use strict;
use ExtUtils::MakeMaker;
my $pm = 'lib/WWW/WWWJDIC.pm';

WriteMakefile (
    NAME => 'WWW::WWWJDIC',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    LICENSE => 'perl',
    PREREQ_PM => {
	'LWP::UserAgent' => '0',
	'HTML::TreeBuilder' => '0',
	'URI::Escape' => '0',
    },
);

