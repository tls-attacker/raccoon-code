#! /usr/bin/env bash

echo 'Analyzing 1032-bit modulus'
./mann_whitney_test.py kernel1032.run 100 10 5000

echo 'Trying to achieve low FP rate, increase the number of experiments to properly evaluate it.'
./mann_whitney_test.py /localwork/racoon/kernel1032.run 1000 0.01 50000
