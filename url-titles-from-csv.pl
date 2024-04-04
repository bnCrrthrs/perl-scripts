#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Tiny;
use Tie::File;

my $tsv = shift @ARGV || 0;
unless ( $tsv =~ m/\.tsv$/ && -e $tsv) { die "Please supply valid tsv\n" }; 

# open (my $fh, "<", $tsv);
# my @lines = ();

# while ( my $line = readline($fh) ) {
#   print "$line\n";
#   print "==============\n"
#   # my ($page, $content, $destination) = ( $line =~ m{"(.*?)"}g );
#   # print "PAGE: $page\n";
#   # print "CONTENT: $content\n";
#   # print "DESTINATION: $destination\n";
# }

# close ($fh);

# exit;



print "Processing $tsv\n";

tie my @array, 'Tie::File', $tsv, recsep => "\r" or die "Can't open file";

my $records = @array;
# print "$records\n";
$array[0] = "Page\tContent\tDestination\tSuccess\tRedirects\tTitle"; #TODO Can't append to line without adding new line :(

for (my $i = 1; $i < $records; $i++) {
  # print $array[$i];
  # my ($page, $content, $destination) = ( $array[$i] =~ m/(".*?")/g );
  my ($page, $content, $destination) = split( "\t", $array[$i] );

  unless ( $destination =~ m{^"(https?://.+)"$} ) {
    $array[$i] = join(",", $page, $content, $destination, "FAIL: invalid url");
    next;
  }

  my $url = $1;

  my $response = HTTP::Tiny->new->get( $url );

  unless ( $response->{success} ) {
    $array[$i] = join(",", $page, $content, $destination, "FAIL: no response");
    next;
  }

  my $phrase = wrap($response->{ reason });
  my $redirected = wrap($response->{redirects} ? $response->{url} : "none");
  my $title = wrap(response_title( $response->{content} ) || "none");
  my $newline = join("\t", $page, $content, $destination, $phrase, $redirected, $title );
  # print "$newline\n";

  $array[$i] = $newline;
#  $array[$i] = "$page,$content,$destination,$phrase,$redirected,$title";

}
# ( $xml =~ m|<w:p [^>]+>.+?</w:p>|g );



# open (my $fh, "<", $tsv ) or die "Can't open tsv... maybe check permissions?\n";

# my $headers = <$fh>;

# while ( my $line = <$fh> ) {
#   chomp $line; #remove's \n from line
#   my @fields = ();
#   while 
# }
untie @array;
print "Complete\n";
exit;

sub wrap {
  return "\"$_[0]\"" ;
}





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

  print "$slug\nRedirected to: $redirected\nTitle: $title\n"

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
  return $_[0] =~ m{^"https?://}i;
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