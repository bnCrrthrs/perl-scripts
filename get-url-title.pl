#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
use HTTP::Tiny;

use Data::Dumper;


#+ handle options +#
our( $opt_h, $opt_l );
getopts('hl');

if ($opt_h) {
  help_fn();
  exit 0;
}

#+ MAIN +#

foreach my $input (@ARGV) {
  unless ( valid_url($input) ) { 
    print "Invalid url: $input\n";
    next;
  }

  my $slug = slugify( $input );
  my $response = HTTP::Tiny->new->get( $input );
  # die "Failed!\n" unless $response->{success};

  unless ( $response->{success} ) {
    print "Request failed: $input\n";
    next;
  }

  # my $content = $response->{content};
  my $redirected = $response->{redirects} ? $response->{url} : "none";
  my $title = response_title( $response->{content} ) || "none";

  if ($opt_l) {
    print "$slug\nRedirected to: $redirected\nTitle: $title\n";
  } else {
    print "$title\n";
  }

  # print $response->{ content };
  # print "$response->{ success } \n"; # response code is 2XX
  # print "$response->{ url } \n"; # final URL after redirections (or original if none)
  # print "$response->{ status } \n"; # status code of response
  # print "$response->{ reason } \n"; # response phrase returned
  # my $headerRef = $response->{ headers };
  # my $redirectsRef = $response->{ redirects };
  # print $redirectsRef ? "Redirected\n" : "OK\n";
  # print Dumper( $redirectsRef ); # headers
}

# extracts titles from supplied urls using curl

# foreach my $input (@ARGV) {
#  unless (valid_url($input)) { next };
#   my $slug = slugify($input);
#   my $response = `curl --location --include --fail --globoff --silent --max-time 10 $input`;
#   my $code = response_code($response);
#   my $title = $code ? response_title($response) : "";
#   print "$slug CODE: $code TITLE: $title\n";
# }

1;

sub valid_url {
  return $_[0] =~ m{^https?://}i;
};

sub slugify {
  my $slug = lc $_[0];
  $slug =~ s/^https?:\/\/(?:www\.)?//;
  $slug =~ s/\/.*//;
  $slug =~ s/[^\w\.]/_/;
  return $slug;
}

sub response_code {
  if ( $_[0] =~ /^\S+\s(\d+)/ ) {
    return $1;
  } else {
    return undef;
  }
}

sub response_title {
  if ( $_[0] =~ m{<title[^>]*>(.+)</title>}i ) {
    return $1;
  } else {
    return undef;
  }
}

sub help_fn {
  print "\nget-url-title.pl\n", "================\n";
  print "    Takes one or more URLs as arguments and retrieves their titles.\n\n";
  print "    Options:\n--------\n";
  print "        -h) Prints this help menu and exits.\n";
  print "        -l) Print slug and redirect info for each URL.\n";
  print "\n";
}
