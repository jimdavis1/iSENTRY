

# MetaData Cleanup Work, last updated 3-2020

This repo contains the up to date metadata cleanup work that has been done for the iSENTRY project using the data from PATRIC.

The objective of this work is to build clean metadata fields that describe bacterial pathogens and non pathogens for use in machine learning and other algorithmic prediction projects. 

PATRIC contains genomes and metadata from GenBank and other sources, including the literature and data for genomes assembled from SRA.

Data that related to pathogenicity, and which might be most predictive for models include the following SOLR fields:

* host name
* body sample site
* body sample subsite
* other clinical
* host health
* isolation site
* isolation source

The host name field at patric has received the most attention, and is also the most populated.  
The remaining fields vary in their quality and some are nearly free form text. 

I have generated a program, *cleanup_PATRIC_metadata.pl* that reads a tab-delimited set of PATRIC fields in the following order:

	0.  genome id
	1.  sra accession
	2.  genome status
	3.  genome name
	4.  host name
	5.  body sample site
	6.  body sample subsite
	7.  other clinical
	8.  host health
	7.  isolation site
	10. isolation source
  
 It also reads as input a set of ontology tables (tab-delimited text format) for cleaning up the fields. Current versions are:  
 
 * Host-3-20.txt
 * Envt-3-20.txt
 * Body-3-20.txt
 
 These are managed by hand in a corresponding set of excel files. 
 
 The code works in the following way:
 1.  It reads the host ontology and cleans the host filed
 2.  For genomes lacking a curated host, it reads the Environment ontology, and applies the environment ontology for any field that maches in fileds 5-10.
 3.  For genomes with a human host, it reads fields 5-10 and tries to apply the human body site ontology 
 4.  For genomes with no classifie environment or host it reads fields 5-10 and tries to find human host, or human body site
 
 
 
 
 
 
 
 


