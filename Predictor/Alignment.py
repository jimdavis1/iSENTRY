# given options and attribute order, makes alignment vector
def readAlignment(options, attrOrder):
	f = open(options.aliFile)

	arr = [float('nan')]*len(attrOrder)
	for i in f:
		i = i.strip().split('\t')[-1]
		i = list(i)
		for j in range(0,len(i)):
			arr[j] = int(i[j])

	f.close()

	return arr
