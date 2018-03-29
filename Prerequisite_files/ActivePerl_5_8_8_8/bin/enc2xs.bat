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
#!perl
#line 15
    eval 'exec C:\Perl_5_8_8\bin\perl.exe -S $0 ${1+"$@"}'
	if $running_under_some_shell;
#!./perl
BEGIN {
    # @INC poking  no longer needed w/ new MakeMaker and Makefile.PL's
    # with $ENV{PERL_CORE} set
    # In case we need it in future...
    require Config; import Config;
}
use strict;
use warnings;
use Getopt::Std;
my @orig_ARGV = @ARGV;
our $VERSION  = do { my @r = (q$Revision: 2.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# These may get re-ordered.
# RAW is a do_now as inserted by &enter
# AGG is an aggreagated do_now, as built up by &process

use constant {
  RAW_NEXT => 0,
  RAW_IN_LEN => 1,
  RAW_OUT_BYTES => 2,
  RAW_FALLBACK => 3,

  AGG_MIN_IN => 0,
  AGG_MAX_IN => 1,
  AGG_OUT_BYTES => 2,
  AGG_NEXT => 3,
  AGG_IN_LEN => 4,
  AGG_OUT_LEN => 5,
  AGG_FALLBACK => 6,
};

# (See the algorithm in encengine.c - we're building structures for it)

# There are two sorts of structures.
# "do_now" (an array, two variants of what needs storing) is whatever we need
# to do now we've read an input byte.
# It's housed in a "do_next" (which is how we got to it), and in turn points
# to a "do_next" which contains all the "do_now"s for the next input byte.

# There will be a "do_next" which is the start state.
# For a single byte encoding it's the only "do_next" - each "do_now" points
# back to it, and each "do_now" will cause bytes. There is no state.

# For a multi-byte encoding where all characters in the input are the same
# length, then there will be a tree of "do_now"->"do_next"->"do_now"
# branching out from the start state, one step for each input byte.
# The leaf "do_now"s will all be at the same distance from the start state,
# only the leaf "do_now"s cause output bytes, and they in turn point back to
# the start state.

# For an encoding where there are varaible length input byte sequences, you
# will encounter a leaf "do_now" sooner for the shorter input sequences, but
# as before the leaves will point back to the start state.

# The system will cope with escape encodings (imagine them as a mostly
# self-contained tree for each escape state, and cross links between trees
# at the state-switching characters) but so far no input format defines these.

# The system will also cope with having output "leaves" in the middle of
# the bifurcating branches, not just at the extremities, but again no
# input format does this yet.

# There are two variants of the "do_now" structure. The first, smaller variant
# is generated by &enter as the input file is read. There is one structure
# for each input byte. Say we are mapping a single byte encoding to a
# single byte encoding, with  "ABCD" going "abcd". There will be
# 4 "do_now"s, {"A" => [...,"a",...], "B" => [...,"b",...], "C"=>..., "D"=>...}

# &process then walks the tree, building aggregate "do_now" structres for
# adjacent bytes where possible. The aggregate is for a contiguous range of
# bytes which each produce the same length of output, each move to the
# same next state, and each have the same fallback flag.
# So our 4 RAW "do_now"s above become replaced by a single structure
# containing:
# ["A", "D", "abcd", 1, ...]
# ie, for an input byte $_ in "A".."D", output 1 byte, found as
# substr ("abcd", (ord $_ - ord "A") * 1, 1)
# which maps very nicely into pointer arithmetic in C for encengine.c

sub encode_U
{
 # UTF-8 encode long hand - only covers part of perl's range
 ## my $uv = shift;
 # chr() works in native space so convert value from table
 # into that space before using chr().
 my $ch = chr(utf8::unicode_to_native($_[0]));
 # Now get core perl to encode that the way it likes.
 utf8::encode($ch);
 return $ch;
}

sub encode_S
{
 # encode single byte
 ## my ($ch,$page) = @_; return chr($ch);
 return chr $_[0];
}

sub encode_D
{
 # encode double byte MS byte first
 ## my ($ch,$page) = @_; return chr($page).chr($ch);
 return chr ($_[1]) . chr $_[0];
}

sub encode_M
{
 # encode Multi-byte - single for 0..255 otherwise double
 ## my ($ch,$page) = @_;
 ## return &encode_D if $page;
 ## return &encode_S;
 return chr ($_[1]) . chr $_[0] if $_[1];
 return chr $_[0];
}

my %encode_types = (U => \&encode_U,
                    S => \&encode_S,
                    D => \&encode_D,
                    M => \&encode_M,
                   );

# Win32 does not expand globs on command line
eval "\@ARGV = map(glob(\$_),\@ARGV)" if ($^O eq 'MSWin32');

my %opt;
# I think these are:
# -Q to disable the duplicate codepoint test
# -S make mapping errors fatal
# -q to remove comments written to output files
# -O to enable the (brute force) substring optimiser
# -o <output> to specify the output file name (else it's the first arg)
# -f <inlist> to give a file with a list of input files (else use the args)
# -n <name> to name the encoding (else use the basename of the input file.
getopts('CM:SQqOo:f:n:',\%opt);

$opt{M} and make_makefile_pl($opt{M}, @ARGV);
$opt{C} and make_configlocal_pm($opt{C}, @ARGV);

# This really should go first, else the die here causes empty (non-erroneous)
# output files to be written.
my @encfiles;
if (exists $opt{'f'}) {
    # -F is followed by name of file containing list of filenames
    my $flist = $opt{'f'};
    open(FLIST,$flist) || die "Cannot open $flist:$!";
    chomp(@encfiles = <FLIST>);
    close(FLIST);
} else {
    @encfiles = @ARGV;
}

my $cname = (exists $opt{'o'}) ? $opt{'o'} : shift(@ARGV);
chmod(0666,$cname) if -f $cname && !-w $cname;
open(C,">$cname") || die "Cannot open $cname:$!";

my $dname = $cname;
my $hname = $cname;

my ($doC,$doEnc,$doUcm,$doPet);

if ($cname =~ /\.(c|xs)$/i) # VMS may have upcased filenames with DECC$ARGV_PARSE_STYLE defined
 {
  $doC = 1;
  $dname =~ s/(\.[^\.]*)?$/.exh/;
  chmod(0666,$dname) if -f $cname && !-w $dname;
  open(D,">$dname") || die "Cannot open $dname:$!";
  $hname =~ s/(\.[^\.]*)?$/.h/;
  chmod(0666,$hname) if -f $cname && !-w $hname;
  open(H,">$hname") || die "Cannot open $hname:$!";

  foreach my $fh (\*C,\*D,\*H)
  {
   print $fh <<"END" unless $opt{'q'};
/*
 !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
 This file was autogenerated by:
 $^X $0 @orig_ARGV
*/
END
  }

  if ($cname =~ /(\w+)\.xs$/)
   {
    print C "#include <EXTERN.h>\n";
    print C "#include <perl.h>\n";
    print C "#include <XSUB.h>\n";
    print C "#define U8 U8\n";
   }
  print C "#include \"encode.h\"\n\n";

 }
elsif ($cname =~ /\.enc$/)
 {
  $doEnc = 1;
 }
elsif ($cname =~ /\.ucm$/)
 {
  $doUcm = 1;
 }
elsif ($cname =~ /\.pet$/)
 {
  $doPet = 1;
 }

my %encoding;
my %strings;
my $string_acc;
my %strings_in_acc;

my $saved = 0;
my $subsave = 0;
my $strings = 0;

sub cmp_name
{
 if ($a =~ /^.*-(\d+)/)
  {
   my $an = $1;
   if ($b =~ /^.*-(\d+)/)
    {
     my $r = $an <=> $1;
     return $r if $r;
    }
  }
 return $a cmp $b;
}


foreach my $enc (sort cmp_name @encfiles)
 {
  my ($name,$sfx) = $enc =~ /^.*?([\w-]+)\.(enc|ucm)$/;
  $name = $opt{'n'} if exists $opt{'n'};
  if (open(E,$enc))
   {
    if ($sfx eq 'enc')
     {
      compile_enc(\*E,lc($name));
     }
    else
     {
      compile_ucm(\*E,lc($name));
     }
   }
  else
   {
    warn "Cannot open $enc for $name:$!";
   }
 }

if ($doC)
 {
  print STDERR "Writing compiled form\n";
  foreach my $name (sort cmp_name keys %encoding)
   {
    my ($e2u,$u2e,$erep,$min_el,$max_el) = @{$encoding{$name}};
    process($name.'_utf8',$e2u);
    addstrings(\*C,$e2u);

    process('utf8_'.$name,$u2e);
    addstrings(\*C,$u2e);
   }
  outbigstring(\*C,"enctable");
  foreach my $name (sort cmp_name keys %encoding)
   {
    my ($e2u,$u2e,$erep,$min_el,$max_el) = @{$encoding{$name}};
    outtable(\*C,$e2u, "enctable");
    outtable(\*C,$u2e, "enctable");

    # push(@{$encoding{$name}},outstring(\*C,$e2u->{Cname}.'_def',$erep));
   }
  foreach my $enc (sort cmp_name keys %encoding)
   {
    # my ($e2u,$u2e,$rep,$min_el,$max_el,$rsym) = @{$encoding{$enc}};
    my ($e2u,$u2e,$rep,$min_el,$max_el) = @{$encoding{$enc}};
    #my @info = ($e2u->{Cname},$u2e->{Cname},$rsym,length($rep),$min_el,$max_el);
    my $replen = 0; 
    $replen++ while($rep =~ /\G\\x[0-9A-Fa-f]/g);
    my @info = ($e2u->{Cname},$u2e->{Cname},qq((U8 *)"$rep"),$replen,$min_el,$max_el);
    my $sym = "${enc}_encoding";
    $sym =~ s/\W+/_/g;
    print C "encode_t $sym = \n";
    # This is to make null encoding work -- dankogai
    for (my $i = (scalar @info) - 1;  $i >= 0; --$i){
	$info[$i] ||= 1;
    }
    # end of null tweak -- dankogai
    print C " {",join(',',@info,"{\"$enc\",(const char *)0}"),"};\n\n";
   }

  foreach my $enc (sort cmp_name keys %encoding)
   {
    my $sym = "${enc}_encoding";
    $sym =~ s/\W+/_/g;
    print H "extern encode_t $sym;\n";
    print D " Encode_XSEncoding(aTHX_ &$sym);\n";
   }

  if ($cname =~ /(\w+)\.xs$/)
   {
    my $mod = $1;
    print C <<'END';

static void
Encode_XSEncoding(pTHX_ encode_t *enc)
{
 dSP;
 HV *stash = gv_stashpv("Encode::XS", TRUE);
 SV *sv    = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))),stash);
 int i = 0;
 PUSHMARK(sp);
 XPUSHs(sv);
 while (enc->name[i])
  {
   const char *name = enc->name[i++];
   XPUSHs(sv_2mortal(newSVpvn(name,strlen(name))));
  }
 PUTBACK;
 call_pv("Encode::define_encoding",G_DISCARD);
 SvREFCNT_dec(sv);
}

END

    print C "\nMODULE = Encode::$mod\tPACKAGE = Encode::$mod\n\n";
    print C "BOOT:\n{\n";
    print C "#include \"$dname\"\n";
    print C "}\n";
   }
  # Close in void context is bad, m'kay
  close(D) or warn "Error closing '$dname': $!";
  close(H) or warn "Error closing '$hname': $!";

  my $perc_saved    = $saved/($strings + $saved) * 100;
  my $perc_subsaved = $subsave/($strings + $subsave) * 100;
  printf STDERR "%d bytes in string tables\n",$strings;
  printf STDERR "%d bytes (%.3g%%) saved spotting duplicates\n",
    $saved, $perc_saved              if $saved;
  printf STDERR "%d bytes (%.3g%%) saved using substrings\n",
    $subsave, $perc_subsaved         if $subsave;
 }
elsif ($doEnc)
 {
  foreach my $name (sort cmp_name keys %encoding)
   {
    my ($e2u,$u2e,$erep,$min_el,$max_el) = @{$encoding{$name}};
    output_enc(\*C,$name,$e2u);
   }
 }
elsif ($doUcm)
 {
  foreach my $name (sort cmp_name keys %encoding)
   {
    my ($e2u,$u2e,$erep,$min_el,$max_el) = @{$encoding{$name}};
    output_ucm(\*C,$name,$u2e,$erep,$min_el,$max_el);
   }
 }

# writing half meg files and then not checking to see if you just filled the
# disk is bad, m'kay
close(C) or die "Error closing '$cname': $!";

# End of the main program.

sub compile_ucm
{
 my ($fh,$name) = @_;
 my $e2u = {};
 my $u2e = {};
 my $cs;
 my %attr;
 while (<$fh>)
  {
   s/#.*$//;
   last if /^\s*CHARMAP\s*$/i;
   if (/^\s*<(\w+)>\s+"?([^"]*)"?\s*$/i) # " # Grrr
    {
     $attr{$1} = $2;
    }
  }
 if (!defined($cs =  $attr{'code_set_name'}))
  {
   warn "No <code_set_name> in $name\n";
  }
 else
  {
   $name = $cs unless exists $opt{'n'};
  }
 my $erep;
 my $urep;
 my $max_el;
 my $min_el;
 if (exists $attr{'subchar'})
  {
   #my @byte;
   #$attr{'subchar'} =~ /^\s*/cg;
   #push(@byte,$1) while $attr{'subchar'} =~ /\G\\x([0-9a-f]+)/icg;
   #$erep = join('',map(chr(hex($_)),@byte));
   $erep = $attr{'subchar'}; 
   $erep =~ s/^\s+//; $erep =~ s/\s+$//;
  }
 print "Reading $name ($cs)\n";
 my $nfb = 0;
 my $hfb = 0;
 while (<$fh>)
  {
   s/#.*$//;
   last if /^\s*END\s+CHARMAP\s*$/i;
   next if /^\s*$/;
   my (@uni, @byte) = ();
   my ($uni, $byte, $fb) = m/^(\S+)\s+(\S+)\s+(\S+)\s+/o
       or die "Bad line: $_";
   while ($uni =~  m/\G<([U0-9a-fA-F\+]+)>/g){
       push @uni, map { substr($_, 1) } split(/\+/, $1);
   }
   while ($byte =~ m/\G\\x([0-9a-fA-F]+)/g){
       push @byte, $1;
   }
   if (@uni)
    {
     my $uch =  join('', map { encode_U(hex($_)) } @uni );
     my $ech = join('',map(chr(hex($_)),@byte));
     my $el  = length($ech);
     $max_el = $el if (!defined($max_el) || $el > $max_el);
     $min_el = $el if (!defined($min_el) || $el < $min_el);
     if (length($fb))
      {
       $fb = substr($fb,1);
       $hfb++;
      }
     else
      {
       $nfb++;
       $fb = '0';
      }
     # $fb is fallback flag
     # 0 - round trip safe
     # 1 - fallback for unicode -> enc
     # 2 - skip sub-char mapping
     # 3 - fallback enc -> unicode
     enter($u2e,$uch,$ech,$u2e,$fb+0) if ($fb =~ /[01]/);
     enter($e2u,$ech,$uch,$e2u,$fb+0) if ($fb =~ /[03]/);
    }
   else
    {
     warn $_;
    }
  }
 if ($nfb && $hfb)
  {
   die "$nfb entries without fallback, $hfb entries with\n";
  }
 $encoding{$name} = [$e2u,$u2e,$erep,$min_el,$max_el];
}



sub compile_enc
{
 my ($fh,$name) = @_;
 my $e2u = {};
 my $u2e = {};

 my $type;
 while ($type = <$fh>)
  {
   last if $type !~ /^\s*#/;
  }
 chomp($type);
 return if $type eq 'E';
 # Do the hash lookup once, rather than once per function call. 4% speedup.
 my $type_func = $encode_types{$type};
 my ($def,$sym,$pages) = split(/\s+/,scalar(<$fh>));
 warn "$type encoded $name\n";
 my $rep = '';
 # Save a defined test by setting these to defined values.
 my $min_el = ~0; # A very big integer
 my $max_el = 0;  # Anything must be longer than 0
 {
  my $v = hex($def);
  $rep = &$type_func($v & 0xFF, ($v >> 8) & 0xffe);
 }
 my $errors;
 my $seen;
 # use -Q to silence the seen test. Makefile.PL uses this by default.
 $seen = {} unless $opt{Q};
 do
  {
   my $line = <$fh>;
   chomp($line);
   my $page = hex($line);
   my $ch = 0;
   my $i = 16;
   do
    {
     # So why is it 1% faster to leave the my here?
     my $line = <$fh>;
     $line =~ s/\r\n$/\n/;
     die "$.:${line}Line should be exactly 65 characters long including
     newline (".length($line).")" unless length ($line) == 65;
     # Split line into groups of 4 hex digits, convert groups to ints
     # This takes 65.35		
     # map {hex $_} $line =~ /(....)/g
     # This takes 63.75 (2.5% less time)
     # unpack "n*", pack "H*", $line
     # There's an implicit loop in map. Loops are bad, m'kay. Ops are bad, m'kay
     # Doing it as while ($line =~ /(....)/g) took 74.63
     foreach my $val (unpack "n*", pack "H*", $line)
      {
       next if $val == 0xFFFD;
       my $ech = &$type_func($ch,$page);
       if ($val || (!$ch && !$page))
        {
         my $el  = length($ech);
         $max_el = $el if $el > $max_el;
         $min_el = $el if $el < $min_el;
         my $uch = encode_U($val);
         if ($seen) {
           # We're doing the test.
           # We don't need to read this quickly, so storing it as a scalar,
           # rather than 3 (anon array, plus the 2 scalars it holds) saves
           # RAM and may make us faster on low RAM systems. [see __END__]
           if (exists $seen->{$uch})
             {
               warn sprintf("U%04X is %02X%02X and %04X\n",
                            $val,$page,$ch,$seen->{$uch});
               $errors++;
             }
           else
             {
               $seen->{$uch} = $page << 8 | $ch;
             }
         }
         # Passing 2 extra args each time is 3.6% slower!
         # Even with having to add $fallback ||= 0 later
         enter_fb0($e2u,$ech,$uch);
         enter_fb0($u2e,$uch,$ech);
        }
       else
        {
         # No character at this position
         # enter($e2u,$ech,undef,$e2u);
        }
       $ch++;
      }
    } while --$i;
  } while --$pages;
 die "\$min_el=$min_el, \$max_el=$max_el - seems we read no lines"
   if $min_el > $max_el;
 die "$errors mapping conflicts\n" if ($errors && $opt{'S'});
 $encoding{$name} = [$e2u,$u2e,$rep,$min_el,$max_el];
}

# my ($a,$s,$d,$t,$fb) = @_;
sub enter {
  my ($current,$inbytes,$outbytes,$next,$fallback) = @_;
  # state we shift to after this (multibyte) input character defaults to same
  # as current state.
  $next ||= $current;
  # Making sure it is defined seems to be faster than {no warnings;} in
  # &process, or passing it in as 0 explicity.
  # XXX $fallback ||= 0;

  # Start at the beginning and work forwards through the string to zero.
  # effectively we are removing 1 character from the front each time
  # but we don't actually edit the string. [this alone seems to be 14% speedup]
  # Hence -$pos is the length of the remaining string.
  my $pos = -length $inbytes;
  while (1) {
    my $byte = substr $inbytes, $pos, 1;
    #  RAW_NEXT => 0,
    #  RAW_IN_LEN => 1,
    #  RAW_OUT_BYTES => 2,
    #  RAW_FALLBACK => 3,
    # to unicode an array would seem to be better, because the pages are dense.
    # from unicode can be very sparse, favouring a hash.
    # hash using the bytes (all length 1) as keys rather than ord value,
    # as it's easier to sort these in &process.

    # It's faster to always add $fallback even if it's undef, rather than
    # choosing between 3 and 4 element array. (hence why we set it defined
    # above)
    my $do_now = $current->{Raw}{$byte} ||= [{},-$pos,'',$fallback];
    # When $pos was -1 we were at the last input character.
    unless (++$pos) {
      $do_now->[RAW_OUT_BYTES] = $outbytes;
      $do_now->[RAW_NEXT] = $next;
      return;
    }
    # Tail recursion. The intermdiate state may not have a name yet.
    $current = $do_now->[RAW_NEXT];
  }
}

# This is purely for optimistation. It's just &enter hard coded for $fallback
# of 0, using only a 3 entry array ref to save memory for every entry.
sub enter_fb0 {
  my ($current,$inbytes,$outbytes,$next) = @_;
  $next ||= $current;

  my $pos = -length $inbytes;
  while (1) {
    my $byte = substr $inbytes, $pos, 1;
    my $do_now = $current->{Raw}{$byte} ||= [{},-$pos,''];
    unless (++$pos) {
      $do_now->[RAW_OUT_BYTES] = $outbytes;
      $do_now->[RAW_NEXT] = $next;
      return;
    }
    $current = $do_now->[RAW_NEXT];
  }
}

sub process
{
  my ($name,$a) = @_;
  $name =~ s/\W+/_/g;
  $a->{Cname} = $name;
  my $raw = $a->{Raw};
  my ($l, $agg_max_in, $agg_next, $agg_in_len, $agg_out_len, $agg_fallback);
  my @ent;
  $agg_max_in = 0;
  foreach my $key (sort keys %$raw) {
    #  RAW_NEXT => 0,
    #  RAW_IN_LEN => 1,
    #  RAW_OUT_BYTES => 2,
    #  RAW_FALLBACK => 3,
    my ($next, $in_len, $out_bytes, $fallback) = @{$raw->{$key}};
    # Now we are converting from raw to aggregate, switch from 1 byte strings
    # to numbers
    my $b = ord $key;
    $fallback ||= 0;
    if ($l &&
        # If this == fails, we're going to reset $agg_max_in below anyway.
        $b == ++$agg_max_in &&
        # References in numeric context give the pointer as an int.
        $agg_next == $next &&
        $agg_in_len == $in_len &&
        $agg_out_len == length $out_bytes &&
        $agg_fallback == $fallback
        # && length($l->[AGG_OUT_BYTES]) < 16
       ) {
      #     my $i = ord($b)-ord($l->[AGG_MIN_IN]);
      # we can aggregate this byte onto the end.
      $l->[AGG_MAX_IN] = $b;
      $l->[AGG_OUT_BYTES] .= $out_bytes;
    } else {
      # AGG_MIN_IN => 0,
      # AGG_MAX_IN => 1,
      # AGG_OUT_BYTES => 2,
      # AGG_NEXT => 3,
      # AGG_IN_LEN => 4,
      # AGG_OUT_LEN => 5,
      # AGG_FALLBACK => 6,
      # Reset the last thing we saw, plus set 5 lexicals to save some derefs.
      # (only gains .6% on euc-jp  -- is it worth it?)
      push @ent, $l = [$b, $agg_max_in = $b, $out_bytes, $agg_next = $next,
                       $agg_in_len = $in_len, $agg_out_len = length $out_bytes,
                       $agg_fallback = $fallback];
    }
    if (exists $next->{Cname}) {
      $next->{'Forward'} = 1 if $next != $a;
    } else {
      process(sprintf("%s_%02x",$name,$b),$next);
    }
  }
  # encengine.c rules say that last entry must be for 255
  if ($agg_max_in < 255) {
    push @ent, [1+$agg_max_in, 255,undef,$a,0,0];
  }
  $a->{'Entries'} = \@ent;
}


sub addstrings
{
 my ($fh,$a) = @_;
 my $name = $a->{'Cname'};
 # String tables
 foreach my $b (@{$a->{'Entries'}})
  {
   next unless $b->[AGG_OUT_LEN];
   $strings{$b->[AGG_OUT_BYTES]} = undef;
  }
 if ($a->{'Forward'})
  {
   my $var = $^O eq 'MacOS' ? 'extern' : 'static';
   print $fh "$var encpage_t $name\[",scalar(@{$a->{'Entries'}}),"];\n";
  }
 $a->{'DoneStrings'} = 1;
 foreach my $b (@{$a->{'Entries'}})
  {
   my ($s,$e,$out,$t,$end,$l) = @$b;
   addstrings($fh,$t) unless $t->{'DoneStrings'};
  }
}

sub outbigstring
{
  my ($fh,$name) = @_;

  $string_acc = '';

  # Make the big string in the string accumulator. Longest first, on the hope
  # that this makes it more likely that we find the short strings later on.
  # Not sure if it helps sorting strings of the same length lexcically.
  foreach my $s (sort {length $b <=> length $a || $a cmp $b} keys %strings) {
    my $index = index $string_acc, $s;
    if ($index >= 0) {
      $saved += length($s);
      $strings_in_acc{$s} = $index;
    } else {
    OPTIMISER: {
	if ($opt{'O'}) {
	  my $sublength = length $s;
	  while (--$sublength > 0) {
	    # progressively lop characters off the end, to see if the start of
	    # the new string overlaps the end of the accumulator.
	    if (substr ($string_acc, -$sublength)
		eq substr ($s, 0, $sublength)) {
	      $subsave += $sublength;
	      $strings_in_acc{$s} = length ($string_acc) - $sublength;
	      # append the last bit on the end.
	      $string_acc .= substr ($s, $sublength);
	      last OPTIMISER;
	    }
	    # or if the end of the new string overlaps the start of the
	    # accumulator
	    next unless substr ($string_acc, 0, $sublength)
	      eq substr ($s, -$sublength);
	    # well, the last $sublength characters of the accumulator match.
	    # so as we're prepending to the accumulator, need to shift all our
	    # existing offsets forwards
	    $_ += $sublength foreach values %strings_in_acc;
	    $subsave += $sublength;
	    $strings_in_acc{$s} = 0;
	    # append the first bit on the start.
	    $string_acc = substr ($s, 0, -$sublength) . $string_acc;
	    last OPTIMISER;
	  }
	}
	# Optimiser (if it ran) found nothing, so just going have to tack the
	# whole thing on the end.
	$strings_in_acc{$s} = length $string_acc;
	$string_acc .= $s;
      };
    }
  }

  $strings = length $string_acc;
  my $definition = "\nstatic const U8 $name\[$strings] = { " .
    join(',',unpack "C*",$string_acc);
  # We have a single long line. Split it at convenient commas.
  print $fh $1, "\n" while $definition =~ /\G(.{74,77},)/gcs;
  print $fh substr ($definition, pos $definition), " };\n";
}

sub findstring {
  my ($name,$s) = @_;
  my $offset = $strings_in_acc{$s};
  die "Can't find string " . join (',',unpack "C*",$s) . " in accumulator"
    unless defined $offset;
  "$name + $offset";
}

sub outtable
{
 my ($fh,$a,$bigname) = @_;
 my $name = $a->{'Cname'};
 $a->{'Done'} = 1;
 foreach my $b (@{$a->{'Entries'}})
  {
   my ($s,$e,$out,$t,$end,$l) = @$b;
   outtable($fh,$t,$bigname) unless $t->{'Done'};
  }
 print $fh "\nstatic encpage_t $name\[",scalar(@{$a->{'Entries'}}),"] = {\n";
 foreach my $b (@{$a->{'Entries'}})
  {
   my ($sc,$ec,$out,$t,$end,$l,$fb) = @$b;
   # $end |= 0x80 if $fb; # what the heck was on your mind, Nick?  -- Dan
   print  $fh "{";
   if ($l)
    {
     printf $fh findstring($bigname,$out);
    }
   else
    {
     print  $fh "0";
    }
   print  $fh ",",$t->{Cname};
   printf $fh ",0x%02x,0x%02x,$l,$end},\n",$sc,$ec;
  }
 print $fh "};\n";
}

sub output_enc
{
 my ($fh,$name,$a) = @_;
 die "Changed - fix me for new structure";
 foreach my $b (sort keys %$a)
  {
   my ($s,$e,$out,$t,$end,$l,$fb) = @{$a->{$b}};
  }
}

sub decode_U
{
 my $s = shift;
}

my @uname;
sub char_names
{
 my $s = do "unicore/Name.pl";
 die "char_names: unicore/Name.pl: $!\n" unless defined $s;
 pos($s) = 0;
 while ($s =~ /\G([0-9a-f]+)\t([0-9a-f]*)\t(.*?)\s*\n/igc)
  {
   my $name = $3;
   my $s = hex($1);
   last if $s >= 0x10000;
   my $e = length($2) ? hex($2) : $s;
   for (my $i = $s; $i <= $e; $i++)
    {
     $uname[$i] = $name;
#    print sprintf("U%04X $name\n",$i);
    }
  }
}

sub output_ucm_page
{
  my ($cmap,$a,$t,$pre) = @_;
  # warn sprintf("Page %x\n",$pre);
  my $raw = $t->{Raw};
  foreach my $key (sort keys %$raw) {
    #  RAW_NEXT => 0,
    #  RAW_IN_LEN => 1,
    #  RAW_OUT_BYTES => 2,
    #  RAW_FALLBACK => 3,
    my ($next, $in_len, $out_bytes, $fallback) = @{$raw->{$key}};
    my $u = ord $key;
    $fallback ||= 0;

    if ($next != $a && $next != $t) {
      output_ucm_page($cmap,$a,$next,(($pre|($u &0x3F)) << 6)&0xFFFF);
    } elsif (length $out_bytes) {
      if ($pre) {
        $u = $pre|($u &0x3f);
      }
      my $s = sprintf "<U%04X> ",$u;
      #foreach my $c (split(//,$out_bytes)) {
      #  $s .= sprintf "\\x%02X",ord($c);
      #}
      # 9.5% faster changing that loop to this:
      $s .= sprintf +("\\x%02X" x length $out_bytes), unpack "C*", $out_bytes;
      $s .= sprintf " |%d # %s\n",($fallback ? 1 : 0),$uname[$u];
      push(@$cmap,$s);
    } else {
      warn join(',',$u, @{$raw->{$key}},$a,$t);
    }
  }
}

sub output_ucm
{
 my ($fh,$name,$h,$rep,$min_el,$max_el) = @_;
 print $fh "# $0 @orig_ARGV\n" unless $opt{'q'};
 print $fh "<code_set_name> \"$name\"\n";
 char_names();
 if (defined $min_el)
  {
   print $fh "<mb_cur_min> $min_el\n";
  }
 if (defined $max_el)
  {
   print $fh "<mb_cur_max> $max_el\n";
  }
 if (defined $rep)
  {
   print $fh "<subchar> ";
   foreach my $c (split(//,$rep))
    {
     printf $fh "\\x%02X",ord($c);
    }
   print $fh "\n";
  }
 my @cmap;
 output_ucm_page(\@cmap,$h,$h,0);
 print $fh "#\nCHARMAP\n";
 foreach my $line (sort { substr($a,8) cmp substr($b,8) } @cmap)
  {
   print $fh $line;
  }
 print $fh "END CHARMAP\n";
}

use vars qw(
    $_Enc2xs
    $_Version
    $_Inc
    $_E2X 
    $_Name
    $_TableFiles
    $_Now
);

sub find_e2x{
    eval { require File::Find; };
    my (@inc, %e2x_dir);
    for my $inc (@INC){
	push @inc, $inc unless $inc eq '.'; #skip current dir
    }
    File::Find::find(
	     sub {
		 my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		     $atime,$mtime,$ctime,$blksize,$blocks)
		     = lstat($_) or return;
		 -f _ or return;
		 if (/^.*\.e2x$/o){
		     no warnings 'once';
		     $e2x_dir{$File::Find::dir} ||= $mtime;
		 }
		 return;
	     }, @inc);
    warn join("\n", keys %e2x_dir), "\n";
    for my $d (sort {$e2x_dir{$a} <=> $e2x_dir{$b}} keys %e2x_dir){
	$_E2X = $d;
	# warn "$_E2X => ", scalar localtime($e2x_dir{$d});
	return $_E2X;
    }
}

sub make_makefile_pl
{
    eval { require Encode; };
    $@ and die "You need to install Encode to use enc2xs -M\nerror: $@\n";
    # our used for variable expanstion
    $_Enc2xs = $0;
    $_Version = $VERSION;
    $_E2X = find_e2x();
    $_Name = shift;
    $_TableFiles = join(",", map {qq('$_')} @_);
    $_Now = scalar localtime();

    eval { require File::Spec; };
    _print_expand(File::Spec->catfile($_E2X,"Makefile_PL.e2x"),"Makefile.PL");
    _print_expand(File::Spec->catfile($_E2X,"_PM.e2x"),        "$_Name.pm");
    _print_expand(File::Spec->catfile($_E2X,"_T.e2x"),         "t/$_Name.t");
    _print_expand(File::Spec->catfile($_E2X,"README.e2x"),     "README");
    _print_expand(File::Spec->catfile($_E2X,"Changes.e2x"),    "Changes");
    exit;
}

use vars qw(
	    $_ModLines
	    $_LocalVer
	    );

sub make_configlocal_pm
{
    eval { require Encode; };
    $@ and die "Unable to require Encode: $@\n";
    eval { require File::Spec; };
    # our used for variable expanstion
    my %in_core = map {$_=>1}('ascii','iso-8859-1','utf8');
    my %LocalMod = ();
    for my $d (@INC){
	my $inc = File::Spec->catfile($d, "Encode");
	-d $inc or next;
	opendir my $dh, $inc or die "$inc:$!";
	warn "Checking $inc...\n";
	for my $f (grep /\.pm$/o, readdir($dh)){
	    -f File::Spec->catfile($inc, "$f") or next;
	    $INC{"Encode/$f"} and next;
	    warn "require Encode/$f;\n";
	    eval { require "Encode/$f"; };
	    $@ and die "Can't require Encode/$f: $@\n";
	    for my $enc (Encode->encodings()){
		no warnings 'once';
		$in_core{$enc} and next;
		$Encode::Config::ExtModule{$enc} and next;
		my $mod = "Encode/$f"; 
		$mod =~ s/\.pm$//o; $mod =~ s,/,::,og;
		$LocalMod{$enc} ||= $mod;
	    }
	}
    }
    $_ModLines = "";
    for my $enc (sort keys %LocalMod){
	$_ModLines .= 
	    qq(\$Encode::ExtModule{'$enc'} =\t"$LocalMod{$enc}";\n);
    }
    warn $_ModLines;
    $_LocalVer = _mkversion();
    $_E2X = find_e2x();
    $_Inc = $INC{"Encode.pm"}; $_Inc =~ s/\.pm$//o;    
    _print_expand(File::Spec->catfile($_E2X,"ConfigLocal_PM.e2x"),    
		  File::Spec->catfile($_Inc,"ConfigLocal.pm"),
		  1);
    exit;
}

sub _mkversion{
    my ($ss,$mm,$hh,$dd,$mo,$yyyy) = localtime();
    $yyyy += 1900, $mo +=1;
    return sprintf("v%04d.%04d.%04d", $yyyy, $mo*100+$dd, $hh*100+$mm);
}

sub _print_expand{
    eval { require File::Basename; };
    $@ and die "File::Basename needed.  Are you on miniperl?;\nerror: $@\n";
    File::Basename->import();
    my ($src, $dst, $clobber) = @_;
    if (!$clobber and -e $dst){
	warn "$dst exists. skipping\n";
	return;
    }
    warn "Generating $dst...\n";
    open my $in, $src or die "$src : $!";
    if ((my $d = dirname($dst)) ne '.'){
	-d $d or mkdir $d, 0755 or die  "mkdir $d : $!";
    }	   
    open my $out, ">$dst" or die "$!";
    my $asis = 0;
    while (<$in>){ 
	if (/^#### END_OF_HEADER/){
	    $asis = 1; next;
	}	  
	s/(\$_[A-Z][A-Za-z0-9]+)_/$1/gee unless $asis;
	print $out $_;
    }
}
__END__

=head1 NAME

enc2xs -- Perl Encode Module Generator

=head1 SYNOPSIS

  enc2xs -[options]
  enc2xs -M ModName mapfiles...
  enc2xs -C

=head1 DESCRIPTION

F<enc2xs> builds a Perl extension for use by Encode from either
Unicode Character Mapping files (.ucm) or Tcl Encoding Files (.enc).
Besides being used internally during the build process of the Encode
module, you can use F<enc2xs> to add your own encoding to perl.
No knowledge of XS is necessary.

=head1 Quick Guide

If you want to know as little about Perl as possible but need to
add a new encoding, just read this chapter and forget the rest.

=over 4

=item 0.

Have a .ucm file ready.  You can get it from somewhere or you can write
your own from scratch or you can grab one from the Encode distribution
and customize it.  For the UCM format, see the next Chapter.  In the
example below, I'll call my theoretical encoding myascii, defined
in I<my.ucm>.  C<$> is a shell prompt.

  $ ls -F
  my.ucm

=item 1.

Issue a command as follows;

  $ enc2xs -M My my.ucm
  generating Makefile.PL
  generating My.pm
  generating README
  generating Changes

Now take a look at your current directory.  It should look like this.

  $ ls -F
  Makefile.PL   My.pm         my.ucm        t/

The following files were created.

  Makefile.PL - MakeMaker script
  My.pm       - Encode submodule
  t/My.t      - test file

=over 4

=item 1.1.

If you want *.ucm installed together with the modules, do as follows;

  $ mkdir Encode
  $ mv *.ucm Encode
  $ enc2xs -M My Encode/*ucm

=back

=item 2.

Edit the files generated.  You don't have to if you have no time AND no
intention to give it to someone else.  But it is a good idea to edit
the pod and to add more tests.

=item 3.

Now issue a command all Perl Mongers love:

  $ perl Makefile.PL
  Writing Makefile for Encode::My

=item 4.

Now all you have to do is make.

  $ make
  cp My.pm blib/lib/Encode/My.pm
  /usr/local/bin/perl /usr/local/bin/enc2xs -Q -O \
    -o encode_t.c -f encode_t.fnm
  Reading myascii (myascii)
  Writing compiled form
  128 bytes in string tables
  384 bytes (75%) saved spotting duplicates
  1 bytes (0.775%) saved using substrings
  ....
  chmod 644 blib/arch/auto/Encode/My/My.bs
  $

The time it takes varies depending on how fast your machine is and
how large your encoding is.  Unless you are working on something big
like euc-tw, it won't take too long.

=item 5.

You can "make install" already but you should test first.

  $ make test
  PERL_DL_NONLAZY=1 /usr/local/bin/perl -Iblib/arch -Iblib/lib \
    -e 'use Test::Harness  qw(&runtests $verbose); \
    $verbose=0; runtests @ARGV;' t/*.t
  t/My....ok
  All tests successful.
  Files=1, Tests=2,  0 wallclock secs
   ( 0.09 cusr + 0.01 csys = 0.09 CPU)

=item 6.

If you are content with the test result, just "make install"

=item 7.

If you want to add your encoding to Encode's demand-loading list
(so you don't have to "use Encode::YourEncoding"), run

  enc2xs -C

to update Encode::ConfigLocal, a module that controls local settings.
After that, "use Encode;" is enough to load your encodings on demand.

=back

=head1 The Unicode Character Map

Encode uses the Unicode Character Map (UCM) format for source character
mappings.  This format is used by IBM's ICU package and was adopted
by Nick Ing-Simmons for use with the Encode module.  Since UCM is
more flexible than Tcl's Encoding Map and far more user-friendly,
this is the recommended formet for Encode now.

A UCM file looks like this.

  #
  # Comments
  #
  <code_set_name> "US-ascii" # Required
  <code_set_alias> "ascii"   # Optional
  <mb_cur_min> 1             # Required; usually 1
  <mb_cur_max> 1             # Max. # of bytes/char
  <subchar> \x3F             # Substitution char
  #
  CHARMAP
  <U0000> \x00 |0 # <control>
  <U0001> \x01 |0 # <control>
  <U0002> \x02 |0 # <control>
  ....
  <U007C> \x7C |0 # VERTICAL LINE
  <U007D> \x7D |0 # RIGHT CURLY BRACKET
  <U007E> \x7E |0 # TILDE
  <U007F> \x7F |0 # <control>
  END CHARMAP

=over 4

=item *

Anything that follows C<#> is treated as a comment.

=item *

The header section continues until a line containing the word
CHARMAP. This section has a form of I<E<lt>keywordE<gt> value>, one
pair per line.  Strings used as values must be quoted. Barewords are
treated as numbers.  I<\xXX> represents a byte.

Most of the keywords are self-explanatory. I<subchar> means
substitution character, not subcharacter.  When you decode a Unicode
sequence to this encoding but no matching character is found, the byte
sequence defined here will be used.  For most cases, the value here is
\x3F; in ASCII, this is a question mark.

=item *

CHARMAP starts the character map section.  Each line has a form as
follows:

  <UXXXX> \xXX.. |0 # comment
    ^     ^      ^
    |     |      +- Fallback flag
    |     +-------- Encoded byte sequence
    +-------------- Unicode Character ID in hex

The format is roughly the same as a header section except for the
fallback flag: | followed by 0..3.   The meaning of the possible
values is as follows:

=over 4

=item |0 

Round trip safe.  A character decoded to Unicode encodes back to the
same byte sequence.  Most characters have this flag.

=item |1

Fallback for unicode -> encoding.  When seen, enc2xs adds this
character for the encode map only.

=item |2 

Skip sub-char mapping should there be no code point.

=item |3 

Fallback for encoding -> unicode.  When seen, enc2xs adds this
character for the decode map only.

=back

=item *

And finally, END OF CHARMAP ends the section.

=back

When you are manually creating a UCM file, you should copy ascii.ucm
or an existing encoding which is close to yours, rather than write
your own from scratch.

When you do so, make sure you leave at least B<U0000> to B<U0020> as
is, unless your environment is EBCDIC.

B<CAVEAT>: not all features in UCM are implemented.  For example,
icu:state is not used.  Because of that, you need to write a perl
module if you want to support algorithmical encodings, notably
the ISO-2022 series.  Such modules include L<Encode::JP::2022_JP>,
L<Encode::KR::2022_KR>, and L<Encode::TW::HZ>.

=head2 Coping with duplicate mappings

When you create a map, you SHOULD make your mappings round-trip safe.
That is, C<encode('your-encoding', decode('your-encoding', $data)) eq
$data> stands for all characters that are marked as C<|0>.  Here is
how to make sure:

=over 4

=item * 

Sort your map in Unicode order.

=item *

When you have a duplicate entry, mark either one with '|1' or '|3'.
  
=item * 

And make sure the '|1' or '|3' entry FOLLOWS the '|0' entry.

=back

Here is an example from big5-eten.

  <U2550> \xF9\xF9 |0
  <U2550> \xA2\xA4 |3

Internally Encoding -> Unicode and Unicode -> Encoding Map looks like
this;

  E to U               U to E
  --------------------------------------
  \xF9\xF9 => U2550    U2550 => \xF9\xF9
  \xA2\xA4 => U2550
 
So it is round-trip safe for \xF9\xF9.  But if the line above is upside
down, here is what happens.

  E to U               U to E
  --------------------------------------
  \xA2\xA4 => U2550    U2550 => \xF9\xF9
  (\xF9\xF9 => U2550 is now overwritten!)

The Encode package comes with F<ucmlint>, a crude but sufficient
utility to check the integrity of a UCM file.  Check under the
Encode/bin directory for this.

When in doubt, you can use F<ucmsort>, yet another utility under
Encode/bin directory.

=head1 Bookmarks

=over 4

=item *

ICU Home Page 
L<http://oss.software.ibm.com/icu/>

=item *

ICU Character Mapping Tables
L<http://oss.software.ibm.com/icu/charset/>

=item *

ICU:Conversion Data
L<http://oss.software.ibm.com/icu/userguide/conversion-data.html>

=back

=head1 SEE ALSO

L<Encode>,
L<perlmod>,
L<perlpod>

=cut

# -Q to disable the duplicate codepoint test
# -S make mapping errors fatal
# -q to remove comments written to output files
# -O to enable the (brute force) substring optimiser
# -o <output> to specify the output file name (else it's the first arg)
# -f <inlist> to give a file with a list of input files (else use the args)
# -n <name> to name the encoding (else use the basename of the input file.

With %seen holding array refs:

      865.66 real        28.80 user         8.79 sys
      7904  maximum resident set size
      1356  average shared memory size
     18566  average unshared data size
       229  average unshared stack size
     46080  page reclaims
     33373  page faults

With %seen holding simple scalars:

      342.16 real        27.11 user         3.54 sys
      8388  maximum resident set size
      1394  average shared memory size
     14969  average unshared data size
       236  average unshared stack size
     28159  page reclaims
      9839  page faults

Yes, 5 minutes is faster than 15. Above is for CP936 in CN. Only difference is
how %seen is storing things its seen. So it is pathalogically bad on a 16M
RAM machine, but it's going to help even on modern machines.
Swapping is bad, m'kay :-)

__END__
:endofperl
