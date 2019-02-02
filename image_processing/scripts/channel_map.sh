#!/bin/bash
#
# Normalize an image by mapping its channels and converting it to v3draw format 
#

DIR=$(cd "$(dirname "$0")"; pwd)
Vaa3D="/opt/Vaa3D/vaa3d"
INPUT_FILE=""
OUTPUT_FILE=""
CHANNEL_MAPPING=""

while getopts "i:o:m:h" opt
do case "$opt" in
    i)  INPUT_FILE="$OPTARG";;
    o)  OUTPUT_FILE="$OPTARG";;
    m)  CHANNEL_MAPPING="$OPTARG";;
    h) echo "Usage: $0 [-i input_file] [-o output_file] [-m channel_mapping]" >&2
        exit 1;;
    esac
done
shift $((OPTIND-1))

# If all channels are mapped to themselves, then this will result in an empty string
R=`echo "$CHANNEL_MAPPING" | sed -r "s/([0-9]),\1,?//g"`

echo "Run Dir: $DIR"
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "Channel Mapping: $CHANNEL_MAPPING"
echo "Mapping residue: $R"

if [ $INPUT_FILE = $OUTPUT_FILE ]; then

    OUTPUT_DIR=${OUTPUT_FILE%/*}
    export TMPDIR="$OUTPUT_DIR"
    WORKING_DIR=`mktemp -d`
    TEMP_FILE="$WORKING_DIR/temp.v3draw"
    echo "Working Dir: $WORKING_DIR"
    echo "Using Temp File: $TEMP_FILE"

    if [ "$R" == "" ]; then
        echo "File is already in place and in the correct format/channel ordering."
    else
        cd $WORKING_DIR
        echo "Mapping file: $INPUT_FILE"
        $Vaa3D -cmd image-loader -mapchannels $INPUT_FILE $TEMP_FILE $CHANNEL_MAPPING
        mv $TEMP_FILE $OUTPUT_FILE
    fi
    
    echo "~ Removing working directory $WORKING_DIR"
    rm -rf $WORKING_DIR

else
    echo "Mapping file: $INPUT_FILE"
    $Vaa3D -cmd image-loader -mapchannels $INPUT_FILE $OUTPUT_FILE $CHANNEL_MAPPING
fi

echo ""

