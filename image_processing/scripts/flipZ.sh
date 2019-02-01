#!/bin/bash
#
# Normalize a face down image by flipping it over like a pancake.
#
# The flip is done around the diagonal from the upper left to the lower right. 
# This is because tissue is oriented along this diagonal, so after flipping 
# the orientation is preserved.
#
# Temporarily creates working files in the current working directory.
#

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` [source path] [target path]"
    exit 65
fi

# Exit on error
set -e

DIR=$(cd "$(dirname "$0")"; pwd)
Vaa3D="/opt/Vaa3D/vaa3d"
SOURCE_FILE=$1
TARGET_FILE=$2

echo "Vaa3D: $Vaa3D"
echo "Source: $SOURCE_FILE"
echo "Target: $TARGET_FILE"

TEMP_FILE1="ymirrored.v3draw"
TEMP_FILE2="zflipped.v3draw"
echo "Working Dir: $WORKING_DIR"

echo "Mirroring in Y-axis"
time $Vaa3D -x ireg -f xflip -i $SOURCE_FILE -o $TEMP_FILE1
echo "Mirroring in Z-axis"
time $Vaa3D -x ireg -f zflip -i $TEMP_FILE1 -o $TEMP_FILE2
echo "Rotating back"
time $Vaa3D -x rotate -f left90 -i $TEMP_FILE2 -o $TARGET_FILE

echo "Removing temporary files"
rm $TEMP_FILE1
rm $TEMP_FILE2

echo "Flip completed"
