#!/usr/bin/env perl

use strict;
use warnings;

foreach my $input (@ARGV) {
 unless (valid_url($input)) { next };
  my $slug = slugify($input);
  my $response = `curl --location --include --fail --globoff --silent --max-time 10 $input`;
  my $code = response_code($response);
  my $title = $code ? response_title($response) : "";
  print "$slug CODE: $code TITLE: $title\n";
}

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