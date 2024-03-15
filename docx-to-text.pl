#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

#+ handle options +#
our( $opt_a, $opt_b, $opt_c, $opt_d );
getopts('abc:d:');

$opt_a && print "option a\n";
$opt_b && print "option b\n";
$opt_c && print $opt_c . "\n";
$opt_d && print $opt_d . "\n";

#+ handle arguments +#
while( @ARGV ) {
  my $file = shift @ARGV;
  die "Bad file argument: $file\n" unless ( -e $file && $file =~ /\.docx$/ );
  extract_text( $file );
}

#+ subroutines +#
sub extract_text {
  my $file = shift @_;
  my $xml = `unzip -p "$file" word/document.xml`;
  my @paragraphs = ( $xml =~ m|<w:p [^>]+>(.+?)</w:p>|g );
  print Dumper( \@paragraphs );
};

1;