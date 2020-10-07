#! /usr/bin/env python3

import sys
from tqdm import tqdm
from statistics import median, mean
import matplotlib.pyplot as plt

MAX_INPUT_LEN_FOR_GRAPH = 512 + 10

def get_tick_indices(xs, ys, diff_threshold, rising=True):
    res = []
    for i in range(1, len(xs)):
        if ys[i] - ys[i-1] > diff_threshold and rising:
            res.append(i-1)
        elif ys[i-1] - ys[i] > diff_threshold and not rising:
            res.append(i-1)
    return res

def get_label_from_filename(filename):
    if '256' in filename:
        return 'HMAC-SHA-256'
    if '384' in filename:
        return 'HMAC-SHA-384'
    raise

def unique(l):
    return [l[i] for i in range(len(l)) if l[i] not in l[:i]]

def merge_lists(l1, l2):
    return unique(sorted(l1) + sorted(l2))

def main(filenames):
    fig = plt.figure()
    plt.xlabel('Key length (bytes)')
    plt.ylabel('Cycles')
    ax1 = fig.add_subplot(111)
    ax1.set_xlim(0, MAX_INPUT_LEN_FOR_GRAPH)
    ax2 = ax1.twiny()
    ax2.set_xlim(0, MAX_INPUT_LEN_FOR_GRAPH)
    ax2.set_yticks([])

    for filename, ax in zip(reversed(filenames), [ax1, ax2]):
        xs = []
        ys = []
        for line in tqdm(open(filename).readlines()[:MAX_INPUT_LEN_FOR_GRAPH]):
            x, y = map(int, line[:-1].split())
            xs.append(x)
            ys.append(y)

        plt.plot(xs, ys, label=get_label_from_filename(filename))

        rising_tick_indices = get_tick_indices(xs, ys, 200, rising=True)
        rising_tick_xs = [xs[tick] for tick in rising_tick_indices]
        rising_tick_ys = [ys[tick] for tick in rising_tick_indices]
        ax.set_xticks(rising_tick_xs)
        ax.set_yticks(rising_tick_ys)

    plt.legend(loc='upper left')
    fig.savefig('Figure_3.png')
    plt.show()

if __name__ == '__main__':
    main(sys.argv[1:3])
