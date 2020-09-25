#! /usr/bin/env python3

import sys
from statistics import median, mean
from collections import defaultdict
from tqdm import tqdm

def main(filename):
    d = defaultdict(list)
    for line in tqdm(open(filename)):
        input_len, timing = map(int, line[:-1].split('\t'))
        d[input_len].append(timing)

    for input_len in sorted(d.keys()):
        print(input_len, int(median(d[input_len])))

if __name__ == '__main__':
    main(sys.argv[1])
