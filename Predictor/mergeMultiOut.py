#!/usr/bin/env python
'''
python mergeMultiOut.py [out 1] <out 2> ... <out n>
Takes multiple output files from the predict.py script and merges them into one table
'''

from sys import argv

def parseFile(fileName):
	f = open(fileName)

	f.readline()
	for i in f:
		i = i.strip()
		if len(i) == 0:
			continue

		print fileName + '\t' + i

	f.close()

arr = ['File Name', 'Prediction', 'Subclass', 'Model Overall Score', 'Model Prediction Score']
print '\t'.join(arr)

for i in range(1,len(argv)):
	parseFile(argv[i])