#! /usr/bin/env bash

echo 'Analyzing 1032-bit modulus'
./mann_whitney_test.py kernel1032.run 100 10 5000

echo
echo 'Trying to achieve low FP rate, increase the number of experiments to properly evaluate it.'
./mann_whitney_test.py kernel1032.run 1000 0.01 50000

echo
echo 'Analyzing 1024-bit modulus'
./mann_whitney_test.py 1024bit.clean 1000 20 5000

echo
echo 'Trying to achieve low FP rate, increase the number of experiments to properly evaluate it.'
./mann_whitney_test.py 1024bit.clean 10000 0.01 10000
