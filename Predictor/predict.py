#!/usr/bin/env python
'''
python predict.py [--arg val] [-a val]
This is your main script used to make predictions with a model.  
Run predict.py -h for argument list.
'''

from sys import stderr
import sys
from optparse import OptionParser
import os
import shutil
import Model
from Err import err

# Some versions of XGBoost will request a GPU if it's
# availabe, even if it never uses it.  This will
# make the GPU invisible to the script.
os.environ["CUDA_VISIBLE_DEVICES"]=""

# takes a string and converts it to a boolean
def strToBool(s):
	if s.lower()[0] == 't':
		s = True
	else:
		s = False

	return s

# takes a directory name and an rm flag to check and
# make a directory.  If the rm flag is True then the
# directory is cleared if it already exists.
def makeDir(d, rm = True):
	flag = True
	if not os.path.isdir(d):
		if os.path.exists(d):
			print d, 'is not a directory'
			flag = False
		else:
			os.mkdir(d)
	else:
		if rm:
			shutil.rmtree(d)
			os.mkdir(d)

	return flag

# checks a directory name to make sure it exists
def checkDir(d):
	if os.path.isdir(d):
		return True
	else:
		print 'directory does not exist:', d
		return False

# checks a file name to make sure it exists
def checkFile(f):
	if os.path.exists(f):
		return True
	else:
		print 'file does not exist:', f
		return False

# cleans the directory name so it has a '/' at
# then end of the name.  Python does weird things
# sometimes if a file name is specified like
# dir//filename.txt.  Even if dir/filename.txt exists,
# it'll say it doesn't sometimes.  So the crude fix is
# to just stick to a directory naming convetion.
def cleanDir(d):
	if d == '':
		return d

	if d[-1] != '/':
		d += '/'

	return d

# reads all the options passed into the script and parses
# them for correctness
def getOptions():
	# init parser
	parser = OptionParser()

	# add options, defaults, etc.
	parser.add_option('-f', '--fasta_file', help="Specify the fasta file to predict on if model is K-mer based", metavar='FILE', default='', dest='fastaFile')
	parser.add_option('-m', '--model_dir', help='Specify the model directory to predict with', metavar='DIR', default='', dest='model')
	parser.add_option('-T', '--temp_dir', help='Specify a temporary directory to use', metavar='DIR', default='temp', dest='tempDir')
	parser.add_option('-o', '--out_file', help='Specify an output file', default='prediction.tab', dest='outFile')
	parser.add_option('-g', '--genus_species', help='Specify a genus/species for the fasta file', metavar='GENUS_SPECIES', default='', dest='spc')
	parser.add_option('-s', '--stats_mat', help='Specify the stats matrix file to base predictions off of', metavar='FILE', default='', dest='statMat')
	parser.add_option('-a', '--amr_model', help='Specify if the model is an AMR model since the matrix stat file is formatted slightly differently for that', metavar='BOOL=TRUE', default='TRUE', dest='isAMR')
	parser.add_option('-L', '--alignment', help='Specify the alignment file to predict on if alignment if model is alignment based', metavar='FILE', default='', dest='aliFile')
	parser.add_option('-k', '--kmc_sh_loc', help='Specify the location of kmc.sh required to run KMC', metavar='FILE', default='', dest='kmcExe')

	#parse options
	options,args = parser.parse_args()

	# convert isAMR to a boolean
	options.isAMR = strToBool(options.isAMR)

	# clean model and temp directory names
	options.model = cleanDir(options.model)
	options.tempDir = cleanDir(options.tempDir)
	# try to make temp directory
	if not makeDir(options.tempDir):
		err("Could not make directory: " + options.tempDir + '\n')
		exit(1)

	# if no input file, print error
	if options.fastaFile == '' and options.aliFile == '':
		err("Fasta file (-f|--fasta_file) or alignment file (-L|--alignment Required\n")
		exit(2)
	# if input file invalid, print error
	if options.fastaFile != '' and not checkFile(options.fastaFile):
		err("Fasta file doesn't exist\n")
		exit(2)
	if options.aliFile != '' and not checkFile(options.aliFile):
		err("Alignment file doesn't exist\n")
		exit(2)
	# check kmc executible, set if unset
	if options.kmcExe == '':
		dirName = os.path.dirname(__file__)
		if dirName[-1] != '/':
			dirName += '/'
		options.kmcExe = 'kmc.sh'
		options.kmcExe = dirName + 'kmc/kmc.sh'

	# check species name, it's required
	if options.spc == '':
		err("Genus/Species (-g|--genus_species) required\n")
		exit(3)

	# check to make sure the stat matrix exists
	if options.statMat == '':
		err("Model statistics matrix (-s|--stats_mat) required\n")
		exit(4)
	if not checkFile(options.statMat):
		err("Model statistics matrix doesn't exist\n")
		exit(4)

	return options, parser

# parse options
options,parser = getOptions()
# some versions of XGBoost will default to all threads, even if
# specified, this limits the number of visible threads to 1
os.environ["OMP_NUM_THREADS"] = '1'

# get predictions, order of predictions, and model statistics
pred,order,statInfo = Model.predict(options)
# get model directory and species
model = options.model
spc = options.spc

# open output file
f = open(options.outFile, 'w')

# print header
arr = ['Prediction', 'Subclass', 'Model Overall Score', 'Model Prediction Score']
f.write('\t'.join(arr) + '\n')
# for each prediction
for i in range(0,len(pred)):
	# get prediction, antibiotic (non-empty if AMR model),
	# overall accuracy and antibiotic/label accuracy for model
	pr = pred[i]
	ab = order[i]
	scal = statInfo[spc]['ALL']
	scab = ''
	if ab != '':
		scab = statInfo[spc][ab]
	else:
		scab = statInfo[spc][pr]
	# print line
	arr = [pr, ab, str(scal), str(scab)]

	f.write('\t'.join(arr) + '\n')

# close file
f.close()
