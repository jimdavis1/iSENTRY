

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
    
| PATRIC Name | Curated Name |
| ----------- | -----------  |
|  ANIMAL-chicken | Chicken, Gallus gallus
|  Chickens | Chicken, Gallus gallus
|  Gallus gallus | Chicken, Gallus gallus
|  Young Chicken | Chicken, Gallus gallus
|  animal-chicken-young chicke | Chicken, Gallus gallus
|  egg laying hen | Chicken, Gallus gallus



The environment ontology file is a simple mapping between names in the database and environments of varying levels of specificity, e.g.,

| PATRIC Name | Level 1     |Level 2     |Level 3       |Level 4 |
| ----------- | ----------- | -----------| -----------  | -----------  |
|Tap water|environmental|water|freshwater|drinking or tap water
|household tap filter|environmental|water|freshwater|drinking or tap water
|lake water|environmental|water|freshwater|freshwater pond or lake
|freshwater lake|environmental|water|freshwater|freshwater pond or lake
|Lake Lanier|environmental|water|freshwater|freshwater pond or lake
|freshwater lake, 40-80 m depth|environmental|water|freshwater|freshwater pond or lake
|Advanced Water Purification Facility|environmental|water|freshwater|water purification facility


Likewise, the body site ontology file is also a simple mapping between names in the database and body sites of varying levels of specificity.  It also provides disease and whether or not the sample is listed as a clinical specimen or from a healty person. 

| PATRIC Name | Level 1     |Level 2     |Disease      |Clinical or Healthy|
| ----------- | ----------- | -----------| -----------  | -----------  |
|intestinal cancer|intestine|gastrointestinal tract|cancer|clinical|
|intestinal metaplasia|intestine|gastrointestinal tract|intestinal metaplasia|clinical|
|intestinal metaplasia|intestine|gastrointestinal tract|intestinal metaplasia|clinical|
|intestine|intestine|gastrointestinal tract||clinical|
|intestine of patients with crohn's disease|intestine|gastrointestinal tract|chrons disease|clinical|

These ontologies are obviously a work in progress.  They are intended to be as simple as possible and to yeild the most predictive power.  In this regard, the body site data still requires the most work  because the body sites are currently least predicitive and also not deliniated in a way that offers good predictive power. 

