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
  my $xml = extract_text ( $file, "word/document.xml" );
  my @paragraphs = ( $xml =~ m|<w:p [^>]+>.+?</w:p>|g );

 print Dumper( \@paragraphs );

}

#+ subroutines +#
sub extract_text {
  my ( $zip, $zipped ) = @_;
  my $result = `unzip -p "$zip" "$zipped" 2> /dev/null`;
  if (${^CHILD_ERROR_NATIVE}) { die  "Could not extract $zipped from $zip" };
  return $result;
};

q {
HEADER / FOOTER => ultimately just in <w:t>header</w:t> tags
                => ./word/header1.xml
                => ./word/footer1.xml
                        But more than 1 is possible for each doc!
HEADINGS => <w:p w14:paraId="668156E0" w14:textId="7BD575FF" w:rsidR="00A61A63" w:rsidRDefault="00225D12" w:rsidP="00225D12"><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Simple word document</w:t></w:r></w:p>
LINE BREAKS => <w:br/>
TEXT => <w:t xml:space="preserve">text</w:t> || <w:t>text</w:t>
LINKS => <w:hyperlink r:id="rId8" w:tooltip="Screentip" w:history="1"><w:r w:rsidRPr="00225D12"><w:rPr><w:rStyle w:val="Hyperlink"/></w:rPr><w:t>Sustrans homepage</w:t></w:r></w:hyperlink>
      => ./word/_rels/document.xml.rels -> <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.sustrans.org.uk/" TargetMode="External"/>
FOOTNOTES => <w:footnoteReference w:id="1"/>
          => ./word/footnotes.xml -> <w:footnote w:id="1"><w:p w14:paraId="7A10C2BB" w14:textId="700B836E" w:rsidR="00225D12" w:rsidRDefault="00225D12"><w:pPr><w:pStyle w:val="FootnoteText"/></w:pPr><w:r><w:rPr><w:rStyle w:val="FootnoteReference"/></w:rPr><w:footnoteRef/></w:r><w:r><w:t xml:space="preserve"> This is the content of the first footnote.</w:t></w:r></w:p></w:footnote>
ENDNOTES => <w:endnoteReference w:id="1"/>
         => ./word/endnotes.xml -> <w:endnote w:id="1"><w:p w14:paraId="5E85FCC1" w14:textId="22024CDA" w:rsidR="00225D12" w:rsidRDefault="00225D12"><w:pPr><w:pStyle w:val="EndnoteText"/></w:pPr><w:r><w:rPr><w:rStyle w:val="EndnoteReference"/></w:rPr><w:endnoteRef/></w:r><w:r><w:t xml:space="preserve"> This is the content of the first </w:t></w:r><w:proofErr w:type="gramStart"/><w:r><w:t>endnote.</w:t></w:r><w:proofErr w:type="gramEnd"/></w:p></w:endnote>
LISTS =?>
TABLES =?>
IMAGES =>     <wp:docPr id="557673366" name="Picture 1" descr="Alt text for the image – logos for sustrans, canal and river trust and west berkshire"/> || <pic:cNvPr id="557673366" name="Picture 1" descr="Alt text for the image – logos for sustrans, canal and river trust and west berkshire"/>
SPECIAL CHARACTERS
};

1;