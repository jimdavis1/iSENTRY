

# MetaData Cleanup Work, last updated 3-2020

This repo contains the up to date metadata curation work that has been done for the iSENTRY project using the data from PATRIC.

The objective of this project is to build clean metadata fields that describe bacterial pathogens and non pathogens for use in machine learning and other algorithmic forms of prediction. 

PATRIC contains genomes and metadata from GenBank and other sources, including the literature and data for genomes assembled from SRA. 

The following fields relate to pathogenicity in the PATRIC SOLR schema, have the most data, and are likely to be most predictive:

* host name
* body sample site
* body sample subsite
* other clinical
* host health
* isolation site
* isolation source

The host name field at patric has received the most curation, and is also the most populated.  
The remaining fields vary in their quality and some are nearly free form text. 

I have generated a program, *`cleanup_PATRIC_metadata.pl`* that reads a tab-delimited set of PATRIC fields in the following order:

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
  
 It also reads as input a set of otology tables (tab-delimited text format) for cleaning up the fields. Current versions are:  
 
 * Host-3-20.txt
 * Envt-3-20.txt
 * Body-3-20.txt
 
 These are managed by hand in a corresponding set of excel files. 
 
 The code works in the following way:

    1. It reads the host ontology and cleans the host field
    2. For genomes lacking a curated host, it reads the environment ontology and applies the environment ontology for any field that matches in fileds 5-10.
    3. For genomes with a human host, it reads fields 5-10 and tries to apply the human body site ontology 
    4. For genomes with no classified host or environment, it reads fields 5-10 and tries to find a human host field or a human body site.  This last step is optional.


The code returns three formatted files:

    1.  Genomes with formatted hosts 
    2.  Genomes with formatted environments
    3.  Genomes with formatted human body sites (these overlap with #1)

The output files are:
   
    Host-3-20.txt
    Body-3-20.txt
    Envt-3-20.txt

The output files are formatted as ID, SRA ID, species, host, curated metadata

The host ontology file is a simple mapping between commonly occuring host names to a standard host name, e.g.,
    
| Common Name | Curated name |
| ----------- | -----------  |
|  Chicken | Chicken, Gallus gallus



    
    Young Chickens	Chicken, Gallus gallus
ANIMAL-chicken	Chicken, Gallus gallus
Chickens	Chicken, Gallus gallus
Gallus gallus	Chicken, Gallus gallus
Gallus gallus domesticus	Chicken, Gallus gallus
Gallus gallus domesticus (chicken)	Chicken, Gallus gallus
Young Chicken	Chicken, Gallus gallus
animal-chicken-young chicken	Chicken, Gallus gallus
chicken	Chicken, Gallus gallus
egg laying hen	Chicken, Gallus gallus
Animal-Chicken-Young Chicken	Chicken, Gallus gallus
chicken	Chicken, Gallus gallus








