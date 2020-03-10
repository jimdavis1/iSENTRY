import ast
import numpy as np
from glob import glob
import xgboost as xgb
import KMC
import Alignment
from Err import err

# reads the parameter file and sets parameters
def getParams(options):
	modelDir = options.model
	f = open(modelDir + 'model.params')
	params = f.readline().strip()
	params = ast.literal_eval(params)
	f.close()

	return params

# reads feature file and sets order
# also gets non-genomic features by searching for sequences that
# aren't genomic bases
def getFeatureOrder(options):
	# set model directory
	modelDir = options.model

	# open attribute order file
	f = open(modelDir + 'model.attrOrder')

	# read attribute order file
	attrOrder = {}
	for i in f:
		i = i.strip().split('\t')
		attrOrder[i[0]] = int(i[1])

	f.close()

	# initialize bases
	bases = {
		'a':0,
		'c':0,
		'g':0,
		't':0
	}

	# check each item in attrOrder to see if nucl
	# if not add to non-genomic
	nonGenomic = {}
	for i in attrOrder:
		isGenomic = True
		if i[0].isalpha():
			for j in i:
				if j.lower() not in bases:
					isGenomic = False
					break
		else:
			isGenomic = False

		if not isGenomic:
			nonGenomic[i] = attrOrder[i]

	# return attribute order and non-genomic features
	return attrOrder, nonGenomic

# reads header of the statistical matrix file
def parseStatHeader(f):
	# read a line and split by tab
	line = f.readline().strip('\n').split('\t')
	# initialize hash
	headHsh = {}
	# for each element in line, add to hash
	for i in range(0,len(line)):
		headHsh[i] = line[i]

	# return hash
	return headHsh

# Reads through statistic matrix to get model statistics
# per species and label/antibiotic
def getStatInfo(options):
	# open up the file
	f = open(options.statMat)
	# parse the header
	headHsh = parseStatHeader(f)

	# read through file to set items in the statistic hash
	statInfo = {}
	for i in f:
		i = i.strip('\n').split('\t')
		spc = i[0]
		statInfo[spc] = {}
		for j in range(1,len(i)):
			if i[j] == '':
				continue

			scr = float(i[j])
			statInfo[spc][headHsh[j]] = scr

	f.close()

	# return stat hash
	return statInfo

# Reads through the label mapping for the model
def getLabHsh(options):
	# open up label map file
	f = open(options.model + 'model.labels.map')

	# for each line add to label hash
	labHsh = {}
	for i in f:
		i = i.strip().split('\t')
		i[1] = float(i[1])
		labHsh[i[1]] = i[0]

	f.close()

	# return hash
	return labHsh

# builds a matrix to predict with
def makeMatrix(options):
	# read model params, get attribute order and initialize array
	modelParams = getParams(options)
	attrOrder, nonGenomic = getFeatureOrder(options)
	arr = []
	# if fasta file, run KMC and convert to array
	if options.fastaFile != '':
		KMC.runKMC(options, modelParams)
		arr = KMC.hshToArr(KMC.readKMC(options), attrOrder)
	# else read alignment file
	else:
		arr = Alignment.readAlignment(options.attrOrder)

	# if the length of the array isn't the length of the attributes
	# append with float('nan')s
	while len(arr) != len(attrOrder):
		arr.append(float('nan'))

	# set the species and get stat info
	spc = options.spc
	statInfo = getStatInfo(options)

	# if species not in stat info, return none
	if spc not in statInfo:
		return [], statInfo

	# initalize matrix and order
	mat = []
	order = []
	# if AMR model set the AMR flag for each antibiotic trained on
	# for the given species
	if options.isAMR:
		for i in statInfo[spc]:
			abInd = attrOrder[i]
			mat.append(np.asarray(arr))
			mat[-1][abInd] = 1
			order.append(i)
	# else juse add the array as is
	else:
		mat.append(np.asarray(arr))
		order.append('')

	# return the matrix, ordering of the matrix, and model statistics
	return np.asarray(mat), order, statInfo

# makes predictions and also returns order of predictions and
# statistics
def predict(options):
	# initialize matrix, order, and stats
	mat,order,statInfo = makeMatrix(options)

	# open up model file
	modFile = glob(options.model + 'all/model.0*pkl')[0]
	mod = xgb.Booster(model_file = modFile)

	# initialize the DMatrix
	dm = xgb.DMatrix(mat)

	# get predictions (numpy array is returned)
	predNp = mod.predict(dm)

	# predictions to return (converted to list of str)
	pred = []
	# initialize the label hash (maps float -> label)
	labHsh = getLabHsh(options)
	# for each prediction
	# convert label and append
	for i in range(0,len(predNp)):
		lab = labHsh[predNp[i]]
		pred.append(lab)

	# Return stuff.
	return pred, order, statInfo
