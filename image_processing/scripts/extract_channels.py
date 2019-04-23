#!/usr/bin/env python
#
# Author: Takashi Kawase
#

import h5py
import numpy
import sys
import argparse
import os

argv = sys.argv
argv = argv[1:]

usage_text = ("Usage:" + "  python extract_channels.py" + " [options]")
parser = argparse.ArgumentParser(description=usage_text)
parser.add_argument("-i", "--input", dest="input", type=str, default="", help="Input file path")
parser.add_argument("-o", "--output", dest="output", type=str, default="", help="Output directory")

if not argv:
    parser.print_help()
    exit()

args = parser.parse_args(argv)

path = args.input
f = h5py.File(path, 'r')

chnum = len(f['Channels'].keys())
outdir = args.output
base = os.path.splitext(os.path.basename(path))
outfs = list()
for i in range(0, chnum):
    basename = base[0] + '_ch' + str(i) + '.h5j'
    newpath = os.path.join(outdir, basename)
    outfs.append(h5py.File(newpath, 'w'))
for a in f.attrs.items():
    for i in range(0, chnum):
        outfs[i].attrs.create(a[0], a[1])

for k in f.keys():
    if k != "Channels":
        for ch in range(0, chnum):
            f.copy(k, outfs[ch], k)
    else:
        for ch in range(0, chnum):
            outfs[ch].create_group(k)
            ochs = outfs[ch][k]
            for a in f[k].attrs.items():
                ochs.attrs.create(a[0], a[1])
            chls = list(f[k].keys())
            f[k].copy(chls[ch], ochs, chls[ch])

for i in range(0, chnum):
    outfs[i].close()
f.close()
