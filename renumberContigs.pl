#!/usr/bin/perl
#Written by Bryan Wee

=comment

Each genbank file must have ONLY ONE source feature from start to end. The sources will be converted to fasta_record and will look like a contig in the final merged genbank file.
Modified line 110: Added \W{0,1} before $2 by Nathan Bachmann on 3/12/12
Does not handle joined features such as merged contigs. - BW 6/3/2013 - this feature needs to be added.


=cut

use strict;
use warnings;

my $file = $ARGV[0];
my $stack = 0;
my $stackEND = 0;
my $stackFEATURESEND = 0;
my $totalLength;
my @array;
my $oneHeaderStored = 0;
my $concatenatedSequence;
my $newrecord = 0;

#Added by Nathan Bachmann on 3/12/12
my $usage = <<'USAGE';

USAGE:

renumberContigs.pl <Multi genbank file> 

Converts a multi genbank file into single genbank file so it is readable in Artemis

USAGE

#print the usage if no files are entered
unless (defined ($ARGV[0]))
{
	print $usage;
	exit;
}


open (IN, "$file") or die;

while (my $line = <IN>)
{
	if ($line =~ (/^\/\/$/))
	{
		$newrecord = 0;
		next;
	}
	
	if ($oneHeaderStored == 0)
	{
			#if ($line =~ (/^LOCUS\s+\w+\s+(\d+)\sbp/)) #finds the first line and pulls out total length of the seq
			#{
				#$totalLength += $1;
				#print $totalLength, "\n";
			
				#push (@array, $line);
			#	print $line;
			#	next;
			#}
			
			if ($line =~ /^FEATURES/)
			{
				#push (@array, $line);
				print $line;
				$oneHeaderStored = 1;
				next;
			}
			
			else
			{
				print $line;
				next;
				#push (@array, $line);
			}
		
	}	
	
		
		
		
		
	if ($line =~ /^\s+source\s+\W{0,1}(\d+)\.\.\W{0,1}(\d+)/) #pulls out coordinates of source line. replaces them with contig details
	{
		my $start = $1;
		#print $start, "\n";
		$stack = $1 + $stackEND;
		#print $stack, "\n";
		my $stop = $2;
		#print $stop, "\n";
		$stackFEATURESEND = $1 + $stackEND - 1;
		
		$stackEND = $2 + $stackEND;
		#print $stackEND, "\n";
		
		
		$line =~ (s/source\s{10}/fasta_record    /); #replaces source with fasta record
		$line =~ (s/$start..\W{0,1}$stop/$stack..$stackEND/); #substitutes the coordinates with the stacked counts #added \W{0,1} BW 6/3/2013
		
		#push (@array, $line);
		print $line;
		$newrecord = 1;
		next;
	}



	if ($newrecord == 1)
	{
		if ($line =~ /(\d+)\.\.\W{0,1}(\d+)/) #pulls out coordinate lines and replaces them with the right increment in value. ^\s{5}\w+\s+\w*?\(* 
		{
			my $startFeature = $1 + $stackFEATURESEND;
			my $stopFeature = $2 + $stackFEATURESEND;
			$line =~ (s/$1..\W{0,1}$2/$startFeature..$stopFeature/); #Added \W{0,1} before $2 by NB on 3/12/12 
			
			#push (@array, $line);
			print $line;
			next;
		}
	}

	if ($line =~ /^\s{21}/) #prints out lines that contain features (genes, cds)
	{
		#push (@array, $line);
		print $line;
		next;
	}
	
	if ($line =~ /^\s+(\d+\s{0,1}\w{0,10}\s{0,1}\w{0,10}\s{0,1}\w{0,10}\s{0,1}\w{0,10}\s{0,1}\w{0,10}\s{0,1}\w{0,10})/) #this regex pulls out sequence lines
	{
		my @splitSequenceLine = split(/\s/, $1); 
		#print join('--', @splitSequenceLine), "\n\n\n\n\n\n\n"; #this was used to test the sequence LINE that was pulled out from the genbank file
		shift(@splitSequenceLine);
		#print @splitSequenceLine, "\n\n\n\n\n\n\n\n\n\n\n\n"; #same as last coment
		my $joinedSequence = join('', @splitSequenceLine);
		#print $joinedSequence, "\n\n\n\n\n\n\n"; #same as last comment
		$concatenatedSequence .= $joinedSequence;
	}
	
	else
	{
		next;#print $line;
	}
}

#this part below prints out the sequence bit under ORIGIN in a genbank file

print "ORIGIN\n";

my $length = 60;

for ( my $pos = 0 ; $pos < length($concatenatedSequence) ; $pos += $length )
{
	my $lineOfSequence = substr($concatenatedSequence, $pos, $length);
			
	my $numberAtBegin = $pos + 1;
	my $numberOfSpaces = 9 - length($numberAtBegin);
	print " " x $numberOfSpaces , $numberAtBegin;
	
	for ( my $pos2 = 0 ; $pos2 < length($lineOfSequence) ; $pos2 += 10 )
		{
		print " ", substr($lineOfSequence, $pos2, 10);
		}
	
	print "\n";
}

print "//\n";

exit
