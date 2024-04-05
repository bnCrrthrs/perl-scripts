#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Tiny;
use Tie::File;

my $csv = shift @ARGV || 0;
unless ( $csv =~ m/\.(c|t)sv$/i && -e $csv) { die "Please supply valid csv\n" };

my $seperator = lc($1) eq 'c' ? ',' : "\t";

# get original contents and standardise \r and \n linebreaks with \n
# this was necessary so Tie::File could read the lines properly
# also has the effect of removing empty lines
open ( my $FH_IN, '<', $csv ) or die "Could not read from $csv\n"; 
my $content = do {
  local $/; <$FH_IN>;
};
close ($FH_IN);

$content =~ s/(?:\h*\v)+/\n/mg;

open ( my $FH_OUT, '>', $csv ) or die "Could not write to $csv\n";
print $FH_OUT $content;
close ($FH_OUT);


# The way to change the record separator is an additional arg: recsep => "\r"
# Loop over lines and add titles
tie my @array, 'Tie::File', $csv, or die "Can't open file";

my $records = @array;

$array[0] .= "${seperator}Success${seperator}Redirects${seperator}Title";

for ( my $i = 1; $i < $records; $i++ ) {
#  next unless $array[$i] =~ m{(https?://[^\s]+)};
  next unless $array[$i] =~ m{(https?://.+)\h*$}m;
  my $url = $1;
  my $response = HTTP::Tiny->new->get( $url );

  unless ( $response->{success} ) {
    $array[$i] .= "${seperator}FAIL: no response";
    next;
  }

  my $phrase = wrap($response->{ reason });
  my $redirected = wrap($response->{redirects} ? $response->{url} : "none");
  my $title = wrap(response_title( $response->{content} ) || "none");
  $array[$i] .= "${seperator}${phrase}${seperator}${redirected}${seperator}${title}";

}

untie @array;
print "Finished retrieving URL titles from $csv\n";

1;

sub wrap {
  return "\"$_[0]\"" ;
}

sub valid_url {
  return $_[0] =~ m{^"https?://}i;
};

sub response_title {
  if ( $_[0] =~ m{<title[^>]*>(.+)</title>}i ) {
    return $1;
  } else {
    return undef;
  }
}