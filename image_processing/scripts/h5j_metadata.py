#!/usr/bin/env python
#
# Import/export of HDF5 attributes. Given an HDF5 file as input, prints all of its attribute metadata to STDOUT as YAML.
# If YAML is provided on STDIN, the HDF5 is first updated with the attribute values from the given YAML.
#
# Attribute values are never deleted from the HDF5 unless an overriding attribute is provided in the YAML. 
#
# Note: this script was developed for use with H5J files, and has only been tested with a small set of attribute types.
#

# suppress harmless warnings (https://stackoverflow.com/questions/40845304/runtimewarning-numpy-dtype-size-changed-may-indicate-binary-incompatibility)
import warnings
warnings.filterwarnings("ignore", message="numpy.dtype size changed")
warnings.filterwarnings("ignore", message="numpy.ufunc size changed")

import sys
import yaml
import argparse
import numpy
from h5py import *

DEBUG = False
ATTRS = "attrs"
GROUPS = "groups"

def parse_cmd_args():
    parser = argparse.ArgumentParser(description='Read or write HDF5 attributes')
    parser.add_argument('input', help='Target HDF5 file')
    parser.add_argument('-d', '--debug', dest="debug", action="store_true", 
            help='Print debug output instead of writing to the file')
    args = parser.parse_args()
    return args


def process(filename, debug=False):

    global DEBUG
    DEBUG = args.debug

    if not sys.stdin.isatty():
        data = yaml.load(sys.stdin)
        write_metadata(filename, data)
        if DEBUG: print()

    if DEBUG: print("Reading attributes from %s"%filename)
    read_metadata(filename)


def write_metadata(filename, data):
    """ Take attributes in the dictionary provided and add them to the HDF5 file.
    """
    if DEBUG: print("Read input from YAML:\n%s"%yaml.dump(data, indent=2))
    h5_file = File(filename, mode='r+')
    root = h5_file['/']
    if DEBUG: print("Would write attributes to %s as follows:" % filename)
    write_attrs(root, data)
    h5_file.close()


def write_attrs(obj, data, level=0):

    indent = '  '*level

    if DEBUG: print("%s%s (%s)"%(indent, obj.name, type(obj).__name__))

    if ATTRS in data:
        attrs = data[ATTRS]
        # Walk through user-provided attributes and ensure
        # that they all exist in the HDF5 object
        for k in attrs:
            cv = obj.attrs[k] if k in obj.attrs else None
            v = attrs[k]
            if v is None: continue
            dt = get_datatype(v)

            if DEBUG: 
                print("  %s%s = %s (data type=%s, current value: %s)"%(indent, k, v, dt, cv))
            else:
                # Actually update the metadata. It would be better to use modify if possible,
                # but string lengths may change so we just recreate the attr each time.
                if cv is not None:
                    del obj.attrs[k]
                obj.attrs.create(k, v, None, dt)

    if GROUPS in data:
        for gc in data[GROUPS]:
            child = obj[gc]
            write_attrs(child, data[GROUPS][gc], level+1)


def get_datatype(value):
    """ Returns the dtype to use in the HDF5 based on the type of the object in the YAML.
        This isn't an exact science, and only a few dtypes are supported. In the future, 
        perhaps we could allow for dtype annotations in the YAML to avoid this kind of ambiguity.
    """

    if isinstance(value,str):
        strlen = len(value)
        if strlen==0: strlen=1
        return 'S%d'%strlen

    elif isinstance(value,int):
        return 'int64'

    elif isinstance(value,float):
        return 'float64'

    elif isinstance(value,list):
        # only lists of numbers are supported
        if len(value)>0:
            first = value[0]
            if isinstance(first,int):
                return 'int64'
            else:
                return 'float64'
        else:
            return 'int64'

    raise Exception("Value has unsupported data type: "+str(type(value)))


def read_metadata(filename, output=sys.stdout):
    """ Read attribute metadata from the given HDF5 file and print it to the specified stream.
    """
    h5_file = File(filename, mode='r')
    root = h5_file['/']
    data = read_attrs(root)
    yaml.dump(data, output)


def read_attrs(g):
    """ Given an HDF5 object, recursively collect its attribute metadata and return a 
        dictionary containing the metadata structured.
    """
    h = {}

    if hasattr(g, ATTRS):
        h[ATTRS] = {}
        for k in g.attrs:
            v = g.attrs[k]
            value = None
            if isinstance(v,numpy.ndarray):
                value = v.tolist()
            elif str(v.dtype)=='float64':
                value = float(v)
            elif str(v.dtype)=='int64':
                value = int(v)
            elif str(v.dtype).startswith('|S'):
                # Strings are stored as byte strings in HDF5 and must be decoded for storage in YAML
                value = v.decode("utf-8")
            else:
                raise Exception("Unrecognized data type: "+str(v.dtype))
            h['attrs'][k] = value

    if type(g) in (Group,):
        h[GROUPS] = {}
        for k in g:
            h[GROUPS][k] = read_attrs(g[k])

    return h


if __name__ == "__main__":
    args = parse_cmd_args()
    process(args.input, args.debug)

