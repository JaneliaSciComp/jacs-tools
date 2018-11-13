#!/bin/bash
#
# Wrapper script for testing alignment pipelines 
#

DIR=$(cd "$(dirname "$0")"; pwd)

SCRIPT_PATH=$1
NUM_THREADS=$2
OUTPUT_DIR=$3
YAML_FILE=$4
DEBUG_MODE="${5:-release}"
FB_MODE="${6:-xvfb}"

export NSLOTS=$NUM_THREADS

echo "~ Alignment Script: $SCRIPT_PATH"
echo "~ Num Threads: $NUM_THREADS"
echo "~ Output Dir: $OUTPUT_DIR"
echo "~ Yaml File: $YAML_FILE"
echo "~ Debug Mode: $DEBUG_MODE"

# Temporary alignment artifacts are too large for local scratch space,
# so we need to keep them on network storage.
WORKING_DIR="$OUTPUT_DIR/temp"
rm -rf $WORKING_DIR
mkdir $WORKING_DIR
cd $WORKING_DIR

function cleanTemp {
    if [[ $DEBUG_MODE =~ "debug" ]]; then
        echo "~ Debugging mode - Leaving temp directory"
    else
        echo "Cleaning $WORKING_DIR"
        rm -rf $WORKING_DIR
        echo "Cleaned up $WORKING_DIR"
    fi
}


if [[ $FB_MODE =~ "xvfb" ]]; then
    # initialize virtual framebuffer
    START_PORT=`shuf -i 5000-6000 -n 1`
    . $DIR/initXvfb.sh $START_PORT
    function exitHandler() { cleanXvfb; cleanTemp; }
    trap exitHandler EXIT
else
    function exitHandler() { cleanTemp; }
    trap exitHandler EXIT
fi

# run aligner
echo ""
echo "~ Running aligner:"
echo ""
CMD="$SCRIPT_PATH $YAML_FILE $WORKING_DIR"
echo $CMD
eval $CMD
echo ""
echo "~ Computations complete"
echo ""

echo ""
echo "~ Listing working files:"
echo ""
ls -lR $WORKING_DIR

echo "~ Moving final output to $OUTPUT_DIR"
mv $WORKING_DIR/FinalOutputs/* $OUTPUT_DIR

echo "~ Finished"

