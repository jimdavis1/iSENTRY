#! /usr/bin/env perl
use strict;
use Data::Dumper;
use Getopt::Long;

my $usage = 'cleanup_PATRIC_metadata.pl [options] <PATRIC_source_file

	The source file is gotten either through the API, P3-scripts or in the following way:
	
	query_PATRIC_bob.pl -i genome_id -c genome -r "genome_id sra_accession genome_status genome_name host_name body_sample_site body_sample_subsite other_clinical host_health isolation_site isolation_source" <All.PATRIC.ids.3-2020.4>All.PATRIC.ids.3-2020.meta.4

	Where the columns are in a tab-delimited file and are:
	0.  genome id
	1.  sra accession (needed for processing non-patric genomes)
	2.  genome status
	3.  genome name
	4.  host name
	5.  body sample site
	6.  body sample subsite
	7.  other clinical
	8.  host health
	7.  isolation site
	10. isolation source
	
	-hs = host synonym file (id \t uniform name)
	-eo = environmental synonym file
	-bs = body site synonyms
	-uh = returns sorted unmatched hosts to stdout. useful for curation
	-uf = returns sorted final set of unclassified fields. useful for curation
	-ob = output body site file name
	-oe = output environment file name
	-oh = output host name
	

';
		
my $help;
my ($host_syns, $envt_syns, $body_syns, $unmatched_host, $unmatched_final, $envt_out, $host_out, $body_out, $keep_host); 
my $opts = GetOptions( 'h'   => \$help,
                       'hs=s' => \$host_syns,
                       'es=s' => \$envt_syns,
                       'bs=s' => \$body_syns,
                       'uh'   => \$unmatched_host,
                       'uf'   => \$unmatched_final,
                       'ob=s'   => \$body_out,
                       'oh=s'   => \$host_out,
                       'oe=s'   => \$envt_out); 

if ($help){die "$usage\n";}
unless ($host_syns){die "must declare host synonym file to proceed\n"}; 

# Step 1.  Classify Hosts. 

open (IN, "<$host_syns"), or die "cannot open host synonym file\n"; 
my %hosts; 
while (<IN>)
{
	chomp; 
	my ($bad, $good) = split /\t/;  
	$hosts{$bad} = $good;
	my $lcbad = lc $bad;
	$hosts{$lcbad} = $good;
}



close IN; 

my $host_classified  = {};
my $host_unclassified = {}; 

my $hc = 0; #host classified count
my $hu = 0; #host unclassified count
my $nh = 0; #no host

while (<>)
{
	chomp;
	
	# clean out all the bad shit.
	unless (($_ =~ /virus/i)|| ($_ =~ /Candidatus/i) || ($_ =~ /uncultured/i) || ($_ =~ /phage/i) || ($_ =~ /bacterium/i) || ($_ =~ /bacterium/i) || ($_ =~ /taxon/i) || ($_ =~ /plasmid/i))
	{
		my @array = split /\t/; 
		
		# clean up genus species.
		my $name = $array[3]; 
		$name =~ s/strain //g; 
		$name =~ s/sp\. /sp#/g; 
		my @names = split (" ", $name); 
		my $gs = "$names[0] $names[1]"; 
		$gs =~ s/#/\. /g;
		
		my $id = $array[0]; 
		
		if (exists $hosts{$array[4]})
		{
			my $host = $hosts{$array[4]};
			
			$host_classified->{$id}->{SPECIES} = $gs;
			$host_classified->{$id}->{HOST} = $host; 	
			$host_classified->{$id}->{META} = \@array;		
			$hc ++;
		}
		else
		{
			$host_unclassified->{$id}->{SPECIES} = $gs;
			$host_unclassified->{$id}->{META} = \@array;				
			if ($array[4])
			{
				$hu ++
			}
			else
			{
				$nh ++;
			}
		}
	}	
}

print STDERR "\nHost Clasified: $hc\n";
print STDERR "Host Unclassified\t$hu\n"; 
print STDERR "No Host\t$nh\n\n"; 


#
# Return unmatched host to STDOUT and die if -uh
#

if ($unmatched_host)
{
	my %unmatched;
	foreach (keys %{$host_unclassified})
	{
		if ($host_unclassified->{$_}->{META}->[4])
		{
			$unmatched{$host_unclassified->{$_}->{META}->[4]} ++; 
		}
	}
	foreach (sort {$unmatched{$a} <=> $unmatched{$b}} keys %unmatched)
	{
		print "$_\t$unmatched{$_}\n";
	}
	die;	
}

#
# Classify the environment for the set with unclassified host
#

open (IN, "<$envt_syns"), or die "cannot open environmental ontology file\n"; 
my $envts = {};
my $ec = 0; #envt classified
my $eu = 0; #envt unclassified
my $ne = 0; # no envt
my $processed = 0;
while (<IN>)
{
	chomp; 
	my @envts = split /\t/;
	my $key1 = shift @envts;
	my $key = lc $key1; 
	$envts->{$key} = \@envts; 
}
close IN; 

my $envt_classified  = {};
my $envt_unclassified = {}; 

foreach (keys %{$host_unclassified})
{
	$processed ++; 
	my $id = $_;
	my $sp = $host_unclassified->{$id}->{SPECIES}; 
	my $has_data = 0;
	
	my @ont;
	my $matched = 0;
	my $unmatched = 0;

	for my $i (4..10)  #cycle through the other metadata categories, look for envt matches
	{
		my $datum = lc $host_unclassified->{$id}->{META}->[$i];
		if (exists $envts->{$datum})
		{
			@ont = @{$envts->{$datum}}; 
			$matched = 1;
		}		
		# Last time I checked this there were 4 incongruent examples of sources in all the 
		# Metadata categories, so the last one is going to be the winner. 
		elsif ($datum)
		{
			$unmatched = 1;
		}
	}
	
	if (($unmatched == 1) && ($matched == 0))
	{
		$eu ++
	}
	elsif (($unmatched == 0) && ($matched == 0))
	{
		$ne ++;
	}
			
	if (@ont)
	{
		$envt_classified->{$id}->{SPECIES} = $sp;
		$envt_classified->{$id}->{ENVT} = \@ont;
		$envt_classified->{$id}->{META} = $host_unclassified->{$id}->{META};			
		$ec ++; 
	}

	else 
	{
		$envt_unclassified->{$id}->{SPECIES} = $sp;
		$envt_unclassified->{$id}->{META} = $host_unclassified->{$id}->{META};			
	}
}

print STDERR "\nEnvt Processed: $processed\n"; 
print STDERR "Environment Clasified: $ec\n";
print STDERR "Environment Unclassified\t$eu\n"; 
print STDERR "No Environment\t$ne\n\n"; 


#
# Classify the body site for the set with unclassified environment or human host
#


open (IN, "<$body_syns"), or die "cannot open body site ontology file\n"; 
my $body_sites = {};
my $bc = 0; #body classified
my $bu = 0; #body unclassified
my $nb = 0; #no body
my $bdy_processed = 0;

while (<IN>)
{
	chomp; 
	my @array = split /\t/;
	my $key1 = shift @array;
	my $key = lc $key1; 
	$body_sites->{$key} = \@array; 
}
close IN; 

my $body_classified  = {};
my $human_body_unclass = {}; # with human host, body site is Unclassified
my %final_unclassified; # has data but got missed.

#here I want to process both the environment unclassified set and the human classified set.
#Process human host set first.

foreach (keys %{$host_classified})
{
	my $id = $_;
	my $host = $host_classified->{$id}->{HOST};
	my $sp = $host_classified->{$id}->{SPECIES};
	
	my $has_data = 0;
	my @ont;
	my $matched = 0;
	my $unmatched = 0;
	
	if ($host =~ /Human/i)
	{
		$bdy_processed ++;
		for my $i (5..10)  #cycle through the other metadata categories, look for body site matches
		{
			my $datum = lc $host_classified->{$id}->{META}->[$i];
			if (exists $body_sites->{$datum})
			{
				@ont = @{$body_sites->{$datum}}; 
				$matched = 1;
			}		
			elsif ($datum)
			{
				$unmatched = 1;
			}
		}
	
		if (($unmatched == 1) && ($matched == 0))
		{
			$bu ++
		}
		elsif (($unmatched == 0) && ($matched == 0))
		{
			$nb ++;
		}
			
		if (@ont)
		{
			$body_classified->{$id}->{SPECIES} = $sp;
			$body_classified->{$id}->{BODY} = \@ont;
			$body_classified->{$id}->{HOST} = $host;
			$body_classified->{$id}->{META} = $host_classified->{$id}->{META};			
			$bc ++; 
		}

		else 
		{
			$human_body_unclass->{$id}->{SPECIES} = $sp;
			$human_body_unclass->{$id}->{HOST} = $host;
			$human_body_unclass->{$id}->{META} = $host_classified->{$id}->{META};			
		}
	}
}
print STDERR "\nTotal Human Host: $bdy_processed\n"; 
print STDERR "Body Site Processed from Human Host: $bc\n";
print STDERR "Human Host, data with no body site classification\t$bu\n"; 
print STDERR "No Body Site for human host\t$nb\n\n"; 


#Troll the Envt unclassified set to find the remaining ones with human body site data. 
my $final_processed = 0;
my $nhc = 0; #non human body site classified
my $nhu = 0; #no human body unclassified
my $nhnb = 0; #no human no bodysite
my $hrc = 0;
foreach (keys %{$envt_unclassified})
{
	my $id = $_;
	my $sp = $envt_unclassified->{$id}->{SPECIES};
	
	my $has_data = 0;
	my @ont;
	my @host;
	my $host;
	my $matched = 0;
	my $unmatched = 0;
	$final_processed ++;
	
	unless ($envt_unclassified->{$id}->{META}->[4])  # get rid of anything that could have been an animal host.
	{
		for my $i (5..10)  #cycle through the other metadata categories, look for body site matches
		{
			my $datum = lc $envt_unclassified->{$id}->{META}->[$i];
			
			if (exists $hosts{$datum})
			{
				$host = $hosts{$datum}; 
				$matched = 1;
			}		
			elsif (exists $body_sites->{$datum})
			{
				@ont = @{$body_sites->{$datum}}; 
				$matched = 1;
				#print Dumper $envt_unclassified->{$id}
			}		
			elsif ($datum)
			{
				$unmatched = 1;
			}
		}

		if (($unmatched == 1) && ($matched == 0))
		{
			$nhu ++;
			for my $j (4..10)
			{	
				$final_unclassified{$envt_unclassified->{$id}->{META}->[$j]}++;
			}
		}
		elsif (($unmatched == 0) && ($matched == 0))
		{
			$nhnb ++;
		}
		
		if ($host)
		{
			$host_classified->{$id}->{SPECIES} = $sp;
			$host_classified->{$id}->{HOST} = $host; 	
			$host_classified->{$id}->{META} = $envt_unclassified->{$id}->{META};		
			$hrc ++;
		}
		if (@ont)
		{
			$body_classified->{$id}->{SPECIES} = $sp;
			$body_classified->{$id}->{BODY} = \@ont;
			$body_classified->{$id}->{META} = $envt_unclassified->{$id}->{META};			
			$nhc ++; 
		}
	}
}
print STDERR "Host reclaimed from genomes with no declared host field: $hrc\n";
print STDERR "Body Site reclaimed from genomes with no declared human host: $nhc\n";
print STDERR "Unclassified with data, but not human body site\t$nhu\n"; 
print STDERR "Unclassified, no data\t$nhnb\n\n"; 

if ($unmatched_final)
{
	foreach (sort {$final_unclassified{$a} <=> $final_unclassified{$b}} keys %final_unclassified)
	{
		print "$_\t$final_unclassified{$_}\n";
	}
}


#PRINT OUTPUT FILES
if ($envt_out)
{
	open (OUT, ">$envt_out") or die "cannot open envt output file\n";
	foreach (sort keys %{$envt_classified})
	{
		my $id = $_;
		my $srr = $envt_classified->{$id}->{META}->[1];
		my $sp = $envt_classified->{$id}->{SPECIES};

		print OUT "$id\t$srr\t$sp\t";
		print OUT join "\t", @{$envt_classified->{$id}->{ENVT}},"\n"; 
	}
	close OUT;
}



if ($body_out)
{
	open (OUT, ">$body_out") or die "cannot open envt output file\n";
	foreach (sort keys %{$body_classified})
	{
		my $id = $_;
		my $srr = $body_classified->{$id}->{META}->[1];
		my $sp = $body_classified->{$id}->{SPECIES};
		my $host = $body_classified->{$id}->{HOST};
		
		
		print OUT "$id\t$srr\t$sp\t$host\t";
		print OUT join "\t", @{$body_classified->{$id}->{BODY}},"\n"; 
	}
	close OUT;
}



if ($host_out)
{
	open (OUT, ">$host_out") or die "cannot open envt output file\n";
	foreach (sort keys %{$host_classified})
	{
		my $id = $_;
		my $srr = $host_classified->{$id}->{META}->[1];
		my $sp = $host_classified->{$id}->{SPECIES};
		my $host = $host_classified->{$id}->{HOST};
		print OUT "$id\t$srr\t$sp\t$host\n";
	}
	close OUT;
}






















