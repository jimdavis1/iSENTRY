#! /usr/bin/env perl
use strict;
use Data::Dumper;
use Getopt::Long;

my $usage = 'All_PATRIC_genomes.pl [options]

	This program downloads all genomes from:
	ftp://ftp.patricbrc.org/RELEASE_NOTES/genome_summary
	

	Where the columns are in a tab-delimited file and are:
	0.  genome_name
	1.  taxon_id
	2.  genome_length
	3.  genome_status
	4.  chromosomes
	5.  plasmids
	6.  contigs
	7.  patric_cds
	9.  refseq_cds

	The default return is the full file.
	
	-h  = help
	-u  = return url:  ftp://ftp.patricbrc.org/RELEASE_NOTES/genome_summary
	-p  = ignore plasmids and phage
	-c  = return only complete
	-e  = ignore uncultured and environmental isolates
	-s  = ignore symbionts
	-t  = ignore candidatus and provisional taxonomy
	-sp = ignore sp. genomes
	
	
';
		
my $help;
my $url = "ftp://ftp.patricbrc.org/RELEASE_NOTES/genome_summary";

my ($u, $idonly, $noplasmid, $complete, $uncult, $symbiont, $candid, $sp); 
my $opts = GetOptions( 'h'   => \$help,
                       'u' => \$u,
                       'p' => \$noplasmid,
                       'i' => \$idonly,
                       'c' => \$complete,
                       'e' => \$uncult,
                       's' => \$symbiont,
                       't' => \$candid,
                       'sp' => \$sp); 

if ($help){die "$usage\n";}
if ($u){die "$url\n"}; 

open (IN, "curl $url | ");
my @keep;

my @array1 = (<IN>);
my @array;

my $size = scalar @array1;
print STDERR "Original Size\nSize = $size\n"; 

close IN; 

if ($noplasmid)
{
	print STDERR "No Plasmid\n"; 
	@array = @array1;
	@array1 = (); 
	@array1 = grep {$_ !~ /(plasmid)|(phage)|(virus)/i}@array;
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}


if ($uncult)
{
	print STDERR "No Uncultured\n"; 
	@array = @array1;
	@array1 = (); 
	@array1 = grep {$_ !~ /(uncultured)|(environmental)/i}@array;	
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}

if ($symbiont)
{
	print STDERR "No Symbionts\n"; 
	@array = @array1;
	@array1 = (); 
	@array1 = grep {$_ !~ /symbion/i}@array;	
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}

if ($candid)
{
	print STDERR "no Candidate tax\n"; 
	@array = @array1;
	@array1 = (); 
	foreach (@array)
	{
		my @line = split /\t/; 
		my $name = $line[1];
		unless (($name =~ /candid/i)|| ($name =~ /^\[/) || ($name =~ /^[a-z]/) || ($name =~ /(^\")|(^\')/) || ($name =~ /(taxon)|(archaeon)|(bacterium)/))
		{ 
			push @array1, $_;
		}
	}	
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}

if ($sp)
{
	print STDERR "no sp. genomes\n"; 
	@array = @array1;
	@array1 = (); 
	@array1 = grep {$_ !~ /sp\./i}@array;	
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}


if ($complete)
{
	print STDERR "Complete Only\n"; 
	@array = @array1;
	@array1 = (); 
	@array1 = grep {$_ =~ /complete/i}@array;	
	my $size = scalar @array1;
	print STDERR "Size = $size\n"; 
}


my @array = @array1;

foreach (@array)
{
	chomp;
	if ($idonly)
	{
		s/\t.+//g; 
		print "$_\n"; 
	}
	else
	{
		print "$_\n"; 
	}
}


















