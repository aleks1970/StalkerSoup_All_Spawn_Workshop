package ActiveState::Scineplex;

use 5.006001;
use strict;
use warnings;
use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Annotate
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.90';

require XSLoader;
XSLoader::load('ActiveState::Scineplex', $VERSION);


# Hardwired constants from scineplex
my %langName2Code = (
		      perl => 6, # SCLEX_PERL
		      xslt => 55, # SCLEX_XSLT
		      python => 2, # SCLEX_PYTHON
		      ruby => 22, # SCLEX_RUBY
		      vb => 8, # SCLEX_VB
		      );

use constant CLASSIC_SCINEPLEX => 0;
use constant LINE_MAPPER_SCINEPLEX => 1;
use constant SINGLE_BUFFER_SCINEPLEX => 2;
use constant ASCII_LINE_MAPPER_SCINEPLEX => 3;
use constant ASCII_SINGLE_BUFFER_SCINEPLEX => 4;
use constant HTML_SCINEPLEX => 5;

use constant SCE_ANY_DEFAULT => 0;

my %outputFormatName2Code = ('html' => HTML_SCINEPLEX,
			      'line' => ASCII_LINE_MAPPER_SCINEPLEX,
			      'classic' => CLASSIC_SCINEPLEX);
			      

sub Annotate {
    my($buf, $langName, %options) = @_;
    my($lang, $outputFormat, $parsingStartState, $DumpSource,
       $DumpEndState, $DumpFoldLevels, $StopAfterDataSectionLine1);
    $lang = $langName2Code{lc $langName || 'perl'};
    croak "Can't handle language $langName" unless $lang;
    if (exists $options{outputFormat}) {
	$outputFormat = $outputFormatName2Code{delete $options{outputFormat}}
    } else {
	$outputFormat = ASCII_LINE_MAPPER_SCINEPLEX;
    }
    foreach my $optname qw(parsingStartState DumpSource DumpEndState
			   DumpFoldLevels StopAfterDataSectionLine1) {
        if (exists $options{$optname}) {
	    eval "\$$optname = delete \$options{$optname} || 0;";
	} else {
	    eval "\$$optname = 0;";
	}
    }
    if (%options) {
	croak "Unrecognized option in Annotate: " . (keys %options)[0];
    }
    return AnnotateXS($buf,
		      $lang,
		      $outputFormat,
		      $parsingStartState,
		      $DumpSource,
		      $DumpEndState,
		      $DumpFoldLevels,
		      $StopAfterDataSectionLine1);
}

1;
__END__

=head1 NAME

ActiveState::Scineplex - Perl extension to access Scineplex code lexer.

=head1 SYNOPSIS

  use ActiveState::Scineplex qw(Annotate);
  $color_info = Annotate($code, $lang, %options);

=head1 DESCRIPTION

Currently this module implements an interface consisting of one method,
Annotate, which returns a scineplex-driven colorization for one or
more lines of source code.  It either returns a string giving the
colorization or throws an exception.

    $color_info = Annotate($code, $lang, %options);

$code is a block of source-code -- lines are separated by any newline sequence.

$lang must be one of qw/perl python ruby vb xslt/.

%options include the following, with defaults in parentheses:

    outputFormat => 'html' | 'line' | 'classic' ('line')
    parsingStartState => number (0) 
    DumpSource => 0 | 1 (0)
    DumpEndState => 0 | 1 (0)
    DumpFoldLevels => 0 | 1 (0)
    StopAfterDataSectionLine1 => 0 | 1 (0)

The C<outputFormat> is the most important option.  In C<classic> mode,
C<Annotate> echos back each character on the start of a line, followed
by separating white-space and its style value:

    $res = Annotate('$abc = 3;', 'perl', outputFormat => 'classic');
    print $res;

    $       12
    a       12
    b       12
    c       12
    chr(32) 0
    =       10
    chr(32) 0
    3       4
    ;       10
    chr(10) 0

The numeric values can be found in the scintilla interface file, and
are different for each language.

Setting C<outputFormat> to C<line> gives a terser output, and
represents each numeric style with the character corresponding to the
style added to the ASCII value of character '0':

    $res = Annotate('$abc = 3;', 'perl', outputFormat => 'line');
    print $res;

    <<<<0:04:

Setting C<outputFormat> to C<html> returns an HTML-encoded string
containing the original code wrapped in C<span> tags with generic
classes with names like "variable", "operator", etc.  This kind of
output is designed to be wrapped in C<pre> tags, and styled with a CSS
file of that contains rules like

    pre span.comments {
      color: 0x696969;
      font-style: italic;
    }

Default text is not placed in a span tag.

The C<parsingStartState> setting should be used only when you know
that the code starts with a given style, such as lines 3-5 of a
multi-line string.

The C<DumpSource> flag is used only with C<line> output.  It is
intended mostly for human consumption, and produces output like the
following:

    $res = Annotate('$abc = 3;', 'perl', DumpSource=>1);
    print $res;

    $abc = 3;
    <<<<0:04:

The C<DumpEndState> is used only in C<line> mode, and gives the styles
for whichever characters constitute the line-end sequence:

    $res = Annotate(qq($abc = 3;\r\n), 'perl', DumpSource=>1, DumpEndState=>1);
    print $res;

    $abc = 3;
    <<<<0:04:00

The C<DumpFoldLevels> is used only in C<line> mode, and gives the fold
levels as a 4-hex-digit sequence in a leading column.

    $res = Annotate(qq(if(1) {\n$abc = 3;\n}\n), 'perl', DumpSource=>1, DumpEndState=>1);
    print $res;

    2400 if(1) {
         55:4:0:
    0401 $abc = 3
         <<<<0:04
    0401 }
         :

The C<StopAfterDataSectionLine1> is used only for Perl code in C<line>
mode.

=head2 EXPORT

None by default.

Annotate by request.

=head1 SEE ALSO

Info on scintilla available at http://www.scintilla.org.

=head1 AUTHOR

Eric Promislow, E<lt>ericp@activestate.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 by ActiveState Software Inc.

=cut
