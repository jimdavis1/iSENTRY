

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

I have generated a program, *cleanup_PATRIC_metadata.pl* that reads a tab-delimite set of PATRIC fields in the following order

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
  
  


