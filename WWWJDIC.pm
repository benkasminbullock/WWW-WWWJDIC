package WWW::WWWJDIC;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/get_mirrors/;
use warnings;
use strict;
our $VERSION = '0.001';
# to encode the results returned:
use Encode qw/encode decode/;
# need utf8 characters like 【 and 】 here
use utf8;
# DEPENDS
# to get the web page:
use LWP::UserAgent;
# to parse the HTML returned:
use HTML::TreeBuilder;
# to encode our search string in the % form for WWW transfer:
use URI::Escape;
# END DEPENDS

# Mirror sites of WWWJDIC.

# SCRAPE MIRRORS
my %mirrors = (
'australia' => 'http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi',
'canada' => 'http://ryouko.imsb.nrc.ca/cgi-bin/wwwjdic',
'eu' => 'http://jp.celltica.com/cgi-bin/wwwjdic',
'japan' => 'http://www.aa.tufs.ac.jp/~jwb/cgi-bin/wwwjdic.cgi',
'sweden' => 'http://wwwjdic.se/cgi-bin/wwwjdic.cgi',
'usa' => 'http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic',
);
# END SCRAPE

# Dictionaries available.

# SCRAPE DICTIONARIES
my %dictionaries = (
'AV' => 'aviation ',
'BU' => 'buddhdic',
'CA' => 'cardic',
'CC' => 'concrete',
'CO' => 'compdic',
'ED' => 'edict (the rest)',
'EP' => 'edict (priority subset)',
'ES' => 'engscidic',
'EV' => 'envgloss',
'FM' => 'finmktdic',
'FO' => 'forsdic_e',
'GE' => 'geodic ',
'KD' => 'small hiragana dictionary for glossing ',
'LG' => 'lingdic',
'LS' => 'lifscidic',
'MA' => 'manufdic',
'NA' => 'enamdict',
'PL' => 'j_places (entries not already in enamdict)',
'PP' => 'pandpdic ',
'RH' => 'revhenkan (kanji/kana with no English translation yet)',
'RW' => 'riverwater',
'SP' => 'special words &amp; phrases',
'ST' => 'stardict',
);
# END SCRAPE

# SCRAPE CODES
my %codes = (
'Buddh' => 'Buddhism',
'MA' => 'martial arts',
'P' => '"Priority" entry, i.e. among approx. 20,000 words deemed to be common in Japanese',
'X' => 'rude or X-rated term (not displayed in educational software)',
'abbr' => 'abbreviation',
'adj-f' => 'noun, verb, etc. acting prenominally (incl. rentaikei)',
'adj-i' => 'adjective (keiyoushi)',
'adj-na' => 'adjectival nouns or quasi-adjectives (keiyoudoushi)',
'adj-no' => 'nouns which may take the genitive case particle "no"',
'adj-pn' => 'pre-noun adjectival (rentaishi)',
'adj-t' => '"taru" adjective',
'adv' => 'adverb (fukushi)',
'adv-to' => 'adverb (with particle "to")',
'arch' => 'archaism',
'ateji' => 'kanji used as phonetic symbol(s)',
'aux' => 'auxiliary',
'aux-v' => 'auxiliary verb',
'c' => 'company name',
'chn' => 'children\'s language',
'col' => 'colloquialism',
'comp' => 'computing/telecommunications',
'conj' => 'conjunction',
'ctr' => 'counter',
'exp' => 'Expressions (phrases, clauses, etc.)',
'f' => 'female given name',
'fam' => 'familiar language',
'fem' => 'female term or language',
'food' => 'food',
'g' => 'given name, as-yet not classified by sex',
'geom' => 'geometry',
'gikun' => 'gikun (meaning) reading',
'h' => 'a full (family plus given) name of a historical person',
'hon' => 'honorific or respectful (sonkeigo) language',
'hum' => 'humble (kenjougo) language',
'iK' => 'word containing irregular kanji usage',
'id' => 'idiomatic expression',
'ik' => 'word containing irregular kana usage',
'int' => 'interjection (kandoushi)',
'io' => 'irregular okurigana usage',
'ling' => 'linguistics',
'm' => 'male given name',
'm-sl' => 'manga slang',
'male' => 'male term or language',
'math' => 'mathematics',
'mil' => 'military',
'n' => 'noun (common) (futsuumeishi)',
'n-adv' => 'adverbial noun (fukushitekimeishi)',
'n-t' => 'noun (temporal) (jisoumeishi)',
'o' => 'organization name',
'oK' => 'word containing out-dated kanji',
'obs' => 'obsolete term',
'obsc' => 'obscure term',
'ok' => 'out-dated or obsolete kana usage',
'on-mim' => 'onomatopoeic or mimetic word',
'p' => 'place-name',
'physics' => 'physics',
'pn' => 'pronoun',
'pol' => 'polite (teineigo) language',
'pr' => 'product name',
'pref' => 'prefix',
'prt' => 'particle',
's' => 'surname',
'sens' => 'term with some sensitivity about its usage',
'sl' => 'slang',
'st' => 'station name',
'suf' => 'suffix',
'u' => 'person name, as-yet unclassified',
'uK' => 'word usually written using kanji alone',
'uk' => 'word usually written using kana alone',
'v1' => 'Ichidan verb',
'v5' => 'Godan verb (not completely classified)',
'v5aru' => 'Godan verb - -aru special class',
'v5k-s' => 'Godan verb - Iku/Yuku special class',
'v5u, v5k, etc.' => 'Godan verb with `u\', `ku\', etc. endings',
'vi' => 'intransitive verb',
'vk' => 'Kuru verb - special class',
'vs' => 'noun or participle which takes the aux. verb suru',
'vs-s' => 'suru verb - special class',
'vt' => 'transitive verb',
'vulg' => 'vulgar expression or word',
'vz' => 'Ichidan verb - -zuru special class (alternative form of -jiru verbs)',
);
# END SCRAPE

sub get_mirrors
{
    return %mirrors;
}

sub new
{
    my %options = @_;
    my $wwwjdic = {};
    if ($options{mirror}) {
	my $mirror = lc $options{mirror};
	if ($mirrors{$mirror}) {
	    $wwwjdic->{site} = $mirrors{$mirror};
	} else {
	    print STDERR __PACKAGE__,
		": unknown mirror '$options{mirror}': using Australian site\n";
	}
    } else {
	$wwwjdic->{site} = $mirrors{australia};
    }
    $wwwjdic->{user_agent} = LWP::UserAgent->new;
    $wwwjdic->{user_agent}->agent(__PACKAGE__);
    bless $wwwjdic;
    return $wwwjdic;
}

binmode STDOUT,":utf8";

# Parse a page of results from WWWJDIC

sub parse_results
{
    my ($wwwjdic, $contents) = @_;
    $contents = decode ('utf8', $contents);
#    print $contents;
    my $tree = HTML::TreeBuilder->new();
    $tree->parse ($contents);

    my @labels = $tree->look_down ('_tag', 'label');
    my @inputs = $tree->look_down ('_tag', 'input');
    my %fors;
    my @valid;
    for my $input (@inputs) {
	if ($input->attr('name') && $input->attr('name') eq 'jukugosel' 
	    && $input->attr('id')) {
	    $fors{$input->attr('id')} = $input;
	}
    }
    @valid = grep {$fors{$_->attr('for')}} @labels;
    for my $line (@valid) {
	my %results;
	$results{wwwjdic_id} = $line->attr('id');
	my $text = $line->as_text;
	print $text,"\n";
	$results{text} = $text;
	if ($text =~ /^(.*?)\s*【\s*(.*?)\s*】\s*(.*?)\s*$/) {
	    $results{kanji} = $1;
	    $results{reading} = $2;
	    $results{meaning} = $3;
#	    print "$results{kanji}, $results{reading}, $results{meaning}\n";
	} elsif ($text =~ /(.*?)  (.*)$/) {
	    $results{reading} = $1;
	    $results{meaning} = $2;
	} else {
	    print "Unreadable line '$text'\n";
	}
	# Get the dictionary from the end of the string.
	if ($results{meaning}) {
#	    print "$results{meaning}\n";
#	    if ($results{meaning} =~ /([A-Z]{2}[12]?)\s*$/s) {
	    if ($results{meaning} =~ /(.*)\s*([A-Z]{2}[12]?)\s*$/s) {
		$results{meaning} = $1;
		$results{dictionary} = $2;
#		print "$results{meaning}\n";
# 		if (!$dictionaries{$results{dictionary}}) {
# 		    print "Unknown dictionary '$results{dictionary}'\n";
# 		} else {
# 		    print "Dictionary: ", $2, ": ",
# 			$dictionaries{$results{dictionary}},"\n";
# 		}
	    }
	}
    }
}

sub lookup_url
{
    my ($wwwjdic, $search_key, $search_type) = @_;
    my %type;
    for (@$search_type) {
	$type{max} = $_ if /^\d+$/;
    }
    my $url = $wwwjdic->{site}; # Start off with the site.
    # N = all the dictionaries.
    # M = backdoor entry.
    # search type = U: UTF-8 lookup
    $url .= "?NMUJ";
    my $search_key_encoded = URI::Escape::uri_escape_utf8 ($search_key);
    $url .= $search_key_encoded;
    # This means UTF-8 encoding. I don't think this is documented
    # anywhere.
    $url .= "_3";
    # Maximum number of results to return.
    $url .= '_' . $type{max} if $type{max};
    return $url;
}

# Look up a word or phrase ($search_key) in WWWJDIC.

# The Japanese text in $search_key needs to be in Perl's internal
# encoding.

# $wwwjdic is the object used to look things up.

# $search_key is the search key used.

# $search_type is a hash reference which contains options for the
# search.

# dictionaries to look at


# positive integer - the maximum number of results returned
# exact - get an exact match
# start - get a starting match
# any   - get any (substring) match
# common - only look at common words ("(P)" in the WWWJDIC documentation)
# 
# The return value is a reference to an array of hashes, one for each
# successful entry returned.
#
# The hashes have the following fields

# match - term which matched the string
# reading - kana reading of whatever matched
# dictionary - abbreviated name of the dictionary where it was found
# meaning - string containing meanings of the term
# wwwjdic_id - id number of WWWJDIC.
# text - full text returned by the search
# wikipedia - Wikipedia entry with the title of this word
# jekai - jeKai entry with the title of this word

sub lookup
{
    my ($wwwjdic, $search_key, $search_type) = @_;
    my $search_string = $wwwjdic->lookup_url ($search_key, $search_type);
    return if !$search_string;
    my $response = $wwwjdic->{user_agent}->get ($search_string);
    if ($response->is_success) {
	return $wwwjdic->parse_results ($response->content);
    }
}

sub lookup_kanji
{
    my ($wwwjdic, $search_key, $search_type) = @_;
    my $search_string = $wwwjdic->lookup_url ($search_key, $search_type);

}

1;

__END__

@PODTOP@

=head1 METHODS

=head2 new

    my $wwwjdic = @NAME@::new(mirror => "japan")

Create the object which extracts the information from WWWJDIC. Arguments:

mirror: Mirror site. This can take the values @SCRAPE MIRROR NAMES@.

=head2 lookup_url

    my $url = $wwwjdic->lookup_url ($key, $search_type);

For example,

    my $wwwjdic = @NAME@->new();
    $wwwjdic->lookup_url ("日本");

returns a value C<http://>

Make a lookup url (the "backdoor URL") which links to a WWWJDIC page.

=head2 lookup

Look up a word in WWWJDIC.

=head2 parse_results

    $html = <contents of WWWJDIC page>;
    my $results = $wwwjdic->parse_results ($html);
    

=head1 BUGS

The module relies on the structure of the WWWJDIC reply page, which
seems to change every few months.

@PODEND@
