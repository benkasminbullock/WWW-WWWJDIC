#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use lib '/home/ben/projects/perl-build/lib';
use Perl::Build;
perl_build (
    make_pod => './make-pod.pl',
    clean => './clean.pl',
);
