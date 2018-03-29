@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl
#line 15
##########################################################
# This script is part of the Devel::NYTProf distribution
#
# Copyright, contact and other information can be found
# at the bottom of this file, or by going to:
# http://search.cpan.org/dist/Devel-NYTProf/
#
##########################################################
# $Id: nytprofcsv 1310 2010-06-17 14:51:01Z tim.bunce@gmail.com $
##########################################################

use warnings;
use strict;

use Carp;
use Getopt::Long;

use Devel::NYTProf::Reader;

our $VERSION = '4.02';

use constant NUMERIC_PRECISION => 5;

my %delimiters = (
    comma => ",",
    tab   => "\t",
);

my %opt = (
    file => 'nytprof.out',
    out  => 'nytprof',
    delim => 'comma',
);
GetOptions(\%opt, qw/file|f=s delete|d out|o=s help|h delim=s annotated|a/)
    or do {
        usage();
        exit 1;
    };

if (defined($opt{help})) {
    usage();
    exit;
}

$opt{delim} = $delimiters{ $opt{delim} } if exists $delimiters{ $opt{delim} };

# handle file selection option
if (!-r $opt{file}) {
    die "$0: Unable to access $opt{file}\n";
}

# handle handle output location
if (!-e $opt{out}) {

    # will be created
}
elsif (!-d $opt{out}) {
    die "$0: Specified output directory `$opt{out}' is a file. whoops!\n";
}
elsif (!-w $opt{out}) {
    die "$0: Unable to write to output directory `$opt{out}'\n";
}

# handle deleting old db's
if (defined($opt{'delete'})) {
    _delete();
}

print "Generating CSV report...\n";
my $reporter = new Devel::NYTProf::Reader($opt{file});

# place to store this
$reporter->output_dir($opt{out});

$reporter->set_param(mk_report_source_line => sub {
    my ($linenum, $line, $stats_for_line, $statistics, $profile, $filestr) = @_;
    $line =~ s/^\s*//; # trim leading spaces
    my $delim = $opt{delim};

	my $time  = $stats_for_line->{'time'} || 0;
	my $calls = $stats_for_line->{'calls'} || 0;
	$time  += $stats_for_line->{evalcall_stmts_time_nested} || 0;
	#$calls ||= 1 if exists $stats_for_line->{evalcall_stmts_time_nested};

    my $text = sprintf("%f%s%g%s%f%s%s\n",
        $time, $delim,
        $calls, $delim,
		($calls) ? $time/$calls : 0, $delim,
        $line,
    );
    return $text unless $opt{annotated};

    # srcline
    $text = "srcline$delim$text";

    return $text;
});

$reporter->set_param(mk_report_xsub_line => sub { "" });

# generate the files
$reporter->report();

# Delete the previous database if it exists
sub _delete {
    if (-d $opt{out}) {
        print "Deleting $opt{out}\n";
        unlink glob($opt{out} . "/*");
        unlink glob($opt{out} . "/.*");
        rmdir $opt{out} or confess "Delete of $opt{out} failed: $!\n";
    }
}

sub usage {
    print <<END
usage: [perl] nytprofcsv [opts]
 --file <file>, -f <file>  Use the specified file as Devel::NYTProf database
                            file. [default: ./nytprof.out]
 --out <dir>,   -o <dir>   Place generated files here [default: ./nytprof]
 --delete,      -d         Delete the old fprofhtml output [uses --out]
 --help,        -h         Print this message

This script of part of the Devel::NYTProf package by Adam J Kaplan.
Copyright 2008 Adam J Kaplan, http://search.cpan.org/~akaplan, Released under
the same terms as Perl itself.
END
}

__END__

=head1 NAME

nytprofcsv - L<Devel::NYTProf::Reader> CSV format implementation

=head1 SYNOPSIS

 $ nytprofcsv [-h] [-d] [-o <output directory>] [-f <input file>]

 perl -d:NYTProf some_perl_app.pl
 nytprofcsv
 Generating CSV Output...

=head1 HISTORY

A bit of history and a shameless plug...

NYTProf stands for 'New York Times Profiler'. Indeed, the original version of this
module was developed by The New York Times Co. to help our developers quickly
identify bottlenecks in large Perl applications.  The NY Times loves Perl and
we hope the community will benefit from our work as much as we have from theirs.

Please visit L<http://open.nytimes.com>, our open source blog to see what we are
up to, L<http://code.nytimes.com> to see some of our open projects and then 
check out L<htt://nytimes.com> for the latest news!

=head1 DESCRIPTION

C<nytprofcsv> is a script that implements L<Devel::NYTProf::Reader> to
create comma-seperated value formatted reports from L<Devel::NYTProf>
databases.

See the L<Devel::NYTProf> Perl code profiler for more information.

=head1 COMMAND-LINE OPTIONS

These are the command line options understood by C<nytprofcsv>

=over 4

=item -f, --file <filename>

Specifies the location of the input file.  The input file must be the
output of L<fprofpp>. Default: nytprof.out

=item -o, --out <dir>

Where to place the generated report. Default: ./nytprof/

=item -d, --delete

Purge any existing database located at whatever -o (above) is set to

=item -h, --help

Print the help message

=back

=head1 SAMPLE OUTPUT

 # Profile data generated by Devel::NYTProf::Reader v.0.01
 # Author: Adam Kaplan. More information at http://search.cpan.org/~akaplan
 # Format: time,calls,time/call,code
 0,0,0,#--------------------------------------------------------------------
 0,0,0,# My New Source File!
 0,0,0,#--------------------------------------------------------------------
 0,0,0,# $Id: nytprofcsv 1310 2010-06-17 14:51:01Z tim.bunce@gmail.com $
 0,0,0,#--------------------------------------------------------------------
 0,0,0,
 0,0,0,package NYT::Feeds::Util;
 0.00047,3,0.000156666666666667,use Date::Calc qw(Add_Delta_DHMS);
 0.00360,3,0.0012,use HTML::Entities;
 0.00212,3,0.000706666666666667,use Encode;
 0.00248,3,0.000826666666666667,use utf8;
 0.00468,3,0.00156,use strict; 
 0,0,0,
 0.00000,1,0,require Exporter; 
 ... thats enough, get the picture? ...

Note: The format line indicates what fields the numbers correspond to

Note2: If the source file is modified between profiling and report generation,
the source might be misaligned

=head1 SEE ALSO

Mailing list and discussion at L<http://groups.google.com/group/develnytprof-dev>

Public SVN Repository and hacking instructions at L<http://code.google.com/p/perl-devel-nytprof/>

L<Devel::NYTProf>
L<Devel::NYTProf::Reader>
L<nytprofhtml> is an HTML implementation of L<Devel::NYTProf::Reader>

=head1 AUTHOR

Adam Kaplan, akaplan at nytimes dotcom

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

__END__
:endofperl
