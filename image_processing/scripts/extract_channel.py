#!/usr/bin/env python
#
# Author: Takashi Kawase
#
import h5py
import numpy
import sys
import argparse

argv = sys.argv
argv = argv[1:]

usage_text = ("Usage:" + "  python extract_channel.py" + " [options]")
parser = argparse.ArgumentParser(description=usage_text)
parser.add_argument("-i", "--input", dest="input", type=str, default="", help="Input file path")
parser.add_argument("-c", "--channel", dest="channel", type=int, default="", help="channel id")
parser.add_argument("-o", "--output", dest="output", type=str, default="", help="Output file path")

if not argv:
    parser.print_help()
    exit()

args = parser.parse_args(argv)

path = args.input
f = h5py.File(path, 'r')

newpath = args.output
outf = h5py.File(newpath, 'w')

chnum = len(f['Channels'].keys())
ch = args.channel
if ch >= chnum or ch < 0:
    exit()

for a in f.attrs.items():
    outf.attrs.create(a[0], a[1])

for k in f.keys():
    if k != "Channels":
        f.copy(k, outf, k)
    else:
        outf.create_group(k)
        ochs = outf[k]
        for a in f[k].attrs.items():
            ochs.attrs.create(a[0], a[1])
        chls = list(f[k].keys())
        print(list(f[k][chls[ch]].attrs.items()))
        f[k].copy(chls[ch], ochs, chls[ch])

outf.close()
f.close()

