#!/bin/bash
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

Vaa3D="/opt/Vaa3D/vaa3d"
Fiji="/opt/Fiji/ImageJ-linux64"
export TMPDIR=""

NUMPARAMS=$#
if [ $NUMPARAMS -lt 2 ]
then
    echo " "
    echo " USAGE: sh $0 [input path] [output path] [split] <ref channels> <signal channels>"
    echo "   split: 1 if splitting, 0 if not splitting (default)"
    echo "   The channel parameters are 1-indexed and comma-delimited, with no spaces. They are only necessary when converting to H5J format."
    exit
fi

INPUT_FILE=$1
OUTPUT_FILE=$2
SPLIT_CHANNELS=${3:=0}
REF_CHAN=$4
SIGNAL_CHAN=$5
WORKING_DIR=`mktemp -d -p /dev/shm`
cd $WORKING_DIR

function cleanWorkingDir {
    rm -rf $WORKING_DIR
    echo "~ Cleaned up $WORKING_DIR"
}
trap cleanWorkingDir EXIT

# This is needed to ensure that there are no collisions on the cluster. 
# By default, Javacpp caches to ~/.javacpp/cache and the java.io.tmpdir is /tmp
JAVA_OPTS="-Dorg.bytedeco.javacpp.cachedir=$WORKING_DIR -Djava.io.tmpdir=$WORKING_DIR"
OUTPUT_DIR=`dirname $OUTPUT_FILE`
OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
INPUT_FILE_EXT=${INPUT_FILE##*.}

echo "----------------------------------------------------------------------"
echo "  $INPUT_FILE_EXT -> $OUTPUT_FILE_EXT"
echo "  Input file: $INPUT_FILE"
echo "  Output file: $OUTPUT_FILE"
if [[ "$SPLIT_CHANNELS" = "1" ]]; then
    echo "  Split channels: $SPLIT_CHANNELS"
fi
echo "  Channels: ref=$REF_CHAN signal=$SIGNAL_CHAN"
echo "----------------------------------------------------------------------"

function encodeH5J {
    local _in="$1"
    local _out="$2"

    echo "~ Converting $_in to $_out"
    CMD="$Vaa3D -cmd image-loader -codecs $_in $_out"

    if [[ ! -z $SIGNAL_CHAN ]]; then
        CMD="$CMD $SIGNAL_CHAN:HEVC:crf=$SIGNAL_COMPRESSION:psy-rd=1.0"
    fi

    if [[ ! -z $REF_CHAN ]]; then
        CMD="$CMD $REF_CHAN:HEVC:crf=$REF_COMPRESSION:psy-rd=1.0"
    fi

    echo "~ Executing: $CMD"
    $CMD
}

if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && "$SPLIT_CHANNELS" = "0" ]]; then
    # The file is already in the format we're looking for (for example, lsm.bz2), so just copy it over
    echo "~ Rsyncing $INPUT_FILE to $OUTPUT_FILE"
    rsync -av "$INPUT_FILE" "$OUTPUT_FILE"
else
    # Decompress input file if necessary
    ensureUncompressedFile "$WORKING_DIR" "$INPUT_FILE" INPUT_FILE
    echo "Uncompressed input file:"
    ls -lh $INPUT_FILE
    INPUT_FILE_EXT=${INPUT_FILE##*.}

    # Check if we need to compress output file, and strip off the compression extension for now
    bz2Output=false
    gzOutput=false
    if [[ "$OUTPUT_FILE_EXT" = "bz2" ]]; then
        bz2Output=true
        OUTPUT_FILE=${OUTPUT_FILE%.*}
        OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
    elif [[ "$OUTPUT_FILE_EXT" = "gz" ]]; then
        gzOutput=true
        OUTPUT_FILE=${OUTPUT_FILE%.*}
        OUTPUT_FILE_EXT=${OUTPUT_FILE##*.}
    fi

    if [[ "$INPUT_FILE_EXT" = "$OUTPUT_FILE_EXT" && "$SPLIT_CHANNELS" = "0" ]]; then

        # The uncompressed file is already in the format we're looking for

        if [ "$bz2Output" = true ]; then
            # Bzip it into its final position
            echo "~ PBzipping $INPUT_FILE to $OUTPUT_FILE.bz2 with $NSLOTS slots"
            pbzip2 -zc -p$NSLOTS "$INPUT_FILE" > "$OUTPUT_FILE.bz2"
        elif [ "$gzOutput" = true ]; then
            # Gzip it into its final position
            echo "~ Gzipping $INPUT_FILE to $OUTPUT_FILE.bz2"
            gzip -c "$INPUT_FILE" > "$OUTPUT_FILE.gz"
        else
            # Rsync it into its final position
            echo "~ Rsyncing $INPUT_FILE to $OUTPUT_FILE"
            rsync -av "$INPUT_FILE" "$OUTPUT_FILE"
        fi

    elif [[ "$INPUT_FILE_EXT" = "h5j" && "$SPLIT_CHANNELS" = "1" ]]; then

        # Special case for splitting an H5J file

        echo "~ Splitting H5J channels in $INPUT_FILE"
        export PATH="/usr/local/anaconda/bin:$PATH"
        source activate py3
        /opt/scripts/extract_channels.py -i $INPUT_FILE -o $WORKING_DIR
        ls $WORKING_DIR
        # Compress all temporary output files by recursively calling this script
        shopt -s nullglob
        for fin in $(find $WORKING_DIR -name "*.h5j"); do
            inbase=`basename $fin`
            inbase=${inbase%.h5j}
            fout=$OUTPUT_DIR/${inbase}"."${OUTPUT_FILE_EXT}
            /opt/scripts/convert.sh $fin $fout 0 $REF_CHAN $SIGNAL_CHAN
        done
        shopt -u nullglob

    elif [[ ("$INPUT_FILE_EXT" = "v3dpbd" || "$INPUT_FILE_EXT" = "v3draw") && "$OUTPUT_FILE_EXT" = "h5j" && "$SPLIT_CHANNELS" = "0" ]]; then

        # When encoding a new H5J file, use vaa3d.
        # Unlike the Fiji plugin, we can specify differential compression for the signal and reference channels.
        encodeH5J $INPUT_FILE $OUTPUT_FILE

    else
        # To create PBD or MP4 files, we must use Vaa3d, since Fiji does not support these as output formats.
        if [[ "$OUTPUT_FILE_EXT" == "v3dpbd" || "$OUTPUT_FILE_EXT" == "mp4" || "$OUTPUT_FILE_EXT" = "h5j" ]]; then

            # Use Fiji to convert to RAW first. This gives us the greatest input file compatibility (for example, with zipped TIFFs which are not supported by Vaa3d)
            TEMP_FILE=$WORKING_DIR/temp.v3draw
            echo "~ Pre-converting $INPUT_FILE to $TEMP_FILE using Fiji"
            $Fiji $JAVA_OPTS --headless -macro /opt/fiji_macros/convert_stack.ijm "$INPUT_FILE,$TEMP_FILE,$SPLIT_CHANNELS"

            # If channel splitting, there will be multiple files to encode
            if [[ "$SPLIT_CHANNELS" == "1" ]]; then

                # Compress all temporary output files by recursively calling this script
                shopt -s nullglob
                for fin in $(find . -name "$WORKING_DIR/*.v3draw"); do
                    inbase=${fin%.v3draw}
                    fout=${inbase}"."${OUTPUT_FILE_EXT}
                    ./$0 $fin $fout
                done
                shopt -u nullglob

            else
                if [[ "$OUTPUT_FILE_EXT" = "h5j" ]]; then
                    encodeH5J $TEMP_FILE $OUTPUT_FILE
                else
                    echo "~ Converting $TEMP_FILE to $OUTPUT_FILE using Vaa3d"
                    $Vaa3D -cmd image-loader -convert "$TEMP_FILE" "$OUTPUT_FILE" && rm -f $TEMP_FILE
                fi
            fi

        else
            # All other cases, such as creating RAW, TIFF, ZIP, or NRRD files, with or without splitting
            echo "~ Converting $INPUT_FILE to $OUTPUT_FILE using Fiji"
            $Fiji $JAVA_OPTS --headless -macro /opt/fiji_macros/convert_stack.ijm "$INPUT_FILE,$OUTPUT_FILE,$SPLIT_CHANNELS"
        fi

        shopt -s nullglob
        for fin in $(find $OUTPUT_DIR -name "*.$OUTPUT_FILE_EXT"); do
            # Compress in place, if necessary
            if [ "$bz2Output" = true ]; then
                echo "~ Compressing with pbzip2 with $NSLOTS slots: $fin"
                pbzip2 -p$NSLOTS $fin
            elif [ "$gzOutput" = true ]; then
                echo "~ Compressing with gzip: $fin"
                gzip $fin
            fi
        done
    fi

fi
