#!/bin/bash
#
# image alignment pipeline 1.0, March 28, 2012 
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

##################
# Inputs
##################

parseParameters "$@"

CONFIGFILE=$DIR/systemvars.apconf
TEMPLATE_DIR=$TEMPLATE_DIR
TOOLDIR=$TOOL_DIR
WORKDIR=$WORK_DIR
INPUT_FILE=$INPUT1_FILE

FINAL_DIR=$WORKDIR/FinalOutputs
FINAL_OUTPUT=$FINAL_DIR/Aligned63x.v3draw

Vaa3D="/opt/Vaa3D/vaa3d"
ANTS="/opt/ANTS/ANTS"
WARP="/opt/ANTS/antsApplyTransforms"
SAMPLE="/opt/ANTS/ResampleImageBySpacing"
WARPOLD="/opt/ANTS/WarpImageMultiTransform"

FINAL_DIR=${FINAL_OUTPUT%/*}
FINAL_STUB=${FINAL_OUTPUT%.*}
OUTPUT_FILENAME=`basename $FINAL_OUTPUT`

WORKING_DIR=${WORKDIR}"/Outputs"
OUTPUT=$WORKING_DIR
FINALOUTPUT=$FINAL_DIR

if [ ! -d $OUTPUT ]; then
    mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then
    mkdir $FINALOUTPUT
fi

cd $WORKING_DIR

echo "Run Dir: $DIR"
echo "Working Dir: $WORKING_DIR"
echo "Input file: $INPUT_FILE"
echo "Final Output Dir: $FINAL_DIR"

EXT=${INPUT_FILE#*.}
if [ $EXT == "v3dpbd" ]; then
    echo "~ Converting v3dpbd to v3draw"
    PBD_INPUT_FILE=$INPUT_FILE
    INPUT_FILE_STUB=`basename $PBD_INPUT_FILE`
    INPUT_FILE="$WORKING_DIR/${INPUT_FILE_STUB%.*}.v3draw"
    $Vaa3D -cmd image-loader -convert "$PBD_INPUT_FILE" "$INPUT_FILE"
fi

# for local alignment
FIXED="$TEMPLATE_DIR/fbtemplate8bit4localalign.nii"

# for global alignment
INPUT1="$TEMPLATE_DIR/fbavgtemplate8bit.v3draw"
INPUT_REFNO1=1

# subject images
INPUT2=$INPUT_FILE
INPUT_REFNO2=$INPUT1_REF

# output
OUTPUT="$WORKING_DIR/wb63x_"
SUBPREFIX=$OUTPUT

##################
# global alignment
##################

echo "~ Running global alignment"
$Vaa3D -x ireg -f globalalign -o $SUBPREFIX -p "#s $INPUT2 #cs $INPUT_REFNO2 #t $INPUT1 #ct $INPUT_REFNO1"
GA_AFFINE=$SUBPREFIX"Affine.txt"
GA_FLIP=$SUBPREFIX"Flip.txt"
MOVING0=$SUBPREFIX"Deformed.v3draw"

##################
# local alignment
##################

#MAXITERATIONS=30x90x20
MAXITERATIONS=50x0

echo "~ Running NiftiImageConverter on $MOVING0"
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVING0
MOVING=$SUBPREFIX"Deformed_c0.nii"
echo "~ Removing $MOVING0"
rm $MOVING0
echo "~ Space usage: " `du -h $WORKING_DIR`

# ANTS output
SIMMETRIC=$WORKING_DIR"/cc"
AFFINEMATRIX=$WORKING_DIR"/ccAffine.txt"
FWDDISPFIELD=$WORKING_DIR"/ccWarp.nii.gz"
BWDDISPFIELD=$WORKING_DIR"/ccInverseWarp.nii.gz"

FIXEDDS="fixed_ds.nii"
MOVINGDS="moving_ds.nii"
SAMPLERATIO=4
echo "~ Running resampling on $FIXED -> $FIXEDDS"
$SAMPLE 3 $FIXED $FIXEDDS $SAMPLERATIO $SAMPLERATIO $SAMPLERATIO
echo "~ Running resampling on $MOVING -> $MOVINGDS"
$SAMPLE 3 $MOVING $MOVINGDS $SAMPLERATIO $SAMPLERATIO $SAMPLERATIO 

echo "~ Running ANTS on [$FIXEDDS,$MOVINGDS]"
$ANTS 3 -m  CC[ $FIXEDDS, $MOVINGDS, 1, 8]  -t SyN[0.25]  -r Gauss[3#,0] -o $SIMMETRIC --use-Histogram-Matching  -i $MAXITERATIONS --number-of-affine-iterations 100x100x100

echo "~ Removing $FIXEDDS"
rm $FIXEDDS
echo "~ Removing $MOVINGDS"
rm $MOVINGDS
echo "~ Space usage: " `du -h $WORKING_DIR`

##################
# warping
##################

### global warping ###
GA_OUTPUT=$SUBPREFIX"RigidTransformed.v3draw"

echo "~ Running global warping"
$Vaa3D -x ireg -f iwarp -p "#s $INPUT2 #t $INPUT1 #a $GA_AFFINE #f $GA_FLIP" -o $OUTPUT
MOVINGC1=$SUBPREFIX"RigidTransformed_c0.nii"
MOVINGC2=$SUBPREFIX"RigidTransformed_c1.nii"
MOVINGC3=$SUBPREFIX"RigidTransformed_c2.nii"
MOVINGC4=$SUBPREFIX"RigidTransformed_c3.nii"

echo "~ Running NiftiImageConverter on $GA_OUTPUT"
$Vaa3D -x ireg -f NiftiImageConverter -i $GA_OUTPUT -o $SUBPREFIX

echo "~ Removing $GA_OUTPUT"
rm $GA_OUTPUT
echo "~ Space usage: " `du -h $WORKING_DIR`

### local warping ###
DEFORMEDC1=$SUBPREFIX"warpedc0.nii"
DEFORMEDC2=$SUBPREFIX"warpedc1.nii"
DEFORMEDC3=$SUBPREFIX"warpedc2.nii"
DEFORMEDC4=$SUBPREFIX"warpedc3.nii"

echo "~ Running local warping"

echo "~ Running local warping on $MOVINGC1"
$WARPOLD 3 $MOVINGC1 $DEFORMEDC1 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX $BWDDISPFIELD --use-BSpline
echo "~ Running local warping on $MOVINGC2"
$WARPOLD 3 $MOVINGC2 $DEFORMEDC2 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX $BWDDISPFIELD --use-BSpline
echo "~ Running local warping on $MOVINGC3"
$WARPOLD 3 $MOVINGC3 $DEFORMEDC3 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX $BWDDISPFIELD --use-BSpline
echo "~ Running local warping on $MOVINGC4"
$WARPOLD 3 $MOVINGC4 $DEFORMEDC4 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX $BWDDISPFIELD --use-BSpline

echo "~ Running NiftiImageConverter on:\n  $DEFORMEDC1\n  $DEFORMEDC2\n  $DEFORMEDC3\n  $DEFORMEDC4"
LA_OUTPUT=$SUBPREFIX"Aligned.v3draw"
$Vaa3D -x ireg -f NiftiImageConverter -i $DEFORMEDC1 $DEFORMEDC2 $DEFORMEDC3 $DEFORMEDC4 -o $LA_OUTPUT -p "#b 1 #v 2"

echo "~ Moving final output to $FINAL_OUTPUT"
mv $LA_OUTPUT $FINAL_OUTPUT
mv $WORKING_DIR/*.log $FINAL_DIR
mv $WORKING_DIR/*.csv $FINAL_DIR

if [[ -f "$FINAL_OUTPUT" ]]; then
META=${FINAL_DIR}"/Aligned.properties"
echo "alignment.stack.filename=$OUTPUT_FILENAME" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.space.name=JFRC2010_20x" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x512x218" >> $META
echo "alignment.objective=20x" >> $META
fi

compressAllRaw $Vaa3D $WORKDIR

