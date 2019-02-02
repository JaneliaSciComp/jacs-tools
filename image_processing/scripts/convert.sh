#!/bin/sh
#
# Convert or copy
#
# Given an input stack, convert it into the given compatible format, or just copy it into place 
# if its already in the required format.
#
# The input files can be in these formats (may be compressed with bz2 or gzip):
# tif, v3draw, v3dpbd, lsm, h5j
# 
# The output files can be any of these formats (uncompressed):
# tif, zip (zipped tif), v3draw, v3dpbd, mp4, h5j, nrrd
#
# Optionally, this script can downsample the input to 8-bit when converting to v3draw or v3dpbd.
# 
# Optionally, this script can also split the input stack into multiple files, with each color channel in its own file. 
# This is required when choosing nrrd output because nrrd only supports one channel.
# 

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

Vaa3D="/opt/Vaa3d/vaa3d"
Fiji="/opt/Fiji/ImageJ-linux64"
export TMPDIR=""

NUMPARAMS=$#
if [ $NUMPARAMS -lt 3 ]
then
    echo " "
    echo " USAGE: sh $0 [input path] [output path] [split] <ref channels> <signal channels>"
    echo "   split: 1 if splitting, 0 if not splitting (default)"
    echo "   The channel parameters are 1-indexed and comma-delimited, with no spaces. They are only necessary when converting to H5J format."
    exit
fi

INPUT_FILE=$1
OUTPUT_FILE=$2
SPLIT_CHANNELS=$3
REF_CHAN=$4
SIGNAL_CHAN=$5
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
echo "Split channels: $SPLIT_CHANNELS"
echo "Ref channels: $REF_CHAN"
echo "Signal channels: $SIGNAL_CHAN"

OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
INPUT_FILE_EXT=${INPUT_FILE##*.}

if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && "$SPLIT_CHANNELS" = "0" ]]; then
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
    gzOutput=false
    if [[ "$OUTPUT_FILE_EXT" = "gz" ]]; then
        gzOutput=true
        OUTPUT_FILE=${OUTPUT_FILE%.*}
        OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
    fi

    if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && "$SPLIT_CHANNELS" = "0" ]]; then
        # The file is in the format we're looking for (for example, lsm)
        if [ "$bz2Output" = true ]; then
            # Bzip it into its final position
            echo "~ PBzipping $INPUT_FILE to $OUTPUT_FILE.bz2 with $NSLOTS slots"
            pbzip2 -zc -p$NSLOTS "$INPUT_FILE" > "$OUTPUT_FILE.bz2"
        elif [ "$bz2Output" = true ]; then
            # Gzip it into its final position
            echo "~ Gzipping $INPUT_FILE to $OUTPUT_FILE.bz2 with $NSLOTS slots"
            gzip -c "$INPUT_FILE" > "$OUTPUT_FILE.gz"
        else
            # Rsync it into its final position
            echo "~ Rsyncing $INPUT_FILE to $OUTPUT_FILE"
            rsync -av "$INPUT_FILE" "$OUTPUT_FILE"
        fi

    elif [[ "$OUTPUT_FILE_EXT" = "h5j" ]]; then

        echo "~ Converting $INPUT_FILE to $OUTPUT_FILE"
        CMD="$Vaa3D -cmd image-loader -codecs $INPUT_FILE $OUTPUT_FILE"

        if [[ ! -z $SIGNAL_CHAN ]]; then
            CMD="$CMD $SIGNAL_CHAN:HEVC:crf=$SIGNAL_COMPRESSION:psy-rd=1.0"
        fi

        if [[ ! -z $REF_CHAN ]]; then
            CMD="$CMD $REF_CHAN:HEVC:crf=$REF_COMPRESSION:psy-rd=1.0"
        fi

        echo "~ Executing: $CMD"
        $CMD

    else
        # Must convert
        if [[ "$OUTPUT_FILE_EXT" == "v3dpbd" || "$OUTPUT_FILE_EXT" == "mp4" ]]; then
            TEMP_FILE=$WORKING_DIR/temp.v3draw
            echo "~ Converting $INPUT_FILE to $TEMP_FILE using Fiji"
            $Fiji --headless -macro /opt/fiji_macros/convert_stack.ijm "$INPUT_FILE,$OUTPUT_FILE,$SPLIT_CHANNELS"
            echo "~ Converting $TEMP_FILE to $OUTPUT_FILE using Vaa3d"
            $Vaa3D -cmd image-loader -convert "$TEMP_FILE" "$OUTPUT_FILE" && rm -f $TEMP_FILE
        else 
            echo "~ Converting $INPUT_FILE to $OUTPUT_FILE using Fiji"
            $Fiji --headless -macro /opt/fiji_macros/convert_stack.ijm "$INPUT_FILE,$OUTPUT_FILE,$SPLIT_CHANNELS"
        fi
        # Compress in place, if necessary
        if [ "$bz2Output" = true ]; then
            echo "~ Compressing output file with pbzip2 with $NSLOTS slots"
            pbzip2 -p$NSLOTS $OUTPUT_FILE
        elif [ "$bz2Output" = true ]; then
            echo "~ Compressing output file with gzip"
            gzip $OUTPUT_FILE
        fi
    fi

fi
