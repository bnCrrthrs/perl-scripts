#!/usr/bin/env perl


#+ PRAGMAS +#

use strict;
use warnings;
use Getopt::Std;
use HTTP::Tiny;
use Data::Dumper;


#+ GLOBAL VARIABLES +#

# scalars
my $url = "https://www.theguardian.com/uk";
my $response = HTTP::Tiny->new->get( $url );
my $counter = 1;

die "No response from Guardian\n" unless $response->{success};
die "Couldn't find section" unless $response->{content} =~ m{<section.+data-link-name="most-viewed"[^>]+>(.+?)</section};

my @items = $1 =~ m{<li[^>]+>(.+?)</li>}g;

foreach( @items ) {
  $_ =~ m{<span>(.+)</span>} && print ($counter++, " - ", $1, "\n" );
}

# print Dumper(\@items);

exit 0;
