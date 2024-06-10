#!/usr/bin/env perl


#+ PRAGMAS +#

use strict;
use warnings;
use Getopt::Std;
use HTTP::Tiny;
# use Browser::Open qw( open_browser );
use Data::Dumper;


#+ GLOBAL VARIABLES +#

# scalars
my $url = "https://www.theguardian.com";
my $response = HTTP::Tiny->new->get( $url . "/uk" );
my $counter = 1;

die "No response from Guardian\n" unless $response->{success};
die "Couldn't find section" unless $response->{content} =~ m{<section.+data-link-name="most-viewed"[^>]+>(.+?)</section};

my @raw_items = $1 =~ m{<li[^>]+>(.+?)</li>}g;
my @hashes = ();

foreach( @raw_items ) {
  next unless $_ =~ m{href=["']([^"']+).*<span>(.+)</span>};
  my %hash = (
    url => $url . $1,
    headline => $2,
    num => $counter++,
  );
  print($hash{num}, " - ", $hash{headline}, "\n");
  push(@hashes, \%hash);
}

print ("\nEnter a number to read an article... ");
my $input = <>;
chomp($input);
exit 0 unless $input =~ m{^([1-9]|10)\s*$};
foreach ( @hashes ) {
  next unless $_->{num} == $input;
  `open $_->{url}`;
  print ("Opening ", $_->{url}, "\n");
}

exit 0;
