#! /usr/bin/env bash

gcc -std=c11 openssl_hash.c -lssl -lcrypto -ldl -o openssl_hash || exit 1

# Change the number of measurements per key length to 10k to reproduce our
# setup, but this will take time. Or just use 1k as a good compromise.
./openssl_hash > raw_sha256

./get_medians.py raw_sha256
