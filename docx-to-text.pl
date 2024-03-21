#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

#+ handle options +#
our( $opt_h, $opt_E, $opt_F, $opt_G, $opt_H, $opt_K, $opt_N, $opt_s, $opt_c, $opt_d );
getopts('hEFHKNs:c:d:');

if ($opt_h) {
  help_fn();
  exit 1;
}

my $linebreak;
if ( $opt_s && $opt_s =~ m/^\d+$/ && $opt_s > 0 && $opt_s < 21 ) {
  $linebreak = "\n" x $opt_s;
} else {
  $linebreak = "\n" x 2;
  $opt_s && warn "Invalid argument: -s value must be integer between 1 and 20.\nDefault value of 2 has been used.\n";
}
# my $linebreak = "\n" x ($opt_s && $opt_s > 0 ? $opt_s : 2);


#+ handle arguments +#
while( @ARGV ) {
  my $file = shift @ARGV;
  die "Bad file argument: $file\n" unless ( -e $file && $file =~ /\.docx$/ );
  my $full_text = get_full_text( $file );
  my $final = replace_special_chars( $full_text );

  print $final;

#  print Dumper( \@para_strings );
  # print Dumper( \@para_hashes );

}

#* MAIN *#

sub get_full_text {
  my $file = shift;
  my $xml = extract_text ( $file, "word/document.xml", "1" );
  my $footnote_xml = extract_text ( $file, "word/footnotes.xml", "0" ) unless $opt_F; #? status: untested
  my $endnote_xml = extract_text ( $file, "word/endnotes.xml", "0" ) unless $opt_E; #? status: untested
  
  my @para_strings = ( $xml =~ m|<w:p [^>]+>.+?</w:p>|g );
  my $refto_array_of_footnotes = (get_footnote_array( $footnote_xml ));
  my @arr_of_para_hashes = map( make_para_hash($_, $refto_array_of_footnotes ), @para_strings );

  my @array_of_endnotes = get_endnotes_array($endnote_xml) unless $opt_E;

  my $output = "";

  foreach my $para (@arr_of_para_hashes) {
    $output .= "$para->{text}$linebreak";
    my $footnote_refs = $para->{footnotes};
    for my $footnote_ref (@{$footnote_refs}) { 
      $output .= "$footnote_ref$linebreak";
    }
  }

  unless ( $opt_E ) {
    foreach my $endnote (@array_of_endnotes) {
      $output .= "$endnote$linebreak";
    }
  }

  return $output;
}


#+ subroutines +#


sub make_para_hash {
  #? TODO ADD LIST LEVEL
  my ( $string, $all_footnotes_ref ) = @_ ;
  my $footnote_indexes = [];
  my $heading_level = $string =~ m~<w:pStyle w:val="Heading(\d+)~ ? $1 : 0;
  $string =~ s~<w:br/>~<w:t>{& LINE BREAK &}</w:t>~g unless $opt_N;   # add line breaks #! FIX
  unless ($opt_F) { $string =~ s~<w:footnoteReference w:id="(\d+)"/>~add_footnote_ref($1, $footnote_indexes)~ge };   # add footnote refs
  unless ($opt_E) { $string =~ s~<w:endnoteReference w:id="(\d+)"/>~<w:t>[Endnote ref $1]</w:t>~g };   # add endnote refs
  $string =~ s~<pic:[^>]+descr="([^"]*)"[^>]*>~<w:t>[Image: $1]</w:t>~g;   # add alt text
  my $actual_text = ( extract_actual_text($string) );
  my @footnote_content = map( get_footnote_content($_, $all_footnotes_ref), @{$footnote_indexes} );

  my %para_hash = (
    text => $actual_text,
    heading_level => $heading_level,
    footnotes => \@footnote_content,
  );
  return \%para_hash;

}

sub replace_special_chars {
  my $str = shift;
  $str =~ s|{& LINE BREAK &}|\n|g;
  $str =~ s|&lt;|<|g;
  $str =~ s|&gt;|>|g;
  $str =~ s|&amp;|&|g;
  return $str;
}

sub get_footnote_array {
  if ($opt_F) { return };
  my $footnote_xml = shift;
  my @footnotes = ( $footnote_xml =~ m|(<w:footnote [^>]*w:id="\d+".+?</w:footnote>)|g );
  my @footnote_content = map( extract_actual_text($_), @footnotes );
  # my $reference = \@footnotes;
  # return $reference;
  return \@footnote_content;
}

sub get_endnotes_array {
  my $endnote_xml = shift;
  my @endnotes = $endnote_xml =~ m|(<w:endnote [^>]*w:id="\d+".+?</w:endnote>)|g; 
  my @endnote_content = map( extract_actual_endnote_text($_), @endnotes );
  return @endnote_content;
}

sub extract_actual_text {
  my $xml = shift;
  my @text = ( $xml =~ m~<w:t(?: [^>]+)?>(.+?)</w:t>~g );
  my $string = join( "", @text );
  return $string;
}

sub extract_actual_endnote_text {
  my $xml = shift;
  my $id = ($xml =~ m/w:id="(\d+)"/) ? $1 : 0;
  unless ( $id > 0 ) { return "" };
  my $content = extract_actual_text($xml);
  return "[Endnote $id: $content]";
}

sub get_footnote_content {
  my ( $footnote_index, $footnotes ) = @_;
  my $content = @{$footnotes}[$footnote_index];
  my $actual = "[Footnote $footnote_index:$content]";
  return $actual;
}

sub add_footnote_ref {
  my ( $ref, $footnote_a_ref ) = @_;
  push(@{$footnote_a_ref}, $ref);
  return "<w:t>[Footnote ref $ref]</w:t>";
}

sub extract_text {
  my ( $zip, $zipped, $required ) = @_;
  my $result = `unzip -p "$zip" "$zipped" 2> /dev/null`;
  if (${^CHILD_ERROR_NATIVE} && $required) { die  "Could not extract $zipped from $zip" };
  return $result;
};

sub help_fn {
  print "\ndocx-to-txt.pl\n", "==============\n", "Converts docx files to text and prints the contents.\n\n";
  print "Options:\n--------\n";
  print "-h) Prints this help menu.\n";
  print "-E) Excludes endnotes from the output. (todo)\n-";
  print "-F) Excludes footnotes from the output. (todo)\n";
  print "-G) Excludes the alt-text from graphics from the output. (todo)\n";
  print "-H) Doesn't style headings in the output. (todo)\n";
  print "-K) Excludes hyperlinks from the output. (todo)\n";
  print "-N) Ignores line breaks within characters (Puts all characters on a single line).\n";
  print "-s) Requires integer argument, determining the number of linebreaks used\n    to separate paragraphs. Default is 2, max is 20";
  print "\n\n";
}

# q {
# HEADER / FOOTER => ultimately just in <w:t>header</w:t> tags
#                 => ./word/header1.xml
#                 => ./word/footer1.xml
#                         But more than 1 is possible for each doc!
# HEADINGS => <w:p w14:paraId="668156E0" w14:textId="7BD575FF" w:rsidR="00A61A63" w:rsidRDefault="00225D12" w:rsidP="00225D12"><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Simple word document</w:t></w:r></w:p>
# LINE BREAKS => <w:br/>
# TEXT => <w:t xml:space="preserve">text</w:t> || <w:t>text</w:t>
# LINKS => <w:hyperlink r:id="rId8" w:tooltip="Screentip" w:history="1"><w:r w:rsidRPr="00225D12"><w:rPr><w:rStyle w:val="Hyperlink"/></w:rPr><w:t>Sustrans homepage</w:t></w:r></w:hyperlink>
#       => ./word/_rels/document.xml.rels -> <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.sustrans.org.uk/" TargetMode="External"/>
# FOOTNOTES => <w:footnoteReference w:id="1"/>
#           => ./word/footnotes.xml -> <w:footnote w:id="1"><w:p w14:paraId="7A10C2BB" w14:textId="700B836E" w:rsidR="00225D12" w:rsidRDefault="00225D12"><w:pPr><w:pStyle w:val="FootnoteText"/></w:pPr><w:r><w:rPr><w:rStyle w:val="FootnoteReference"/></w:rPr><w:footnoteRef/></w:r><w:r><w:t xml:space="preserve"> This is the content of the first footnote.</w:t></w:r></w:p></w:footnote>
# ENDNOTES => <w:endnoteReference w:id="1"/>
#          => ./word/endnotes.xml -> <w:endnote w:id="1"><w:p w14:paraId="5E85FCC1" w14:textId="22024CDA" w:rsidR="00225D12" w:rsidRDefault="00225D12"><w:pPr><w:pStyle w:val="EndnoteText"/></w:pPr><w:r><w:rPr><w:rStyle w:val="EndnoteReference"/></w:rPr><w:endnoteRef/></w:r><w:r><w:t xml:space="preserve"> This is the content of the first </w:t></w:r><w:proofErr w:type="gramStart"/><w:r><w:t>endnote.</w:t></w:r><w:proofErr w:type="gramEnd"/></w:p></w:endnote>
# LISTS =?>
# TABLES =?>
# IMAGES =>     <wp:docPr id="557673366" name="Picture 1" descr="Alt text for the image – logos for sustrans, canal and river trust and west berkshire"/> || <pic:cNvPr id="557673366" name="Picture 1" descr="Alt text for the image – logos for sustrans, canal and river trust and west berkshire"/>
# SPECIAL CHARACTERS
# };

1;