#! /usr/bin/env bash

gcc -std=c11 openssl_hmac.c -lssl -lcrypto -ldl -o openssl_hmac || exit 1

# Change the number of measurements per key length to 10k to reproduce our
# setup, but this will take time. Or just use 1k as a good compromise.
./openssl_hmac sha256 100 > raw_sha256
./openssl_hmac sha384 100 > raw_sha384

./get_medians.py raw_sha256 > medians_sha256
./get_medians.py raw_sha384 > medians_sha384

# This shows the figure on screen, and also saves it as Figure_3.png
./plot.py medians_sha256 medians_sha384
