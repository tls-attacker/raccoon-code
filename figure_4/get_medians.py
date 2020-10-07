#! /usr/bin/env python3

import sys
from statistics import median, mean
from collections import defaultdict
from tqdm import tqdm
import matplotlib.pyplot as plt

INITIAL_ARRAY_SIZE_PER_LEN = 100 * 1000

def get_tick_indices(xs, ys, diff_threshold, rising=True):
    res = []
    for i in range(1, len(xs)):
        if ys[i] - ys[i-1] > diff_threshold and rising:
            res.append(i-1)
        elif ys[i-1] - ys[i] > diff_threshold and not rising:
            res.append(i-1)
    return res

def main(filename):
    d = defaultdict(list)
    for line in tqdm(open(filename)):
        input_len, timing = map(int, line[:-1].split('\t'))
        d[input_len].append(timing)

    xs = []
    ys = []
    for input_len in sorted(d.keys()):
        xs.append(input_len)
        ys.append(int(median(d[input_len])))
        print(input_len, ys[-1])

    fig = plt.figure()
    ax1 = fig.add_subplot(111)
    ax1.plot(xs, ys)
    ax1.set_xlim(0, max(xs))
    ax2 = ax1.twiny()
    ax2.set_xlim(0, max(xs))

    xmin, xmax, ymin, ymax = plt.axis()
    ax1.set_ylim(ymin, ymax)
    print(plt.axis())
    print(ax1.get_ybound())
    print(ax1.get_ylim())
    rising_tick_indices = get_tick_indices(xs, ys, 200, rising=True)
    rising_tick_xs = [xs[tick] for tick in rising_tick_indices]
    rising_tick_ys = [ys[tick] for tick in rising_tick_indices]
    ax1.set_xticks(rising_tick_xs)

    falling_tick_indices = get_tick_indices(xs, ys, 200, rising=False)
    falling_tick_xs = [xs[tick] for tick in falling_tick_indices]
    falling_tick_ys = [ys[tick] for tick in falling_tick_indices]
    ax2.set_xticks(falling_tick_indices)
    average_peak_height = int(mean(falling_tick_ys + [ys[tick+1] for tick in rising_tick_indices]))
    ax1.set_yticks(list(ax1.get_yticks()) + [average_peak_height])
    ax1.vlines(rising_tick_xs, ax1.get_ybound()[0], rising_tick_ys, linestyle="dashed")
    ax2.vlines(falling_tick_xs, ax2.get_ylim()[1], falling_tick_ys, linestyle="dashed")

    fig.savefig('Figure_4.png')
    plt.xlabel('Input length')
    plt.ylabel('Cycles')
    plt.show()

if __name__ == '__main__':
    main(sys.argv[1])
