#!/bin/sh
#
# Convert or copy
#
# Given an input file which is accessible either in JFS or on disk, and is a vaa3d compatible format,
# convert it into the given vaa3d compatible format, or just copy it into place if its already in the
# required format.
#
# The input files can be in these formats (may be compressed with bz2 or gzip):
# tif, v3draw, v3dpbd, lsm, mp4, h5j
# 
# The output files can be any of these formats (uncompressed):
# tif, v3draw, v3dpbd, mp4, h5j
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

Vaa3D="/opt/Vaa3d/vaa3d"
SyncScript="/misc/local/jfs/jfs"
export TMPDIR=""

NUMPARAMS=$#
if [ $NUMPARAMS -lt 2 ]
then
    echo " "
    echo " USAGE: sh $0 [input path or URL] [output path]"
    echo " "
    exit
fi

INPUT_FILE=$1
OUTPUT_FILE=$2
SAVE_TO_8BIT=$3
WORKING_DIR=`mktemp -d -p /dev/shm`
cd $WORKING_DIR

function cleanWorkingDir {
    rm -rf $WORKING_DIR
    echo "~ Cleaned up $WORKING_DIR"
}
trap cleanWorkingDir EXIT
        
echo "Run Dir: $DIR"
echo "Working Dir: $WORKING_DIR"
echo "Input file: $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"

OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}

ensureLocalFile "$SyncScript" "$WORKING_DIR" "$INPUT_FILE" INPUT_FILE
echo "Local input file: $INPUT_FILE"
INPUT_FILE_EXT=${INPUT_FILE##*.}

if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && -z $SAVE_TO_8BIT ]]; then
    # The file is already in the format we're looking for (for example, lsm.bz2)
    echo "~ Rsyncing $INPUT_FILE to $OUTPUT_FILE"
    rsync -av "$INPUT_FILE" "$OUTPUT_FILE"
else
    # Decompress input file
    ensureUncompressedFile "$WORKING_DIR" "$INPUT_FILE" INPUT_FILE
    echo "Uncompressed input file:" `ls -lh $INPUT_FILE`
    INPUT_FILE_EXT=${INPUT_FILE##*.}

    # Check if we need to compress output file
    bz2Output=false
    if [[ "$OUTPUT_FILE_EXT" = "bz2" ]]; then
        bz2Output=true
        OUTPUT_FILE=${OUTPUT_FILE%.*}
        OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
    fi

    if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && -z $SAVE_TO_8BIT ]]; then
        # The file is in the format we're looking for (for example, lsm)
        if [ "$bz2Output" = true ]; then
            # Bzip it into its final position
            echo "~ PBzipping $INPUT_FILE to $OUTPUT_FILE.bz2 with $NSLOTS slots"
            pbzip2 -zc -p$NSLOTS "$INPUT_FILE" > "$OUTPUT_FILE.bz2"
        else
            # Rsync it into its final position
            echo "~ Rsyncing $INPUT_FILE to $OUTPUT_FILE"
            rsync -av "$INPUT_FILE" "$OUTPUT_FILE"
        fi
    else
        # Must convert using Vaa3d
        echo "~ Converting $INPUT_FILE to $OUTPUT_FILE"
        $Vaa3D -cmd image-loader -convert$SAVE_TO_8BIT "$INPUT_FILE" "$OUTPUT_FILE"
        if [ "$bz2Output" = true ]; then
            echo "~ Compressing output file with pbzip2 with $NSLOTS slots"
            pbzip2 -p$NSLOTS $OUTPUT_FILE
        fi
    fi

fi
