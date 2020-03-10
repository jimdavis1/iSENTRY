#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

testDataDir=$DIR/test_data
testOutDir=$DIR/test_out

for i in $(echo 0 1 2 3); do
	$DIR/predict.py -f test_data/562.23409.fasta -m $testDataDir/model.hosts.d4/ -T temp -o $testOutDir/output.$i.tab -g 'Escherichia coli' -s $testDataDir/model.hosts.d4/f1.mat -a false
done

$DIR/mergeMultiOut.py $testOutDir/output.*.tab > $testOutDir/mergeRes.tab