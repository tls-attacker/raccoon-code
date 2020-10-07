#! /usr/bin/env python2

import sys
import random
import scipy.stats
import pickle
from tqdm import trange

def parse_line(line):
    _, type, timing = line[:-1].split(';')
    type = ['nothing', 'one', 'two'].index(type)
    timing = int(timing)
    return type, timing

def load_samples(f):
    samples = {}
    for line in f:
        type, timing = parse_line(line)
        lst = samples.setdefault(type, [])
        lst.append(timing)

    for lst in samples.values():
        lst.sort()

    return samples

def mann_whitney_test(false_positive_rate, expected_lower_type, expected_higher_type):
    _, pvalue = scipy.stats.mannwhitneyu(expected_lower_type, expected_higher_type, alternative='less')
    return pvalue < false_positive_rate

def main(filename, num_of_samples, false_positive_rate, num_of_simulations):
    print 'Opening file', filename
    print 'Doing %d simulations with %d samples per simulations, aiming for %f%% false positive rate' \
          % (num_of_simulations, num_of_samples, 100 * false_positive_rate)
    f = open(filename)
    samples = load_samples(f)
    higher_type = samples[0]
    lower_type  = samples[1]
    num_of_false_negatives = 0
    for i in trange(num_of_simulations):
        l1 = random.sample(lower_type, num_of_samples)
        l2 = random.sample(higher_type, num_of_samples)
        res = mann_whitney_test(false_positive_rate, l1, l2)
        if not res:
            num_of_false_negatives += 1

    print 'For %d samples, false negative rate is %f%% over %d simulations' \
          % (num_of_samples, 100 * float(num_of_false_negatives) / num_of_simulations, num_of_simulations)

    num_of_false_positives = 0
    for i in trange(num_of_simulations):
        l1 = random.sample(higher_type, num_of_samples)
        l2 = random.sample(higher_type, num_of_samples)
        res = mann_whitney_test(false_positive_rate, l1, l2)
        if res:
            num_of_false_positives += 1
    print 'For %d samples, false positive rate is %f%% over %d simulations' \
          % (num_of_samples, 100 * float(num_of_false_positives) / num_of_simulations, num_of_simulations)

if __name__ == '__main__':
    main(sys.argv[1], int(sys.argv[2]), float(sys.argv[3]) / 100, int(sys.argv[4]))
