# Genomic Metadata Prediction for Merged Models

### Models

This package contains a prediction tool for various models that are trained on multiple species at a time.  They break down into 4 major forms of metadata:
1. Antimicrobial resistance (AMR) models for both susceptible-resistance calls and minimum inhibitory concentration prediction.  The former is setup as a binary classification while the latter is setup as a regression.
2. Body site isolation source to predict where an isolate was isolated if it came from a human.  There are 3 columns/levels to the hierarchy of the ontology with a single model for each.  
3. Environmental isolation source to predict the environment where an isolate was isolated.  These exclude isolates taken from human isolates.  There are three columns/levels to the hierarchy of the ontology with a single model for each.  
4. Host isolation source to predict the host in which the isolate was isolated from.  These generally include live animals in which the isolate was isolated from.  

Each of these 9 models (spanning the 4 above categories) can be found in the *Models* directory.  Each model contains an *all* folder which contains the model testing tabular files, predictions, raw trees, and models (pkl) themselves.  There are also various text files in the model's root directory.  A ***\*.mat*** file contains the statistical matrix which is used to determine what can and cannot be predicted (reliably) using said model.  It contains species as well as prediction labels, or antibiotics (in the event of AMR models) for each given species that exists.  ***This is used as an input into the predictor tool!***  

### Prediction Tool

The prediction tool is stored in the *Predictor* directory which contains all of the python and bash scripts required to run the tool with the exception of one.  The KMC tool (https://github.com/refresh-bio/KMC) which is used to count kmers.  Download the tool, compile it, and make sure it's in your *$PATH* bash variable (can be done in *~/.bash_profile* or *~/.bashrc* file).  

Besides the *kmc* directory, there are 3 other directories in the *Predictor* root, they are *temp*, *test_data*, and *test_out*.  As their names suggestions, they are either temporary or used for testing the script (all three are technically used to test the script).  To test the script to ensure you have a working environment, run the *runTests.sh* script as shown below.

```bash
$ cd Predictor
$ bash runTests.sh
```

Once run, the test_out directory should have all of its files updated.  There are two other python scripts that are designed to be run as part of this package:
1. *predict.py*: This is the script that is used to make predictions on a fasta file.  Support for alignment-based methods is baked into the script, though we currently don't provide any models that are alignment-based.  These may or may not come in the future.  
2. *mergeMultiOut.py*: If you run multiple models on the same fasta file you'll get multiple output files (one for each run).  The *mergeMultiOut.py* file will go ahead and merge each of these for you.  

#### predict.py

This script is run using a variety of options as defined below:
- -f | --fasta_file : Specify the fasta file used to get predictions from.  This is to be used if the model was trained with are K-mer based models.
- -m | --model_dir : Specify the location of the model directory to predict with.  These are all located within the *Models* directory of this package.
- -o | --out_file : Specify the file output to print the output to.  This will default to *predictions.tab* if none are supplied.  
- -g | --genus_species: specify the genus or species of the fasta file to predict with.  All the models provided by this package are currently species based, so provide a species.  Note that if the model is not trained with said species, no predictions will be made.  
- -s | --stats_mat : specify the location of the *\*.mat* file that is in the model's root directory.  For most classification models, it'll be an *f1.mat* file while the AMR MIC models will have *w1.mat* in their model's root directory.  
- -a | --amr_model : specify whether or not the model is an AMR-type model using *TRUE* or *FALSE*.  The statistical matrix file is slightly different for an AMR model over a regular metadata model since they are tested with multiple antibiotics.  By default the value for this is set to *TRUE*.  
- -L | --alignment : specify the alignment file used to get predictions from.  This is to be used if the model was trained using alignments.  Currently, none of the models in this package are trained using alignments.  
- -k | --kmc_sh_loc : specify the location of the *kmc.sh* script if it's not in the default location.  For example, if you've added the kmc.sh and kmc tools to your default paths, you could just specify *kmc.sh*.  If you want this to be default behavior, comment out the following line in the *predict.py* script

```python
def getOptions():
  ...
  options.kmcExe = dirName + 'kmc/kmc.sh' #COMMENT OUT THIS LINE
  ...
```

Example runs for this script can be seen in the *runTests.sh* script described above.  For reference there are a few test runs below as well.

```bash
$ cd Predictor
$ predict.py f test_data/562.23409.fasta -m test_data/model.hosts.d4/ -T temp -o test_out/output.$i.tab -g 'Escherichia coli' -s test_data/model.hosts.d4/f1.mat -a false
```

A sample output file is shown below:

```
Prediction	Subclass	Model Overall Score	Model Prediction Score
Human, Homo sapiens		0.647312781227	0.95548738499
```

The file is tab delimited with 4 columns:
1. Prediction : the prediction the model made
2. Subclass : for AMR models, the antibiotic is listed here
3. Model Overall Score: the overall score for the model on the input species.
4. Model Prediction Score: the score for the model on the input species given the predicted class

#### mergeMultiOut.py

In the prediction script above, specifying the -o or --out_file option will allow you to specify an output file.  Since the script will only run 1 fasta file on 1 model, to get a single genome run with multiple models, you'd have to create multiple output files.  the *mergeMultiOut.py* script allows you to merge these files into a single file.  It takes each of the input tabular files, removes the headers (creating its one single header) and appends the filename to the front of each line in said file before merging them together.  This script prints output to standard out, use bash redirects to output to a file.  Again, an example run of this can be seen in the *runTests.sh*.  For reference, an example is also below.  

```bash
$ cd Predictor
$ python mergeMultiOut.py test_out/output.[0-9]*.tab > test_out/mergeRes.tab
```

Sample output from a run is shown below.  Note that in this instance, 4 files with identical output were used as input into the model.

```
File Name	Prediction	Subclass	Model Overall Score	Model Prediction Score
/vol/ml/mnguyen/AMR_Model_Predictor_Mrg/test_out/output.0.tab	Human, Homo sapiens		0.647312781227	0.95548738499
/vol/ml/mnguyen/AMR_Model_Predictor_Mrg/test_out/output.1.tab	Human, Homo sapiens		0.647312781227	0.95548738499
/vol/ml/mnguyen/AMR_Model_Predictor_Mrg/test_out/output.2.tab	Human, Homo sapiens		0.647312781227	0.95548738499
/vol/ml/mnguyen/AMR_Model_Predictor_Mrg/test_out/output.3.tab	Human, Homo sapiens		0.647312781227	0.95548738499
```

There are 5 tab-delimited columns in this file's output:
1. File Name : The file name provided to the script.
2. Prediction : the prediction the model made
3. Subclass : for AMR models, the antibiotic is listed here
4. Model Overall Score: the overall score for the model on the input species.
5. Model Prediction Score: the score for the model on the input species given the predicted class
