import os

# Given script options and model parameters, runs
# kmc on input fasta file
def runKMC(options, modelParams):
	# get the fasta file, kmc location, and temp dir
	fastaFile = options.fastaFile
	kmcExe = options.kmcExe
	tempDir = options.tempDir

	# set k from model parameters
	k = str(modelParams['kmerSize'])

	# get basename of the fasta file
	base = os.path.basename(fastaFile)

	# command array to run kmc, error out goes to error file
	arr = [kmcExe, k, fastaFile, tempDir + base, tempDir, '1', '&>', options.outFile + '.kmc.err']
	os.system(' '.join(arr))

	# set output kmc file
	options.kmcOut = tempDir + base + '.' + k + '.kmrs'

# read kmc output file into kmer hash
def readKMC(options):
	# set output file and open
	kmcOut = options.kmcOut
	f = open(kmcOut)

	# for each line in kmc output, append to hash
	kmrHsh = {}
	for i in f:
		i = i.strip().split('\t')
		kmrHsh[i[0]] = int(i[1])

	f.close()

	# return hash
	return kmrHsh

# given kmer hash and attribute order, create kmer counts
# array
def hshToArr(kmrHsh, attrOrder):
	# initialize array to 'nan's
	arr = [float('nan')]*len(attrOrder)
	# for each item in kmer hash
	# if not in attribute order, wasn't trained on continue
	# else add to array
	for i in kmrHsh:
		if i not in attrOrder:
			continue

		ind = attrOrder[i]
		arr[ind] = kmrHsh[i]

	# return array
	return arr