package Boot;
use warnings;
use strict;
use Carp 'croak';
sub substitute
{
#    print join (" ",caller()),"\n";
    my ($module_info,$text) = @_;
    die "No text" unless $text;
    if ($module_info->{NODEPENDS}) {
	$text =~ s/\@IFDEPENDS\@.*?\@ENDIFDEPENDS\@//gs;
    } else {
	$text =~ s/\@(IFDEPENDS|ENDIFDEPENDS)\@//g;
    }
    while ($text =~ /(\@([A-Z]+)\@)/) {
	my $was = $1;
	my $will_be = $module_info->{$2};
	die "Unknown field $2" unless $will_be;
	die "Circular substitution" if $will_be =~ /(\@([A-Z]+)\@)/;
	$text =~ s/$was/$will_be/e;
    }
    return $text;
}
sub load_info
{
    my ($module_info) = @_;
    my $inputname;
    my $inputtext;
    while (<DATA>) {
	if (/\@START\s+(\w+)\@/) {
	    $inputtext = "";
	    $inputname = $1;
	} elsif (/\@END\s+(\w+)\@/) {
	    print "End of a data block '$1'\n" if $module_info->{chat};
	    die "No input name/no text" if !$inputname;
	    die "Bad input name" if $inputname ne $1;
	    $inputtext = substitute($module_info, $inputtext);
	    $module_info->{$inputname} = $inputtext;
	} else {
	    $inputtext .= $_;
	}
    }
}
sub get_version
{
    my ($module_info) = @_;
    my $version_file = "$module_info->{bootdir}/VERSION";
    die "No version file '$version_file'" unless -f $version_file;
    open my $input, "<", $version_file or die $!;
    my $version = <$input>;
    $version =~ s/\s+//g;
    die "Bad version string '$version'" unless $version =~ /^[\d.]+$/;
    close $input or die $!;
    $module_info->{VERSION} = $version;
}
sub read_readme
{
    my ($module_info) = @_;
    $module_info->{readme_in} = "$module_info->{bootdir}/README.in";
    my $readme_in = $module_info->{readme_in};
    die "Can't find '$readme_in'" unless -f $readme_in;
    open my $input, "<", $readme_in or die $!;
    while (<$input>) {
	my $nospaces = $_;
	$nospaces =~ s/^\s+|\s+$//;
	if ($nospaces =~ /(\w+):\s*(.*)$/) {
	    my $field = uc $1;
	    $module_info->{$field} = $2;
	} else {
	    last;
	}
    }
    close $input or die $!;
    die "No name" unless $module_info->{NAME};
}

sub get_dependencies
{
    my ($module_info) = @_;
    my $source = $module_info->{SOURCE};
    die unless $source;
    open my $source_in, "<", $source or die $!;
    my $depends;
    my @dependencies;
    while (<$source_in>) {
	if ($depends) {
	    if (/END\s+DEPENDS/) {
		$depends = undef;
		next;
	    }
	    if (/use\s+(.*);/) {
		my $dependency = $1;
		if ($dependency !~ /::/) {
		    die "Parse error";
		}
		push @dependencies, $dependency;
	    }
	} elsif (/DEPENDS/) {
	    die "Parse error" if ($depends);
	    $depends = 1;
	    next;
	}
    }
    close $source_in or die $!;
    if (@dependencies) {
	$module_info->{DEPENDENCIES} = join ("\n", @dependencies);
	$module_info->{USES} =
	    join (",\n", (map {"'$_' => '0'"} @dependencies));
    } else {
	$module_info->{NODEPENDS} = 1;
    }
}
# Make the lib/blah/blah directory

sub copy_to_lib
{
    my ($module_info) = @_;
    my $source = $module_info->{SOURCE};
    die unless $source;
    my $name = $module_info->{NAME};
    my $fullname = "lib/$name.pm";
    $fullname =~ s!::!/!g;
    _make_directories ($fullname);
    copy_substitute ($source, "$fullname", $module_info);
}

sub _make_directories
{
    my ($fullname) = @_;
    my @subdirs = split '/', $fullname;
    # Remove the final thing which isn't a directory.
    pop @subdirs;
    my $fulldir = ".";
    for my $dir (@subdirs) {
	$fulldir .= "/".$dir;
	unless (-d $fulldir) {
	    mkdir $fulldir or die $!;
	}
    }
}
sub copy_substitute
{
    my ($infile, $outfile, $info) = @_;
    croak "No input file" unless $infile;
    die "No info" unless $info;
    open my $input, "<:utf8", $infile or die "Can't open '$infile': $!";
    open my $output, ">:utf8", $outfile or die $!;
    my $ifdepends;
    my $pod;
    my $keeppod;
    while (my $line = <$input>) {
	if ($line =~ /\@IFDEPENDS\@/) {
	    if ($info->{NODEPENDS}) {
		$ifdepends = 1;
	    }
	    next;
	}
	if ($line =~ /\@ENDIFDEPENDS\@/) {
	    if ($ifdepends) {
		undef $ifdepends;
	    }
	    next;
	}
	next if $ifdepends;
	$line = Boot::substitute ($info, $line);
	if ($line =~ /package (\w+);/) {
	    print $output <<EOF;
package $info->{NAME};
our \$VERSION='$info->{VERSION}';
EOF
	    next;
	}
	next if $line =~ /^#/;
	if ($line =~ /__END__/) {
	    $keeppod = 1;
	}
	unless ($keeppod) {
	    if ($pod) {
		if ($line =~ /^=cut/) {
		    undef $pod;
		}
		next;
	    }
	    if ($line =~ /^=/) {
		die "POD error" if $line =~ /^=cut/;
		$pod = 1;
		next;
	    }
	}
	print $output $line;
    }
    close $input or die $!;
    close $output or die $!;
}
sub build_build
{
    my ($module_info) = @_;
    my $build_in = "$module_info->{bootdir}/Build.PL.in";
    Boot::copy_substitute ($build_in, "Build.PL", $module_info);
}
sub build_readme
{
    my ($module_info) = @_;
    Boot::copy_substitute ($module_info->{readme_in}, "README", $module_info);
}
sub build_manifest
{
    my ($module_info) = @_;
    open my $skip, ">", "MANIFEST.SKIP" or die $!;
    print $skip $module_info->{NODIST};
    close $skip or die $!;
}

sub _begin_end
{
    my ($hash, $filename, $begin_re, $end_re) = @_;
    open my $input, "<:utf8", $filename or die $!;
    my $inside;
    my $text;
    my $name;
    my @keys;
    while (my $line = <$input>) {
	if ($line =~ /$begin_re/) {
	    die "bad regex $begin_re" unless $1 && ! $2;
	    $name = $1;
	    push @keys, $name;
	    die "parse error" if $inside;
	    $inside = 1;
	    $text = "";
	    next;
	}
	if ($inside) {
	    if ($line =~ /$end_re/) {
		undef $inside;
		die "Parse error" unless $name;
		$hash->{$name} = $text;
		next;
	    } else {
		$text .= $line;
	    }
	}
    }
    $hash->{keys} = \@keys;
    close $input or die $!;
}

sub _code
{
    my ($example) = @_;
    return "<pre class='perl_code'>\n$example</pre>\n";
}

sub get_functions
{
    my $tests = "tests/test.pl";
    return unless -f $tests;
    my ($module_info) = @_;
    my $examples = {};
    _begin_end ($examples, $tests,
		qr/#\s*EXAMPLE\s+(\w+)/,
		qr/#\s*END\s+EXAMPLE/);
    my $functions = {};
    _begin_end ($functions, $module_info->{SOURCE},
		qr/=function\s+(\w+)/,
		qr/=cut/);
    $module_info->{functions} = $functions;
    my $synopsis = $examples->{SYNOPSIS};
    my $allfunctions = "";
    $allfunctions .= $synopsis ? _code ($synopsis) : "";
    $allfunctions .= "<h1>FUNCTIONS</h1>\n";
    for my $key (@{$functions->{keys}}) {
	my $func_doc = "\n<h2 name='#$key'>$key</h2>\n";
	my $example = $examples->{$key};
	if ($example) {
	    $func_doc .= _code ($example);
	}
	$func_doc .= "$functions->{$key}";
	$allfunctions .= $func_doc;
    }
    $module_info->{PODTOP} .= $allfunctions;
}

sub module_info
{
    my ($name) = @_;
    die "No name" unless $name;
    die "Can't find file '$name'" unless -f $name;
    my $module_info = {};
#    $module_info->{chat} = 1;
    $module_info->{bootdir} = "./boot";
    $module_info->{SOURCE} = $name;
    my $package = $name;
    $package =~ s/\.pm$// or die "No .pm on name '$name'";
    $module_info->{package} = $package;
    print "Reading readme\n" if $module_info->{chat};
    Boot::read_readme ($module_info);
    print "Getting version\n" if $module_info->{chat};
    Boot::get_version ($module_info);
    print "Getting dependencies\n" if $module_info->{chat};
    Boot::get_dependencies($module_info);
    print "Loading info from the end of this file\n" if $module_info->{chat};
    Boot::load_info ($module_info);
    print "Building build script\n" if $module_info->{chat};
    Boot::build_build ($module_info);
    Boot::get_functions ($module_info);
    Boot::copy_to_lib ($module_info);
    Boot::build_readme ($module_info);
    Boot::build_manifest ($module_info);
}

our @crap = qw/
*.tmp
README
_build
blib
Build.PL
Build
lib
build.log
MANIFEST*
META.yml
*.tar.gz
/;

1;

__DATA__

Stuff which we will not include in the distributed version of the module:

@START README@
INSTALLING THIS MODULE

To install the module on your system, run the script "Build.PL" using
Perl,

    perl Build.PL

then type

    ./Build
    ./Build test
    ./Build install

to complete the installation. You need to have the Perl module
"Module::Build" already installed. To obtain "Module::Build", use the
"cpan" command provided with Perl as follows:

    cpan Module::Build

@IFDEPENDS@

@NAME@ also depends on the following modules, available via CPAN:

@DEPENDENCIES@

You can obtain these from the internet using the "cpan" command plus
the name of the module.

@ENDIFDEPENDS@

USING THIS MODULE

To use this module, please follow the instructions given in the module
itself, which can be accessed using

    perldoc @NAME@
@END README@

Stuff which we will not include in the distributed version of the module:

@START NODIST@
^@SOURCE@
^blib
.*\.tmp
build.log
boot\/.*
\.~\d+~
_build\/.*
MANIFEST.bak
MANIFEST.SKIP
MANIFEST
^backup
^tests
.*\.txt
^Build$
@END NODIST@

@START PODTOP@
<head>
<meta charset="UTF-8">
</head>
<h1>NAME</h1>

@NAME@: @DESCRIPTION@

<h1>SYNOPSIS</h1>
@END PODTOP@

@START PODEND@
<h1>COPYRIGHT</h1>

Copyright 2009 @AUTHOR@

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
@END PODEND@

__END__

